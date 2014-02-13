module entreri.world;

import entreri.aspect;
import entreri.component;
import entreri.componentallocator;
import entreri.allocators.growingstructallocator;
import entreri.system;

import alg = std.algorithm;
import std.conv: emplace;
import std.container: Array;
import std.algorithm: filter;
debug import std.stdio: writeln;

/++
 + A collection that manages Entities, Systems and Components
 + at the highest level.  Any simulation requires a single
 + World object.  Entities can not be shared between different
 + World instances.
 +/
class World {
    private GrowingStructAllocator!Entity entities;
    private uint idCounter = 0;

    private void*[uint] allocators;
    private IAspectSystem[] aspectSystems;
    private Array!System systems;

    this() {
        this.entities = new GrowingStructAllocator!Entity;
    }

    /++
     + Creates an Entity managed by this world with a unique id number.
     +/
    Entity* newEntity() {
        auto id = idCounter++;
        Entity* e = entities.allocate(id);
        // This field is const, but for some reason, I can't emplace
        // from here.
        cast(uint)(e.id) = id;
        e.world = this;
        return e;
    }

    /++
     + Returns the entity with the provided id.
     +
     + If an entity doesn't exist with that ID, an Exception will be thrown.
     + This is meant for retrieving an entity whose ID you have already
     + known and are sure that it is still alive.
     +
     +/
    Entity* entityFrom(uint id) {
        return entities.get(id);
    }

    /++
     + Checks to see if the world is managing an entity with the provided id.
     +
     + Returns: true if an entity with the id exists and is alive.
     +/
    bool hasEntity(uint id) {
        return entities.hasComponent(id);
    }

    /++
     + Sets an allocation strategy for a specific Component.
     +
     + Components can have different allocation strategies.
     + By default, structs use the GrowingStructAllocator, but
     + you can use other provided allocators or write your own.
     +/
    void register(S)(ComponentAllocator!S componentAllocator)
    if (is (S == struct) && __traits(compiles, S.typeNum)) {
        allocators[S.typeNum] = cast(void*) componentAllocator;
    }

    /++
     + Registers a component with the default Allocation
     + strategy.
     +/
    void register(S)() if (is (S == struct)){
        register!S(new GrowingStructAllocator!S);
    }

    /++
     + Adds an AspectSystem to the world to be run when
     + world.advance() is called.
     +
     + The order of multiple calls to addSystem (independent from override)
     + is significant because Systems are run in the order that they are added.
     +/
    void addSystem(IAspectSystem system) {
        aspectSystems ~= system;
        systems ~= system;
        system.setWorld(this);
    }

    /++
     + Adds a system to the world to be run when world.advance() is called.
     +
     + The order of multiple calls to addSystem is significant because
     + Systems are run in the order that they are added.
     +
     + TODO: Write tests.
     +/
    void addSystem(System system) {
        systems ~= system;
        system.setWorld(this);
    }

    /++
     + Removes a system from the world.
     + TODO: Write tests. Fuck std.container
     +/
    void removeSystem(System system) {
        import std.algorithm: find;
        systems.linearRemove(systems[].find(system)[0..1]);
    }

    /++
     + Runs a single step of the simulation.  All systems
     + added to the world are run in the order that they
     + were added in.
     +/
    void advance() {
        foreach (system; systems) {
            system.step();
        }
    }

    struct Entity {
        private bool alive = true;
        public const uint id;
        private World world;
        private Aspect _aspect;

        private void*[uint] componentCache;
        // Used as a set.
        private byte[System] systems;

        @property
        public const(Aspect) aspect() {
            return _aspect;
        }

        package this(uint id, World world) {
            this.id = id;
            this.alive = true;
            this.world = world;
        }

