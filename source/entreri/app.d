module entreri.app;

import std.stdio;
import std.conv: to;

import entreri.world;
import entreri.componentmanager;
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
    override void process(Entity entity) {
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
    override void process(Entity entity) {
        auto pos = entity.get!Position;
        writefln("id: %d, x: %d, y: %d", entity.id, pos.x, pos.y);
    }
}

final class NameRenderSystem: EntitySystem {
    this() {
        super(Aspect.from!(Name));
    }

    override void process(Entity entity) {
        auto name = entity.get!Name.name;
        writeln(name);
    }
}

void main()
{
    auto world = new World();

    world.addManager(new ComponentManager!Position);
    world.addManager(new ComponentManager!Velocity);
    world.addManager(new ComponentManager!Name);

    world.addSystem(new RenderSystem);
    world.addSystem(new MovementSystem);
    world.addSystem(new NameRenderSystem);

    world.initialize();


    for(auto i = 0; i < 5; i++) {
        auto e = world.newEntity();
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
