const std = @import("std");
const rl = @import("raylib");

const game = @import("./game/game.zig");
const level = @import("./game/level.zig");

const Bsp = struct {
    const SplitDirection = enum {
        horizontal,
        vertical,
    };

    shape: rl.Rectangle,
    left: ?*Bsp,
    right: ?*Bsp,
    rnd: *std.rand.Xoshiro256,

    // fn makeChildren(self: *@This(), min_size: rl.Vector2, direction: SplitDirection) void {
    //     //
    // }
};

pub fn randomGrid(
    width: usize,
    height: usize,
    wall_prob: f32,
    allocator: std.mem.Allocator,
) !std.ArrayList(std.ArrayList(level.Tile)) {
    const rng = std.Random.DefaultPrng;
    var rnd = rng.init(@intCast(std.time.timestamp()));

    var tiles = std.ArrayList(std.ArrayList(level.Tile)).init(allocator);

    for (0..width) |i| {
        try tiles.append(std.ArrayList(level.Tile).init(allocator));
        for (0..height) |_| {
            const res = rnd.random().float(f32);
            if (res < wall_prob) {
                try tiles.items[i].append(.{ .wall = false });
            } else {
                try tiles.items[i].append(.{ .floor = false });
            }
        }
    }

    return tiles;
}

pub fn fillNeighbors(
    x: usize,
    y: usize,
    tiles: *std.ArrayList(std.ArrayList(level.Tile)),
    checked_tiles: *std.ArrayList(std.ArrayList(rl.Vector2)),
    tile_type: level.Tile,
) !void {
    if (std.meta.eql(tiles.items[x].items[y], tile_type)) return;
    if (std.meta.eql(tiles.items[x].items[y], .{ .wall = false })) return;
    if (std.meta.eql(tiles.items[x].items[y], .{ .wall = true })) return;

    const i = checked_tiles.items.len - 1;
    tiles.items[x].items[y] = tile_type;
    try checked_tiles.items[i].append(.{ .x = @floatFromInt(x), .y = @floatFromInt(y) });

    if (x > 0) try fillNeighbors(x - 1, y, tiles, checked_tiles, tile_type);
    if (x + 1 < tiles.items.len) try fillNeighbors(x + 1, y, tiles, checked_tiles, tile_type);
    if (y > 0) try fillNeighbors(x, y - 1, tiles, checked_tiles, tile_type);
    if (y + 1 < tiles.items[x].items.len) try fillNeighbors(x, y + 1, tiles, checked_tiles, tile_type);
}

pub fn floodFillFloors(
    tiles: *std.ArrayList(std.ArrayList(level.Tile)),
    tile_type: level.Tile,
    allocator: std.mem.Allocator,
) !void {
    var checked_tiles = std.ArrayList(std.ArrayList(rl.Vector2)).init(allocator);
    defer {
        for (checked_tiles.items) |x| {
            x.deinit();
        }
        checked_tiles.deinit();
    }
    for (0.., tiles.items) |i, x| {
        for (0.., x.items) |j, y| {
            switch (y) {
                .floor => {
                    try checked_tiles.append(std.ArrayList(rl.Vector2).init(allocator));
                    try fillNeighbors(i, j, tiles, &checked_tiles, tile_type);
                },
                else => continue,
            }
        }
    }
    var max: usize = 0;
    var max_index: usize = undefined;
    for (0.., checked_tiles.items) |i, x| {
        if (x.items.len > max) {
            max = x.items.len;
            max_index = i;
        }
    }
    for (0.., checked_tiles.items) |i, _| {
        if (i == max_index) {
            for (checked_tiles.items[max_index].items) |y| {
                const ix: usize = @intFromFloat(y.x);
                const iy: usize = @intFromFloat(y.y);
                tiles.items[ix].items[iy] = .{ .floor = false };
            }
        } else {
            for (checked_tiles.items[i].items) |y| {
                const ix: usize = @intFromFloat(y.x);
                const iy: usize = @intFromFloat(y.y);
                tiles.items[ix].items[iy] = .{ .wall = false };
            }
        }
    }
}

pub fn makeMapFromCellularAutomata(
    tiles: *std.ArrayList(std.ArrayList(level.Tile)),
    allocator: std.mem.Allocator,
) !void {
    var new_tiles = std.ArrayList(std.ArrayList(level.Tile)).init(allocator);

    for (0.., tiles.items) |i, x| {
        try new_tiles.append(std.ArrayList(level.Tile).init(allocator));

        for (0.., x.items) |j, _| {
            var alive: i32 = 0;

            const i_int: i32 = @intCast(i);
            const j_int: i32 = @intCast(j);

            //NOTE: This technically works in an appreciable way,
            // however, its not technically *correct*
            var n: i32 = -1;
            while (n <= 1) : (n += 1) {
                var m: i32 = -1;
                while (m <= 1) : (m += 1) {
                    if (i_int == 0) {
                        alive += 1;
                        continue;
                    }
                    if (i_int >= tiles.items.len - 1) {
                        alive += 1;
                        continue;
                    }
                    if (j_int == 0) {
                        alive += 1;
                        continue;
                    }
                    if (j_int >= tiles.items[0].items.len - 1) {
                        alive += 1;
                        continue;
                    }

                    if (i_int + n < tiles.items.len - 1 and i_int + n >= 0) {
                        if (j_int + m < tiles.items[0].items.len - 1 and j_int + m >= 0) {
                            switch (tiles.items[@intCast(n + i_int)].items[@intCast(m + j_int)]) {
                                .floor => {
                                    alive += 1;
                                },
                                else => {},
                            }
                        }
                    }
                }
            }
            switch (tiles.items[i].items[j]) {
                .wall => {
                    if (alive >= 3) {
                        try new_tiles.items[i].append(.{ .wall = false });
                    } else {
                        try new_tiles.items[i].append(.{ .floor = false });
                    }
                },
                else => {
                    if (alive <= 10) {
                        try new_tiles.items[i].append(.{ .wall = false });
                    } else {
                        try new_tiles.items[i].append(.{ .floor = false });
                    }
                },
            }
        }
    }

    for (tiles.items) |*x| {
        x.deinit();
    }
    tiles.deinit();

    tiles.* = new_tiles;
}
