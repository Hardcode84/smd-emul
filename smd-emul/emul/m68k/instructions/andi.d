module emul.m68k.instructions.andi;

import emul.m68k.instructions.create;

package pure nothrow:
void addAndiInstructions(ref Instruction[ushort] ret)
{
    //andi
    foreach(v; TupleRange!(0,writeAddressModesWSize.length))
    {
        enum mode = writeAddressModesWSize[v];
        static if(addressModeTraits!mode.Alterable)
        {
            alias Type = sizeField!(mode >> 6);
            enum dataSize = 0x2 + max(Type.sizeof,0x2);
            ret.addInstruction(Instruction("andi",0x0200 | mode,dataSize,&andiImpl!(Type,mode)));
            //NOTE: 0x0200 bug in programmers reference
        }
    }
}

private:
void andiImpl(Type,ubyte Mode)(CpuPtr cpu)
{
    const val = cpu.memory.getValue!Type(cpu.state.PC - Type.sizeof);
    addressModeWSize!(false,Mode,(cpu,b)
        {
            addressModeWSize!(true,Mode,(cpu)
                {
                    const result = val & b;
                    updateFlags(cpu,result);
                    return cast(Type)result;
                })(cpu);
        })(cpu);
}