        /++
         + Adds a component to the entity.
         +
         + The world that this Entity comes from must already be
         + registered with the component that you are trying to add
         + and this entity must not already have this type of component.
         +
         + Returns: A pointer to the component attached to the entity.
         +
         + WARNING: The pointer returned by this method is only garanteed to be valid
         + until the next time world.advance() is called.  After that point, behavior
         + is entirely undefined.  Do not store the return value of this method.
         +
         + Examples:
         + ---
         + struct Foo {
         +   mixin Component;
         +   uint x;
         + }
         + ...
         + Entity* e = world.newEntity();
         + e.add!Foo(5); // Adds a new Foo component.  The arguments are
         +               // passed to the Foo constructor.
         + ---
         +/
        S* add(S, Args...)(Args args)
        if (is (S == struct) && __traits(compiles, S.typeNum)) {
            if (S.typeNum !in world.allocators) {
                throw new Exception("No allocator registered for component " ~ typeid(S).stringof);
            }

            ComponentAllocator!S alloc = (cast (ComponentAllocator!S) world.allocators[S.typeNum]);
            S* ptr = alloc.allocate(id);
            ptr = emplace(ptr, args);

            auto oldAspect = this.aspect;
            auto newAspect = oldAspect.add!S;

            foreach(system; world.aspectSystems) {
                if (!system.shouldContain(oldAspect) && system.shouldContain(newAspect)) {
                    system.addEntity(id);
                }
            }

            this._aspect = newAspect;
            this.componentCache[S.typeNum] = ptr;
            return ptr;
        }

        /++
         + Fetches a pointer to a component attached to this entity.  If there is
         + no such component attached to the entity, an exception will be raised.
         +
         + WARNING: The pointer returned by this method is only garanteed to be valid
         + until the next time world.advance() is called.  After that point, behavior
         + is entirely undefined.  Do not store the return value of this method.
         +/
        S* get(S)()
        if (is (S == struct) && __traits(compiles, S.typeNum)) {
            if (S.typeNum in this.componentCache) {
                return cast(S*) this.componentCache[S.typeNum];
            }
            if (S.typeNum !in world.allocators) {
                throw new Exception("No allocator registered for component " ~ typeid(S).stringof);
            }
            auto ptr = (cast (ComponentAllocator!S) world.allocators[S.typeNum]).get(id);
            this.componentCache[S.typeNum] = ptr;
            return ptr;
        }

        /++
         + Removes a component from this entity.  If there is no such component in the entity
         + an exception will be thrown.
         +/
        void remove(S)() if (is (S == struct) && __traits(compiles, S.typeNum)) {
            this.componentCache.remove(S.typeNum);

            if (S.typeNum !in world.allocators) {
                throw new Exception("No allocator registered for component " ~ typeid(S).stringof);
            }

            auto oldAspect = this.aspect;
            auto newAspect = oldAspect.remove!S;

            foreach (system; world.aspectSystems) {
                if(system.shouldContain(oldAspect) &&
                   !system.shouldContain(newAspect)) {
                    system.removeEntity(id);
                }
            }

            this._aspect = newAspect;

            // Remove the element from the allocator last because we want the
            // Systems to be able to perform cleanup later.
            (cast (ComponentAllocator!S) world.allocators[S.typeNum]).remove(id);
        }


        package
        void addSystem(System system) {
            this.systems[system] = 0;
        }

        package
        void removeSystem(System system) {
            if (this.alive) {
                this.systems.remove(system);
            }
        }

        /++
         + Removes the entity from the world and removes all the components from the
         + entity and removes the entity from all the systems that it belongs to.
         +/
        public
        void kill() {
            this.alive = false;

            auto preAspect = this._aspect;
            // TODO: Test this
            // Remove from allocators.
            foreach (typeId; preAspect) {
                auto cMan = cast (ComponentAllocator!void) this.world.allocators[typeId];
                if(cMan.hasComponent(id))  {
                    cMan.remove(id);
                }
                this.componentCache.remove(typeId);
            }

            // TODO: Test this
            // Remove from systems.
            foreach (system, _; this.systems) {
                if (system.hasEntity(this.id)) {
                    system.removeEntity(id);
                }
            }

            this.world.entities.remove(id);
        }
    }
}

