module typedecl;
import std.traits;

// This source file is completely ripped off from artemisd.
mixin template ComponentDecl() {
    static if(!__traits(compiles,TypeNum)) {
        protected static uint TypeNum = 0;
        enum BaseType = typeid(typeof(this));
        uint GetTypeId();
    }

    static uint TypeId;

    static if(!__traits(isAbstractClass,typeof(this))) {
        static if (!__traits(isFinalClass, typeof(this))) {
            static assert(0, fullyQualifiedName!(typeof(this)) ~ " *MUST* be a final class");
        }
        override uint GetTypeId() {
            return TypeId;
        }

        static this() {
            TypeId = TypeNum++;
            debug {
                import std.stdio;
                import std.array;
                writeln(typeid(typeof(this)), ":", BaseType.toString().split(".")[$-1], " Registered with TypeId = ", TypeId);
            }
        }
    }
}

mixin template ComponentImpl() {
    new(size_t sz, ComponentManager!(typeof(this)) cmp, uint id) {
        return cmp.nextpos(id);
    }
}
