module entreri.component;


struct GlobalComponentData {
    static uint typenum_pool = 0;
};

mixin template Component() {
    static immutable uint typeNum;
    static this() {
        typeNum = GlobalComponentData.typenum_pool++;
    }
}

unittest {
    import std.stdio;
    struct Foo {
        mixin Component;
    }

    struct Bar {
        mixin Component;
    }

    assert(Foo.typeNum != Bar.typeNum);
}
