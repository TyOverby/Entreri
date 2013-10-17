import std.stdio;

import world;
import componentmanager;
import component;
import typedecl;

final class MyComponent: Component {
    mixin ComponentDecl;
    mixin ComponentImpl;

    int x = 0;
    int y = 5;
}

void main()
{
    auto world = new World();
    auto mycm = new ComponentManager!MyComponent;
    world.addComponentManager!MyComponent(mycm);

    auto mc = new(mycm, 0) MyComponent();
    mc.x = 10;
    mc.y = 53;
}
