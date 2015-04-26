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
    this(RomRef rom)
    {
        mRom = rom;
        mCpuRunner = makeSafe!CpuRunner();
        mVdp = makeSafe!Vdp();
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
        bool trace = false;
        CpuRunner.RunParams params;
        params.breakHandlers[CpuRunner.BreakReason.SingleStep] = (CpuPtr cpu)
        {
            if(cpu.state.TickCounter > 5000_000)
            {
                debugOut(cpu.state);
                return false;
            }
            /*if(cpu.state.PC == 0x4a8)
            {
                trace = true;
            }
            if(cpu.state.PC == 0x210)
            {
                trace = true;
            }
            if(cpu.state.PC == 0x4ba)
            {
                trace = false;
            }*/
            if(trace)
            {
                //debugfOut("%x",cpu.state.PC);
                debugOut("-------\n",cpu.state);
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
    VdpRef mVdp;
}

alias CoreRef = SafeRef!Core;