// system removal
unittest {
    class MySystem: System {
        bool added = false;
        bool removed = false;
        uint ran = 0;

        override
        void onAdd(World.Entity* e) {
            added = true;
        }

        protected override
        bool process(World.Entity* e) {
            ran ++;
            return true;
        }

        override
        void onRemove(World.Entity* e) {
            removed = true;
        }
    }

    {
        auto world = new World();
        auto sys = new MySystem();
        world.addSystem(sys);

        auto e = world.newEntity();
        sys.addEntity(e.id);

        assert(sys.hasEntity(e.id));
        assert(sys.added);

        world.advance();
        assert(sys.ran == 1);

        e.kill();

        assert(!sys.hasEntity(e.id));
        assert(sys.removed);

        world.advance();
        assert(sys.ran == 1);
    }
    {
        auto world = new World();
        auto sys = new MySystem();
        world.addSystem(sys);

        auto e = world.newEntity();
        sys.addEntity(e.id);
        assert(sys.hasEntity(e.id));
        assert(sys.added);

        world.advance();
        assert(sys.ran == 1);

        sys.removeEntity(e.id);
        assert(!sys.hasEntity(e.id));
        assert(sys.removed);

        world.advance();
        assert(sys.ran == 1);

        e.kill();

        world.advance();
        assert(sys.ran == 1);
    }
}

// Struct component
unittest {
    struct Foo {
        mixin Component;
        uint x = 5;
    }

    auto w = new World;
    w.register!Foo(new GrowingStructAllocator!Foo);

    auto e = w.newEntity();
    assert(e.id == 0);
    assert(e.world == w);

    auto f = e.add!Foo;
    assert(f.x == 5);
    f.x = 10;

    auto f2 = e.get!Foo;
    assert(f2.x != 5);
    assert(f2.x == 10);
}

// Struct component with constructor.
unittest {
    struct Foo {
        mixin Component;
        uint x;
        int y;

        this(uint x, int y) {
            this.x = x;
            this.y = y;
        }
    }

    auto w = new World;
    w.register!Foo(new GrowingStructAllocator!Foo);

    auto e = w.newEntity();

    auto foo = e.add!Foo(4, -1);

    auto foog = e.get!Foo;
    assert(foog.x == 4);
    assert(foog.y == -1);
}

// Struct component with default allocator
unittest {
    struct Foo {
        mixin Component;
        uint x;
    }

    auto w = new World;
    w.register!Foo;

    auto e = w.newEntity();
    auto f = e.add!Foo;
    f.x = 5;

    auto f2 = e.get!Foo;
    assert(f2.x == 5);
}

// Misbehaving
unittest {
    import std.exception: assertThrown;

    struct Foo {
       mixin Component;
       uint x = 5;
    }

    auto w = new World;

    auto e = w.newEntity();
    assertThrown(e.add!Foo);
    assertThrown(e.get!Foo);
    assertThrown(e.remove!Foo);
}

// Entity and Allocator removal
unittest {
    struct Foo {
        mixin Component;
        uint x = 5;
    }

    struct Bar {
        mixin Component;
        float y = 10;
    }

    auto w = new World;
    auto fAlloc = new GrowingStructAllocator!Foo;
    auto bAlloc = new GrowingStructAllocator!Bar;
    w.register!Foo(fAlloc);
    w.register!Bar(bAlloc);

    auto e = w.newEntity();
    e.add!Foo;
    e.add!Bar;

    assert(fAlloc.hasComponent(e.id) &&
           bAlloc.hasComponent(e.id));

    e.kill();

    assert(!fAlloc.hasComponent(e.id));
    assert(!bAlloc.hasComponent(e.id));
    assert(!fAlloc.hasComponent(e.id) &&
           !bAlloc.hasComponent(e.id));
}

// World.entityFrom
unittest {
    struct Foo {
        mixin Component;
        uint x;
    }


    auto w = new World;
    w.register!Foo;

    auto e1 = w.newEntity();
    auto e2 = w.entityFrom(e1.id);

    assert(e1.id == e2.id);

    e1.add!Foo;

    auto e1f = e1.get!Foo;
    auto e2f = e2.get!Foo;

    e1f.x = 5;
    assert(e2f.x == 5);

    e2f.x = 10;
    assert(e1f.x == 10);

    assert(w.hasEntity(e1.id));
    e1.kill();
    assert(!w.hasEntity(e1.id));
}

// World.removeSystem
unittest {
    struct Foo {
        mixin Component;
        uint x;
    }
    class MySystem: System {
        uint count;
    }
}
