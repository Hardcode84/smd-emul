﻿module emul.cpu.cpurunner;

import std.string;
import std.algorithm;
import std.exception;

import gamelib.types;
import gamelib.memory.saferef;

import emul.rom;
import emul.cpu.cpu;

import emul.cpu.instructions.create;

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

    void run()
    {
        convertSafe2(&runImpl, ()=>assert(false),&mCpu);
    }
private:
    Cpu mCpu;
    SafeRef!Rom mRom;
    Op[] mOps;

    struct Op
    {
        ushort size;
        ushort ticks = 1;
        void function(CpuPtr) @nogc pure nothrow impl;
        debug
        {
            string name;
        }
        this(in Instruction instr)
        {
            size = instr.size;
            impl = instr.impl;
            debug
            {
                name = instr.name;;
            }
        }
    }

    static auto createOps()
    {
        Op[] ret;
        ret.length = ushort.max + 1;
        ret[] = Op(InvalidInstruction);
        const instructions = createInstructions();
        debugfOut("Total instructions: %s",instructions.length);
        foreach(i,instr; instructions)
        {
            ret[i] = Op(instr);
        }
        return ret;
    }

    void runImpl(CpuPtr cpu)
    {
        scope(failure) debugOut(cpu.state);
        while(true)
        {
            const opcode = mCpu.memory.getRawValue!ushort(mCpu.state.PC);
            const op = mOps[opcode];
            debug
            {
                debugfOut("0x%.6x op: 0x%.4x %s",mCpu.state.PC,opcode,op.name);
            }
            mCpu.state.PC += op.size;
            mCpu.state.tickCounter += op.ticks;
            op.impl(cpu);
        }
    }
}

