module entreri.entitysystem;

import entreri.world;
import entreri.aspect;

abstract class EntitySystem {
    void process(Entity entity);

    public const Aspect aspect;

    this(Aspect aspect) {
        this.aspect = aspect;
    }
}

unittest {

    import entreri.component;

    final class Component1: Component {
        mixin TypeNum;
    }

    class MyEntitySystem: EntitySystem {
        this() {
            super(Aspect.from!(Component1));
        }

    }
}
