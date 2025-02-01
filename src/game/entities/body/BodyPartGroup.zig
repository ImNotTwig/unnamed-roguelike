const std = @import("std");
const BodyPart = @import("./BodyPart.zig");

const config = @import("../../../main.zig").config;

const MaxSlotsType = struct { label: []const u8, slots: f32 = 1 };

root_part_label: []const u8,
parts: std.ArrayList(BodyPart),
max_slots: std.ArrayList(MaxSlotsType),

pub const errors = error{
    OverBodyPartLimit,
    WrongBodyPartGroupInsertion,
    BodyPartPositionFilled,
    BodyPartDoesntExist,
    BodyPartDoesntExistAtPosition,
    BodyPartDepsNotSatisfied,
};

pub fn init(allocator: std.mem.Allocator, root_part_label: []const u8) @This() {
    return .{
        .parts = std.ArrayList(BodyPart).init(allocator),
        .root_part_label = root_part_label,
        .max_slots = std.ArrayList(MaxSlotsType).init(allocator),
    };
}

pub fn getMaxSlots(self: @This(), label: []const u8) !f32 {
    for (self.max_slots.items) |i| {
        if (std.mem.eql(u8, label, i.label)) return i.slots;
    } else {
        if (comptime @intFromEnum(config.debug.log_level) >= 1) {
            std.log.err(
                "Tried getting max slot count for BodyPart: {s}, but it does not exist.",
                .{label},
            );
        }
        return errors.BodyPartDoesntExist;
    }
}

pub fn getMaxSlotsExists(self: @This(), label: []const u8) bool {
    for (self.max_slots.items) |i| {
        if (std.mem.eql(u8, label, i.label)) return true;
    } else return false;
}

pub fn currentFilledSlots(self: @This(), label: []const u8) f32 {
    var slot_count: f32 = 0;
    for (self.parts.items) |i| {
        if (std.mem.eql(u8, label, i.meta.label)) {
            slot_count += i.occupied_slots;
        }
    }
    return slot_count;
}

pub fn getPart(self: @This(), label: []const u8, position: ?[]const u8) !BodyPart {
    for (self.parts.items) |i| {
        if (std.mem.eql(u8, label, i.meta.label)) {
            if (position) |pos| {
                if (i.meta.position) |iposs| for (iposs) |ipos| {
                    if (std.mem.eql(u8, ipos, pos)) return i;
                };
            } else return i;
        }
    }
    if (comptime @intFromEnum(config.debug.log_level) >= 1) {
        std.log.err(
            "Tried getting BodyPart: {s}, but it does not exist.",
            .{label},
        );
    }
    return errors.BodyPartDoesntExistAtPosition;
}

pub fn getPartExists(self: @This(), label: []const u8, position: ?[]const u8) bool {
    for (self.parts.items) |i| {
        if (std.mem.eql(u8, label, i.meta.label)) {
            if (position) |pos| {
                if (i.meta.position) |iposs| for (iposs) |ipos| {
                    if (std.mem.eql(u8, ipos, pos)) return true;
                };
            } else return true;
        }
    }
    return false;
}

pub fn addPart(self: *@This(), bp: BodyPart) !void {
    const max_slots = try self.getMaxSlots(bp.meta.label);

    // make sure we dont go over capacity
    if (self.currentFilledSlots(bp.meta.label) + bp.occupied_slots > max_slots) {
        if (comptime @intFromEnum(config.debug.log_level) >= 1) {
            std.log.err(
                "Tried inserting BodyPart: {s} into BodyPartGroup: {s} when the BodyPart would cause the BodyPartGroup to go over capacity\n",
                .{ bp.meta.label, self.root_part_label },
            );
        }
        return errors.OverBodyPartLimit;
    }
    // make sure we dont already have this part at the specified position
    if (bp.meta.position) |poss| {
        for (poss) |pos| {
            if (self.getPartExists(bp.meta.label, pos)) {
                if (comptime @intFromEnum(config.debug.log_level) >= 1) {
                    std.log.err(
                        "Tried inserting BodyPart: {s} at position: {s}, but position in BodyPartGroup: {s} is already taken.",
                        .{ bp.meta.label, pos, self.root_part_label },
                    );
                }
                return errors.BodyPartPositionFilled;
            }
        }
    }
    // check deps
    if (bp.meta.parent) |parent| {
        for (self.parts.items) |our_part| {
            if (std.mem.eql(u8, parent, our_part.meta.label)) {
                try self.parts.append(bp);
                return;
            }
        }
        if (comptime @intFromEnum(config.debug.log_level) >= 1) {
            std.log.err(
                "Tried inserting BodyPart: {s} in BodyPartGroup: {s}, but dependencies were not satisfied: {s}.\n",
                .{ bp.meta.label, self.root_part_label, bp.meta.parent.? },
            );
            return errors.BodyPartDepsNotSatisfied;
        }
    } else {
        try self.parts.append(bp);
    }
}
