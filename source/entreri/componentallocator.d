module entreri.componentallocator;

interface ComponentAllocator(C) {
    C* allocate(uint id);
    C* get(uint id);
    void remove(uint id);
    bool hasComponent(uint id);
    package void merge();
}
