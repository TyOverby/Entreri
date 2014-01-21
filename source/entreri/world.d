module entreri.world;

import entreri.component;
import entreri.componentallocator;
import entreri.growingstructallocator;

import std.conv: emplace;
debug import std.stdio;

class World {
    //TODO: Use a StructAllocator to manage the entities list :P
    private Entity[] entities;
    private uint idCounter = 0;

    void*[uint] allocators;

    Entity* newEntity() {
        auto e = Entity(idCounter++);
        e.world = this;
        entities ~= e;
        return &entities[entities.length - 1];
    }

    void register(C)(ComponentAllocator!C componentAllocator) {
        allocators[C.typeNum] = cast(void*) componentAllocator;
    }

    void register(S)() if (is (S == struct)){
        register!S(new GrowingStructAllocator!S);
    }

    struct Entity {
        private bool alive = true;
        const uint id;
        package World world;

        private this(uint id) {
            this.id = id;
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
