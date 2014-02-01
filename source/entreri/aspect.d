module entreri.aspect;

import std.bitmanip;
import entreri.component;

/++
 + A representaton of a set of types.  Every Entity contains an Aspect that
 + represents the components that have been added to it.  Every AspectSystem
 + has an Aspect that represents the minimum component requirements for
 + watching an Entity.
 +/
package struct Aspect {
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
        return this.add(T.typeNum);
    }

    private Aspect add(uint id) const {
        Aspect copy = this.dup();

        if(copy.ba.length < id + 1) {
            copy.ba.length = id + 1;
        }

        copy.ba[id] = 1;
        return copy;
    }

    public Aspect remove(T)() const {
        return this.remove(T.typeNum);
    }

    public Aspect remove(uint id) const {
        Aspect copy = this.dup();
        copy.ba[id] = 0;

        // We should resize the array so that
        // isSubsetOf can skip the
        if (id == copy.ba.length - 1) {
            for (uint i = id; i >= 0; i--) {
                auto v = copy.ba[i];
                if (v == 1) {
                    copy.ba.length = i + 1;
                    break;
                }
            }
        }
        assert(copy.ba[copy.ba.length - 1] == 1);
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

    bool isSubsetOf(const Aspect other) const {
        debug import std.stdio;
        if(this.ba.length > other.ba.length) {
            return false;
        } else {
            foreach(i, x; this.ba) {
                if(x && !other.ba[i]) {
                    debug writeln("falsy at", x, i);
                    return false;
                }
            }
            return true;
        }
    }

    bool contains(const uint id) {
        if (id >= ba.length) {
            return false;
        }
        return ba[id] == 1;
    }

    int opApply(int delegate(uint) dg) const {
        int result = 0;
        foreach (i, v; this.ba) {
            if (v == 1) {
                result = dg(cast(uint) i);
                if (result) {
                    break;
                }
            }
        }
        return result;
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
