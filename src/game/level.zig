const std = @import("std");
const rl = @import("raylib");

// a Tile which is false should be obscured from the player
pub const Tile = union(enum) {
    stair: bool,
    floor: bool,
    wall: bool,

    other: struct { hidden: bool, color: rl.Color },
};

pub const Level = struct {
    size: rl.Vector2,
    tiles: std.ArrayList(std.ArrayList(Tile)),

    pub fn new(size: rl.Vector2, allocator: ?std.mem.Allocator) !@This() {
        const ux: usize = @intFromFloat(size.x);
        const uy: usize = @intFromFloat(size.y);

        if (allocator) |a| {
            var tiles = std.ArrayList(std.ArrayList(Tile)).init(a);
            for (0..ux) |i| {
                try tiles.append(std.ArrayList(Tile).init(a));
                for (0..uy) |_| {
                    try tiles.items[i].append(.{ .wall = false });
                }
            }
            return .{
                .size = size,
                .tiles = tiles,
            };
        } else {
            return .{
                .size = size,
                .tiles = undefined,
            };
        }
    }

    pub fn createStairs(self: @This(), allocator: std.mem.Allocator) !rl.Vector2 {
        const rng = std.Random.DefaultPrng;
        var rnd = rng.init(@intCast(std.time.timestamp()));

        var valid_coords = std.ArrayList(rl.Vector2).init(allocator);

        for (0..@intFromFloat(self.size.x - 1) ) |i| {
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
        const entrance_location_index = rnd.random().intRangeAtMost(usize, 0, valid_coords.items.len);
        const entrance_location = valid_coords.items[entrance_location_index];
        self.tiles.items[@intFromFloat(entrance_location.x)].items[@intFromFloat(entrance_location.y)] = .{ .stair = true };

        return entrance_location;
    }
};
