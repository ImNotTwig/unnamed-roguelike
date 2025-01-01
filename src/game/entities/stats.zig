const rl = @import("raylib");

/// Health is a struct to give something--in most cases, an entity--health statistics
/// which can be used to determine if it should be dead, or have debuffs, etc
pub const Health = struct {
    // max_health is the base amount of health something should be brought to
    // when fully healed
    max_health: f32 = 100,
    // current_health is the amount of health something currently has, obviously lol
    current_health: f32 = 100,
    // over_health is a special temporary boost in health something has, which will bring
    // its total amount of usable health higher than that of its normal max_health
    over_health: f32 = 0,
    // under_health is a special temporary deficit in health that will lower the amount of
    // health something can heal up to
    under_health: f32 = 0,
};

// values > 0 but <= 1,
// the higher the value the lower the resistance
pub const DamageTypeValues = struct {
    // common basic damage types
    sharp: f32 = 1,
    blunt: f32 = 1,
    ballistic: f32 = 1,

    // common elemental damage types
    fire: f32 = 1,
    ice: f32 = 1,
    electric: f32 = 1,

    // poison is generally specific to magic users
    poison: f32 = 1,
    // radiation is generally specific to ultratech users
    radiation: f32 = 1,

    // necrotic - magic
    necrotic: f32 = 1,
    // acid - ultratech
    acid: f32 = 1,

    // magnetic - magic
    magnetic: f32 = 1,
    // psychic - ultratech
    psychic: f32 = 1,

    // shadow - magic
    shadow: f32 = 1,
    // light - ultratech
    light: f32 = 1,

    // spacial - magic
    spacial: f32 = 1,
    // temporal - ultratech
    temporal: f32 = 1,
};

pub const Combat = struct {
    // if your attack is higher than the opponents defense, it will do more damage
    // if it is lower, it does less, depending on how much lower
    attack: DamageTypeValues,
    defense: DamageTypeValues,
    //NOTE: even though this is called accuracy, it effects damage outcome, not hit chance
    // accuracy.x is the lower threshold of accuracy, y is the higher threshold
    // a random number between these two will be chosen, which will then be multiplied against
    // the damage calculation after weapon damage, weapon damage chance, modifiers, etc
    // the min and max range should be 0 < x <= 1 and 0 < y <= 1
    // also any time x > y, it should be considered a bug or error
    accuracy: rl.Vector2,
};
