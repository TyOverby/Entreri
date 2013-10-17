module world;

import componentmanager;
import entreriexception;
import entitysystem;

import std.stdio;
import std.array;
import std.traits;

class World {
    private Object[int] mapping;
    private bool initialized = false;

    private uint ids = 0;

    private Entity[] entities;
    private EntitySystem[] entitySystems;

    void addManager(A)(ComponentManager!A cm) {
        if(initialized) {
            throw new EntreriException("Added a componentManager to already initialized World");
        }
        if(A.TypeId in mapping) {
            throw new EntreriException("Duplicate ComponentManager: " ~ fullyQualifiedName!(A));
        }

        mapping[A.TypeId] = cm;
        cm.addedToWorld(this);
    }

    ComponentManager!A componentManager(A)(){
        return cast(ComponentManager!A)(mapping[A.TypeId]);
    }


    void addSystem(EntitySystem es) {
        entitySystems ~= es;
    }

    void runIteration() {
        foreach(es; entitySystems) {
            foreach(e; entities) {
                es.process(e);
            }
        }
    }


    void initialize() {
        initialized = true;
    }

    Entity newEntity() {
        auto toReturn = new Entity(ids++, this);
        entities ~= toReturn;
        return toReturn;
    }

}

class Entity {
    immutable uint id;
    World world;

    this(uint id, World world) {
        this.id = id;
        this.world = world;
    }

    A get(A)(){
        return world.componentManager!A.get(id);
    }

    void addComponent(A)(A component) {
       auto manager = world.componentManager!A;
       manager.registerComponent(id, component);
    }
}
