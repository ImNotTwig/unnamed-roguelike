const std = @import("std");
const rl = @import("raylib");

const game = @import("./game/game.zig");
const level = @import("./game/level.zig");
const gen = @import("./generation.zig");
const tiles = @import("./game/tiles.zig");
const colors = @import("./colors.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var g: game.Game = .{
        .tile_scale = .{ .x = 30, .y = 30 },
        .tile_margin = 10 * 0.1,
        .camera = .{
            .camera = rl.Camera2D{
                .target = .{ .x = 0, .y = 0 },
                .offset = .{ .x = 0, .y = 0 },
                .rotation = 0,
                .zoom = 2.0,
            },
            .lock = .{
                .transition = false,
                .animation_time = 0.001,
                .delta = 0,
                .visual_location = undefined,
                .target_location = undefined,
            },
            .target_location = .{ .x = 0, .y = 0 },
        },
        .player = .{
            .actual_location = .{ .x = 0, .y = 0 },
            .visual_location = .{ .x = 0, .y = 0 },
            .occupied_tile = .{ .x = 0, .y = 0 },
            .lock = .{
                .transition = false,
                .animation_time = 0.150,
                .delta = 0,
                .visual_location = undefined,
                .target_location = undefined,
            },
        },
        .current_level = undefined,
    };
    g.player.lock.target_location = &g.player.actual_location;
    g.player.lock.visual_location = &g.player.visual_location;
    g.camera.lock.visual_location = &g.camera.camera.target;
    g.camera.lock.target_location = &g.camera.target_location;

    g.current_level = try level.Level.new(.{ .x = 150, .y = 75 }, null);
    g.current_level.tiles = try gen.randomGrid(150, 75, 0.675, allocator);

    for (0..24) |_| {
        try gen.makeMapFromCellularAutomata(&g.current_level.tiles, allocator);
    }
    try gen.floodFillFloors(
        &g.current_level.tiles,
        tiles.checking_tile,
        allocator,
    );

    const entrance = try g.current_level.createStairs(allocator);
    g.setPlayerLocation(entrance);

    rl.setConfigFlags(.{
        .window_resizable = true,
        .msaa_4x_hint = true,
    });

    rl.initWindow(1920 / 2, 1080 / 2, "unnamed-roguelike");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.beginMode2D(g.camera.camera);
        defer rl.endMode2D();

        rl.clearBackground(colors.FF_BG);

        g.drawLevel();

        g.checkMoveKey();

        g.player.lock.updateLocation();
        g.moveCameraToPlayer();
        g.camera.lock.updateLocation();
        g.drawPlayer();

        const mouse_wheel = rl.getMouseWheelMove();
        if (mouse_wheel > 0) {
            g.camera.camera.zoom *= 2;
        } else if (mouse_wheel < 0) {
            g.camera.camera.zoom /= 2;
        }

        if (rl.isKeyPressed(.key_p)) {
            for (0.., g.current_level.tiles.items) |i, x| {
                for (0.., x.items) |j, _| {
                    switch (g.current_level.tiles.items[i].items[j]) {
                        .floor => |*tile| tile.hidden = false,
                        .wall => |*tile| tile.hidden = false,
                        .stair => |*tile| tile.hidden = false,
                        .other => |*tile| tile.hidden = false,
                    }
                }
            }
        }
    }
}
