module entreri.world;

import entreri.componentmanager;
import entreri.entreriexception;
import entreri.entitysystem;
import entreri.aspect;
import entreri.component;
import entreri.mem.memorymanager;

import std.stdio;
import std.array;
import std.traits;

class World {
    private Object[int] managers;
    private bool initialized = false;

    private uint ids = 0;

    private Entity[] entities;
    private EntitySystem[] entitySystems;

    void addManager(A)(ComponentManager!A cm) {
        if(initialized) {
            throw new EntreriException("Added a componentManager to already initialized World");
        }
        if(A.typenum in managers) {
            throw new EntreriException("Duplicate ComponentManager: " ~ fullyQualifiedName!(A));
        }

        managers[A.typenum] = cast(Object) cm;
        cm.addToWorld(this);
    }

    ComponentManager!A getComponentManager(A)(){
        if(A.typenum in managers){
            return cast(ComponentManager!A) managers[A.typenum];
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
         //ComponentManager!A manager = getComponentManager!A;
         GrowingManager!A manager = cast(GrowingManager!A) getComponentManager!A;
         A component = manager.addComponent!Args(args);
         manager.registerComponent(id, component);
         aspect.add!A;
      }
  }
}
