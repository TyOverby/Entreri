import std.stdio;

import world;
import componentmanager;
import component;
import typedecl;
import entitysystem;

final class Position: Component {
    mixin ComponentDecl;
    mixin ComponentImpl;

    int x;
    int y;

    this(int x, int y) {
        this.x = x;
        this.y = y;
    }
}

final class Velocity: Component {
    mixin ComponentDecl;
    mixin ComponentImpl;

    int vx;
    int vy;

    this(int vx, int vy) {
        this.vx = vx;
        this.vy = vy;
    }
}

final class MovementSystem: EntitySystem {
    override void process(Entity entity) {
        auto pos = entity.get!Position;
        auto vel = entity.get!Velocity;

        assert(pos !is null);
        assert(vel !is null);

        //pos.x = 0;
        //pos.y = 0;

        //pos.x += vel.vx;
        //pos.y += vel.vy;
    }
}

final class RenderSystem: EntitySystem {
    override void process(Entity entity) {
        auto pos = entity.get!Position;

        writefln("id: %d, x: %d, y: %d", entity.id, pos.x, pos.y);
        writefln("%X", cast(void*) pos);
        //writefln("%d", entity.id);
    }
}

void main()
{
    auto world = new World();

    auto positionManager = new ComponentManager!Position;
    world.addManager(positionManager);
    //auto velocityManager = new ComponentManager!Velocity;
    //world.addManager(velocityManager);

    //world.addSystem(new MovementSystem);
    world.addSystem(new RenderSystem);

    world.initialize();

    for(auto i = 0; i < 3; i++) {
        auto e = world.newEntity();
        e.addComponent(new(positionManager) Position(i, 1000 - i));
        //e.addComponent(new(velocityManager) Velocity(0, 0));

        writefln("id: %d, x: %d, y:%d", e.id, e.get!Position.x, e.get!Position.y);
        writefln("%X", cast(void*) e.get!Position);
        //writefln("%X", cast(void*) e.get!Position);
        //writefln("%d", e.id);
    }

    writeln();

    world.runIteration();
}
