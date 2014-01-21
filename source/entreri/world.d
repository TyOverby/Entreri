module entreri.world;

import entreri.component;
import entreri.componentallocator;
import entreri.growingstructallocator;
import entreri.system;

import std.conv: emplace;
debug import std.stdio;

class World {
    //TODO: Use a StructAllocator to manage the entities list :P
    private GrowingStructAllocator!Entity entities;
    private uint idCounter = 0;

    private void*[uint] allocators;
    private System[] systems;

    this() {
        this.entities = new GrowingStructAllocator!Entity;
    }

    Entity* newEntity() {
        auto id = idCounter++;
        Entity* e = entities.allocate(id);
        cast(uint)(e.id) = id;
        cast(World)(e.world) = this;
        return e;
    }

    void register(C)(ComponentAllocator!C componentAllocator) {
        allocators[C.typeNum] = cast(void*) componentAllocator;
    }

    void register(S)() if (is (S == struct)){
        register!S(new GrowingStructAllocator!S);
    }

    void addSystem(System system) {
        systems ~= system;
    }

    void advance() {
        foreach (system; systems) {
            system.step();
        }
    }

    struct Entity {
        private bool alive = true;
        public const uint id;
        private World world;

        package this(uint id, World world) {
            this.id = id;
            this.alive = true;
            this.world = world;
        }

        S* add(S, Args...)(Args args) if (is (S == struct)) {
            if (S.typeNum !in world.allocators) {
                throw new Exception("No allocator registered for component " ~ typeid(S).stringof);
            }

            ComponentAllocator!S alloc = (cast (ComponentAllocator!S) world.allocators[S.typeNum]);
            S* ptr = alloc.allocate(id);
            ptr = emplace(ptr, args);
            return ptr;
        }

        S* get(S)() if (is (S == struct)) {
            if (S.typeNum !in world.allocators) {
                throw new Exception("No allocator registered for component " ~ typeid(S).stringof);
            }
            return (cast (ComponentAllocator!S) world.allocators[S.typeNum]).get(id);
        }

        void kill() {
            this.alive = false;
            this.world.entities.remove(id);

            foreach (c; this.world.allocators) {
                auto cMan = cast (ComponentAllocator!void) c;
                if (cMan.hasComponent(id)) {
                    cMan.remove(id);
                }
            }

            // TODO: Go through and remove from any systems that this entity might belong to.
        }
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

    assert(!fAlloc.hasComponent(e.id) &&
           !bAlloc.hasComponent(e.id));
}
