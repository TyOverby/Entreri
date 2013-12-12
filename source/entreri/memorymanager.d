module entreri.memorymanager;

import entreri.component;
import entreri.allocator;

import core.memory: GC;
import core.exception: OutOfMemoryError;
import std.conv: emplace;

interface MemoryManager(C: Component) {
    C instantiate(Args...)(Args args);
    void free(C obj);
}

class GrowingManager(C: Component): MemoryManager!C {
    private ClassAllocator!(C, true) allocator;

    this(size_t initialCapacity = 64) {
       this.allocator = new ClassAllocator!(C)(initialCapacity);
    }
    this() {
      this(64);
    }

    C instantiate(Args...)(Args args) {
        return allocator.place(args);
    }

    void free(C obj) {
        allocator.free(obj);
    }
}

unittest {
    final class Example: Component {
        int x;
        string s;

        this(int x, string s) {
            this.x = x;
            this.s = s;
        }
    }

    auto man = new GrowingManager!Example();

    Example ins = man.instantiate(5, "hi");
    assert(ins.x == 5);
    assert(ins.s == "hi");
}

class StaticManager(C: Component): MemoryManager!C {
    private ClassAllocator!(C, false) allocator;

    this(size_t initialCapacity) {
        this.allocator = new ClassAllocator!(C, false)(initialCapacity);
    }

    C instantiate(Args...)(Args args) {
        return allocator.place(args);
    }

    void free(C obj) {
        allocator.free(obj);
    }
}

unittest {
    import std.exception;
    final class Example: Component {
        int x;
        string s;

        this(int x, string s) {
            this.x = x;
            this.s = s;
        }
    }

    // Only get enough room for 1 Example object
    auto man = new StaticManager!Example(1);

    Example ins = man.instantiate(5, "hi");
    assert(ins.x == 5);
    assert(ins.s == "hi");

    assertThrown!OutOfMemoryError(man.instantiate(6, "another"));
}

class HeapManager(C: Component): MemoryManager!C {
    this(int n) {}
    C instantiate(Args...)(Args args) {
        size_t size = __traits(classInstanceSize, C);
        void* memory = GC.malloc(size);
        void[] chunk = memory[0 .. size];

        return emplace!C(chunk, args);
    }

    void free(C obj) {
        GC.free(cast (void*) obj);
    }
}

unittest {
    class Example: Component {
        int x;
        string s;

        this(int x, string s) {
            this.x = x;
            this.s = s;
        }
    }

    auto man = new HeapManager!Example;

    Example ins = man.instantiate(5, "hi");
    assert(ins.x == 5);
    assert(ins.s == "hi");

}
