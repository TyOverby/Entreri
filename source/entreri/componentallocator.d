module entreri.componentallocator;

/++
 + An allocator that is used to only produce
 + instances of the struct C.
 +/
interface ComponentAllocator(C) {
    /++
     + Allocates an instance of C and returns
     + a pointer to it.  This pointer may not
     + be valid after the next `reorg()`.
     +/
    C* allocate(uint id);
    /++
     +
     +/
    C* get(uint id);
    void remove(uint id);
    bool hasComponent(uint id);
    void reorg();
}
