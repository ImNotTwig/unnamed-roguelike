const Self = @This();
const std = @import("std");
const game = @import("../game.zig");
const rl = @import("raylib");

const BodyPart = @import("./body/BodyPart.zig");
const Effect = @import("./effect.zig");
const body_parts = @import("./body/body_part_constants.zig");
const labels = @import("./body/body_part_labels.zig").labels;

const config = @import("../../main.zig").config;

pub fn baseliner(allocator: std.mem.Allocator) !Self {
    var set_root = false;
    var p = Self{
        .root_body_part = undefined,
        .status_effects = &.{},
        .occupied_tile = .{ .x = 0, .y = 0 },
        .lock = game.TransitionLock{
            .transition = false,
            .animation_time = 0.150,
            .delta = 0,
            .visual_location = .{ .x = 0, .y = 0 },
            .target_location = .{ .x = 0, .y = 0 },
        },
        .required_body_parts = &.{
            labels.heart,
            labels.brain,
            labels.head,
            labels.lung,
            labels.liver,
            labels.kidney,
        },
    };

    var part_list: [std.meta.fields(@TypeOf(body_parts.baseline)).len]?BodyPart = undefined;

    inline for (0.., std.meta.fields(@TypeOf(body_parts.baseline))) |i, body_part| {
        part_list[i] = @field(body_parts.baseline, body_part.name);
    }

    var valid_insertions: usize = 0;
    while (valid_insertions < part_list.len) {
        inline for (0.., part_list) |part_list_idx, optpart| if (optpart) |part| {
            var new_part = part;
            try new_part.init(allocator);
            if (set_root == false) {
                if (part.meta.parent == null) {
                    p.root_body_part = new_part;
                    set_root = true;
                }
            } else {
                if (p.root_body_part.addPart(&new_part)) |_| {
                    part_list[part_list_idx] = null;
                    valid_insertions += 1;
                } else |_| {}
            }
        };
    }
    return p;
}

// if any body part in this list is not present on this entity, the entity should be killed asap
required_body_parts: ?[]const []const u8,

root_body_part: BodyPart,

// for statuses that affect the whole body
status_effects: []Effect,

// occupied_tile is the tile in which the entity resides on the level grid
occupied_tile: rl.Vector2,
lock: game.TransitionLock
