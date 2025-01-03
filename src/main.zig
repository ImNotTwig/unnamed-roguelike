const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

const game = @import("./game/game.zig");
const level = @import("./game/level.zig");
const gen = @import("./generation.zig");
const tiles = @import("./game/tiles.zig");
const colors = @import("./colors.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var g = game.Game.init(allocator);

    g.current_level = try level.Level.new(.{ .x = 150, .y = 75 }, tiles.wall_0, allocator);
    g.current_level.tiles = try gen.randomGrid(150, 75, 0.65, allocator);

    for (0..19) |_| {
        try gen.makeMapFromCellularAutomata(&g.current_level.tiles, allocator);
    }
    try gen.floodFillFloors(
        &g.current_level.tiles,
        tiles.checking_tile,
        allocator,
    );

    const stairs = try g.current_level.createStairs(allocator);
    g.setPlayerLocation(stairs[0]);

    rl.setConfigFlags(.{
        .window_resizable = true,
        .msaa_4x_hint = true,
    });

    rl.initWindow(1920 / 2, 1080 / 2, "unnamed-roguelike");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.text_color_normal), colors.FF_FG.toInt());
    rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.text_color_focused), colors.FF_FG.toInt());
    rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.text_color_pressed), colors.FF_FG.toInt());
    rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.text_color_disabled), colors.FF_BEIGE.toInt());

    rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.base_color_normal), colors.FF_BG.toInt());
    rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.base_color_disabled), colors.FF_RED.toInt());
    rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.base_color_focused), colors.FF_BG.toInt());
    rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.base_color_pressed), colors.FF_BG.toInt());

    rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.border_color_normal), colors.FF_GRAY02.toInt());
    rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.border_color_focused), colors.FF_GRAY04.toInt());
    rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.border_color_pressed), colors.FF_GRAY04.toInt());
    rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.border_color_disabled), colors.FF_GRAY03.toInt());

    rg.guiSetStyle(.progressbar, @intFromEnum(rg.GuiControlProperty.base_color_pressed), colors.FF_ORANGE.toInt());

    // rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.base_color_normal), colors.FF_BG.toInt());
    // rg.guiSetStyle(.default, @intFromEnum(rg.GuiControlProperty.base_color_normal), colors.FF_BG.toInt());

    rl.setTextLineSpacing(0);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.beginMode2D(g.camera);

        rl.clearBackground(colors.FF_BG);

        g.drawLevel();

        try g.checkMoveKey();
        g.movePlayer();

        g.player.lock.updateLocation();
        g.moveCameraToPlayer();
        g.drawPlayer(rl.getFontDefault());

        const mouse_wheel = rl.getMouseWheelMove();
        if (mouse_wheel > 0) {
            g.camera.zoom *= 1.1;
        } else if (mouse_wheel < 0) {
            g.camera.zoom /= 1.1;
        }

        if (rl.isKeyPressed(.p)) {
            for (0.., g.current_level.tiles.items) |i, x| {
                for (0..x.items.len) |j| {
                    switch (g.current_level.tiles.items[i].items[j]) {
                        .floor => |*tile| tile.hidden = false,
                        .wall => |*tile| tile.hidden = false,
                        .stair => |*tile| tile.hidden = false,
                        .other => |*tile| tile.hidden = false,
                    }
                }
            }
        }

        rl.endMode2D();

        const screen_width: f32 = @floatFromInt(rl.getScreenWidth());
        // const screen_height: f32 = @floatFromInt(rl.getScreenHeight());

        // var current_health_buf: [5]u8 = undefined;
        // var max_health_buf: [5]u8 = undefined;
        // const current_health = try std.fmt.bufPrintZ(&current_health_buf, "{}", .{@as(i32, @intFromFloat(g.player.current_health))});
        // const max_health = try std.fmt.bufPrintZ(&max_health_buf, "{}", .{@as(i32, @intFromFloat(g.player.max_health))});

        rl.drawRectanglePro(.{
            .x = 0,
            .y = 0,
            .width = screen_width,
            .height = 25,
        }, .{ .x = 0, .y = 0 }, 0, colors.FF_BG);

        // _ = rg.guiProgressBar(.{
        //     .x = screen_width - 450,
        //     .y = 0,
        //     .width = 400,
        //     .height = 25,
        // }, current_health, max_health, &g.player.current_health, 0, g.player.max_health);
    }
}
