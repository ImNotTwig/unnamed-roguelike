const rl = @import("raylib");
const std = @import("std");

const config = @import("../main.zig").config;
const colors = config.colors;

const PartWithSize = @import("../entities/Entity.zig").PartWithSize;
const BodyPart = @import("../body/BodyPart.zig");

hit_list: struct {
    enabled: bool = false,
    rect: rl.Rectangle = .{
        .height = 0,
        .width = 0,
        .x = 0,
        .y = 0,
    },
    slider: struct {
        x: f32 = 0,
        width: f32 = 0,
        direction: i3 = 1,
    } = .{},

    pub fn reset(self: *@This()) void {
        self.* = @This(){};
    }
    pub fn resetSlider(self: *@This()) void {
        self.slider = .{
            .x = self.rect.x,
        };
    }
} = .{},

ui_state: enum {
    none,
    player_stats,
} = .none,

fn scalePartSize(p: PartWithSize, total_width: f32, total_parts_width: f32) PartWithSize {
    const scale = @max(total_parts_width / total_width, total_width / total_parts_width);

    return PartWithSize{
        .bp = p.bp,
        .children = p.children,
        .size = .{
            .width = p.size.width * scale,
            .x = p.size.x * scale,
        },
    };
}

const rotate_colors = &[_]rl.Color{
    colors.ff_blue,
    colors.ff_green,
    colors.ff_red,
    colors.ff_orange,
    colors.ff_magenta,
    colors.ff_cyan,
    colors.ff_purple,
};

fn drawSegment(list: []PartWithSize, parent_rect: rl.Rectangle) void {
    const rng = std.Random.DefaultPrng;
    var rnd = rng.init(@intCast(std.time.timestamp()));

    var total_dist: f32 = parent_rect.x;
    var total_list_width: f32 = 0;

    const scaled_list = list;

    rnd.random().shuffle(@TypeOf(list[0]), list);

    for (list) |pws| {
        total_list_width += pws.size.width;
    }
    var total_scaled_root_length: f32 = 0;
    for (scaled_list) |*root_child| {
        root_child.* = scalePartSize(root_child.*, total_list_width, parent_rect.width);
        total_scaled_root_length += root_child.size.width;
    }
    for (0.., scaled_list) |root_idx, root_child| {
        rl.drawRectanglePro(.{
            .x = total_dist,
            .y = parent_rect.y + parent_rect.height * 0.2,
            .width = root_child.size.width,
            .height = parent_rect.height - parent_rect.height * 0.2 * 2,
        }, .{ .x = 0, .y = 0 }, 0, rotate_colors[root_idx % rotate_colors.len]);
        if (root_child.children) |children| {
            var x = total_dist;
            var total_children_width: f32 = 0;
            for (children) |child| {
                total_children_width += child.size.width;
            }
            var total_scaled_width: f32 = 0;
            const scaled_children = children;
            for (scaled_children) |*child| {
                child.* = scalePartSize(child.*, root_child.size.width, total_children_width);
                total_scaled_width += child.size.width;
            }

            for (0.., scaled_children) |idx, child| {
                rl.drawRectanglePro(.{
                    .x = x,
                    .y = parent_rect.y + parent_rect.height * 0.2,
                    .width = child.size.width,
                    .height = parent_rect.height - parent_rect.height * 0.2 * 2,
                }, .{ .x = 0, .y = 0 }, 0, rotate_colors[idx % rotate_colors.len]);
                x += child.size.width;
            }

            drawSegment(children, .{
                .x = total_dist,
                .y = parent_rect.y,
                .width = total_scaled_width,
                .height = parent_rect.height,
            });
        }
        total_dist += root_child.size.width;
    }
}

const PartWithPercent = struct {
    percent: f32,
    bp: *BodyPart,
};

pub fn drawHitList(self: *@This(), hit_list: []PartWithSize, allocator: std.mem.Allocator) !?[]PartWithPercent {
    const rect = self.hit_list.rect;
    const slider = &self.hit_list.slider;

    // drawing background
    rl.drawRectanglePro(.{
        .x = rect.x,
        .y = rect.y,
        .width = rect.width,
        .height = rect.height,
    }, .{ .x = 0, .y = 0 }, 0, colors.ff_gray03);

    drawSegment(hit_list, rect);

    // slider stuff
    rl.drawRectanglePro(.{
        .x = slider.x,
        .y = rect.y + (rect.height * 0.3),
        .width = slider.width,
        .height = rect.height - (rect.height * 0.3) * 2,
    }, .{ .x = 0, .y = 0 }, 0, colors.ff_gray03);

    slider.x += 2 * @as(f32, @floatFromInt(slider.direction));

    //TODO
    // we need to get the amount of overlap the body part is taking up on the slider
    // as well as the amount of area the slider is taking up on the body part
    // and then average the results
    if (rl.isKeyPressed(config.keybinds.commit_attack)) {
        var overlaps = std.ArrayList(PartWithPercent).init(allocator);
        defer overlaps.deinit();

        var dist: f32 = 0;
        for (hit_list) |i| {
            var x1: f32 = 0;
            var x2: f32 = 0;
            var w1: f32 = 0;
            var w2: f32 = 0;
            if (rect.x + dist < slider.x) {
                x1 = rect.x + dist;
                x2 = slider.x;
                w1 = i.size.width;
                w2 = slider.width;
            } else {
                x1 = slider.x;
                x2 = rect.x + dist;
                w1 = slider.width;
                w2 = i.size.width;
            }
            dist += i.size.width;

            const overlap_length = @min(x2 + w2, x1 + w1) - x2;

            if (x1 + w1 < x2) continue;
            if (x1 > x2 + w2) continue;
            try overlaps.append(.{
                .percent = overlap_length / @min(w1, w1),
                .bp = i.bp,
            });
            std.debug.print("overlap: {}\n", .{overlap_length / @min(w1, w2)});

            //check if slider is on top of the area of each item
        }
        self.hit_list.enabled = false;
        return try overlaps.toOwnedSlice();
    }

    if (slider.x + slider.width >= rect.x + rect.width) {
        slider.x = rect.x + rect.width - slider.width;
        slider.direction = -1;
    }
    if (slider.x <= rect.x) {
        slider.x = rect.x;
        slider.direction = 1;
    }
    return null;
}
