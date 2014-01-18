module entreri.mem.memorymanager;

import entreri.mem.memorycontroller;
import entreri.componentmanager;
import entreri.component;
import entreri.world;
import entreri.entreriexception;

private class MemoryComponentManager(C, CM: MemoryController!C): ComponentManager!C {
    protected CM controller;
    private C[uint] idToComponent;

    private World world_ = null;
    override @property World world() {return world_;}

    override public C addComponent(Args...)(Args args){
        return controller.instantiate(args);
    }

    override public C get(uint id) {
        return idToComponent.get(id, null);
    }

    override public void addToWorld(World world) {
        if(world_) {
            throw new EntreriException("Multiple world assignment");
        }

        this.world_ = world;
    }

    override public void registerComponent(uint id, C component) {
        if(id in idToComponent) {
            throw new EntreriException("Entity already has component of this type");
        }

        idToComponent[id] = component;
    }

    override public void removeComponent(uint id) {
        controller.free(idToComponent[id]);
        idToComponent.remove(id);
    }
}

class GrowingManager(C: Component): MemoryComponentManager!(C, GrowingController!C) {
    this(uint startingSize = 64) {
        this.controller = new GrowingController!C(startingSize);
    }
}

class StaticManager(C: Component): MemoryComponentManager!(C, StaticController!C) {
    this(uint startingSize) {
        this.controller = new StaticCOntroller!C(startingSize);
    }
}

class HeapController(C: Component): MemoryComponentManager!(C, HeapController!C) {
    this() {
        this.controller = new HeapController();
    }
}
