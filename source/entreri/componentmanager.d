module entreri.componentmanager;

import entreri.entreriexception;
import entreri.component;
import entreri.world;
public import entreri.mem.memorymanager;

import core.memory;
import std.conv;
import std.stdio;

class ComponentManager(C: Component) {
    abstract World world();

    abstract public C get(uint id);

    abstract public void addToWorld(World world);

    abstract public C addComponent(Args...)(Args args) {

    }

    abstract public void registerComponent(uint id, C component);

    abstract public void removeComponent(uint id);
}
