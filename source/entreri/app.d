module entreri.app;

import std.stdio;
import std.conv: to;

import entreri.world;
import entreri.mem.memorymanager;
import entreri.component;
import entreri.entitysystem;
import entreri.aspect;

final class Position: Component {
    mixin TypeNum;

    int x;
    int y;

    this(int x, int y) {
        this.x = x;
        this.y = y;
    }
}

final class Velocity: Component {
    mixin TypeNum;

    int vx;
    int vy;

    this(int vx, int vy) {
        this.vx = vx;
        this.vy = vy;
    }
}

final class Name: Component {
    mixin TypeNum;

    string name;

    this(string name) {
        this.name = name;
    }
}

final class MovementSystem: EntitySystem {
    this() {
        super(Aspect.from!(Position, Velocity));
    }
    override void process(World.Entity entity) {
        auto pos = entity.get!Position;
        auto vel = entity.get!Velocity;

        assert(pos !is null);
        assert(vel !is null);

        pos.x += vel.vx;
        pos.y += vel.vy;
    }
}

final class RenderSystem: EntitySystem {
    this() {
        super(Aspect.from!(Position, Velocity));
    }
    override void process(World.Entity entity) {
        auto pos = entity.get!Position;
        writefln("id: %d, x: %d, y: %d", entity.id, pos.x, pos.y);
    }
}

final class NameRenderSystem: EntitySystem {
    this() {
        super(Aspect.from!(Name));
    }

    override void process(World.Entity entity) {
        auto name = entity.get!Name.name;
        writeln(name);
    }
}

version(App){
void main() {
    auto world = new World();

    auto x = new GrowingManager!Position;
    x.addComponent(5,6);
    auto y = new GrowingManager!Velocity;
    y.addComponent(5,6);
    auto z = new GrowingManager!Name;
    z.addComponent("hi");

    world.addManager(new GrowingManager!Position);
    world.addManager(new GrowingManager!Velocity);
    world.addManager(new GrowingManager!Name);

    world.addSystem(new RenderSystem);
    world.addSystem(new MovementSystem);
    world.addSystem(new NameRenderSystem);

    world.initialize();


    for(auto i = 0; i < 5; i++) {
        auto e = world.new Entity;
        e.add!Position(i, i);
        e.add!Velocity(i, i);
        if(i % 2 == 0) {
            e.add!Name("foo " ~ to!string(i));
        }
    }

    world.runIteration();
    writeln();
    world.runIteration();
    writeln();
    world.runIteration();
}
}
