module emul.cpu.cpurunner;

import std.string;
import std.algorithm;
import std.exception;

import gamelib.memory.saferef;

import emul.rom;
import emul.cpu.cpu;

class CpuRunner
{
public:
    this(SafeRef!Rom rom)
    {
        mRom = rom;
        enforce(mRom.header.romEndAddress < mRom.header.ramEndAddress, 
            format("Invalid memory ranges %s %s", mRom.header.romEndAddress, mRom.header.ramEndAddress));
        mCpu.memory.data.length = mRom.header.ramEndAddress;
        mCpu.memory.data[0..mRom.header.romEndAddress] = mRom.data[0..mRom.header.romEndAddress];
        mCpu.state.PC = mRom.header.entryPoint;
        mCpu.state.SP = mRom.header.stackPointer;
        mOps = createOps();
    }
private:
    Cpu mCpu;
    SafeRef!Rom mRom;
    Op[] mOps;

    struct Op
    {
        uint size;
        void function(Cpu*) pure nothrow impl;
    }

    static auto createOps()
    {
        import std.bitmanip;
        import emul.cpu.instructions;
        Op[] ret;
        ret.length = Instructions.length;
        foreach(i,instr; Instructions)
        {
            ret[i] = Op(instr.size,instr.impl);
        }
        return ret;
    }
}

