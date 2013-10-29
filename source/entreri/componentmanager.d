module entreri.componentmanager;

import entreri.entreriexception;
import entreri.component;
import entreri.world;
import entreri.allocator;

import core.memory;
import std.conv;
import std.stdio;

class ComponentManager(C: Component) {
    private ClassAllocator!C alloc;
    private C[uint] idToComponent;

    private World _world = null;
    @property World world() {return _world;}

    this() {
        alloc= new ClassAllocator!C;
    }

    package C addComponent(C, Args...)(auto ref Args args) {
        C c =  emplace!C(alloc.getNext(), args);
        return c;
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

