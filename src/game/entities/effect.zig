const Self = @This();

const std = @import("std");

const Entity = @import("./entity.zig");
const game = @import("../game.zig");

pub const on_fire = Self{
    .name = "on_fire",
    .negative = true,
    .predicate_fns = &.{
        &(struct {
            fn f(e: *Entity, _: game.Game) bool {
                for (e.status_effects) |effect| {
                    if (std.mem.eql(u8, effect.name, "fire_immunity")) {
                        return false;
                    }
                }
                return true;
            }
        }),
    },
    .tick_cooldown = 1,
    .apply_fn = &(struct {
        fn f(e: *Entity, _: game.Game) void {
            var iter = e.body_parts.iterator();
            while (iter.next()) |entry| {
                for (entry.value_ptr.items) |val| {
                    val.health -= val.defense.fire * 10;
                }
            }
        }
    }.f),
};

name: []const u8,

// is this effect considered negative?
negative: bool,

// any predicates this effect needs fulfilled to apply
predicate_fns: ?[](*const fn (Entity, game.Game) bool) = null,

// how many ticks should we wait before applying the effect again?
// set to null to disable tick based applications
tick_cooldown: ?usize,

// the function that this effect will run whenever it should be triggered
apply_fn: ?*const fn (*Entity, game.Game) void = null,
