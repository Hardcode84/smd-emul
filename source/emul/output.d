module emul.output;

import std.exception;

import gamelib.debugout;
import gamelib.types;
import gamelib.memory.saferef;
import gamelib.graphics.window;
import gamelib.graphics.surface;
import gamelib.graphics.color;

import emul.vdp.vdp;
import emul.settings;

final class Output
{
public:
    alias Color = BGRA8888Color;
    this(in Settings settings)
    {
        enforce(settings.scale > 0, "Invalid scale");
        mScale = settings.scale;
        mSize = Size(1024,768);
        mWindow = makeSafe!Window("smd-emul", mSize,0);
        scope(failure) mWindow.dispose();
        mSurface = createSurface();
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

    @property auto ref showPalette() inout pure nothrow @nogc { return mShowPalette; }
    @property bool insideFrame() const pure nothrow @nogc { return mInsideFrame; }

private:
    SafeRef!Window mWindow;
    SafeRef!(FFSurface!Color) mSurface;
    bool mInsideFrame = false;
    Size mSize;
    int mScale = 1;
    bool mShowPalette = false;

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

    void checkWindowSize(in Size srcSize)
    in
    {
        assert(srcSize.w > 0);
        assert(srcSize.h > 0);
    }
    body
    {
        assert(!mInsideFrame);
        assert(mScale > 0);
        const newSize = Size(srcSize.w * mScale, srcSize.h * mScale);
        if(newSize != mSize)
        {
            mSurface.dispose();
            mWindow.size = newSize;
            mSurface = createSurface();
            mSize = newSize;
        }
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
            assert(!mInsideFrame);
            checkWindowSize(Size(vdp.state.Width, vdp.state.Height));
            mSurface.lock;
            mInsideFrame = true;
        }
        else if(Vdp.FrameEvent.End == event)
        {
            assert(mInsideFrame);
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

        auto surfLine = mSurface[line * mScale];
        foreach(int i, d; data[])
        {
            const col = mColorCache[d];
            foreach(j;0..mScale)
            {
                assert((i * mScale + j) < mSize.w);
                surfLine[i * mScale + j] = col;
            }
        }
        const len = cast(uint)data.length * mScale;
        foreach(j;1..mScale)
        {
            mSurface[line * mScale + j][0..len] = surfLine[0..len];
        }

        if(showPalette)
        {
            if(line < 50)
            {
                const start = mSize.w - 64;
                foreach(i;0..64)
                {
                    assert((start + i) < mSize.w);
                    mSurface[line][start + i] = mColorCache[i];
                }
            }
        }
    }
}

alias OutputRef = SafeRef!Output;

