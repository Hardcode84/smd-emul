﻿module emul.vdp.vdp;

import std.bitmanip;
import std.algorithm;
import std.range;

import gamelib.memory.saferef;
import gamelib.debugout;

import emul.settings;

import emul.m68k.cpu;

import emul.vdp.vdpstate;
import emul.vdp.vdpmemory;
import emul.vdp.vdplayers;
import emul.vdp.vdpspritetable;

final class Vdp
{
    private struct VdpSettings
    {
        DisplayFormat format;
        uint frameSkip;
    }
public:
/*pure nothrow:*/

    this(in Settings settings) pure
    {
        mSettings = VdpSettings(settings.vmode, settings.frameskip);
        mLineBuff.length = 400;
        updateDisplayMode();
        mState.CurrentLine = mState.EndLine;
        mState.setFlags!(VdpFlags.PalMode)(mSettings.format == DisplayFormat.PAL);
    }

    void register(ref Cpu cpu) pure nothrow
    {
        cpu.addReadHook(&readHook,   0xc00000, 0xc0000A);
        cpu.addWriteHook(&writeHook, 0xc00000, 0xc0000A);
        cpu.setInterruptsHook(&interruptsHook);
    }

    void update(ref Cpu cpu)
    {
        if(!mState.displayEnable())
        {
            mState.HBlankScheduled = false;
            mState.VBlankScheduled = false;
            mState.clearFlags!(VdpFlags.HBlank | VdpFlags.VBlank);
            if(mState.CurrentLine != mState.EndLine)
            {
                callEventCallback(FrameEvent.End);
                mState.CurrentLine = mState.EndLine;
            }
            return;
        }

        const ticksPerLine = (mState.TicksPerScan + mState.TicksPerRetrace);
        if(mState.CurrentLine >= mState.EndLine)
        {
            mState.FrameStart = cpu.state.TickCounter;
            mState.CurrentLine = mState.StartLine;
            mState.HInterruptCounter = mState.interruptCounter;
            cpu.scheduleProcessStop(-mState.StartLine * ticksPerLine + 1);
        }
        else
        {
            const int delta = cpu.state.TickCounter - mState.FrameStart;
            const reqLine = delta / ticksPerLine + mState.StartLine;
            assert(reqLine >= mState.CurrentLine);
            if(reqLine > mState.CurrentLine)
            {
                assert((mState.CurrentLine < 0 || mState.CurrentLine >= mState.Height) ||
                       (reqLine - mState.CurrentLine) == 1);
                assert(mState.CurrentLine >= 0 || reqLine <= 0);
                mState.CurrentLine = reqLine;
                if(mState.CurrentLine == 0)
                {
                    mState.clearFlags!(VdpFlags.VInterruptPending)();
                    callEventCallback(FrameEvent.Start);
                    ++mState.CurrentFrame;
                }

                if(mState.CurrentLine >= 0 && mState.CurrentLine < mState.Height)
                {
                    mState.clearFlags!(VdpFlags.HBlank | VdpFlags.VBlank);
                    if(0 == mSettings.frameSkip || 0 == (mState.CurrentFrame % (mSettings.frameSkip + 1)))
                    {
                        renderLine();
                    }
                }
                else
                {
                    if(mState.vInterruptEnabled && !mState.testFlags!(VdpFlags.VBlank))
                    {
                        mState.VBlankScheduled = true;
                    }
                    mState.setFlags!(VdpFlags.HBlank | VdpFlags.VBlank);
                }

                if(mState.CurrentLine == (mState.Height - 1))
                {
                    mState.setFlags!(VdpFlags.VInterruptPending)();
                    callEventCallback(FrameEvent.End);
                }
            }

            assert(mState.CurrentLine <= mState.EndLine);
            if(mState.CurrentLine >= 0 && mState.CurrentLine < mState.Height)
            {
                const hblankPos = ((mState.CurrentLine - mState.StartLine) * ticksPerLine + mState.TicksPerScan);
                if(delta > hblankPos)
                {
                    if(!mState.testFlags!(VdpFlags.HBlank))
                    {
                        mState.setFlags!(VdpFlags.HBlank);
                        if(mState.HInterruptCounter <= 0 || mState.CurrentLine == 0)
                        {
                            mState.HInterruptCounter = mState.interruptCounter;
                        }
                        else
                        {
                            --mState.HInterruptCounter;
                        }

                        if(mState.hInterruptEnabled && 0 == mState.HInterruptCounter)
                        {
                            mState.HBlankScheduled = true;
                        }
                    }

                    cpu.scheduleProcessStop(hblankPos + mState.TicksPerRetrace - delta + 1);
                }
                else
                {
                    cpu.scheduleProcessStop(hblankPos - delta + 1);
                }
            }
            else if(mState.CurrentLine == mState.EndLine)
            {
                if(mNeedUpdateDispMode)
                {
                    updateDisplayMode();
                    mNeedUpdateDispMode = false;
                }
                mState.FrameStart = cpu.state.TickCounter;
                mState.CurrentLine = mState.StartLine;
                mState.HInterruptCounter = mState.interruptCounter;
                const val = -mState.StartLine * ticksPerLine + 1;
                cpu.scheduleProcessStop(val);
            }
            else if(mState.CurrentLine >= mState.Height)
            {
                const val = mState.TicksPerFrame - delta + 1;
                cpu.scheduleProcessStop(val);
            }
            else
            {
                const val = -mState.StartLine * ticksPerLine - delta + 1;
                cpu.scheduleProcessStop(val);
            }
        }
    }

