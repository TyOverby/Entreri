import std.conv: emplace;

struct Box(C) {
    void[__traits(classInstanceSize, C)] mem;
    this(Args...)(auto ref Args args) {
        emplace!C(mem, args);
    }

    alias instance this;

    @property
    C instance() {
        return cast(C) mem.ptr;
    }

}

unittest {
    class Foo{
        string s;
        uint x;
        this(uint x, string s) {
            this.x = x;
            this.s = s;
        }
    }

    Box!Foo foobox = Box!Foo(4, "hi");

    assert(foobox.instance.x == 4);
    assert(foobox.instance.s == "hi");

    void takesFoo(Foo f) {
        assert(f.x == 4);
        assert(f.s == "hi");
    }

    takesFoo(foobox);
}
