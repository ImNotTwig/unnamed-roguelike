const stats = @import("./stats.zig");

health: stats.Health,
defense: stats.DamageTypeValues,

// occupied_slots determines how many slots this body part will take up
// when placed on an entity
// NOTE: this can be negative, in case you want to actually have a body part that *makes* slots
occupied_slots: i32,

//NOTE: there will be other things to implement as I implement more features
