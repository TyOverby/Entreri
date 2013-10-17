module memorymanager;

import core.memory;
import std.conv;

class MemoryManager(C) {
    void* memory = void;

    immutable SIZE = __traits(classInstanceSize, C);

    size_t capacity;
    size_t componentCount = 0;

    static assert(1, "SIZE " ~ to!string(SIZE));

    this() {
        this(512);
    }

    this(size_t initialSize) {
        this.capacity = initialSize;
        immutable memoryLength = this.capacity * SIZE;
        this.memory = GC.malloc(memoryLength);
    }

    protected void checkSize(){
        if(componentCount + 2 >= capacity) {
            grow();
        } else if(componentCount * 3 < capacity) {
            shrink();
        }
    }

    protected void grow() {
        this.capacity = (this.capacity * 3) / 2;
        immutable memoryLength = this.capacity * SIZE;
        this.memory = GC.realloc(this.memory, memoryLength);
    }

    protected void shrink() {
        immutable memoryLength = (this.capacity / 2) * SIZE;
        this.memory = GC.realloc(this.memory, memoryLength);
    }

    protected void* addressOf(size_t i) {
        return &(memory[i * SIZE]);
    }
    protected C indexInto(size_t i) {
        return cast(C) addressOf(i);
    }
}
