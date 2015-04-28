module emul.output;

import gamelib.memory.saferef;
import gamelib.graphics.window;
import gamelib.graphics.color;

import emul.vdp.vdp;

final class Output
{
public:
    alias Color = BGRA8888Color;
    this()
    {
        // Constructor code
        mWindow = makeSafe!Window("smd-emul", 100,100,0);
        scope(failure) mWindow.dispose();
    }

    void dispose() nothrow
    {
        mWindow.dispose();
    }

    void register(VdpRef vdp)
    {
        vdp.setCallbacks(&frameEvent, &renderCallback);
    }

nothrow:
@nogc:
private:
    SafeRef!Window mWindow;

    void frameEvent(const VdpRef vdp, Vdp.FrameEvent event)
    {
    }

    void renderCallback(const VdpRef vdp, int line, const ubyte[] data)
    {
    }
}

alias OutputRef = SafeRef!Output;

