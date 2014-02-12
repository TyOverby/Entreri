module entreri.aspectsystem;

import entreri.aspect;
import entreri.system;
import entreri.world;

debug import std.stdio;

/++
 + A system that only operates on entities that have the specified components.
 +
 + For example, if entity `a` has components {X, Y, Z}, and an AspectSystem `as`
 + is watching entities with {X, Y}, `as` will follow entity `a`.  However, if
 + an entity `b` has components {X, Z}, `as` will *not* follow `b`.
 +
 + Examples:
 + ---
 + struct X {
 +     mixin Component;
 + }
 + struct Y {
 +     mixin Component;
 +  }
 + struct Z {
 +     mixin Component;
 + }
 +
 + // We are *just* following X and Y.
 + class XYSystem: AspectSystem!(X, Y) {
 +     protected bool process(World.Entity* entity) {
 +         // We can ask for these components now
 +         X* x = entity.get!X;
 +         Y* y = entity.get!Y;
 +
 +         // if we returned false at any point
 +         // the system would stop processing entities.
 +         return true;
 +     }
 + }
 + ---
 +
 + See_Also: entreri.System
 +/
class AspectSystem(Components...): IAspectSystem {
    private Aspect _aspect;

    this() {
        _aspect = Aspect.from!(Components);
    }

    package void setWorld(World world) {
        super.setWorld(world);
    }

    /++
     + Returns: The aspect of components that this System follows.
     +/
    @property override Aspect aspect() {
        return _aspect;
    }
}

unittest {
    debug import std.stdio;
    import entreri.component;
    struct Foo {
        mixin Component;
    }


    struct Bar {
        mixin Component;
    }


    class FooSystem: AspectSystem!Foo { }
    class BarSystem: AspectSystem!(Foo, Bar) { }

    // Make sure that the super this() call still
    // works.
    class SubBarSystem: BarSystem {
        this() { }
    }

    IAspectSystem fs = new FooSystem;
    IAspectSystem bs = new BarSystem;
    IAspectSystem sbs = new SubBarSystem;

    assert(fs.aspect.contains(Foo.typeNum));
    assert(!fs.aspect.contains(Bar.typeNum));

    assert(bs.aspect.contains(Bar.typeNum));
    assert(bs.aspect.contains(Foo.typeNum));

    assert(sbs.aspect.contains(Bar.typeNum));
    assert(sbs.aspect.contains(Foo.typeNum));
}

unittest {
    import entreri.component;
    struct Position {
        mixin Component;
        int x, y;
    }

    struct Velocity {
        mixin Component;
        int vx, vy;
    }

    class MovementSystem: AspectSystem!(Position, Velocity) {
        override protected
        bool process(World.Entity* e) {
            auto pos = e.get!Position;
            auto vel = e.get!Velocity;

            pos.x += vel.vx;
            pos.y += vel.vy;
            return true;
        }
    }

    class RenderSystem: AspectSystem!Position {
        import std.stdio: writefln;

        Position[] positions;

        override
        bool process(World.Entity* e) {
            Position* pos = e.get!Position;
            positions ~= *pos;
            return true;
        }
    }

    auto world = new World;

    world.register!Position;
    world.register!Velocity;

    world.addSystem(new MovementSystem);
    RenderSystem rs = new RenderSystem;
    world.addSystem(rs);

    auto e = world.newEntity();
    e.add!Position(0, 0);
    e.add!Velocity(2, -1);

    world.advance();

    assert(e.get!Position.x == 2);
    assert(e.get!Position.y == -1);

    world.advance();

    assert(e.get!Position.x == 4);
    assert(e.get!Position.y == -2);

    e.remove!Velocity;
    world.advance();

    assert(e.get!Position.x == 4);
    assert(e.get!Position.y == -2);

    assert(rs.positions.length == 3);
}
