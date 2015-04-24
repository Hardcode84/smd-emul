module emul.m68k.instructions.subq;

import emul.m68k.instructions.common;

package nothrow:
void addSubqInstructions(ref Instruction[ushort] ret) pure
{
    //subq
    foreach(v; TupleRange!(0,writeAddressModesWSize.length))
    {
        enum mode = writeAddressModesWSize[v];
        static if(addressModeTraits!mode.Alterable && (addressModeTraits!mode.Data || sizeField!(mode >> 6).sizeof > 1))
        {
            static if(!addressModeTraits!mode.Data)
            {
                alias T = int;
            }
            else
            {
                alias T = sizeField!(mode >> 6);
            }
            foreach(d; 0..8)
            {
                const instr = 0x5100 | (d << 9) | mode;
                ret.addInstruction(Instruction("subq",cast(ushort)instr,0x2,&subqImpl!mode));
            }
        }
    }
}

private:
void subqImpl(ubyte Mode)(CpuPtr cpu)
{
    const data = cast(byte)((cpu.getInstructionData!ubyte(cpu.state.PC - 0x2) >> 1) & 0b111);
    static if(addressModeTraits!Mode.Data)
    {
        addressModeWSize!(AddressModeType.ReadWriteDontExtendRegister,Mode,(cpu,val)
            {
               return sub(val, data, cpu);
            })(cpu);
    }
    else
    {
        addressMode!(uint,AddressModeType.ReadWrite,Mode,(cpu,val)
            {
                return val - data;
            })(cpu);
    }
}