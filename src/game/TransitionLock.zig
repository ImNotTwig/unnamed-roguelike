// TransitionLock is a struct used by visual elements that transition from
// one place to another within a target amount of time
const Self = @This();
const rl = @import("raylib");

// visual_location is the location that is perceived in the game
visual_location: rl.Vector2,
// target_location is where the thing being animated is actually located
target_location: rl.Vector2,
// transition is whether or not the thing is being animated currently
transition: bool,
// animation_time is how long the animation should take
animation_time: f32,
// delta keeps track of how long its been since the animation started
delta: f32,

pub fn updateLocation(self: *@This()) void {
    if (self.transition) {
        self.delta += rl.getFrameTime();

        var t = self.delta / self.animation_time;
        if (t >= 1) {
            t = 1;
            self.transition = false;
            self.delta = 0;
        }

        self.visual_location = self.visual_location.lerp(self.target_location, t);
    }
}
