module entreri.component;

public import entreri.typenum;

abstract class Component {
    protected static typenum_pool = 0;

    @property static public int typenum();
}
