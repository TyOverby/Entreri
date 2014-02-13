import std.stdio: writeln;
import std.container: Array;
import core.memory: GC;

struct Foo {
    private string s;
    this(string s) {
        this.s = s;
    }
    this(this) {
        writeln("blit ", s);
    }
    ~this() {
        writeln("destroying: ", s);
    }
}

version(ArrayTest) {
void main() {
    {
        Array!Foo a;
        a ~= Foo("a1");
        a ~= Foo("a2");
        a ~= Foo("a3");

        Foo f = Foo("f");
        Foo g = Foo("g");
        g.destroy();
    }
    GC.collect();
}
}
