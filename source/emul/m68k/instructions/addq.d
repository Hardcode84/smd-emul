module emul.m68k.instructions.addq;

import emul.m68k.instructions.common;

package pure nothrow:
void addAddqInstructions(ref Instruction[ushort] ret)
{
    //addq
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
                const instr = 0x5000 | (d << 9) | mode;
                ret.addInstruction(Instruction("addq",cast(ushort)instr,0x2,&addqImpl!mode));
            }
        }
    }
}

private:
void addqImpl(ubyte Mode)(CpuPtr cpu)
{
    const data = cast(byte)(cpu.getMemValueNoHook!ubyte(cpu.state.PC - 1) & 0b111);
    static if(addressModeTraits!Mode.Data)
    {
        addressModeWSize!(AddressModeType.ReadWriteDontExtendRegister,Mode,(cpu,val)
            {
                return add(val, data, cpu);
            })(cpu);
    }
    else
    {
        addressMode!(uint,AddressModeType.ReadWrite,Mode,(cpu,val)
            {
                return val + data;
            })(cpu);
    }
}