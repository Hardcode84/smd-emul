﻿module emul.core;

import std.stdio;
import std.exception;
import std.string;
import std.range;

import gamelib.types;

import gamelib.core;
import gamelib.memory.saferef;
import gamelib.debugout;

import emul.settings;
import emul.rom;
import emul.m68k.cpu;
import emul.m68k.cpurunner;
import emul.m68k.disasm;

import emul.misc.misc;
import emul.z80.z80;
import emul.vdp.vdp;

import emul.output;

class Core
{
public:
    this(RomRef rom)
    {
        Settings settings;
        //settings.model = Model.Domestic;
        debug
        {
            settings.framesyncMethod = FramesyncMethod.None;
        }
        settings.scale = 2;
        settings.vmode = DisplayFormat.NTSC;
        mRom = rom;
        mCpuRunner = 0;
        mMisc = makeSafe!Misc(settings);
        mZ80 = makeSafe!Z80();
        mVdp = makeSafe!Vdp(settings);
        initSDL();
        scope(failure) deinitSDL();
        mOutput = makeSafe!Output(settings);
        scope(failure) mOutput.dispose();
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
        mCpu.setReset();

        mMisc.register(mCpu);
        mZ80.register(mCpu);
        mVdp.register(mCpu);
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
            Disasm disasm = 0;
            foreach(i; 0..pos.length)
            {
                debugfOut("0x%.6x\t%s",buf.front,disasm.getDesc(mCpu, buf.front));
                buf.popFront;
            }
        }
        params.breakHandlers[CpuRunner.BreakReason.SingleStep] = (ref Cpu cpu)
        {
            buf.front = cpu.state.PC;
            buf.popFront;
            return true;
        };
        bool invalidOpcode = false;
        params.breakHandlers[CpuRunner.BreakReason.InvalidOpCode] = (ref Cpu cpu)
        {
            const pc = cpu.state.PC - 0x2;
            debugfOut("Invalid op: 0x%.6x 0x%.4x",pc,cpu.getMemValue!ushort(pc));
            invalidOpcode = true;
            return false;
        };

        uint ticks = 0;
        params.processHandler = (ref Cpu cpu)
        {
            if(cpu.state.TickCounter > (ticks + 10_000) && !mOutput.insideFrame)
            {
                ticks = cpu.state.TickCounter;
                return false;
            }
            mVdp.update(cpu);
            return true;
        };

    mainloop: while(true)
        {
            SDL_Event e = void;
            while(SDL_PollEvent(&e))
            {
                switch(e.type)
                {
                    case SDL_KEYDOWN:
                        switch(e.key.keysym.scancode)
                        {
                            case SDL_SCANCODE_ESCAPE:
                                break mainloop;
                            case SDL_SCANCODE_LEFTBRACKET:
                                mOutput.showPalette = !mOutput.showPalette;
                                break;
                            case SDL_SCANCODE_RIGHTBRACKET:
                                mVdp.userSettings.isAplaneVisible = !mVdp.userSettings.isAplaneVisible;
                                break;
                            case SDL_SCANCODE_APOSTROPHE:
                                mVdp.userSettings.isBplaneVisible = !mVdp.userSettings.isBplaneVisible;
                                break;
                            case SDL_SCANCODE_SLASH:
                                mVdp.userSettings.isWindowVisible = !mVdp.userSettings.isWindowVisible;
                                break;
                            default: break;
                        }
                        break;

                    case SDL_QUIT:
                        break mainloop;
                    default:
                }
            }
            mCpuRunner.run(mCpu,params);
            if(invalidOpcode)
            {
                break;
            }
        }
    }

    void dispose()
    {
        mOutput.dispose();
        deinitSDL();
    }

private:
    RomRef mRom;
    CpuRunner mCpuRunner;
    Cpu mCpu;
    MiscRef mMisc;
    Z80Ref mZ80;
    VdpRef mVdp;
    OutputRef mOutput;
}

alias CoreRef = SafeRef!Core;

