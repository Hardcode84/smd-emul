module emul.vdp.vdp;

import std.bitmanip;

import gamelib.memory.saferef;
import gamelib.debugout;

import emul.m68k.cpu;

import emul.vdp.vdpstate;
import emul.vdp.vdpmemory;

enum DisplayFormat
{
    NTSC,
    PAL
}

struct VdpSettings
{
    DisplayFormat format = DisplayFormat.NTSC;
}

final class Vdp
{
public:
/*pure*/ nothrow:

    this(in VdpSettings settings = VdpSettings()) pure
    {
        mSettings = settings;
        mLineBuff.length = 400;
        updateDisplayMode();
    }

    void register(CpuPtr cpu) pure
    {
        cpu.addReadHook(&readHook,   0xc00000, 0xc0000A);
        cpu.addWriteHook(&writeHook, 0xc00000, 0xc0000A);
        cpu.setInterruptsHook(&interruptsHook);
    }

    void update(CpuPtr cpu)
    {
        if(!mState.displayEnable())
        {
            mState.HBlankScheduled = false;
            mState.VBlankScheduled = false;
            mState.clearFlags!(VdpFlags.HBlank | VdpFlags.VBlank);
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
            const delta = cpu.state.TickCounter - mState.FrameStart;
            const reqLine = delta / ticksPerLine;
            assert((reqLine - mState.CurrentLine) <= 1);
            if(reqLine > mState.CurrentLine)
            {
                ++mState.CurrentLine;
                if(mState.CurrentLine >= 0 && mState.CurrentLine < mState.Height)
                {
                    mState.clearFlags!(VdpFlags.HBlank | VdpFlags.VBlank);
                    renderLine();
                }
                else
                {
                    if(mState.vInterruptEnabled && !mState.testFlags!(VdpFlags.VBlank))
                    {
                        mState.VBlankScheduled = true;
                    }
                    mState.setFlags!(VdpFlags.HBlank | VdpFlags.VBlank);
                }

            }

            if(mState.CurrentLine >= 0 && mState.CurrentLine < mState.Height)
            {
                const hblankPos = (mState.CurrentLine * ticksPerLine + mState.TicksPerScan);
                if(delta > hblankPos && !mState.testFlags!(VdpFlags.HBlank))
                {
                    mState.setFlags!(VdpFlags.HBlank);
                    if(mState.HInterruptCounter <= 0)
                    {
                        mState.HInterruptCounter = mState.interruptCounter;
                    }
                    if(mState.hInterruptEnabled && 0 == mState.HInterruptCounter)
                    {
                        mState.HBlankScheduled = true;
                    }
                    --mState.HInterruptCounter;
                    cpu.scheduleProcessStop(hblankPos + mState.TicksPerRetrace - delta + 1);
                }
                else
                {
                    cpu.scheduleProcessStop(hblankPos - delta + 1);
                }
            }
            else if(mState.CurrentLine > mState.Height)
            {
                cpu.scheduleProcessStop(mState.TotalHeight * ticksPerLine - delta + 1);
            }
            else
            {
                cpu.scheduleProcessStop(-mState.StartLine * ticksPerLine - delta + 1);
            }
        }
    }

@nogc:
    alias RenderCallback = void delegate(const VdpRef,in ubyte[]) pure nothrow @nogc @safe;

    void setRenderCallback(RenderCallback callback) pure nothrow @nogc @safe { mRenderCallback = callback; }

    @property auto ref state()  const pure @nogc @safe { return mState; }
    @property auto ref memory() const pure @nogc @safe { return mMemory; }

private:
    const VdpSettings mSettings;
    ubyte[] mLineBuff;
    RenderCallback mRenderCallback;

    bool mPendingControlWrite = false;
    ushort[2] mPendingControlBuff;
    bool mPendingVramFill = false;

    VdpState mState;
    VdpMemory mMemory;

    ushort readHook(CpuPtr cpu, uint offset, Cpu.MemWordPart wpart)
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
    void writeHook(CpuPtr cpu, uint offset, Cpu.MemWordPart wpart, ushort data)
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
    void interruptsHook(const CpuPtr cpu, ref Exceptions e)
    {
        if(mState.HBlankScheduled)
        {
            e.setInterrupt(ExceptionCodes.IRQ_4);
            mState.HBlankScheduled = false;
        }
        if(mState.VBlankScheduled)
        {
            e.setInterrupt(ExceptionCodes.IRQ_6);
            mState.VBlankScheduled = false;
        }
    }

