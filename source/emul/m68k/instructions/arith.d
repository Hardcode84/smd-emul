module emul.m68k.instructions.arith;

import emul.m68k.instructions.common;

T add(T)(in T x, in T y, ref Cpu cpu)
{
    const r1 = cast(long)x + cast(long)y;
    updateNZFlags(cpu, cast(T)r1);
    cpu.state.setFlags!(CCRFlags.V)(r1 < Signed!T.min || r1 > Signed!T.max);
    cpu.state.setFlags!(CCRFlags.C | CCRFlags.X)((cast(Unsigned!T)x + cast(Unsigned!T)y) > Unsigned!T.max);
    return cast(T)r1;
}

T sub_no_x(T)(in T x, in T y, ref Cpu cpu)
{
    const r1 = cast(long)x - cast(long)y;
    updateNZFlags(cpu, cast(T)r1);
    cpu.state.setFlags!(CCRFlags.V)(r1 < Signed!T.min || r1 > Signed!T.max);
    cpu.state.setFlags!(CCRFlags.C)(cast(Unsigned!T)x < cast(Unsigned!T)y);
    return cast(T)r1;
}

T sub(T)(in T x, in T y, ref Cpu cpu)
{
    const r1 = cast(long)x - cast(long)y;
    updateNZFlags(cpu, cast(T)r1);
    cpu.state.setFlags!(CCRFlags.V)(r1 < Signed!T.min || r1 > Signed!T.max);
    cpu.state.setFlags!(CCRFlags.C | CCRFlags.X)(cast(Unsigned!T)x < cast(Unsigned!T)y);
    return cast(T)r1;
}

T mul(T)(in T x, in T y, ref Cpu cpu)
{
    const r1 = cast(long)x * cast(long)y;
    updateNZFlags(cpu, cast(Signed!T)r1);
    cpu.state.setFlags!CCRFlags.V(r1 < Signed!T.min || r1 > Signed!T.max);
    cpu.state.clearFlags!(CCRFlags.C);
    return cast(T)r1;
}