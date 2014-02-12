import entreri;
import entreri.allocators.growingstructallocator;

import std.datetime: Clock;
import std.stdio: writeln;
import core.memory: GC;

// A plain-old-data struct that just contains the position
// of an object.
struct Position {
    // You must remember to mixin Component into your
    // component structs!  This adds extra type information
    // to the internal systems!
    mixin Component;

    double x;
    double y;
}

// A plain-old-data struct that just contains the velocity
// of an object.  Please note that you'd probably want to
// group this with Position in any real simulation unless
// you have a crazy number of entities that never move and
// you need the seperation for your mental health.
struct Velocity {
    mixin Component;

    double vx;
    double vy;
}

// Create a system that only acts on entities that have
// both a Position component and a Velocity component.
class MovementSystem: AspectSystem!(Position, Velocity) {
    // Every frame, `process` will be called on every
    // entity that contains a Position and a Velocity
    // component.
    override bool process(World.Entity* e) {
        // Grab the components out of them.
        // (please note that we are handed pointers to
        // the component structs.)
        Position* pos = e.get!Position;
        Velocity* vel = e.get!Velocity;
        // Update the position from the velocity.
        pos.x += vel.vx;
        pos.y += vel.vy;

        // Return true to continue processing entities
        // in this system.  false would immediately
        // end this system's processing and start the
        // next system.
        return true;
    }
}

// Create a system that only acts on entities that
// have a Position component.
class RenderSystem: AspectSystem!Position {
    import std.stdio: writefln;
    // Every frame, `process` will be called on
    // every entity that contains a Position.
    override bool process(World.Entity* e) {
        Position* pos  = e.get!Position;

        // uncomment this if you actually want your
        // terminal bombarded with a shit-ton of
        // update messages.

        // writefln("%d (%f, %f)", e.id, pos.x, pos.y);
        return true;
    }
}

enum EntityCount = 100;
enum IterationCount = 60;
void main() {
    World world = new World;

    // Register the Position component with a default allocator.
    world.register!Position;
    // Register the Velocity component with an explicit allocator.
    // The GrowingStructAllocator keeps all of its components in the
    // same chunk of memory.  It does perform resizes which can result in
    // pointers being invalidated!
    world.register!Velocity(new GrowingStructAllocator!Velocity(EntityCount));

    // Add our two systems.
    world.addSystem(new MovementSystem);
    world.addSystem(new RenderSystem);

    foreach (i; 0 .. EntityCount) {
        // Create a new entity.
        world.Entity* e = world.newEntity();
        // Add our components to it.
        // In this case, we are calling the constructors of Position
        // and Velocity with the arguments (i, i) in order to create
        // the structs with some initial data.
        e.add!Position(i, i);
        e.add!Velocity(i, i);
    }

    foreach (i; 0 .. IterationCount) {
        // Advance the stage of the world.  This basically goes through
        // each of your systems and calls processAll() and process().
        world.advance();
    }
}
