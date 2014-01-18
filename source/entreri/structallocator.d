module entreri.structallocator;

import entreri.componentallocator;

import std.array;
import std.conv;

//TODO: Make a ClassAllocator

class StructAllocator(S): ComponentAllocator!S {
    private S[] arr;
    private uint[] holes;
    private uint[uint] mapping;

    S* allocate(uint id) {
        if (holes.length > 0) {
            uint pos = holes[$ - 1];
            holes.popBack();
            mapping[id] = pos;
            arr[pos] = S();
            return &arr[pos];
        } else {
            arr ~= S();
            mapping[id] = to!uint(arr.length - 1);
            return &arr[$ - 1];
        }
    }

    S* get(uint id) {
        return &arr[mapping[id]];
    }
    void remove(uint id) {
        uint pos = mapping[id];
        mapping.remove(id);

        holes ~= pos;
    }
}

unittest {
    struct Foo {
        int x;
        double d;
    }
    auto sa = new StructAllocator!Foo;

    auto f = sa.allocate(0);
    f.x = 5;

    auto f2 = sa.get(0);
    // assert(f2.x == 5);
    f2.d = 1.0;

    auto f3 = sa.get(0);
    assert(f3.d == 1.0);
}
