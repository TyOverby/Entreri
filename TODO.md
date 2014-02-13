* Adding and removing elements to / from an allocator can force a memory reallocation
  which can make pointers invalid.  This is normal and is fine if it happens at a
  well-defined boundry, but if it happens in the middle of a frame, it could be
  disasterous.

  Rewrite the allocators to have a requirement that no memory pointed to by them
  should be invalidated until the end of the frame when frameEnd() is called.

* Rewrite allocators with std.container.Array instead of a raw array.
* Add entity tagging support. (as a built in system?)
* Add own exception class
