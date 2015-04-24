module emul.m68k.instructions.mul;

import emul.m68k.instructions.common;

package nothrow:
void addAddMulInstructions(ref Instruction[ushort] ret) pure
{
    //mul
    foreach(v; TupleRange!(0,readAddressModes.length))
    {
        enum mode = readAddressModes[v];
        static if(addressModeTraits!mode.Data)
        {
            foreach(r; 0..8)
            {
                const instr1 = 0xc1c0 | (r << 9) | mode;
                ret.addInstruction(Instruction("muls", cast(ushort)instr1,0x2,&mulwImpl!(true,mode)));

                const instr2 = 0xc0c0 | (r << 9) | mode;
                ret.addInstruction(Instruction("mulu", cast(ushort)instr2,0x2,&mulwImpl!(false,mode)));
            }

            const instr = 0x4c00 | mode;
            ret.addInstruction(Instruction("mul", cast(ushort)instr,0x4,&mulImpl!mode));
        }
    }
}

private:
void mulwImpl(bool Signed, ubyte Mode)(CpuPtr cpu)
{
    const reg = ((cpu.getInstructionData!ubyte(cpu.state.PC - 0x2) >> 1) & 0b111);
    static if(Signed)
    {
        addressMode!(short,AddressModeType.Read,Mode,(cpu,val)
            {
                const result = cast(int)val * cast(int)cpu.state.D[reg];
                updateFlags(cpu, result);
                cpu.state.D[reg] = result;
            })(cpu);
    }
    else
    {
        addressMode!(ushort,AddressModeType.Read,Mode,(cpu,val)
            {
                const result = cast(uint)val * cast(uint)cpu.state.D[reg];
                updateFlags(cpu, cast(int)result);
                cpu.state.D[reg] = result;
            })(cpu);
    }
}

void mulImpl(ubyte Mode)(CpuPtr cpu)
{
    const word = cpu.getInstructionData!ushort(cpu.state.PC - 0x2);
    static immutable funcs = [
        &mulImpl2!(false,false,Mode),
        &mulImpl2!(false,true,Mode),
        &mulImpl2!(true,false,Mode),
        &mulImpl2!(true,true,Mode)];
    funcs[(word >> 10) & 0b11](cpu,word);
}

void mulImpl2(bool S, bool Quad, ubyte Mode)(CpuPtr cpu, ushort word)
{
    static if(S)
    {
        alias Type = int;
        alias ResType = long;
    }
    else
    {
        alias Type = uint;
        alias ResType = ulong;
    }
    const regl = ((word >> 12) & 0b111);
    addressMode!(Type,AddressModeType.Read,Mode,(cpu,val)
        {
            const result = cast(ResType)val * cast(ResType)cpu.state.D[regl];
            updateNZFlags(cpu,cast(Signed!ResType)result);
            cpu.state.clearFlags!(CCRFlags.C);
            static if(Quad)
            {
                cpu.state.clearFlags!(CCRFlags.V);
                const regh = (word & 0b111);
                cpu.state.D[regh] = cast(int)((result >> 32) & 0xffffffff);
            }
            else
            {
                static if(S)
                {
                    cpu.state.setFlags!(CCRFlags.V)(result < Type.min || result > Type.max);
                }
                else
                {
                    cpu.state.setFlags!(CCRFlags.V)(result > Type.max);
                }
            }
            cpu.state.D[regl] = cast(int)result;
        })(cpu);
}