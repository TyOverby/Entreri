module entreri.allocator;

import core.memory;
import core.exception;
import std.stdio;
import std.conv;

class ClassAllocator(A, bool GROWABLE = true) {
    static assert(__traits(isFinalClass, A), "ClassAllocator can only work with final classes.");

    private immutable SIZE = __traits(classInstanceSize, A);

    private void* memptr = null;
    private void[] mem = null;
    private size_t offset = 0;

    private size_t capacity = 0;

    private bool[size_t] holes;

    this(size_t initialCapacity = 64) {
        capacity = initialCapacity;
        resize();
    }

    private void resize() {
        immutable length = SIZE * capacity;
        if(mem) {
            memptr = GC.realloc(memptr, length);
            mem = memptr[0 .. length];
        } else {
            memptr = GC.malloc(length);
            mem = memptr[0 .. length];
        }
    }

    protected void grow() {
        if(!GROWABLE) {
            throw new OutOfMemoryError();
        } else {
            this.capacity *= 3;
            this.capacity /= 2;
            this.resize();
        }
    }

    private void testResize() {
        if(offset >= capacity) {
            grow();
        }
    }

    private void[] getNext() {
        testResize();

        if(holes.length != 0) {
            size_t found_offset;
            foreach(k; holes) {
                found_offset = k;
                break;
            }
            holes.remove(found_offset);
            return mem[found_offset * SIZE .. found_offset * SIZE + SIZE];
        }

        auto toReturn = mem[offset * SIZE .. offset * SIZE + SIZE];
        offset++;
        return toReturn;
    }

    public A place(Args...)(ref Args args) {
        return emplace!A(getNext(), args);
    }

    public A opIndex(size_t index) {
        return cast(A)  &(mem[index * SIZE]);
    }

    public bool remove(size_t index) {
        if(index >= capacity) {
            throw new Error("Index not in range.");
        }

        if(index in holes) {
            return false;
        } else {
            holes[index] = true;
            return true;
        }
    }

    public bool free(A obj) {
        return true;
    }
}

//TODO(tyoverby): write unittests

unittest {
    final class Position {
        int x;
        int y;

        this(int x, int y) {
            this.x = x;
            this.y = y;
        }
    }

    Position[] positions;
    immutable TO = 100;

    auto alloc = new ClassAllocator!(Position, true)(64);
    for(int i = 0; i < TO; i++) {
        Position p =  alloc.place(i, TO - i);//emplace!Position(i, TO - i);
    }

    for(size_t i = 0; i < TO; i++) {
         assert(alloc[i].x == i);
         assert(alloc[i].y == TO - i);
    }
}