    enum FrameEvent
    {
        Start,
        End
    }
    alias FrameEventCallback = void delegate(const VdpRef,FrameEvent);
    alias RenderCallback     = void delegate(const VdpRef,int,in ubyte[]) nothrow @nogc;

    void setCallbacks(FrameEventCallback eventCallbak, RenderCallback renderCallback) pure nothrow @nogc @safe
    {
        mEventCallback  = eventCallbak;
        mRenderCallback = renderCallback;
    }

    @property @nogc nothrow
    {
        auto ref userSettings() inout { return mState.user; }
        auto ref state()  const { return mState; }
        auto ref memory() const { return mMemory; }
    }

private:
    const VdpSettings mSettings;
    ubyte[] mLineBuff;
    FrameEventCallback mEventCallback;
    RenderCallback mRenderCallback;

    bool mPendingControlWrite = false;
    ushort[2] mPendingControlBuff;
    bool mPendingVramFill = false;
    bool mNeedUpdateDispMode = true;

    VdpState mState;
    VdpMemory mMemory;
    VdpLayers mVdpLayers;
    VdpSpriteTable mSpriteTable;

    ushort readHook(ref Cpu cpu, uint offset, Cpu.MemWordPart wpart) nothrow @nogc
    {
        //debugfOut("vdp read : 0x%.6x 0x%.8x %s",cpu.state.PC,offset,wpart);
        assert(0x0 == (offset & 0x1));
        if(0xc00000 == offset || 0xc00002 == offset)
        {
            return readDataPort(cpu);
        }
        else if(0xc00004 == offset || 0xc00006 == offset)
        {
            return readControlPort(cpu);
        }
        else if(0xc00008 == offset || 0xc0000a == offset || 0xc0000c == offset || 0xc0000e == offset)
        {
            return readHVCounter(cpu);
        }
        assert(false);
    }
    void writeHook(ref Cpu cpu, uint offset, Cpu.MemWordPart wpart, ushort data) nothrow @nogc
    {
        //debugfOut("vdp write : 0x%.6x 0x%.8x %s 0x%.4x",cpu.state.PC,offset,wpart,data);
        assert(0x0 == (offset & 0x1));
        if(wpart == Cpu.MemWordPart.LowerByte)
        {
            data = cast(ushort)(data | (data << 8));
        }
        else if(wpart == Cpu.MemWordPart.UpperByte)
        {
            data = cast(ushort)(data | (data >> 8));
        }

        if(0xc00000 == offset || 0xc00002 == offset)
        {
            return writeDataPort(cpu, data);
        }
        else if(0xc00004 == offset || 0xc00006 == offset)
        {
            return writeControlPort(cpu, data);
        }
       assert(false);
    }
    void interruptsHook(const ref Cpu cpu, ref Exceptions e) nothrow @nogc
    {
        if(mState.HBlankScheduled)
        {
            //debugOut("hinterrupt");
            e.setInterrupt(ExceptionCodes.IRQ_4);
            mState.HBlankScheduled = false;
        }
        if(mState.VBlankScheduled)
        {
            //debugOut("vinterrupt");
            e.setInterrupt(ExceptionCodes.IRQ_6);
            mState.VBlankScheduled = false;
        }
    }

