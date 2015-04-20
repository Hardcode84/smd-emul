module emul.m68k.conditional;

import std.array;
import std.algorithm;
import std.range;

import emul.m68k.cpu;

pure nothrow @nogc @safe:
bool conditionalTest(ubyte Code)(CpuPtr cpu)
{
    bool t(CCRFlags flag)() { return cpu.state.testFlags!flag; }
         static if(0b0000 == Code) return true;
    else static if(0b0001 == Code) return false;
    else static if(0b0010 == Code) return !t!(CCRFlags.C) && !t!(CCRFlags.Z);
    else static if(0b0011 == Code) return t!(CCRFlags.C) || t!(CCRFlags.Z);

    else static if(0b0100 == Code) return !t!(CCRFlags.C);
    else static if(0b0101 == Code) return t!(CCRFlags.C);
    else static if(0b0110 == Code) return !t!(CCRFlags.Z);
    else static if(0b0111 == Code) return t!(CCRFlags.Z);

    else static if(0b1000 == Code) return !t!(CCRFlags.V);
    else static if(0b1001 == Code) return t!(CCRFlags.V);
    else static if(0b1010 == Code) return !t!(CCRFlags.N);
    else static if(0b1011 == Code) return t!(CCRFlags.N);

    else static if(0b1100 == Code) return (t!(CCRFlags.N) && t!(CCRFlags.V)) || (!t!(CCRFlags.N) && !t!(CCRFlags.V));
    else static if(0b1101 == Code) return (t!(CCRFlags.N) && !t!(CCRFlags.V)) || (!t!(CCRFlags.N) && t!(CCRFlags.V));
    else static if(0b1110 == Code) return (t!(CCRFlags.N) && t!(CCRFlags.V) && !t!(CCRFlags.Z)) || (!t!(CCRFlags.N) && !t!(CCRFlags.V) && !t!(CCRFlags.Z));
    else static if(0b1111 == Code) return t!(CCRFlags.Z) || (t!(CCRFlags.N) && !t!(CCRFlags.V)) || (!t!(CCRFlags.N) && t!(CCRFlags.V));
    else static assert(false);
}

enum ubyte[] conditionalTests = iota(16).array;
enum ubyte[] conditionalTestsBcc = conditionalTests.filter!(a => (a != 0 && a != 1)).array;