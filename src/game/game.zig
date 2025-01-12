const std = @import("std");
const rl = @import("raylib");

const level = @import("./level.zig");
const colors = @import("../colors.zig");
const tiles = @import("./tiles.zig");
const Entity = @import("./entities/entity.zig");

// TransitionLock is a struct used by visual elements that transition from
// one place to another within a target amount of time
pub const TransitionLock = struct {
    //visual_location is the location that is perceived in the game
    visual_location: rl.Vector2,
    //target_location is where the thing being animated is actually located
    target_location: rl.Vector2,
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
            self.visual_location = self.visual_location.lerp(self.target_location, t);
            if (t == 1) {
                self.transition = false;
                self.delta = 0;
            }
        }
    }
};

pub const Game = struct {
    pub const Direction = enum { right, left, up, down };
    const MoveDirection = union(Direction) {
        right: f32,
        left: f32,
        up: f32,
        down: f32,
    };

    // tile_scale is how much the tiles should be scaled,
    // horizontal and vertical dimensions can be scaled seperately
    tile_scale: rl.Vector2,
    // tile_margin is how much space should be between each tile
    tile_margin: f32,

    player: Entity,
    player_movement_queue: std.ArrayList(MoveDirection),
    camera: rl.Camera2D,
    current_level: level.Level,

    pub fn init(allocator: std.mem.Allocator) @This() {
        var self = Game{
            .tile_scale = .{ .x = 10, .y = 10 },
            .tile_margin = undefined,
            .camera = .{
                .target = .{ .x = 0, .y = 0 },
                .offset = .{ .x = 0, .y = 0 },
                .rotation = 0,
                .zoom = 2.0,
            },
            .player = .{
                .body_parts = undefined,
                .occupied_tile = .{ .x = 0, .y = 0 },
                .lock = .{
                    .transition = false,
                    .animation_time = 0.150,
                    .delta = 0,
                    .visual_location = .{ .x = 0, .y = 0 },
                    .target_location = .{ .x = 0, .y = 0 },
                },
            },
            .player_movement_queue = std.ArrayList(MoveDirection).init(allocator),
            .current_level = undefined,
        };
        self.tile_margin = self.tile_scale.x * 0.1;
        return self;
    }

    pub fn movePlayer(self: *@This()) void {
        // direction is in terms of a traditional screen grid where
        // adding to the y coordinate moves down visually and subtracting moves up
        while (self.player_movement_queue.popOrNull()) |direction| {
            const x: usize = @intFromFloat(self.player.occupied_tile.x);
            const y: usize = @intFromFloat(self.player.occupied_tile.y);

            switch (direction) {
                .right => |distance| {
                    if (self.player.occupied_tile.x < self.current_level.size.x - 1) switch (self.current_level.tiles.items[x + 1].items[y]) {
                        .wall => {},
                        else => {
                            self.player.occupied_tile.x += distance;
                            self.player.lock.target_location.x += distance * self.tile_scale.x;
                            self.player.lock.transition = true;
                        },
                    };
                },
                .left => |distance| {
                    if (self.player.occupied_tile.x > 0) switch (self.current_level.tiles.items[x - 1].items[y]) {
                        .wall => {},
                        else => {
                            self.player.occupied_tile.x -= distance;
                            self.player.lock.target_location.x -= distance * self.tile_scale.x;
                            self.player.lock.transition = true;
                        },
                    };
                },
                .up => |distance| {
                    if (self.player.occupied_tile.y > 0) switch (self.current_level.tiles.items[x].items[y - 1]) {
                        .wall => {},
                        else => {
                            self.player.occupied_tile.y -= distance;
                            self.player.lock.target_location.y -= distance * self.tile_scale.y;
                            self.player.lock.transition = true;
                        },
                    };
                },
                .down => |distance| {
                    if (self.player.occupied_tile.y < self.current_level.size.y - 1) switch (self.current_level.tiles.items[x].items[y + 1]) {
                        .wall => {},
                        else => {
                            self.player.occupied_tile.y += distance;
                            self.player.lock.target_location.y += distance * self.tile_scale.y;
                            self.player.lock.transition = true;
                        },
                    };
                },
            }
        }
    }

    pub fn moveCameraToPlayer(self: *@This()) void {
        const screen_width = rl.getScreenWidth();
        const screen_height = rl.getScreenHeight();

        self.camera.target.x = self.player.lock.visual_location.x + (self.tile_scale.x - self.tile_margin) / 2;
        self.camera.target.y = self.player.lock.visual_location.y + (self.tile_scale.y - self.tile_margin) / 2;

        self.camera.offset.x = @as(f32, @floatFromInt(@divTrunc(screen_width, 2)));
        self.camera.offset.y = @as(f32, @floatFromInt(@divTrunc(screen_height, 2)));
    }

    pub fn setPlayerLocation(self: *@This(), tile: rl.Vector2) void {
        self.player.occupied_tile = tile;
        const x = self.player.lock.target_location.x + (tile.x * (self.tile_scale.x));
        const y = self.player.lock.target_location.y + (tile.y * (self.tile_scale.y));
        self.player.lock.target_location = .{
            .x = x,
            .y = y,
        };
        self.player.lock.visual_location = .{
            .x = x,
            .y = y,
        };
    }

    pub fn checkMoveKey(self: *@This()) !void {
        if (!self.player.lock.transition) {
            var move = false;
            if (rl.isKeyDown(.a)) {
                try self.player_movement_queue.append(.{ .left = 1 });
                move = true;
            }
            if (rl.isKeyDown(.w)) {
                try self.player_movement_queue.append(.{ .up = 1 });
                move = true;
            }
            if (rl.isKeyDown(.d)) {
                try self.player_movement_queue.append(.{ .right = 1 });
                move = true;
            }
            if (rl.isKeyDown(.s)) {
                try self.player_movement_queue.append(.{ .down = 1 });
                move = true;
            }
            if (move) self.movePlayer();
        }
    }

    pub fn discoverAroundPlayer(self: @This(), tile_pos: rl.Vector2) void {
        const i: usize = @intFromFloat(tile_pos.x);
        const j: usize = @intFromFloat(tile_pos.y);

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
                .floor => |*tile| tile.hidden = false,
                .stair => |*tile| tile.hidden = false,
                .wall => |*tile| tile.hidden = false,
                .other => |*tile| tile.hidden = false,
            }
        }
    }

    pub fn drawPlayer(self: @This(), font: rl.Font) void {
        const player_text_size = rl.measureTextEx(
            rl.getFontDefault(),
            "@",
            self.tile_scale.x,
            0,
        );

        rl.drawTextEx(
            font,
            "@",
            .{
                .x = self.player.lock.visual_location.x + (self.tile_scale.x - self.tile_margin - player_text_size.x) / 2,
                .y = self.player.lock.visual_location.y + (self.tile_scale.y - self.tile_margin * 2 - player_text_size.y) / 2,
            },
            self.tile_scale.x,
            0,
            rl.Color{ .r = 248, .g = 200, .b = 220, .a = 255 },
        );
    }

    pub fn drawLevel(self: @This()) void {
        for (0.., self.current_level.tiles.items) |i, x| {
            for (0.., x.items) |j, y| {
                self.discoverAroundPlayer(.{ .x = @floatFromInt(i), .y = @floatFromInt(j) });
                const tile_color = switch (y) {
                    .stair => |tile| if (!tile.hidden) tile.color else colors.FF_BG,
                    .floor => |tile| if (!tile.hidden) tile.color else colors.FF_BG,
                    .other => |tile| if (!tile.hidden) tile.color else colors.FF_BG,
                    .wall => |tile| if (!tile.hidden) tile.color else colors.FF_BG,
                };

                rl.drawRectanglePro(.{
                    .x = @as(f32, @floatFromInt(i)) * self.tile_scale.x,
                    .y = @as(f32, @floatFromInt(j)) * self.tile_scale.y,
                    .width = self.tile_scale.x - self.tile_margin,
                    .height = self.tile_scale.y - self.tile_margin,
                }, .{ .x = 0, .y = 0 }, 0, tile_color);
            }
        }

        // drawing the borders around exposed walls
        for (0.., self.current_level.tiles.items) |i, x| {
            for (0.., x.items) |j, y| {
                switch (y) {
                    .wall => {},
                    else => continue,
                }
                const fi: f32 = @floatFromInt(i);
                const fj: f32 = @floatFromInt(j);

                const dirs = self.getEmptyDirections(.{ .x = fi, .y = fj });
                var lines: [4]struct { rl.Vector2, rl.Vector2 } = undefined;
                var idx: usize = 0;

                for (dirs) |dir| {
                    switch (dir) {
                        .right => {
                            lines[idx] = .{ .{
                                .x = ((fi + 1) * self.tile_scale.x) - self.tile_margin,
                                .y = (fj * self.tile_scale.y),
                            }, .{
                                .x = ((fi + 1) * self.tile_scale.x) - self.tile_margin,
                                .y = ((fj + 1) * self.tile_scale.y) - self.tile_margin,
                            } };
                            idx += 1;
                        },
                        .left => {
                            lines[idx] = .{ .{
                                .x = (fi * self.tile_scale.x) - self.tile_margin,
                                .y = (fj * self.tile_scale.y),
                            }, .{
                                .x = (fi * self.tile_scale.x) - self.tile_margin,
                                .y = ((fj + 1) * self.tile_scale.y) - self.tile_margin,
                            } };
                            idx += 1;
                        },
                        .up => {
                            lines[idx] = .{ .{
                                .x = (fi * self.tile_scale.x),
                                .y = (fj * self.tile_scale.y) - self.tile_margin,
                            }, .{
                                .x = ((fi + 1) * self.tile_scale.x) - self.tile_margin,
                                .y = (fj * self.tile_scale.y) - self.tile_margin,
                            } };
                            idx += 1;
                        },
                        .down => {
                            lines[idx] = .{ .{
                                .x = (fi * self.tile_scale.x),
                                .y = ((fj + 1) * self.tile_scale.y) - self.tile_margin,
                            }, .{
                                .x = ((fi + 1) * self.tile_scale.x) - self.tile_margin,
                                .y = ((fj + 1) * self.tile_scale.y) - self.tile_margin,
                            } };
                            idx += 1;
                        },
                    }
                }

                //TODO: draw corners when needed
                for (lines[0..idx]) |line| {
                    rl.drawRectanglePro(.{
                        .x = line[0].x,
                        .y = line[0].y,
                        .width = @abs(line[1].x - line[0].x) + if (@abs(line[1].x - line[0].x) == 0) self.tile_margin else 0,
                        .height = @abs(line[1].y - line[0].y) + if (@abs(line[1].y - line[0].y) == 0) self.tile_margin else 0,
                    }, .{ .x = 0, .y = 0 }, 0, tiles.wall_0_border);
                }
            }
        }
    }

    fn getEmptyDirections(self: @This(), tile: rl.Vector2) []Direction {
        var dirs: [4]Direction = undefined;
        var idx: usize = 0;

        if (tile.x < self.current_level.size.x - 1) {
            switch (self.current_level.tiles.items[@intFromFloat(tile.x + 1)].items[@intFromFloat(tile.y)]) {
                .floor => |neighbor| if (!neighbor.hidden) {
                    dirs[idx] = .right;
                    idx += 1;
                },
                else => {},
            }
        }
        if (tile.x > 0) {
            switch (self.current_level.tiles.items[@intFromFloat(tile.x - 1)].items[@intFromFloat(tile.y)]) {
                .floor => |neighbor| if (!neighbor.hidden) {
                    dirs[idx] = .left;
                    idx += 1;
                },
                else => {},
            }
        }
        if (tile.y > 0) {
            switch (self.current_level.tiles.items[@intFromFloat(tile.x)].items[@intFromFloat(tile.y - 1)]) {
                .floor => |neighbor| if (!neighbor.hidden) {
                    dirs[idx] = .up;
                    idx += 1;
                },
                else => {},
            }
        }
        if (tile.y < self.current_level.size.y - 1) {
            switch (self.current_level.tiles.items[@intFromFloat(tile.x)].items[@intFromFloat(tile.y + 1)]) {
                .floor => |neighbor| if (!neighbor.hidden) {
                    dirs[idx] = .down;
                    idx += 1;
                },
                else => {},
            }
        }
        return dirs[0..idx];
    }
};
