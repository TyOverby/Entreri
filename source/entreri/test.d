import std.stdio;

import entreri.world;
import entreri.componentmanager;
//import entreri.typedecl;
import entreri.component;

final class Position: Component {
    mixin TypeNum;

    int x;
    int y;

    this(int x, int y) {
        this.x = x;
        this.y = y;
    }
}

/*void main() {
    auto world = new World();
    world.addManager(new ComponentManager!Position);

    auto entity = world.newEntity();
    entity.add!Position(5, 10);

    auto pos = entity.get!Position;
    writefln("x: %d, y: %d", pos.x, pos.y);
}*/
