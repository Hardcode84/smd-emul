module emul.cpu.addressmodes;

import emul.cpu.cpu;

pure nothrow @nogc @safe:
template addressMode(T, bool Write, ubyte Mode, ubyte Reg)
{
    pure nothrow @nogc @safe:
    private void memProxy(F)(CpuPtr cpu, uint address)
    {
        static if(Write)
        {
            cpu.memory.setValue!T(address,F(cpu));
        }
        else
        {
            F(cpu,cpu.memoty.getValue!T(address));
        }
    }
    private enum RegInc = (7 == Reg ? max(2,T.sizeof) : T.sizeof);

    static if(0x000b == Mode)
    {
        void call(F)(CpuPtr cpu)
        {
            static if(Write)
            {
                cpu.state.D[Reg] = F(cpu);
            }
            else
            {
                F(cpu,cpu.state.D[Reg]);
            }
        }
    }
    static if(0x001b == Mode)
    {
        void call(F)(CpuPtr cpu)
        {
            static if(Write)
            {
                cpu.state.A[Reg] = F(cpu);
            }
            else
            {
                F(cpu,cpu.state.A[Reg]);
            }
        }
    }
    static if(0x010b == Mode)
    {
        void call(F)(CpuPtr cpu)
        {
            memProxy!F(cpu,cpu.state.A[Reg]);
        }
    }
    static if(0x011b == Mode)
    {
        void call(F)(CpuPtr cpu)
        {
            memProxy!F(cpu,cpu.state.A[Reg]);
            cpu.state.A[Reg] += RegInc;
        }
    }
    static if(0x100b == Mode)
    {
        void call(F)(CpuPtr cpu)
        {
            cpu.state.A[Reg] -= RegInc;
            memProxy!F(cpu,cpu.state.A[Reg]);
        }
    }
    static if(0x101b == Mode)
    {
        void call(F)(CpuPtr cpu)
        {
            const address = cpu.state.A[Reg] + cpu.memory.getValue!short(cpu.state.PC);
            cpu.state.PC += short.sizeof;
            memProxy!F(cpu,address);
        }
    }
    static if(0x110b == Mode)
    {
        void call(F)(CpuPtr cpu)
        {
            const address = decodeExtensionWord(cpu,cpu.state.A[Reg]);
            memProxy!F(cpu,address);
        }
    }
    static if(0x111b == Mode && 0x010b == Reg && !Write)
    {
        void call(F)(CpuPtr cpu)
        {
            const address = cpu.state.PC + cpu.memory.getValue!short(cpu.state.PC);
            cpu.state.PC += short.sizeof;
            memProxy!F(cpu,address);
        }
    }
    static if(0x111b == Mode && 0x011b == Reg && !Write)
    {
        void call(F)(CpuPtr cpu)
        {
            const address = decodeExtensionWord(cpu,cpu.state.PC);
            memProxy!F(cpu,address);
        }
    }
    static if(0x111b == Mode && 0x000b == Reg)
    {
        void call(F)(CpuPtr cpu)
        {
            const address = cpu.memory.getValue!short(cpu.state.PC);
            cpu.state.PC += short.sizeof;
            memProxy!F(cpu,address);
        }
    }
    static if(0x111b == Mode && 0x001b == Reg)
    {
        void call(F)(CpuPtr cpu)
        {
            const address = cpu.memory.getValue!uint(cpu.state.PC);
            cpu.state.PC += uint.sizeof;
            memProxy!F(cpu,address);
        }
    }
    static if(0x111b == Mode && 0x100b == Reg)
    {
        void call(F)(CpuPtr cpu)
        {
            const pc = cpu.state.PC;
            cpu.state.PC += T.sizeof;
            static if(Write)
            {
                cpu.memory.setValue!T(pc,F(cpu));
            }
            else
            {
                F(cpu,cpu.memory.getValue!T(pc));
            }
        }
    }
}

private uint decodeExtensionWord(CpuPtr cpu, uint addrRegVal)
{
    auto pc = cpu.state.PC;
    const word = cpu.memory.getValue!ushort(pc);
    pc += ushort.sizeof;
    scope(exit) cpu.state.PC = pc;
    const bool da = (0x0 == (word & (1 << 15)));
    const ushort reg = (word >> 12) & 0x111b;
    const bool wl = (0x0 == (word & (1 << 11)));
    const int scale = 1 << ((word >> 9) & 0x11b);
    int indexVal = (da ? cpu.state.D[reg] : cpu.state.A[reg]);
    if(wl) indexVal = cast(short)indexVal;
    if(0x0 == (word & (1 << 8))) // BRIEF EXTENSION WORD FORMAT
    {
        const int disp = cast(byte)(word & 0xff);
        return addrRegVal + disp + scale * indexVal;
    }
    else // FULL EXTENSION WORD FORMAT
    {
        const bool BS = (0x0 == (word & (1 << 7)));
        const bool IS = (0x0 == (word & (1 << 6)));
        const ushort BDSize = (word >> 4) & 0x11b;
        int baseDisp = 0;
        if(0x2 == BDSize)
        {
            baseDisp = cpu.memory.getValue!short(pc);
            pc +=short.sizeof;
        }
        else if(0x3 == BDSize)
        {
            baseDisp = cpu.memory.getValue!int(pc);
            pc += int.sizeof;
        }
        else
        {
            assert(false);
        }

        const IIS = word & 0x111b;

        if(0x0 == IIS) // Address Register Indirect with Index
        {
            return addrRegVal + baseDisp + scale * indexVal + baseDisp;
        }
        else
        {
            int outerDisp = void;
            switch(IIS & 0x11b)
            {
                case 0x2:
                    outerDisp = cpu.memory.getValue!short(pc);
                    pcInc += short.sizeof;
                    break;
                case 0x3:
                    outerDisp = cpu.memory.getValue!int(pc);
                    pcInc += int.sizeof;
                    break;
                default:
                    outerDisp = 0;
            }

            if(IS)
            {
                if(0x0 == (IIS & 0x100b)) // Indirect Preindexed
                {
                    const intermediate = addrRegVal + baseDisp + indexVal * scale;
                    return cpu.memory.getValue!uint(intermediate) + outerDisp;
                }
                else // Indirect Postindexed
                {
                    const intermediate = addrRegVal + baseDisp;
                    return cpu.memory.getValue!uint(intermediate) + indexVal * scale + outerDisp;
                }
            }
            else
            {
                assert(0x0 == (IIS & 0x100b));
                // Memory Indirect
                const intermediate = addrRegVal + baseDisp;
                return cpu.memory.getValue!uint(intermediate) + outerDisp;
            }
        }
    }
}