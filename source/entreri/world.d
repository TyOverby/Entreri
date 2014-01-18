module entreri.world;

import entreri.componentallocator;

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


    struct Entity {
        private bool alive = true;
        const uint id;
        package World world;

        private this(uint id) {
            this.id = id;
        }

        C* add(C)() {
            if (C.typeNum !in world.allocators) {
                throw new Exception("No allocator for component ");
            }
            auto alloc = (cast (ComponentAllocator!C) world.allocators[C.typeNum]);
            return alloc.allocate(id);
        }

        C* get(C)() {
            return (cast (ComponentAllocator!C) world.allocators[C.typeNum]).get(id);
        }
    }
}

unittest {
    import entreri.structallocator;

    struct Foo {
        static typeNum = 0;
        uint x = 5;
    }

    auto w = new World;
    w.register!Foo(new StructAllocator!Foo);

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

