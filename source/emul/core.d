﻿module emul.core;

import std.exception;
import std.string;
import std.range;

import gamelib.types;

import gamelib.core;
import gamelib.memory.saferef;
import gamelib.debugout;

import emul.rom;
import emul.m68k.cpu;
import emul.m68k.cpurunner;

import emul.vdp.vdp;

import emul.output;

class Core
{
public:
    this(RomRef rom)
    {
        mRom = rom;
        mCpuRunner = 0;
        mVdp = makeSafe!Vdp();
        initSDL();
        scope(failure) dispose();
        mOutput = makeSafe!Output();
        mOutput.register(mVdp);
        enforce(mRom.header.romEndAddress < mRom.header.ramEndAddress,
            format("Invalid memory ranges %s %s", mRom.header.romEndAddress, mRom.header.ramEndAddress));
        CpuParams params;
        params.memory.length = mRom.header.ramEndAddress + 1;
        params.memory[0..mRom.data.length] = mRom.data[];

        params.romStart = rom.header.romStartAddress;
        params.romEnd   = rom.header.romEndAddress;
        params.ramStart = rom.header.ramStartAddress;
        params.ramEnd   = rom.header.ramEndAddress;

        mCpu = params;

        convertSafe2((CpuPtr cpu) { mVdp.register(cpu); },
            () {assert(false);},
            &mCpu);
    }

    void run()
    {
        bool trace = false;
        CpuRunner.RunParams params;
        uint[20] pos;
        auto buf = pos[].cycle;
        scope(exit)
        {
            debugOut(mCpu.state);
            foreach(i; 0..pos.length)
            {
                debugfOut("0x%.6x",buf.front);
                buf.popFront;
            }
        }
        params.breakHandlers[CpuRunner.BreakReason.SingleStep] = (CpuPtr cpu)
        {
            /*if(cpu.state.TickCounter > 5000_000)
            {
                debugOut(cpu.state);
                return false;
            }*/
            buf.front = cpu.state.PC;
            buf.popFront;
            return true;
        };

        uint ticks = 0;
        params.processHandler = (CpuPtr cpu)
        {
            if(cpu.state.TickCounter > (ticks + 100_000) && !mOutput.insideFrame)
            {
                ticks = cpu.state.TickCounter;
                return false;
            }
            mVdp.update(cpu);
            return true;
        };

        bool quit = false;
    mainloop: while(!quit)
        {
            SDL_Event e = void;
            while(SDL_PollEvent(&e))
            {
                switch(e.type)
                {
                    case SDL_KEYDOWN:
                        if(SDL_SCANCODE_ESCAPE == e.key.keysym.scancode)
                        {
                            break mainloop;
                        }
                        break;
                    case SDL_QUIT:
                        break mainloop;
                    default:
                }
            }
            convertSafe2((CpuPtr cpu)
                {
                    mCpuRunner.run(cpu,params);
                },
                () {assert(false);},
                &mCpu);
        }
    }

    void dispose() nothrow
    {
        mOutput.dispose();
        deinitSDL();
    }

private:
    RomRef mRom;
    CpuRunner mCpuRunner;
    Cpu mCpu;
    VdpRef mVdp;
    OutputRef mOutput;
}

alias CoreRef = SafeRef!Core;

