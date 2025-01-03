const std = @import("std");
const rl = @import("raylib");
const tiles = @import("./tiles.zig");

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
    size: rl.Vector2,
    tiles: std.ArrayList(std.ArrayList(Tile)),

    // if given an allocator, this will populate the tiles field with only walls,
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

    pub fn createStairs(self: @This(), allocator: std.mem.Allocator) ![2]rl.Vector2 {
        const rng = std.Random.DefaultPrng;
        var rnd = rng.init(@intCast(std.time.timestamp()));

        var valid_coords = std.ArrayList(rl.Vector2).init(allocator);
        var valid_entrance_coords = std.ArrayList(rl.Vector2).init(allocator);
        var valid_exit_coords = std.ArrayList(rl.Vector2).init(allocator);
        defer {
            valid_coords.deinit();
            valid_entrance_coords.deinit();
            valid_exit_coords.deinit();
        }

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
        var greatest_y: f32 = 0;
        var greatest_x: f32 = 0;
        var least_x: f32 = valid_coords.items[0].x;
        var least_y: f32 = valid_coords.items[0].y;
        for (valid_coords.items) |coord| {
            if (coord.x > greatest_x) greatest_x = coord.x;
            if (coord.y > greatest_y) greatest_y = coord.y;
            if (coord.y < least_y) least_y = coord.y;
            if (coord.x < least_x) least_x = coord.x;
        }
        const x_first_4th: usize = @intFromFloat((greatest_x - least_x) / 4);
        const x_third_4th: usize = @intFromFloat((greatest_x - least_x) * 3 / 4);

        const y_first_4th: usize = @intFromFloat((greatest_y - least_y) / 4);
        const y_third_4th: usize = @intFromFloat((greatest_y - least_y) * 3 / 4);

        while (valid_entrance_coords.items.len == 0 or valid_exit_coords.items.len == 0) {
            // if true, place entrance at the left
            // if false, place entrance at the right
            const split_direction_v = rnd.random().boolean();
            // if true, place entrance at the top
            // if false, place entrance at the bottom
            const split_direction_h = rnd.random().boolean();

            if (split_direction_h) {
                if (split_direction_v) { // top-left
                    for (valid_coords.items) |coord| {
                        const xu: usize = @intFromFloat(coord.x);
                        const yu: usize = @intFromFloat(coord.y);

                        if (xu <= x_first_4th and yu <= y_first_4th) {
                            try valid_entrance_coords.append(coord);
                        }
                        if (xu >= x_third_4th and yu >= y_third_4th) {
                            try valid_exit_coords.append(coord);
                        }
                    }
                } else { // top-right
                    for (valid_coords.items) |coord| {
                        const xu: usize = @intFromFloat(coord.x);
                        const yu: usize = @intFromFloat(coord.y);

                        if (xu >= x_third_4th and yu <= y_first_4th) {
                            try valid_entrance_coords.append(coord);
                        }
                        if (xu <= x_first_4th and yu >= y_third_4th) {
                            try valid_exit_coords.append(coord);
                        }
                    }
                }
            } else {
                if (split_direction_v) { // bottom-left
                    for (valid_coords.items) |coord| {
                        const xu: usize = @intFromFloat(coord.x);
                        const yu: usize = @intFromFloat(coord.y);

                        if (xu <= x_first_4th and yu >= y_third_4th) {
                            try valid_entrance_coords.append(coord);
                        }
                        if (xu >= x_third_4th and yu <= y_first_4th) {
                            try valid_exit_coords.append(coord);
                        }
                    }
                } else { // bottom-right
                    for (valid_coords.items) |coord| {
                        const xu: usize = @intFromFloat(coord.x);
                        const yu: usize = @intFromFloat(coord.y);

                        if (xu >= x_third_4th and yu >= y_third_4th) {
                            try valid_entrance_coords.append(coord);
                        }
                        if (xu <= x_first_4th and yu <= y_first_4th) {
                            try valid_exit_coords.append(coord);
                        }
                    }
                }
            }
        }

        const entrance_location_idx = rnd.random().intRangeAtMost(usize, 0, valid_entrance_coords.items.len - 1);
        const entrance_location = valid_entrance_coords.items[entrance_location_idx];
        self.tiles.items[@intFromFloat(entrance_location.x)].items[@intFromFloat(entrance_location.y)] = tiles.stair_0;

        const exit_location_idx = rnd.random().intRangeAtMost(usize, 0, valid_exit_coords.items.len - 1);
        const exit_location = valid_exit_coords.items[exit_location_idx];
        self.tiles.items[@intFromFloat(exit_location.x)].items[@intFromFloat(exit_location.y)] = tiles.stair_0;

        return .{ entrance_location, exit_location };
    }
};
