module entreri.component;

uint _typenum_pool = 0;

mixin template Component() {
    static immutable uint typeNum;
    static this() {
        typeNum = _typenum_pool++;
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
