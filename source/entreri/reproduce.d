import std.stdio;

interface Inter {
  void foo(Args...)(Args args);
}

class Foo: Inter {
  void foo(Args...)(Args args) {
    writeln(args);
  }
}

void through(Args...)(Inter i, Args args) {
  i.foo(args);
}

/*
void main() {
  Inter i = new Foo;
  i.foo(1,2,3);
}
*/
