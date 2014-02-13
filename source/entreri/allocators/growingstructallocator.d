module entreri.allocators.growingstructallocator;

import entreri.componentallocator;

import std.array;
import std.conv: to;
debug import std.stdio;

class GrowingStructAllocator(S): ComponentAllocator!S {
    private S[] arr;
    // An array of positions (inside of arr) that are
    // currently not in use.
    private uint[] holes;
    // Id -> Position
    private uint[uint] mapping;

    // An array similar to arr, but for temporary usage.
    private S[] temp;
    // Id -> Position
    private uint[uint] tempMapping;
    // Can we invalidate pointers
    private bool clobber = false;

    this(uint startingSize = 128) {
        assert(startingSize != 0);
        arr.reserve(startingSize);
        holes.reserve(startingSize / 4);
        temp.reserve(startingSize / 4);
    }

    S* allocate(uint id) {
        if (id in mapping) {
            throw new Exception("Entity " ~ id.to!string ~
                    " already has a mapping to " ~ typeid(S).stringof);
        }
        // Allocate into an already existing part of the array.
        if (holes.length > 0) {
            uint pos = holes[$ - 1];
            holes.length -= 1;
            mapping[id] = pos;
            return &arr[pos];
        } else {
            if (clobber || arr.capacity - arr.length > 0) {
                // We can either insert without reallocating for the array
                // or we don't care anyway.

                arr.length += 1;
                mapping[id] = to!uint(arr.length - 1);

                return &arr[$ - 1];
            } else {
                // We need to place the element in the temp array.
                temp.length += 1;
                tempMapping[id] = to!uint(arr.length - 1);
                return &temp[$ - 1];
            }
        }
    }

    S* get(uint id) {
        if (id !in mapping) {
            if (id in tempMapping) {
                return &temp[tempMapping[id]];
            }

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
            if (id in tempMapping) {
                uint pos = tempMapping[id];
                tempMapping.remove(id);
                temp[pos].destroy();
            }
            throw new Exception("Entity " ~ id.to!string ~
                    " does not have a mapping to " ~ typeid(S).stringof ~
                    " to remove");
        }
        uint pos = mapping[id];
        mapping.remove(id);

        holes.assumeSafeAppend() ~= pos;

        arr[pos].destroy();
    }

    void reorg() {
        this.clobber = true;
        scope(exit) this.clobber = false;

        foreach (id, pos; tempMapping) {
            enum Size = S.sizeof;

            S* pointer = this.allocate(id);
            // *pointer = temp[pos];
            // The above doesn't work because of some stupid immutability error.
            (cast(void*)(pointer))[0 .. Size] = (cast(void*)(&temp[pos]))[0 .. Size];
        }

        temp.length = 0;

        foreach (key; tempMapping.keys()) {
            tempMapping.remove(key);
        }
    }
}

// Test using merge.
unittest {
    struct Foo {
        int x;
        double d;
    }

    enum Cap = 3;
    enum Post = 10;

    auto sa = new GrowingStructAllocator!Foo(Cap);

    for (uint i = 0; i < Cap; i++) {
        sa.allocate(i);
        assert(sa.arr.length == i + 1);
        assert(sa.mapping.length == i + 1);
        assert(sa.temp.length == 0);
        assert(sa.tempMapping.length == 0);
    }

    for (uint i = Cap; i < Post; i++) {
        sa.allocate(i);

        assert(sa.arr.length == Cap);
        assert(sa.mapping.length == Cap);
        assert(sa.temp.length == i - Cap + 1);
        assert(sa.tempMapping.length == i - Cap + 1);
    }

    sa.reorg();
    assert(sa.arr.length == Post);
    assert(sa.mapping.length == Post);
    assert(sa.temp.length == 0);
    assert(sa.tempMapping.length == 0);
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
