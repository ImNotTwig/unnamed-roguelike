const std = @import("std");
const rl = @import("raylib");

// TransitionLock is a struct used by visual elements that transition from
// one place to another within a target amount of time
const TransitionLock = struct {
    //visual_location is the location that is perceived in the game
    visual_location: *rl.Vector2,
    //target_location is where the thing being animated is actually located
    target_location: *rl.Vector2,
    //transition is whether or not the thing is being animated currently
    transition: bool,
    //animation_time is how long the animation should take
    animation_time: f32,
    // delta keeps track of how long its been since the animation started
    delta: f32,

    fn updateLocation(self: *@This()) void {
        if (self.transition) {
            self.delta += rl.getFrameTime();
            var t = self.delta / self.animation_time;

            if (t >= 1) t = 1;
            self.visual_location.* = self.visual_location.lerp(self.target_location.*, t);
            if (t == 1) {
                self.transition = false;
                self.delta = 0;
            }
        }
    }
};

const Player = struct {
    lock: TransitionLock,
    //visual_location and actual_location are similar to visual_location and
    //target_location as specified in TransitionLock
    visual_location: rl.Vector2,
    actual_location: rl.Vector2,

    // occupied_tile is the tile in which the player resides on the level grid
    occupied_tile: rl.Vector2,
};

const AnimatedCamera = struct {
    target_location: rl.Vector2,
    camera: rl.Camera2D,
    lock: TransitionLock,
};

// a Tile which is false should be obscured from the player
const Tile = union(enum) {
    stair: bool,
    floor: bool,
    wall: bool,
};

const Level = struct {
    size: rl.Vector2,
    tiles: std.ArrayList(std.ArrayList(Tile)),

    fn new(size: rl.Vector2, allocator: std.mem.Allocator) !@This() {
        const ux: usize = @intFromFloat(size.x);
        const uy: usize = @intFromFloat(size.y);

        var tiles = std.ArrayList(std.ArrayList(Tile)).init(allocator);
        for (0..ux) |i| {
            try tiles.append(std.ArrayList(Tile).init(allocator));
            for (0..uy) |_| {
                try tiles.items[i].append(.{ .wall = false });
            }
        }
        return .{
            .size = size,
            .tiles = tiles,
        };
    }
};

const Game = struct {
    const MoveDirection = enum {
        right,
        left,
        up,
        down,
    };

    tile_scale: rl.Vector2,
    tile_margin: f32,

    player: Player,
    camera: AnimatedCamera,
    current_level: Level,

    // direction is in terms of a traditional screen grid where
    // adding to the y coordinate moves down visually and subtracting moves up
    fn movePlayer(self: *@This(), direction: MoveDirection, distance: f32) void {
        switch (direction) {
            .right => {
                self.player.occupied_tile.x += distance;
                self.player.actual_location.x += distance * self.tile_scale.x;
                self.player.lock.transition = true;
            },
            .left => {
                self.player.occupied_tile.x -= distance;
                self.player.actual_location.x -= distance * self.tile_scale.x;
                self.player.lock.transition = true;
            },
            .up => {
                self.player.occupied_tile.y -= distance;
                self.player.actual_location.y -= distance * self.tile_scale.y;
                self.player.lock.transition = true;
            },
            .down => {
                self.player.occupied_tile.y += distance;
                self.player.actual_location.y += distance * self.tile_scale.y;
                self.player.lock.transition = true;
            },
        }
    }

    fn checkMoveKey(self: *@This()) void {
        if (!self.player.lock.transition) {
            if (self.player.occupied_tile.x > 0) {
                if (rl.isKeyDown(.key_left)) {
                    self.movePlayer(.left, 1);
                }
            }
            if (self.player.occupied_tile.y > 0) {
                if (rl.isKeyDown(.key_up)) {
                    self.movePlayer(.up, 1);
                }
            }
            if (self.player.occupied_tile.x < self.current_level.size.x) {
                if (rl.isKeyDown(.key_right)) {
                    self.movePlayer(.right, 1);
                }
            }
            if (self.player.occupied_tile.y < self.current_level.size.x) {
                if (rl.isKeyDown((.key_down))) {
                    self.movePlayer(.down, 1);
                }
            }
        }
    }

    fn drawPlayer(self: @This()) void {
        const player_text_size = rl.measureTextEx(
            rl.getFontDefault(),
            "@",
            self.tile_scale.x - self.tile_margin * 2,
            0,
        );

        rl.drawTextEx(
            rl.getFontDefault(),
            "@",
            .{
                .x = self.player.visual_location.x + (self.tile_scale.x + self.tile_margin - player_text_size.x) / 4 + 1,
                .y = self.player.visual_location.y,
            },
            self.tile_scale.x - self.tile_margin * 2,
            0,
            rl.Color.init(248, 200, 220, 255),
        );
    }

    fn drawLevel(self: @This()) void {
        for (0.., self.current_level.tiles.items) |i, x| {
            for (0.., x.items) |j, y| {
                const tile_color = switch (y) {
                    .stair => |tile| if (tile == true) rl.Color.light_gray else rl.Color.dark_gray,
                    .floor => |tile| if (tile == true) rl.Color.dark_gray else rl.Color.dark_gray,
                    .wall => |tile| if (tile == true) rl.Color.gray else rl.Color.dark_gray,
                };
                rl.drawRectanglePro(
                    .{
                        .x = @as(f32, @floatFromInt(i)) * self.tile_scale.x,
                        .y = @as(f32, @floatFromInt(j)) * self.tile_scale.y,
                        .width = self.tile_scale.x - self.tile_margin,
                        .height = self.tile_scale.y - self.tile_margin,
                    },
                    .{ .x = 0, .y = 0 },
                    0,
                    tile_color,
                );
            }
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var g: Game = .{
        .tile_scale = .{ .x = 25, .y = 25 },
        .tile_margin = 25 * 0.1,
        .camera = .{
            .camera = rl.Camera2D{
                .target = .{ .x = 0, .y = 0 },
                .offset = .{ .x = 0, .y = 0 },
                .rotation = 0,
                .zoom = 0,
            },
            .lock = .{
                .transition = false,
                .animation_time = 0.200,
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
                .animation_time = 0.200,
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

    g.current_level = try Level.new(.{ .x = 100, .y = 100 }, allocator);

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
        rl.clearBackground(rl.Color.black);

        g.drawLevel();

        g.checkMoveKey();
        g.player.lock.updateLocation();
        g.drawPlayer();
    }
}
