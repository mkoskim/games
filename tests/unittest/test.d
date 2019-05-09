import std.stdio;

static this()
{
    writeln("Running: static this()");
}

unittest
{
    writeln("Running: unit test.");
}

void main()
{
    writeln("Running: main()");
}

