module entreri.system;

import entreri.aspect;
import entreri.world;

import std.algorithm: map;
import std.array: array;

/++
 + A System is an abstraction around a process that is applied to
 + many entities.
 +/
abstract class System {
    private World world;
    // entities is mostly just being used as a set...
    private bool[uint] entities;

    final package void setWorld(World world) {
        assert(this.world is null);
        this.world = world;
    }

    /++
     + Decides if this system should process entities for the frame.
     +
     + This method is meant to be overridden by user-defined Systems.
     +
     + If shouldProcess() returns true, then when the world advances,
     + processAll() and process() will be called on the System.
     +
     + TODO: Add example to documentation.
     +/
    protected bool shouldProcess() {
        // Meant to be overridden.
        return true;
    }

    /++
     + Processes the array of entities that this system is watching.
     +
     + This method is meant to be overridden by user-defined Systems.
     +
     + This method can be overridden to let the System access the whole
     + list of entities that the system watches.  This should be a last
     + resort when you really need a whole array instead of processing
     + them individually with `process()`.
     +
     + TODO: Add example to documentation.
     +/
    protected void processAll(lazy World.Entity*[] entities) {
        // Meant to be overridden.
    }

    /++
     + Processes a single Entity.
     +
     + This method is meant to be overridden by user-defined Systems.
     +
     + This method will be called on every Entity that this system
     + is watching on every call of World.advance() when this.shouldProcess()
     + returns true.  This is the main way to update an entity inside
     + of a System.
     +
     + TODO: Add example to documentation.
     +/
    protected bool process(World.Entity* entity) {
        // Meant to be overridden.
        return false;
    }

    /++
     + Called when an entity is added to this system.
     +
     + This method is meant to be overridden by user-defined Systems.
     +
     + This method will be called when this system starts watching an Entity.
     +
     + TODO: Add example to documentation.
     +/
    protected void onAdd(World.Entity* e) {
        // Meant to be overridden.
    }

    /++
     + Called when an entity is removed from this system.
     +
     + This method is meant to be overridden by user-defined Systems.
     +
     + This method will be called when this system stops watching an Entity.
     +
     + TODO: Add example to documentation.
     +/
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

    /++
     + Adds an entity by id-number directly to the system.  This method is
     + to be used with custom-made systems and should not be used directly
     + with AspectSystems.
     +/
    final public void addEntity(uint id) {
        entities[id] = true;
        assert(id in entities);
        onAdd(world.entityFrom(id));
    }

    /++
     + Removes an entity by id-number directly from the system.  This method
     + is to be used with custom-made systems and should not be used directly
     + with AspectSystems.
     +/
    final public void removeEntity(uint id) {
        entities.remove(id);
        assert(id !in entities);
        onRemove(world.entityFrom(id));
    }
}

package abstract class IAspectSystem: System {
    final package bool shouldContain(const Aspect aspect) {
        return this.aspect.isSubsetOf(aspect);
    }

    @property Aspect aspect();
}
