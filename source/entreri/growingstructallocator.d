module entreri.growingstructallocator;

import entreri.componentallocator;

import std.array;
import std.conv: to;
debug import std.stdio;

//TODO: Make a ClassAllocator

class GrowingStructAllocator(S): ComponentAllocator!S {
    private S[] arr;
    private uint[] holes;
    private uint[uint] mapping;

    this() {
        arr.reserve(100);
        holes.reserve(25);
    }

    this(uint startingSize) {
        arr.reserve(startingSize);
        holes.reserve(25);
    }

    S* allocate(uint id) {
        if (id in mapping) {
            throw new Exception("Entity " ~ id.to!string ~
                    " already has a mapping to " ~ typeid(S).stringof);
        }
        if (holes.length > 0) {
            uint pos = holes[$ - 1];
            holes.length -= 1;
            mapping[id] = pos;
            return &arr[pos];
        } else {
            arr.length += 1;
            mapping[id] = to!uint(arr.length - 1);

            return &arr[$ - 1];
        }
    }

    S* get(uint id) {
        if (id !in mapping) {
            throw new Exception("Entity " ~ id.to!string ~
                    " does not have a mapping to " ~ typeid(S).stringof ~
                    " to get");
        }
        return &arr[mapping[id]];
    }

    bool hasComponent(uint id) {
        return (id in mapping) !is null;
    }

    void remove(uint id) {
        if (id !in mapping) {
            throw new Exception("Entity " ~ id.to!string ~
                    " does not have a mapping to " ~ typeid(S).stringof ~
                    " to remove");
        }
        uint pos = mapping[id];
        mapping.remove(id);

        holes.assumeSafeAppend() ~= pos;
    }
}

// Basic allocate / get
unittest {
    struct Foo {
        int x;
        double d;
    }
    auto sa = new GrowingStructAllocator!Foo;

    auto f = sa.allocate(0);
    f.x = 5;

    auto f2 = sa.get(0);
    assert(f2.x == 5);
    f2.d = 1.0;

    auto f3 = sa.get(0);
    assert(f3.d == 1.0);
}

// Basic allocation locations
unittest {
    struct Foo {
        int x;
        double d;
    }

    auto sa = new GrowingStructAllocator!Foo;
    auto f1 = cast(void*) sa.allocate(0);
    auto f2 = cast(void*) sa.allocate(1);
    auto f3 = cast(void*) sa.allocate(2);

    assert(f1 != f2);
    assert(f2 != f3);
}

// Basic allocate / remove
unittest {
    struct Foo {
        int x;
        double d;
    }

    auto sa = new GrowingStructAllocator!Foo;

    auto f1 = sa.allocate(0);
    assert(sa.hasComponent(0));

    sa.remove(0);

    assert(!sa.hasComponent(0));

    auto f2 = sa.allocate(1);
    auto f3 = sa.allocate(2);

    // f1 (after being removed) should have the same location as f2
    assert(cast(void*) f1 == cast(void*) f2);
    assert(cast(void*) f3 != cast(void*) f1);
}

// Incorrectly using features
unittest {
    import std.exception: assertThrown;
    struct Foo {
        uint x;
        double d;
    }
    auto sa = new GrowingStructAllocator!Foo;

    // getting a component that doesn't exist
    assertThrown(sa.get(0));

    // removing a component that doesn't exist
    assertThrown(sa.remove(0));

    // allocating a component that already exists
    sa.allocate(0);
    assertThrown(sa.allocate(0));
}
