
module entreri.allocators.blockstructallocator;

import entreri.componentallocator;

import std.conv: to;
debug import std.stdio;

class BlockStructAllocator(S): ComponentAllocator!S {
    private struct BlockLoc {
        ulong block;
        ulong offset;
    }

    private S[][] blocks;
    private uint curBlock = 0;

    BlockLoc[uint] mapping;
    BlockLoc[] holes;

    const private uint unitsPerBlock;

    this(uint unitsPerBlock = 256,  uint initBlocks = 16) {
        assert(unitsPerBlock > 0);
        assert(initBlocks > 0);
        this.unitsPerBlock = unitsPerBlock;

        this.blocks = [];
        this.blocks.length = initBlocks;
        assert(blocks.length == initBlocks);

        foreach (ref arr; blocks) {
            arr.reserve(unitsPerBlock);
        }
    }

    S* allocate(uint id) {
        if (id in mapping) {
            throw new Exception("Entity " ~ id.to!string ~
                    "already has a mapping to " ~ typeid(S).stringof);
        }

        // Check to see if we have any holes to use
        if (holes.length > 0) {
            BlockLoc pos = holes[$ - 1];
            holes.length -= 1;
            mapping[id] = pos;

            return &(blocks[pos.block][pos.offset]);
        } else {
            auto curArr = blocks[curBlock];
            // If we have more room in this block
            if (curArr.capacity() - curArr.length <= 0) {
                curBlock ++;
                // For the preallocated arrays.
                if (curBlock < blocks.length) {
                    curArr = blocks[curBlock];
                } else {
                    blocks ~= [];
                    curArr = blocks[$ - 1];
                    curArr.reserve(unitsPerBlock);
                }
            }
            curArr.length = curArr.length + 1;
            blocks[curBlock] = curArr;
            BlockLoc loc;
            loc.block = curBlock;
            loc.offset = curArr.length - 1;
            mapping[id] = loc;
            return &curArr[$ - 1];
        }
    }

    S* get(uint id) {
        if (id !in mapping) {
            throw new Exception("Entity " ~ id.to!string ~
                    " does not have a mapping to " ~ typeid(S).stringof ~
                    " to get");
        }

        auto pos = mapping[id];
        return &(blocks[pos.block][pos.offset]);
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
        auto pos = mapping[id];
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
    auto sa = new BlockStructAllocator!Foo;

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

    auto sa = new BlockStructAllocator!Foo;

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

    auto sa = new BlockStructAllocator!Foo;

    auto f1 = sa.allocate(0);
    assert(sa.hasComponent(0));

    sa.remove(0);

    assert(!sa.hasComponent(0));

    auto f2 = sa.allocate(1);
    auto f3 = sa.allocate(2);

    // test holes usage
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
    auto sa = new BlockStructAllocator!Foo;

    // getting a component that doesn't exist
    assertThrown(sa.get(0));

    // removing a component that doesn't exist
    assertThrown(sa.remove(0));

    // allocating a component that already exists
    sa.allocate(0);
    assertThrown(sa.allocate(0));
}

// Growing past boundries
unittest {
    struct Foo {
        uint x;
        double d;
    }

    auto sa = new BlockStructAllocator!Foo(2,2);

    auto init (uint x) {
        auto f = sa.allocate(x);
        f.x = x;
        return f;
    }

    auto f1 = init(0);
    auto f2 = init(1);
    auto f3 = init(2);
    auto f4 = init(3);
    auto f5 = init(4);
    auto f6 = init(5);

    assert(f1.x == 0);
    assert(f2.x == 1);
    assert(f3.x == 2);
    assert(f4.x == 3);
    assert(f5.x == 4);
    assert(f6.x == 5);

    foreach (i; 0..5) {
        assert(i == sa.get(i).x);
    }
}