    ushort readDataPort(CpuPtr cpu)
    {
        //debugOut("read data");
        debugfOut("data port: %s 0x%.6x",mState.CodeReg,mState.AddressReg);
        flushControl(cpu);
        return 0;
    }
    void writeDataPort(CpuPtr cpu, ushort data)
    {
        //debugfOut("write data 0x%.4x",data);
        if(mPendingVramFill)
        {
            flushControl(cpu);
            dmaFill(data);
            return;
        }
        flushControl(cpu);
        debugfOut("data port: %s 0x%.6x 0x%.4x",mState.CodeReg,mState.AddressReg,data);
        switch(mState.CodeReg)
        {
            case VdpCodeRegState.VRamWrite:  mMemory.writeVram(mState.AddressReg, data);  break;
            case VdpCodeRegState.CRamWrite:  mMemory.writeCram(mState.AddressReg, data);  break;
            case VdpCodeRegState.VSRamWrite: mMemory.writeVsram(mState.AddressReg, data); break;
            default: return;
        }
        mState.AddressReg += mState.autoIncrement;
    }
    ushort readControlPort(CpuPtr cpu)
    {
        //debugOut("read control");
        flushControl(cpu);
        return mState.Status;
    }
    void writeControlPort(CpuPtr cpu, ushort data)
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
            debugfOut("vdp reg %s 0x%.2x",reg,val);
            if(reg < mState.R.length)
            {
                mState.R[reg] = val;
                if(0 == reg || 1 == reg || 12 == reg)
                {
                    updateDisplayMode();
                }
            }
            mState.CodeReg = VdpCodeRegState.VRamRead;
            mState.AddressReg = 0;
        }
        else
        {
            mPendingControlBuff[0] = data;
            mPendingControlWrite = true;
        }
    }
    ushort readHVCounter(CpuPtr cpu)
    {
        debugOut("read HV counter");
        return 0;
    }

    void flushControl(CpuPtr cpu)
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

    void executeDma(CpuPtr cpu)
    {
        debugfOut("exec dma: enbl=%s %s %s",mState.dmaEnabled,mState.dmaType,mState.CodeReg);
        debugfOut("src= 0x%.8x start=0x%.4x inc=%s len=%s",
            (DmaType.Transfer ==mState.dmaType ? mState.dmaSrcAddress:0),mState.AddressReg,mState.autoIncrement,mState.dmaLen);
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

    void dmaTransfer(CpuPtr cpu)
    {
        switch(mState.CodeReg)
        {
            case VdpCodeRegState.VRamWrite:  dmaTransferImpl!(VdpCodeRegState.VRamWrite)(cpu);  break;
            case VdpCodeRegState.CRamWrite:  dmaTransferImpl!(VdpCodeRegState.CRamWrite)(cpu);  break;
            case VdpCodeRegState.VSRamWrite: dmaTransferImpl!(VdpCodeRegState.VSRamWrite)(cpu); break;
            default: assert(false);
        }
    }
    void dmaTransferImpl(VdpCodeRegState Dir)(CpuPtr cpu)
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
    void dmaFill(ushort val)
    {
        debugfOut("fill val=0x%.4x",val);
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
    void dmaCopy()
    {
        assert(false);
    }

    void updateDisplayMode() pure @safe
    {
        mState.TotalWidth  = (mSettings.format == DisplayFormat.NTSC ? 262 : 322);
        mState.TotalHeight = (mSettings.format == DisplayFormat.NTSC ? 262 : 312);

        mState.CellWidth   = (mSettings.format == DisplayFormat.PAL && mState.wideDisplayMode ? 40 : 32);
        mState.CellHeight  = (mState.tallDisplayMode ? 30 : 28);
        mState.Width  = mState.CellWidth * 8;
        mState.Height = mState.CellHeight * 8;

        mState.StartLine = -(mState.TotalHeight - mState.Height) / 2;
        mState.EndLine = mState.StartLine + mState.TotalHeight;

        const fps = (mSettings.format == DisplayFormat.NTSC ? 60 : 50);
        const ticksPerFrame = 7_600_000 / fps; //TODO
        const ticksPerLine = ticksPerFrame / mState.TotalHeight;
        mState.TicksPerScan = (ticksPerLine * mState.Width) / mState.TotalWidth;
        mState.TicksPerRetrace = ticksPerLine - mState.TicksPerScan;
        if(!mState.displayEnable)
        {
            mState.CurrentLine = mState.EndLine;
        }
    }

    void renderLine()
    {
        assert(mState.displayEnable);
        if(mRenderCallback !is null)
        {
            const wdth = mState.Width;
            mLineBuff[0..wdth] = mState.backdropColor;
            if(!mState.displayBlank)
            {
                //TODO: render
            }
            mixin SafeThis;
            mRenderCallback(safeThis, mLineBuff[0..wdth]);
        }
    }
}

alias VdpRef = SafeRef!Vdp;