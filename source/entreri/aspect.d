module entreri.aspect;

import std.bitmanip;
import entreri.component;

struct Aspect {
    static Aspect from(T...)() {
        Aspect a;
        a = a.addAll!(T);
        return a;
    }

    private BitArray ba;

    public Aspect dup() const {
        Aspect copy;
        copy.ba = this.ba.dup;
        return copy;
    }

    private Aspect add(T)() const {
        Aspect copy;
        copy.ba = this.ba.dup;

        if(copy.ba.length < T.typeNum + 1) {
            copy.ba.length = T.typeNum + 1;
        }

        copy.ba[T.typeNum] = 1;
        return copy;
    }

    private Aspect remove(T)() const {
        Aspect copy;
        copy.ba[T.typeNum] = 0;
        return copy;
    }

    private Aspect addAll(T...)() const {
        Aspect a = this.dup();
        foreach(R; T) {
            a = a.add!(R);
        }
        return a;
    }

    bool opEquals(Aspect o) const {
        if (ba.length != o.ba.length) {
            return false;
        } else {
            return ba == o.ba;
        }
    }

    bool isSubsetOf(Aspect other) const {
        import std.stdio;
        if(this.ba.length > other.ba.length) {
            return false;
        } else {
            foreach(i, x; this.ba) {
                if(x && !other.ba[i]) {
                    writeln("falsy at", x, i);
                    return false;
                }
            }
            return true;
        }
    }
}


// Test Equals
unittest {
    struct Component1 {
        mixin Component;
    }
    struct Component2 {
        mixin Component;
    }

    Aspect s1;
    s1 = s1.add!(Component1);
    Aspect s2;
    s2 = s2.add!(Component1);
    assert(s1 == s2);

    Aspect s3;
    s3 = s3.add!(Component2);
    assert(s1 != s3);

    Aspect s4;
    s4 = s4.add!(Component1);
    s4 = s4.add!(Component2);
    Aspect s5;
    s5 = s5.addAll!(Component1, Component2);
    assert(s4 == s5);
    assert(s4 != s1);
    assert(s4 != s3);

    auto s6 = Aspect.from!(Component1, Component2);
    assert(s6 == s4);
    assert(s6 != s1);
    assert(s6 != s3);
}

unittest {
    struct Component1 {
        mixin Component;
    }
    struct Component2 {
        mixin Component;
    }
    struct Component3 {
        mixin Component;
    }

    auto nothing = Aspect.from!();
    auto everything = Aspect.from!(Component1,
                                   Component2,
                                   Component3);

    assert(nothing.isSubsetOf(everything));
    assert(!everything.isSubsetOf(nothing));

    auto just1 = Aspect.from!(Component1);
    auto one2 = Aspect.from!(Component1, Component2);

    assert(just1.isSubsetOf(one2));
    assert(!one2.isSubsetOf(just1));
    assert(nothing.isSubsetOf(just1));
    assert(nothing.isSubsetOf(one2));

    auto one23 = Aspect.from!(Component1,
                              Component2,
                              Component3);
    assert(just1.isSubsetOf(one23));
    assert(one2.isSubsetOf(one23));
    assert(!one23.isSubsetOf(just1));
}