    ushort readDataPort(ref Cpu cpu) nothrow @nogc
    {
        //debugfOut("read data");
        //assert(false);
        flushControl(cpu);
        return 0;
    }
    void writeDataPort(ref Cpu cpu, ushort data) nothrow @nogc
    {
        //debugfOut("write data 0x%.4x",data);
        if(mPendingVramFill)
        {
            flushControl(cpu);
            dmaFill(data);
            return;
        }
        flushControl(cpu);
        //debugfOut("data port: %s 0x%.6x 0x%.4x",mState.CodeReg,mState.AddressReg,data);
        //debugfOut("0x%x",cpu.state.PC);
        switch(mState.CodeReg)
        {
            case VdpCodeRegState.VRamWrite:  mMemory.writeVram(mState.AddressReg,  data); break;
            case VdpCodeRegState.CRamWrite:  mMemory.writeCram(mState.AddressReg,  data); break;
            case VdpCodeRegState.VSRamWrite: mMemory.writeVsram(mState.AddressReg, data); break;
            default: /*assert(false, debugConv(mState.CodeReg))*/debugOut("Invalid write: ",mState.CodeReg); return;
        }
        mState.AddressReg += mState.autoIncrement;
    }
    ushort readControlPort(ref Cpu cpu) nothrow @nogc
    {
        //debugOut("read control");
        flushControl(cpu);
        return mState.Status;
    }
    void writeControlPort(ref Cpu cpu, ushort data) nothrow @nogc
    {
        //debugfOut("write control 0x%.4x",data);
        if(mPendingControlWrite)
        {
            mPendingControlBuff[1] = data;
            flushControl(cpu);
            if(0x0 != (data & (0x80)))
            {
                executeDma(cpu);
            }
        }
        else if(0x8000 == (data & 0xc000))
        {
            const reg = (data >> 8) & 0b11111;
            const val = cast(ubyte)(data & 0xff);
            //debugfOut("vdp reg %s 0x%.2x",reg,val);
            if(reg < mState.R.length)
            {
                mState.R[reg] = val;
                if(0 == reg || 1 == reg || 12 == reg)
                {
                    mNeedUpdateDispMode = true;
                }
            }
            //mState.CodeReg = VdpCodeRegState.VRamRead;
            //mState.AddressReg = 0;
        }
        else
        {
            mPendingControlBuff[0] = data;
            mPendingControlWrite = true;
        }
    }
    ushort readHVCounter(ref Cpu cpu) nothrow @nogc
    {
        //debugOut("read HV counter");
        //assert(false);
        return 0;
    }

    void flushControl(ref Cpu cpu) nothrow @nogc
    {
        if(mPendingControlWrite)
        {
            mState.AddressReg =                       (mPendingControlBuff[0] & ~0xc000) |  (mPendingControlBuff[1] << 14);
            mState.CodeReg    = cast(VdpCodeRegState)((mPendingControlBuff[0] >> 14)     | ((mPendingControlBuff[1] >> 2) & 0b1100));
            //debugfOut("flushControl ar=0x%.8x cr=%s",mState.AddressReg,mState.CodeReg);
            mPendingControlWrite = false;
        }
        mPendingVramFill = false;
    }

    void executeDma(ref Cpu cpu) nothrow @nogc
    {
        //debugfOut("exec dma: enbl=%s %s %s",mState.dmaEnabled,mState.dmaType,mState.CodeReg);
        //debugfOut("src= 0x%.8x start=0x%.4x inc=%s len=%s",
        //    (DmaType.Transfer ==mState.dmaType ? mState.dmaSrcAddress:0),mState.AddressReg,mState.autoIncrement,mState.dmaLen);
        if(mState.dmaEnabled)
        {
            final switch(mState.dmaType)
            {
                case DmaType.Transfer: dmaTransfer(cpu); break;
                case DmaType.Fill:     mPendingVramFill = true; break;
                case DmaType.Copy:     dmaCopy(); break;
            }
        }
    }

