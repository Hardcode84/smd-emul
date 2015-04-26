﻿module emul.vdp.vdp;

import std.bitmanip;

import gamelib.memory.saferef;
import gamelib.debugout;

import emul.m68k.cpu;

import emul.vdp.vdpstate;
import emul.vdp.vdpmemory;

final class Vdp
{
public:
/*pure*/ nothrow:

    void register(CpuPtr cpu) pure
    {
        cpu.addReadHook(&readHook,   0xc00000, 0xc0000A);
        cpu.addWriteHook(&writeHook, 0xc00000, 0xc0000A);
        cpu.setInterruptsHook(&interruptsHook);
    }

private:
@nogc:
    ushort readHook(CpuPtr cpu, uint offset, Cpu.MemWordPart wpart)
    {
        debugfOut("vdp read : 0x%.6x 0x%.8x %s",cpu.state.PC,offset,wpart);
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
        debugfOut("vdp write : 0x%.6x 0x%.8x %s 0x%.4x",cpu.state.PC,offset,wpart,data);
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
        if((cpu.state.tickCounter - mCounter) < 100_000)
        {
            //debugOut("hblank");
            //e.setInterrupt(ExceptionCodes.IRQ_4);
            mCounter = cpu.state.tickCounter;
        }
    }
    int mCounter = 0;
    ushort readDataPort(CpuPtr cpu)
    {
        //debugOut("read data");
        return 0;
    }
    void writeDataPort(CpuPtr cpu,ushort data)
    {
        //debugfOut("write data 0x%.4x",data);
    }
    ushort readControlPort(CpuPtr cpu)
    {
        //debugOut("read control");
        flushControl(cpu);
        return mState.Status;
    }
    void writeControlPort(CpuPtr cpu,ushort data)
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
        mState.AddressReg =                       (mPendingControlBuff[0] & ~0xc000) |  (mPendingControlBuff[1] << 14);
        mState.CodeReg    = cast(VdpCodeRegState)((mPendingControlBuff[0] >> 14)     | ((mPendingControlBuff[1] >> 2) & 0b1100));
        debugfOut("flushControl ar=0x%.8x cr=%s",mState.AddressReg,mState.CodeReg);
        mPendingControlWrite = false;
    }

    void executeDma(CpuPtr cpu)
    {
        debugfOut("exec dma: %s %s %s",mState.dmaEnabled,mState.dmaType,mState.CodeReg);
        if(mState.dmaEnabled)
        {
            final switch(mState.dmaType)
            {
                case DmaType.Transfer: dmaTransfer(cpu); break;
                case DmaType.Fill:     dmaFill(); break;
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
            static if(VdpCodeRegState.VRamWrite == Dir)
            {
                const swapBytes = (0x0 != (addr & 0x1));
                if(swapBytes)
                {
                    mMemory.writeVram(addr + 0, cast(ubyte)(val));
                    mMemory.writeVram(addr + 1, cast(ubyte)(val >> 8));
                }
                else
                {
                    mMemory.writeVram(addr + 0, cast(ubyte)(val >> 8));
                    mMemory.writeVram(addr + 1, cast(ubyte)(val));
                }
            }
            else static if(VdpCodeRegState.CRamWrite == Dir)
            {
                mMemory.writeCram(addr, val);
            }
            else static if(VdpCodeRegState.VSRamWrite == Dir)
            {
                mMemory.writeVsram(addr, val);
            }
            else static assert(false);
            mState.AddressReg += mState.autoIncrement;
        };
        cpu.getMemRange(mState.dmaSrcAddress,mState.dmaLen,writeFunc);
    }
    void dmaFill()
    {
        assert(false);
    }
    void dmaCopy()
    {
        assert(false);
    }

    bool mPendingControlWrite = false;
    ushort[2] mPendingControlBuff;

    VdpState mState;
    VdpMemory mMemory;
}

alias VdpRef = SafeRef!Vdp;