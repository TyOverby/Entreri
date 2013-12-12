module entreri.componentmanager;

import entreri.entreriexception;
import entreri.component;
import entreri.world;
public import entreri.memorymanager;

import core.memory;
import std.conv;
import std.stdio;

class ComponentManager(C: Component) {
    private GrowingManager!C memoryManager;
    private C[uint] idToComponent;

    private World _world = null;
    @property World world() {return _world;}

    this() {
        this.memoryManager = new GrowingManager!C(64);
    }

    package C addComponent(Args...)(Args args) {
        return memoryManager.instantiate(args);
    }

    package C get(uint id) {
        return idToComponent.get(id, null);
    }

    package void addedToWorld(World world) {
        if (_world) {
            throw new EntreriException("ComponentManager has already been added to a world.");
        }

        this._world = world;
    }

    package void registerComponent(uint id, C component) {
        if(id in idToComponent) {
            throw new EntreriException("Entity already has component of this type.");
        }

        idToComponent[id] = component;
    }
}