    void dmaTransfer(ref Cpu cpu) nothrow @nogc
    {
        switch(mState.CodeReg)
        {
            case VdpCodeRegState.VRamWrite:  dmaTransferImpl!(VdpCodeRegState.VRamWrite)(cpu);  break;
            case VdpCodeRegState.CRamWrite:  dmaTransferImpl!(VdpCodeRegState.CRamWrite)(cpu);  break;
            case VdpCodeRegState.VSRamWrite: dmaTransferImpl!(VdpCodeRegState.VSRamWrite)(cpu); break;
            default: assert(false);
        }
    }
    void dmaTransferImpl(VdpCodeRegState Dir)(ref Cpu cpu) nothrow @nogc
    {
        scope void delegate(size_t, ushort val) nothrow @nogc writeFunc = (size_t, ushort val)
        {
            const addr = mState.AddressReg;
            static if(VdpCodeRegState.VRamWrite == Dir)       mMemory.writeVram(addr, val);
            else static if(VdpCodeRegState.CRamWrite == Dir)  mMemory.writeCram(addr, val);
            else static if(VdpCodeRegState.VSRamWrite == Dir) mMemory.writeVsram(addr, val);
            else static assert(false);
            mState.AddressReg += mState.autoIncrement;
        };
        cpu.getMemRange(mState.dmaSrcAddress,mState.dmaLen,writeFunc);
    }
    void dmaFill(ushort val) nothrow @nogc
    {
        //debugfOut("fill val=0x%.4x",val);
        auto len = mState.dmaLen;
        if(len > 0)
        {
            mMemory.writeVram(mState.AddressReg, cast(ubyte)val);
            do
            {
                mMemory.writeVram(mState.AddressReg ^ 1, cast(ubyte)(val >> 8));
                mState.AddressReg += mState.autoIncrement();
            }
            while(--len > 0);
        }
    }
    void dmaCopy() nothrow @nogc
    {
        assert(false);
    }

    void updateDisplayMode() pure @safe nothrow @nogc
    {
        mState.CellWidth   = (mState.wideDisplayMode ? 40 : 32);
        mState.CellHeight  = (mSettings.format == DisplayFormat.PAL && mState.tallDisplayMode ? 30 : 28);

        mState.TotalWidth  = 360;
        mState.TotalHeight = (mSettings.format == DisplayFormat.NTSC ? 262 : 312);

        mState.Width  = mState.CellWidth * 8;
        mState.Height = mState.CellHeight * 8;

        mState.StartLine = -(mState.TotalHeight - mState.Height) / 2;
        mState.EndLine = mState.StartLine + mState.TotalHeight;

        const fps = (mSettings.format == DisplayFormat.NTSC ? 60 : 50);
        const ticksPerFrame    =  (mSettings.format == DisplayFormat.PAL ? 7_600_000 : 7_670_000) / fps; //TODO
        const ticksPerLine     = ticksPerFrame / mState.TotalHeight;
        mState.TicksPerFrame   = ticksPerFrame;
        mState.TicksPerScan    = (ticksPerLine * mState.Width) / mState.TotalWidth;
        mState.TicksPerRetrace = ticksPerLine - mState.TicksPerScan;
        assert(mState.TicksPerScan > 0);
        assert(mState.TicksPerRetrace > 0);

        mState.setFlags!(VdpFlags.PalMode)(mSettings.format == DisplayFormat.PAL);
    }

    void renderLine()
    {
        assert(mState.displayEnable);
        if(mRenderCallback !is null)
        {
            const currLine = mState.CurrentLine;
            const wdth = mState.Width;
            //order: back > LP B > LP A > LP S > HP B > HP A > HP S
            mLineBuff[0..wdth] = mState.backdropColor;
            if(!mState.displayBlank)
            {
                mVdpLayers.update(mState, mMemory);
                mSpriteTable.update(mState, mMemory);

                mVdpLayers.drawPlanes!(VdpLayers.Priotity.Low)(mLineBuff[0..wdth],mState,mMemory,currLine);
                mSpriteTable.drawSprites!(VdpSpriteTable.Priotity.Low)(mLineBuff[0..wdth],mState,mMemory,currLine);
                mVdpLayers.drawPlanes!(VdpLayers.Priotity.High)(mLineBuff[0..wdth],mState,mMemory,currLine);
                mSpriteTable.drawSprites!(VdpSpriteTable.Priotity.High)(mLineBuff[0..wdth],mState,mMemory,currLine);
            }
            callRenderCallback(currLine, mLineBuff[0..wdth]);
        }
    }

    void callEventCallback(FrameEvent event)
    {
        if(mEventCallback !is null)
        {
            mixin SafeThis;
            mEventCallback(safeThis, event);
        }
    }

   void callRenderCallback(int currentLine, in ubyte[] buff)
    {
        if(mRenderCallback !is null)
        {
            mixin SafeThis;
            mRenderCallback(safeThis, currentLine, buff);
        }
    }
}

alias VdpRef = SafeRef!Vdp;