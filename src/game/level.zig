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

    pub fn new(size: rl.Vector2, allocator: ?std.mem.Allocator) !@This() {
        const ux: usize = @intFromFloat(size.x);
        const uy: usize = @intFromFloat(size.y);

        if (allocator) |a| {
            var tile_list = std.ArrayList(std.ArrayList(Tile)).init(a);
            for (0..ux) |i| {
                try tile_list.append(std.ArrayList(Tile).init(a));
                for (0..uy) |_| {
                    try tile_list.items[i].append(tiles.wall_0);
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

    pub fn createStairs(self: @This(), allocator: std.mem.Allocator) !rl.Vector2 {
        const rng = std.Random.DefaultPrng;
        var rnd = rng.init(@intCast(std.time.timestamp()));

        var valid_coords = std.ArrayList(rl.Vector2).init(allocator);

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
        const entrance_location_index = rnd.random().intRangeAtMost(usize, 0, valid_coords.items.len);
        const entrance_location = valid_coords.items[entrance_location_index];
        self.tiles.items[@intFromFloat(entrance_location.x)].items[@intFromFloat(entrance_location.y)] = tiles.stair_0;

        return entrance_location;
    }
};
