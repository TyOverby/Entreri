module entreri.aspect;

import std.bitmanip;
import entreri.component;
import entreri.entreriexception;

// TODO: Make an Aspect immutable.  Adding to an aspect just makes a new one.

class Aspect {
    static Aspect from(T...)() {
        auto a = new Aspect;
        a.addAll!(T);
        return a;
    }

    private BitArray ba;

    private void add(T)() if (is (T: Component)) {
        if(ba.length < T.typenum + 1) {
            ba.length = T.typenum + 1;
        }

        ba[T.typenum] = 1;
    }

    private void addAll(T...)() {
        foreach(R; T) {
            add!(R);
        }
    }

    override bool opEquals(Object o) const {
        if(auto a = cast(Aspect) o) {
            if (ba.length != a.ba.length) {
                return false;
            } else {
                return ba == a.ba;
            }
        } else {
            return false;
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
    final class Component1:Component {
        mixin TypeNum;
    }
    final class Component2:Component {
        mixin TypeNum;
    }

    auto s1 = new Aspect;
    s1.add!(Component1);
    auto s2 = new Aspect;
    s2.add!(Component1);
    assert(s1 == s2);

    auto s3 = new Aspect;
    s3.add!(Component2);
    assert(s1 != s3);

    auto s4 = new Aspect;
    s4.add!(Component1);
    s4.add!(Component2);
    auto s5 = new Aspect;
    s5.addAll!(Component1, Component2);
    assert(s4 == s5);
    assert(s4 != s1);
    assert(s4 != s3);

    auto s6 = Aspect.from!(Component1, Component2);
    assert(s6 == s4);
    assert(s6 != s1);
    assert(s6 != s3);
}

unittest {
    final class Component1:Component {
        mixin TypeNum;
    }
    final class Component2:Component {
        mixin TypeNum;
    }
    final class Component3:Component {
        mixin TypeNum;
    }

    auto nothing = Aspect.from!();
    auto everything = Aspect.from!(Component1, Component2, Component3);

    assert(nothing.isSubsetOf(everything));
    assert(!everything.isSubsetOf(nothing));

    auto just1 = Aspect.from!(Component1);
    auto one2 = Aspect.from!(Component1, Component2);

    assert(just1.isSubsetOf(one2));
    assert(!one2.isSubsetOf(just1));
    assert(nothing.isSubsetOf(just1));
    assert(nothing.isSubsetOf(one2));

    auto one23 = Aspect.from!(Component1, Component2, Component3);
    assert(just1.isSubsetOf(one23));
    assert(one2.isSubsetOf(one23));
    assert(!one23.isSubsetOf(just1));
}
