module emul.m68k.instructions.subq;

import emul.m68k.instructions.create;

package pure nothrow:
void addSubqInstructions(ref Instruction[ushort] ret)
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
    enum DestType = (addressModeTraits!Mode.Data ? AddressModeType.WriteDontExtendRegister : AddressModeType.Write);
    const data = cast(byte)(cpu.getMemValueNoHook!ubyte(cpu.state.PC - 1) & 0b111);
    static if(addressModeTraits!Mode.Data)
    {
        addressModeWSize!(AddressModeType.Read,Mode,(cpu,val)
            {
                const result = sub(val, data, cpu);
                addressModeWSize!(AddressModeType.WriteDontExtendRegister,Mode,(cpu)
                    {
                        return result;
                    })(cpu);
            })(cpu);
    }
    else
    {
        addressModeWSize!(AddressModeType.Read,Mode,(cpu,val)
            {
                const result = cast(uint)val - data;
                addressMode!(uint,AddressModeType.Write,Mode,(cpu)
                    {
                        return result;
                    })(cpu);
            })(cpu);
    }
}