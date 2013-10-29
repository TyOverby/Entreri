module entreri.typenum;

mixin template TypeNum() {
    static if(!__traits(compiles, typenum_pool)) {
        static assert(0, "Only mixin TypeNum into supported types");
    }
    static if(!__traits(isFinalClass, typeof(this))) {
        static assert(0, "Any classes mixing in TypeNum must be final");
    }

    static immutable private uint _typenum;
    static this() {
        _typenum = typenum_pool ++;
    }

    @property
    static public uint typenum() {
        return _typenum;
    }
}
