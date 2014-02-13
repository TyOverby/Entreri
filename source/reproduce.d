import entreri.world;

version (Reproduce) {
void main() {
    World world = new World;
    World.Entity ex;
    auto exp = &ex;

    World.Entity* ex2 = world.newEntity();

    *exp = *ex2;
}
}
