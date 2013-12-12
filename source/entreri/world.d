module entreri.world;

import entreri.componentmanager;
import entreri.entreriexception;
import entreri.entitysystem;
import entreri.aspect;

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
        if(A.typenum in mapping){
            return cast(ComponentManager!A) mapping[A.typenum];
        } else {
            throw new EntreriException("A ComponentManager for " ~
                    typeid(A).typeinfo.name ~ " does not exist.");
        }
    }


    void addSystem(EntitySystem es) {
        entitySystems ~= es;
    }

    void runIteration() {
        foreach(es; entitySystems) {
            foreach(e; entities) {
                if(es.aspect.isSubsetOf(e.aspect)) {
                    es.process(e);
                }
            }
        }
    }


    void initialize() {
        initialized = true;
    }

  class Entity {
      immutable uint id;
      package Aspect aspect;

      this() {
        this(ids++);
      }

      private this(uint id) {
          this.id = id;
          this.aspect = new Aspect;

          entities ~= this;
      }

      A get(A)(){
          return getComponentManager!A.get(id);
      }

      void add(A, Args...)(Args args) {
         ComponentManager!A manager = getComponentManager!A;
         A component = manager.addComponent!Args(args);
         manager.registerComponent(id, component);
         aspect.add!A;
      }
  }
}
