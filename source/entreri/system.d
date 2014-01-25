module entreri.system;

import entreri.aspect;
import entreri.world;

import std.algorithm: map;
import std.array: array;

abstract class System {
    private World world;
    private void*[uint] entities;

    final package void setWorld(World world) {
        assert(this.world is null);
        this.world = world;
    }


    protected bool shouldProcess() {
        // Meant to be overridden.
        return true;
    }

    protected void processAll(lazy World.Entity*[] entities) {
        // Meant to be overridden.
    }

    protected bool process(World.Entity* entity) {
        // Meant to be overridden.
        return false;
    }

    protected void onAdd(World.Entity* e) {
        // Meant to be overridden.
    }

    protected void onRemove(World.Entity* e) {
        // Meant to be overridden.
    }

    final package void step() {
        if(!shouldProcess()) {
            return;
        }

        processAll(entities.keys.map!(x => world.entityFrom(x)).array);

        foreach (uint k, v; entities) {
            // Early exit
            if(!process(world.entityFrom(k))) {
                break;
            }
        }
    }

    final package void addEntity(uint id) {
        entities[id] = null;
        assert(id in entities);
        onAdd(world.entityFrom(id));
    }

    final package void removeEntity(uint id) {
        entities.remove(id);
        assert(id !in entities);
        onRemove(world.entityFrom(id));
    }
}

package abstract class IAspectSystem: System {
    final package bool shouldContain(const Aspect aspect) {
        return this.aspect.isSubsetOf(aspect);
    }

    @property
    abstract Aspect aspect();
}
