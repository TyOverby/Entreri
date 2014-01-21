module entreri.system;

import entreri.world;

class System {
    private World world;
    private World.Entity*[] entities;

    package void setWorld(World world) {
        assert(this.world is null);
        this.world = world;
    }

    void processAll(World.Entity*[] entities) {
        // Meant to be overridden.
    }

    bool process(World.Entity* entity) {
        // Meant to be overridden.
        return false;
    }

    void onAdd(World.Entity* e) {
        // Meant to be overridden.
    }

    void onRemove(World.Entity* e) {
        // Meant to be overridden.
    }

    package void step() {
        processAll(entities);

        foreach (e; entities) {
            // Early exit
            if(!process(e)) {
                break;
            }
        }
    }

}

unittest {
    auto w = new World;
}
