module emul.core;

import std.exception;
import std.string;

import gamelib.memory.saferef;
import gamelib.debugout;

import emul.rom;
import emul.m68k.cpu;
import emul.m68k.cpurunner;

import emul.vdp.vdp;

class Core
{
public:
pure:
    this(RomRef rom)
    {
        mRom = rom;
        mCpuRunner = makeSafe!CpuRunner();
        enforce(mRom.header.romEndAddress < mRom.header.ramEndAddress,
            format("Invalid memory ranges %s %s", mRom.header.romEndAddress, mRom.header.ramEndAddress));
        mCpu.memory.data.length = mRom.header.ramEndAddress + 1;
        mCpu.memory.data[0..mRom.data.length] = mRom.data[];

        mCpu.memory.romStartAddress = rom.header.romStartAddress;
        mCpu.memory.romEndAddress   = rom.header.romEndAddress;
        mCpu.memory.ramStartAddress = rom.header.ramStartAddress;
        mCpu.memory.ramEndAddress   = rom.header.ramEndAddress;

        convertSafe2((CpuPtr cpu) { mVdp.register(cpu); },
            () {assert(false);},
            &mCpu);
    }

    void run()
    {
        CpuRunner.RunParams params;
        params.breakHandlers[CpuRunner.BreakReason.SingleStep] = (CpuPtr cpu)
        {
            if(cpu.state.tickCounter > 3000_000)
            {
                debugOut(cpu.state);
                return false;
            }
            return true;
        };

        convertSafe2((CpuPtr cpu)
            {
                mCpuRunner.run(cpu,params);
            },
            () {assert(false);},
            &mCpu);
    }

private:
    RomRef mRom;
    CpuRunnerRef mCpuRunner;
    Cpu mCpu;
    Vdp mVdp;
}

alias CoreRef = SafeRef!Core;

