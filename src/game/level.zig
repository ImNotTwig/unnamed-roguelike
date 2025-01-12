const std = @import("std");
const rl = @import("raylib");
const tiles = @import("./tiles.zig");
const game = @import("./game.zig");

// a Tile which is false should be obscured from the player
pub const TileData = struct {
    hidden: bool,
    color: rl.Color,
};
pub const Tile = union(enum) {
    stair: TileData,
    floor: TileData,
    wall: TileData,

    other: TileData,
};

pub const Level = struct {
    const Corner = struct {
        v: enum { top, bottom },
        h: enum { right, left },
    };

    size: rl.Vector2,
    tiles: std.ArrayList(std.ArrayList(Tile)),

    // if given an allocator, this will populate the tiles field with only the specified tile,
    // otherwise it will leave it as undefined
    pub fn new(size: rl.Vector2, tile_type: Tile, allocator: ?std.mem.Allocator) !@This() {
        const ux: usize = @intFromFloat(size.x);
        const uy: usize = @intFromFloat(size.y);

        if (allocator) |a| {
            var tile_list = std.ArrayList(std.ArrayList(Tile)).init(a);
            for (0..ux) |i| {
                try tile_list.append(std.ArrayList(Tile).init(a));
                for (0..uy) |_| {
                    try tile_list.items[i].append(tile_type);
                }
            }
            return .{
                .size = size,
                .tiles = tile_list,
            };
        } else {
            return .{
                .size = size,
                .tiles = undefined,
            };
        }
    }

    fn getValidTileFromCorners(
        area: std.ArrayList(rl.Vector2),
        entrance_corner: Corner,
        exit_corner: *Corner,
        allocator: std.mem.Allocator,
    ) !struct {
        entrance: std.ArrayList(rl.Vector2),
        exit: std.ArrayList(rl.Vector2),
    } {
        var greatest_y: f32 = 0;
        var greatest_x: f32 = 0;
        var least_x: f32 = area.items[0].x;
        var least_y: f32 = area.items[0].y;
        for (area.items) |coord| {
            if (coord.x > greatest_x) greatest_x = coord.x;
            if (coord.y > greatest_y) greatest_y = coord.y;
            if (coord.y < least_y) least_y = coord.y;
            if (coord.x < least_x) least_x = coord.x;
        }
        const x_first_4th: usize = @intFromFloat((greatest_x - least_x) / 4);
        const x_third_4th: usize = @intFromFloat((greatest_x - least_x) * 3 / 4);

        const y_first_4th: usize = @intFromFloat((greatest_y - least_y) / 4);
        const y_third_4th: usize = @intFromFloat((greatest_y - least_y) * 3 / 4);

        var valid_entrance_coords = std.ArrayList(rl.Vector2).init(allocator);
        var valid_exit_coords = std.ArrayList(rl.Vector2).init(allocator);

        var exit_tries: usize = 0;
        while (valid_entrance_coords.items.len == 0 or valid_exit_coords.items.len == 0) {
            if (valid_entrance_coords.items.len == 0 and exit_tries == 2) {
                std.log.err("Somehow there were no open tiles available for the entrance???\n", .{});
                std.process.exit(1);
            } else {}
            if (valid_exit_coords.items.len == 0) {
                if (exit_tries == 0) {
                    exit_corner.h = switch (exit_corner.h) {
                        .left => .right,
                        .right => .left,
                    };
                } else if (exit_tries == 1) {
                    exit_corner.v = switch (exit_corner.v) {
                        .top => .bottom,
                        .bottom => .top,
                    };
                    exit_corner.h = switch (exit_corner.h) {
                        .left => .right,
                        .right => .left,
                    };
                } else if (exit_tries == 2) {
                    std.log.err("Could not produce a map with stairs far away enough from each other. Please be patient while this gets resolved in a better manner than crashing the program.\n", .{});
                    std.process.exit(1);
                }
                exit_tries += 1;
            }

            switch (entrance_corner.v) {
                .top => {
                    switch (entrance_corner.h) {
                        .left => {
                            for (area.items) |coord| {
                                const xu: usize = @intFromFloat(coord.x);
                                const yu: usize = @intFromFloat(coord.y);

                                if (xu <= x_first_4th and yu <= y_first_4th) {
                                    try valid_entrance_coords.append(coord);
                                }
                                if (xu >= x_third_4th and yu >= y_third_4th) {
                                    try valid_exit_coords.append(coord);
                                }
                            }
                        },
                        .right => {
                            for (area.items) |coord| {
                                const xu: usize = @intFromFloat(coord.x);
                                const yu: usize = @intFromFloat(coord.y);

                                if (xu >= x_third_4th and yu <= y_first_4th) {
                                    try valid_entrance_coords.append(coord);
                                }
                                if (xu <= x_first_4th and yu >= y_third_4th) {
                                    try valid_exit_coords.append(coord);
                                }
                            }
                        },
                    }
                },
                .bottom => {
                    switch (entrance_corner.h) {
                        .left => {
                            for (area.items) |coord| {
                                const xu: usize = @intFromFloat(coord.x);
                                const yu: usize = @intFromFloat(coord.y);

                                if (xu <= x_first_4th and yu >= y_third_4th) {
                                    try valid_entrance_coords.append(coord);
                                }
                                if (xu >= x_third_4th and yu <= y_first_4th) {
                                    try valid_exit_coords.append(coord);
                                }
                            }
                        },
                        .right => {
                            for (area.items) |coord| {
                                const xu: usize = @intFromFloat(coord.x);
                                const yu: usize = @intFromFloat(coord.y);

                                if (xu >= x_third_4th and yu >= y_third_4th) {
                                    try valid_entrance_coords.append(coord);
                                }
                                if (xu <= x_first_4th and yu <= y_first_4th) {
                                    try valid_exit_coords.append(coord);
                                }
                            }
                        },
                    }
                },
            }
        }
        return .{ .entrance = valid_entrance_coords, .exit = valid_exit_coords };
    }

    pub fn createStairs(self: @This(), allocator: std.mem.Allocator) ![2]rl.Vector2 {
        const rng = std.Random.DefaultPrng;
        var rnd = rng.init(@intCast(std.time.timestamp()));

        var valid_coords = std.ArrayList(rl.Vector2).init(allocator);
        defer valid_coords.deinit();

        for (0..@intFromFloat(self.size.x - 1)) |i| {
            for (0..@intFromFloat(self.size.y - 1)) |j| {
                switch (self.tiles.items[i].items[j]) {
                    .floor => try valid_coords.append(.{
                        .x = @floatFromInt(i),
                        .y = @floatFromInt(j),
                    }),
                    else => {},
                }
            }
        }

        const entrance_corner: Corner = .{
            .v = if (rnd.random().boolean()) .top else .bottom,
            .h = if (rnd.random().boolean()) .left else .right,
        };

        var exit_corner: Corner = switch (entrance_corner.v) {
            .top => switch (entrance_corner.h) {
                .right => .{ .v = .bottom, .h = .left },
                .left => .{ .v = .bottom, .h = .right },
            },
            .bottom => switch (entrance_corner.h) {
                .right => .{ .v = .top, .h = .left },
                .left => .{ .v = .top, .h = .right },
            },
        };

        const corners = try getValidTileFromCorners(valid_coords, entrance_corner, &exit_corner, allocator);

        const entrance_location_idx = rnd.random().intRangeAtMost(usize, 0, corners.entrance.items.len - 1);
        const entrance_location = corners.entrance.items[entrance_location_idx];
        self.tiles.items[@intFromFloat(entrance_location.x)].items[@intFromFloat(entrance_location.y)] = tiles.stair_0;

        const exit_location_idx = rnd.random().intRangeAtMost(usize, 0, corners.exit.items.len - 1);
        const exit_location = corners.exit.items[exit_location_idx];
        self.tiles.items[@intFromFloat(exit_location.x)].items[@intFromFloat(exit_location.y)] = tiles.stair_0;

        return .{ entrance_location, exit_location };
    }
};
