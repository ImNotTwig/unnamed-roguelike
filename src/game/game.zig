const std = @import("std");
const rl = @import("raylib");

const Player = @import("./player.zig");
const level = @import("./level.zig");

// TransitionLock is a struct used by visual elements that transition from
// one place to another within a target amount of time
pub const TransitionLock = struct {
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

    pub fn updateLocation(self: *@This()) void {
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

const AnimatedCamera = struct {
    target_location: rl.Vector2,
    camera: rl.Camera2D,
    lock: TransitionLock,
};

pub const Game = struct {
    const MoveDirection = enum {
        right,
        left,
        up,
        down,
    };

    // tile_scale is how much the tiles should be scaled,
    // horizontal and vertical dimensions can be scaled seperately
    tile_scale: rl.Vector2,
    // tile_margin is how much space should be between each tile
    tile_margin: f32,

    player: Player,
    camera: AnimatedCamera,
    current_level: level.Level,

    // direction is in terms of a traditional screen grid where
    // adding to the y coordinate moves down visually and subtracting moves up
    pub fn movePlayer(self: *@This(), direction: MoveDirection, distance: f32) void {
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

    pub fn moveCameraToPlayer(self: *@This()) void {
        const screen_width = rl.getScreenWidth();
        const screen_height = rl.getScreenHeight();

        self.camera.target_location.x = self.player.visual_location.x;
        self.camera.target_location.y = self.player.visual_location.y;

        self.camera.camera.offset.x = @as(f32, @floatFromInt(@divTrunc(screen_width, 2)));
        self.camera.camera.offset.y = @as(f32, @floatFromInt(@divTrunc(screen_height, 2)));

        self.camera.lock.transition = true;
    }

    pub fn setPlayerLocation(self: *@This(), tile: rl.Vector2) void {
        self.player.occupied_tile = tile;
        self.player.actual_location = .{
            .x = (tile.x * self.tile_scale.x),
            .y = (tile.y * self.tile_scale.y),
        };
        self.player.visual_location = .{
            .x = (tile.x * self.tile_scale.x),
            .y = (tile.y * self.tile_scale.y),
        };
    }

    pub fn checkMoveKey(self: *@This()) void {
        if (!self.player.lock.transition) {
            const x: usize = @intFromFloat(self.player.occupied_tile.x);
            const y: usize = @intFromFloat(self.player.occupied_tile.y);

            if (rl.isKeyDown(.key_left))
                if (self.player.occupied_tile.x > 0)
                    switch (self.current_level.tiles.items[x - 1].items[y]) {
                        .wall => {},
                        else => self.movePlayer(.left, 1),
                    };

            if (rl.isKeyDown(.key_up))
                if (self.player.occupied_tile.y > 0)
                    switch (self.current_level.tiles.items[x].items[y - 1]) {
                        .wall => {},
                        else => self.movePlayer(.up, 1),
                    };

            if (rl.isKeyDown(.key_right))
                if (self.player.occupied_tile.x < self.current_level.size.x)
                    switch (self.current_level.tiles.items[x + 1].items[y]) {
                        .wall => {},
                        else => self.movePlayer(.right, 1),
                    };

            if (rl.isKeyDown(.key_down))
                if (self.player.occupied_tile.y < self.current_level.size.y)
                    switch (self.current_level.tiles.items[x].items[y + 1]) {
                        .wall => {},
                        else => self.movePlayer(.down, 1),
                    };
        }
    }

    pub fn discoverAroundPlayer(self: @This(), tile_pos: rl.Vector2) void {
        const i: usize = @intFromFloat(tile_pos.x);
        const j: usize = @intFromFloat(tile_pos.y);

        if (tile_pos.x == self.player.occupied_tile.x and tile_pos.y == self.player.occupied_tile.y) {
            switch (self.current_level.tiles.items[i].items[j]) {
                .floor => |*tile| tile.* = true,
                else => {},
            }
        }

        if (rl.Vector2.distance(.{
            .x = self.player.occupied_tile.x,
            .y = self.player.occupied_tile.y,
        }, tile_pos) < 7) {
            var px = self.player.occupied_tile.x;
            const direction_x: f32 = if (tile_pos.x < px) -1 else 1;

            while (px != tile_pos.x + direction_x) : (px += direction_x) {
                var py = self.player.occupied_tile.y;
                const direction_y: f32 = if (tile_pos.y < py) -1 else 1;

                while (py != tile_pos.y + direction_y) : (py += direction_y) {
                    if (self.player.occupied_tile.x == px + 1 or
                        self.player.occupied_tile.x == px - 1)
                    {
                        if (self.player.occupied_tile.y == py + 1 or
                            self.player.occupied_tile.y == py - 1) continue;
                    }
                    switch (self.current_level.tiles.items[@intFromFloat(px)].items[@intFromFloat(py)]) {
                        .wall => return,
                        else => {},
                    }
                }
            }

            switch (self.current_level.tiles.items[i].items[j]) {
                .floor => |*tile| tile.* = true,
                .stair => |*tile| tile.* = true,
                .wall => |*tile| tile.* = true,
                .other => |*tile| tile.hidden = false,
            }
        }
    }

    pub fn drawPlayer(self: @This()) void {
        const player_text_size = rl.measureTextEx(
            rl.getFontDefault(),
            "@",
            self.tile_scale.x - self.tile_margin,
            0,
        );

        rl.drawTextEx(
            rl.getFontDefault(),
            "@",
            .{
                .x = self.player.visual_location.x + (self.tile_scale.x + self.tile_margin - player_text_size.x) / 4 + 1,
                .y = self.player.visual_location.y - 1,
            },
            self.tile_scale.x - self.tile_margin,
            0,
            rl.Color{ .r = 248, .g = 200, .b = 220, .a = 255 },
        );
    }

    pub fn drawLevel(self: @This()) void {
        for (0.., self.current_level.tiles.items) |i, x| {
            for (0.., x.items) |j, y| {
                self.discoverAroundPlayer(.{ .x = @floatFromInt(i), .y = @floatFromInt(j) });
                const tile_color = switch (y) {
                    .stair => |tile| if (tile == true) rl.Color.light_gray else rl.Color.brown,
                    .floor => |tile| if (tile == true) rl.Color.dark_gray else rl.Color.brown,
                    .other => |tile| if (!tile.hidden) tile.color else rl.Color.brown,
                    .wall => |tile| if (tile == true) rl.Color.brown else rl.Color.brown,
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

                // drawing the borders around exposed walls
                switch (y) {
                    .wall => {
                        for (0..3) |_| {
                            if (@as(f32, @floatFromInt(i)) < self.current_level.size.x - 1)
                                switch (self.current_level.tiles.items[i + 1].items[j]) {
                                    .floor => |tile| if (tile) {
                                        rl.drawLineEx(.{
                                            .x = (@as(f32, @floatFromInt(i)) * self.tile_scale.x) + self.tile_scale.x,
                                            .y = (@as(f32, @floatFromInt(j)) * self.tile_scale.y),
                                        }, .{
                                            .x = (@as(f32, @floatFromInt(i)) * self.tile_scale.x) + self.tile_scale.x,
                                            .y = (@as(f32, @floatFromInt(j)) * self.tile_scale.y) + self.tile_scale.y,
                                        }, self.tile_margin, rl.Color.blue);
                                    },
                                    else => {},
                                };
                            if (i > 0)
                                switch (self.current_level.tiles.items[i - 1].items[j]) {
                                    .floor => |tile| if (tile) {
                                        rl.drawLineEx(
                                            .{
                                                .x = (@as(f32, @floatFromInt(i)) * self.tile_scale.x),
                                                .y = (@as(f32, @floatFromInt(j)) * self.tile_scale.y),
                                            },
                                            .{
                                                .x = (@as(f32, @floatFromInt(i)) * self.tile_scale.x),
                                                .y = (@as(f32, @floatFromInt(j)) * self.tile_scale.y) + self.tile_scale.y,
                                            },
                                            self.tile_margin,
                                            rl.Color.green,
                                        );
                                    },
                                    else => {},
                                };
                            if (j > 0)
                                switch (self.current_level.tiles.items[i].items[j - 1]) {
                                    .floor => |tile| if (tile) {
                                        rl.drawLineEx(
                                            .{
                                                .x = (@as(f32, @floatFromInt(i)) * self.tile_scale.x),
                                                .y = (@as(f32, @floatFromInt(j)) * self.tile_scale.y),
                                            },
                                            .{
                                                .x = (@as(f32, @floatFromInt(i)) * self.tile_scale.x) + self.tile_scale.x,
                                                .y = (@as(f32, @floatFromInt(j)) * self.tile_scale.y),
                                            },
                                            self.tile_margin,
                                            rl.Color.pink,
                                        );
                                    },
                                    else => {},
                                };
                            if (@as(f32, @floatFromInt(j)) < self.current_level.size.y - 1)
                                switch (self.current_level.tiles.items[i].items[j + 1]) {
                                    .floor => |tile| if (tile) {
                                        rl.drawLineEx(
                                            .{
                                                .x = (@as(f32, @floatFromInt(i)) * self.tile_scale.x),
                                                .y = (@as(f32, @floatFromInt(j)) * self.tile_scale.y) + self.tile_scale.y,
                                            },
                                            .{
                                                .x = (@as(f32, @floatFromInt(i)) * self.tile_scale.x) + self.tile_scale.x,
                                                .y = (@as(f32, @floatFromInt(j)) * self.tile_scale.y) + self.tile_scale.y,
                                            },
                                            self.tile_margin,
                                            rl.Color.red,
                                        );
                                    },
                                    else => {},
                                };
                        }
                    },
                    else => {},
                }
            }
        }
    }
};
