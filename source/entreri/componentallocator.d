module entreri.componentallocator;

interface ComponentAllocator(C) {
    C* allocate(uint id);
    C* get(uint id);
    void remove(uint id);
}