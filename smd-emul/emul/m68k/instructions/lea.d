﻿module emul.m68k.instructions.lea;

import emul.m68k.instructions.create;

package pure nothrow:
void addLeaInstructions(ref Instruction[ushort] ret)
{
    //lea
    foreach(r; TupleRange!(0,8))
    {
        foreach(v; TupleRange!(0,readAddressModes.length))
        {
            enum mode = readAddressModes[v];
            if(addressModeTraits!mode.Control)
            {
                enum instr = 0x41c0 | (r << 9) | mode;
                ret.addInstruction(Instruction("lea",instr,0x2,&leaImpl!(r,mode)));
            }
        }
    }
}

private:
void leaImpl(ubyte reg, ubyte Mode)(CpuPtr cpu)
{
    addressMode!(int,false,Mode,(a,b)
        {
            import gamelib.debugout;
            debugfOut("0x%x 0x%x",Mode,b);
            a.state.A[reg] = b;
        })(cpu);
}