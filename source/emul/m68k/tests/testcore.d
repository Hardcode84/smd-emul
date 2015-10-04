module emul.m68k.tests.testcore;

import gamelib.types;

import gamelib.core;
public import gamelib.memory.saferef;
import gamelib.debugout;

public import emul.m68k.cpu;
import emul.m68k.cpurunner;
import emul.m68k.disasm;

class TestCore
{
public:
    this()
    {
        mCpuRunner = 0;
        CpuParams params;
        params.memory.length = 0xffffff + 1;
        (cast(ubyte[])params.memory)[] = 0xff;

        params.romStart = 0x0;
        params.romEnd   = 0xffff;
        params.ramStart = 0xff0000;
        params.ramEnd   = 0xffffff;

        mCpu = params;
    }

    void reset(uint startAddress, uint stackAddress)
    {
        (cast(ubyte[])mCpu.memory.data)[] = 0xff;
        mCpu.memory.setValueUnchecked(0x0, stackAddress);
        mCpu.memory.setValueUnchecked(0x4, startAddress);
        mCpu.state = CpuState();
        assert(0 == mCpu.state.CCR);
        mCpu.setReset();
    }

    void run(int steps)
    in
    {
        assert(steps > 0);
    }
    body
    {
        CpuRunner.RunParams params;
        int stepsPassed = 0;
        params.breakHandlers[CpuRunner.BreakReason.SingleStep] = (ref Cpu cpu)
        {
            ++stepsPassed;
            return stepsPassed <= steps;
        };
        bool invalidOpcode = false;
        params.breakHandlers[CpuRunner.BreakReason.InvalidOpCode] = (ref Cpu cpu)
        {
            const pc = cpu.state.PC - 0x2;
            debugfOut("Invalid op: 0x%.6x 0x%.4x",pc,cpu.getMemValue!ushort(pc));
            assert(false);
        };
        mCpuRunner.run(mCpu,params);
    }

pure nothrow @nogc:
    auto ref cpu() inout { return mCpu; }

private:
    CpuRunner mCpuRunner;
    Cpu mCpu;
}

alias TestCoreRef = SafeRef!TestCore;

