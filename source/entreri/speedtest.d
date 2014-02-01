import entreri;
import entreri.growingstructallocator;

import std.datetime: Clock;
import std.stdio: writeln;
import core.memory: GC;

struct Position {
    mixin Component;

    double x;
    double y;
}

struct Velocity {
    mixin Component;

    double vx;
    double vy;
}

class MovementSystem: AspectSystem!(Position, Velocity) {
    override bool process(World.Entity* e) {
        Position* pos = e.get!Position;
        Velocity* vel = e.get!Velocity;
        pos.x += vel.vx;
        pos.y += vel.vy;
        return true;
    }
}

class RenderSystem: AspectSystem!Position {
    import std.stdio: writefln;
    override bool process(World.Entity* e) {
        Position* pos  = e.get!Position;
        //writefln("(%f, %f)", pos.x, pos.y);
        return true;
    }
}

enum EntityCount = 100_000;
enum IterationCount = 60;
void main() {
    GC.disable();
    auto startTime = Clock.currTime();
    World world = new World;

    world.register!Position(new GrowingStructAllocator!Position(EntityCount));
    world.register!Velocity(new GrowingStructAllocator!Velocity(EntityCount));

    world.addSystem(new MovementSystem);
    world.addSystem(new RenderSystem);

    foreach (i; 0 .. EntityCount) {
        world.Entity* e = world.newEntity();
        e.add!Position(i, i);
        e.add!Velocity(i, i);
    }

    auto preTime = Clock.currTime();
    writeln("warmup elapsed: ", preTime - startTime);

    foreach (i; 0 .. IterationCount) {
        world.advance();
    }

    auto postTime = Clock.currTime();
    writeln("time elapsed: ", postTime - preTime);
}
