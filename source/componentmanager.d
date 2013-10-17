import typedecl;
import component;
import world;
import memorymanager;

import core.memory;

class ComponentManager(C: Component): MemoryManager!C {
    private C[uint] idToComponent;

    private World _world;
    @property World world() {return _world;}

    void* nextpos() {
        checkSize();

        void* toReturn = addressOf(componentCount++);
        return toReturn;
    }

    C get(uint id) {
        return idToComponent[id];
    }

    void addedToWorld(World world) {
        this._world = world;
    }

    void registerComponent(uint id, C component) {
       idToComponent[id] = component;
    }
}

