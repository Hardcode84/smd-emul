﻿module emul.output;

import gamelib.debugout;
import gamelib.memory.saferef;
import gamelib.graphics.window;
import gamelib.graphics.surface;
import gamelib.graphics.color;

import emul.vdp.vdp;

final class Output
{
public:
    alias Color = BGRA8888Color;
    this()
    {
        // Constructor code
        mWindow = makeSafe!Window("smd-emul", 1024,768,0);
        mSurface = createSurface();

        scope(failure) mWindow.dispose();
    }

    void dispose() nothrow
    {
        if(mInsideFrame)
        {
            mSurface.unlock;
            mInsideFrame = false;
        }
        mSurface.dispose();
        mWindow.dispose();
    }

    void register(VdpRef vdp)
    {
        vdp.setCallbacks(&frameEvent, &renderCallback);
    }

    @property bool insideFrame() const pure nothrow @nogc { return mInsideFrame; }

private:
    SafeRef!Window mWindow;
    SafeRef!(FFSurface!Color) mSurface;
    bool mInsideFrame = false;

    auto createSurface()
    {
        SafeRef!(FFSurface!Color) function() dummy = (){assert(false);};
        return convertSafe2((SafeRef!(FFSurface!Color) surf)
            {
                return surf;
            },
            dummy,
            mWindow.surface!Color);
    }

    Color[64] mColorCache;
    uint mColorCacheVer = 0;

    void buildColorCache(const VdpRef vdp) nothrow @nogc
    {
        foreach(i, col; vdp.memory.cram[])
        {
            const ubyte r_ = cast(ubyte)(((col >> 1) & 0b111) << 5);
            const ubyte g_ = cast(ubyte)(((col >> 5) & 0b111) << 5);
            const ubyte b_ = cast(ubyte)(((col >> 9) & 0b111) << 5);
            Color color = {r:r_, g:g_, b:b_};
            mColorCache[i] = color;
        }
        //debugOut("update color cache");
        //debugOut(vdp.memory.cram[]);
        //debugOut(mColorCache);
    }

    void frameEvent(const VdpRef vdp, Vdp.FrameEvent event)
    {
        if(Vdp.FrameEvent.Start == event)
        {
            //debugOut("begin");
            mSurface.lock;
            mInsideFrame = true;
        }
        else if(Vdp.FrameEvent.End == event)
        {
            //debugOut("end");
            mSurface.unlock;
            mInsideFrame = false;
            mWindow.updateSurface(mSurface);
        }
    }

    void renderCallback(const VdpRef vdp, int line, const ubyte[] data) nothrow @nogc
    {
        if(mColorCacheVer != vdp.memory.cramChanged)
        {
            buildColorCache(vdp);
            mColorCacheVer = vdp.memory.cramChanged;
        }

        auto surfLine = mSurface[line * 2];
        foreach(i, d; data[])
        {
            const col = mColorCache[d];
            surfLine[i * 2 + 0] = col;
            surfLine[i * 2 + 1] = col;
        }
        const len = data.length * 2;
        mSurface[line * 2 + 1][0..len] = surfLine[0..len];

        if(line < 50)
        {
            foreach(i;0..64)
            {
                mSurface[line][900 + i] = mColorCache[i];
            }
        }
    }
}

alias OutputRef = SafeRef!Output;

