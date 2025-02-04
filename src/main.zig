const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

const game = @import("./game/game.zig");
const level = @import("./game/level.zig");
const gen = @import("./generation.zig");
const tiles = @import("./game/tiles.zig");
const colors = @import("./colors.zig");
const Config = @import("./config/Config.zig");

pub const config: Config = .{
    .debug = .{
        .enable_debug_tools = true,
        .log_level = .default,
    },
    .keybinds = .{
        .show_player_stats = .t,
    },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var g = try game.Game.init(allocator);

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

        if (config.debug.enable_debug_tools) {
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
        }

        rl.endMode2D();

        if (rl.isKeyPressed(config.keybinds.show_player_stats)) {
            g.ui_state = switch (g.ui_state) {
                .player_stats => .none,
                else => .player_stats,
            };
        }

        const screen_width: f32 = @floatFromInt(rl.getScreenWidth());
        const screen_height: f32 = @floatFromInt(rl.getScreenHeight());

        switch (g.ui_state) {
            .player_stats => {
                const player_stats_menu_x = screen_width * 0.08;
                const player_stats_menu_y = screen_height * 0.08;
                const player_stats_menu_width = screen_width - ((screen_width * 0.08) * 2);
                const player_stats_menu_height = screen_height - ((screen_height * 0.08) * 2);
                rl.drawRectanglePro(.{
                    .x = player_stats_menu_x,
                    .y = player_stats_menu_y,
                    .width = player_stats_menu_width,
                    .height = player_stats_menu_height,
                }, .{ .x = 0, .y = 0 }, 0, colors.FF_GRAY03);
                //TODO: draw a health bar for every body part of the player,
                // evenly spacing it out vertically
            },
            else => {},
        }
    }
}
