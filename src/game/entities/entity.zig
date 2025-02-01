const Self = @This();
const std = @import("std");
const game = @import("../game.zig");
const rl = @import("raylib");

const BodyPartGroup = @import("./body/BodyPartGroup.zig");
const BodyPart = @import("./body/BodyPart.zig");
const Effect = @import("./effect.zig");
const body_parts = @import("./body/body_part_constants.zig");
const labels = @import("./body/BodyPart.zig").labels;

const config = @import("../../main.zig").config;

pub fn baseliner(allocator: std.mem.Allocator) !Self {
    var p = Self{
        .body_part_group = BodyPartGroup.init(allocator, labels.torso),
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

    //TODO: clean this up

    var unique_labels: [std.meta.fields(@TypeOf(body_parts.baseline)).len]struct { label: []const u8, count: f32 } = undefined;
    var part_list: [std.meta.fields(@TypeOf(body_parts.baseline)).len]?BodyPart = undefined;

    var i: usize = 0;
    var unique_labels_idx: usize = 0;

    inline for (std.meta.fields(@TypeOf(body_parts.baseline))) |body_part| {
        part_list[i] = @field(body_parts.baseline, body_part.name);
        i += 1;
        var match = false;
        for (&unique_labels) |*label| {
            if (std.mem.eql(u8, label.label, @field(body_parts.baseline, body_part.name).meta.label)) {
                label.count += 1;
                match = true;
            }
        }
        if (!match) {
            unique_labels_idx += 1;
            unique_labels[unique_labels_idx] = .{ .count = 1, .label = @field(body_parts.baseline, body_part.name).meta.label };
        }
    }

    i = 0;
    while (i < part_list.len) {
        inline for (0.., part_list) |part_list_idx, optpart| if (optpart) |part| {
            for (unique_labels) |label| {
                if (std.mem.eql(u8, label.label, part.meta.label)) {
                    if (!p.body_part_group.getMaxSlotsExists(label.label)) {
                        try p.body_part_group.max_slots.append(.{
                            .label = label.label,
                            .slots = label.count,
                        });
                    }
                }
            }
            if (p.body_part_group.addPart(part)) |_| {
                part_list[part_list_idx] = null;
                i += 1;
            } else |_| {}
        };
    }
    return p;
}

// if any body part in this list is not present on this entity, the entity should be killed asap
required_body_parts: ?[]const []const u8,

body_part_group: BodyPartGroup,

// for statuses that affect the whole body
status_effects: []Effect,

// occupied_tile is the tile in which the entity resides on the level grid
occupied_tile: rl.Vector2,
lock: game.TransitionLock
