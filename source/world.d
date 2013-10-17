module world;

import componentmanager;
import entreriexception;

import std.stdio;
import std.array;
import std.traits;

class World {
    Object[int] mapping;
    bool initialized = false;

    void addComponentManager(A)(ComponentManager!A cm) {
        if(initialized) {
            throw new EntreriException("Added a componentManager to already initialized World");
        }
        if(A.TypeId in mapping) {
            throw new EntreriException("Duplicate ComponentManager: " ~ fullyQualifiedName!(A));
        }

        mapping[A.TypeId] = cm;
        cm.addedToWorld(this);
    }

    ComponentManager!A getComponentManager(A)(){
        return cast(ComponentManager!A)(mapping[A.TypeId]);
    }

    void initialize() {
        initialized = true;
    }

    class Entity {
        immutable uint id;
        World world;
        this(uint id, World world) {
            this.id = id;
            this.world = world;
        }

        A getComponent(A)(){
            return world.getComponentManager!A.get(id);
        }
    }
}
