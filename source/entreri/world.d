module entreri.world;

import entreri.componentmanager;
import entreri.entreriexception;
import entreri.entitysystem;

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
        if(A.typenum in mapping) {
            throw new EntreriException("Duplicate ComponentManager: " ~ fullyQualifiedName!(A));
        }

        mapping[A.typenum] = cm;
        cm.addedToWorld(this);
    }

    ComponentManager!A getComponentManager(A)(){
        return cast(ComponentManager!A)(mapping.get(A.typenum , null));
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
        return world.getComponentManager!A.get(id);
    }

    void add(A, Args...)(Args args) {
       auto manager = world.getComponentManager!A;
       auto component = manager.addComponent!A(args);
       manager.registerComponent(id, component);
    }
}

