import std.stdio;

import entreri.world;
import entreri.componentmanager;
import entreri.component;
import entreri.memorymanager;

final class Position: Component {
    mixin TypeNum;

    int x;
    int y;

    this(){}
    this(int x, int y) {
        this.x = x;
        this.y = y;
    }
}

Position through(Args...)(MemoryManager!Position gm, Args args) {
  return gm.instantiate(args);
}


version(Test){
void main() {
  auto world = new World;
  auto gm = new GrowingManager!Position;
  //auto cm = new ComponentManager!Position(gm);
  //world.addManager(cm);

  //auto e = world.newEntity();
  //e.add!Position(4,5);
  //gm.instantiate(1,2);
  auto pos =  through(gm, 1,2);

  writefln("%d, %d", pos.x, pos.y);
}
}
