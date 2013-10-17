import typedecl;
import component;
import world;

import core.memory;

class ComponentManager(C: Component) {
    void* memory = void;
    C[uint] idToComponent;

    size_t capacity;
    size_t componentCount = 0;

    World _world;
    @property World world() {return _world;}

    this() {
        this(512);
    }

    this(size_t initialSize) {
        this.capacity = initialSize;
        immutable memoryLength = this.capacity * C.sizeof;
        this.memory = GC.malloc(memoryLength);
    }

    C get(uint id) {
        return idToComponent[id];
    }

    void addedToWorld(World world) {
        this._world = world;
    }

    void* nextpos(int id) {
        void* toReturn = addressOf(componentCount++);
        idToComponent[id] = cast(C)(toReturn);
        return toReturn;
    }

    private void grow() {
        this.capacity = (this.capacity * 3) / 2;
        immutable memoryLength = this.capacity * C.sizeof;
        this.memory = GC.realloc(this.memory, memoryLength);
    }

    private void shrink() {
        if(this.componentCount < this.capacity / 3) {
            immutable memoryLength = (this.capacity / 2) * C.sizeof;
            this.memory = GC.realloc(this.memory, memoryLength);
        }
    }

    private void* addressOf(size_t i) {
        return &memory[i * C.sizeof];
    }
    private C indexInto(size_t i) {
        return cast(C) addressOf(i);
    }
}

