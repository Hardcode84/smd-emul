module emul.output;

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
        mWindow = makeSafe!Window("smd-emul", 800,600,0);
        mSurface = createSurface();

        scope(failure) mWindow.dispose();
    }

    void dispose() nothrow
    {
        mSurface.dispose();
        mWindow.dispose();
    }

    void register(VdpRef vdp)
    {
        vdp.setCallbacks(&frameEvent, &renderCallback);
    }

private:
    SafeRef!Window mWindow;
    SafeRef!(FFSurface!Color) mSurface;

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
            const ubyte r = cast(ubyte)(((col >> 1) & 0b111) << 4);
            const ubyte g = cast(ubyte)(((col >> 5) & 0b111) << 4);
            const ubyte b = cast(ubyte)(((col >> 9) & 0b111) << 4);
            mColorCache[i] = Color(r,g,b);
        }
    }

    void frameEvent(const VdpRef vdp, Vdp.FrameEvent event)
    {
        if(Vdp.FrameEvent.Start == event)
        {
            //debugOut("begin");
            mSurface.lock;
        }
        else if(Vdp.FrameEvent.End == event)
        {
            //debugOut("end");
            mSurface.unlock;
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
        auto surfLine = mSurface[line];
        foreach(i, d; data[])
        {
            surfLine[i] = mColorCache[d];
        }
    }
}

alias OutputRef = SafeRef!Output;

