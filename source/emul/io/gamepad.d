module emul.io.gamepad;

import gamelib.memory.saferef;
import gamelib.debugout;
import gamelib.core;
import gamelib.types;

import emul.m68k.cpu;
import emul.misc.misc;

final class Gamepad
{
public:
    enum Buttons
    {
        Up = 0,
        Down,
        Left,
        Right,
        Start,
        A,
        B,
        C,
        X,
        Y,
        Z,
        Mode
    }
    enum Type
    {
        ThreeButtons,
        SixButtons
    }
    this()
    {
        // Constructor code
        mKeyMap = [
            SDL_SCANCODE_UP : Buttons.Up,
            SDL_SCANCODE_DOWN : Buttons.Down,
            SDL_SCANCODE_LEFT : Buttons.Left,
            SDL_SCANCODE_RIGHT : Buttons.Right,
            SDL_SCANCODE_RETURN : Buttons.Start,
            SDL_SCANCODE_A : Buttons.A,
            SDL_SCANCODE_S : Buttons.B,
            SDL_SCANCODE_D : Buttons.C,
            SDL_SCANCODE_Z : Buttons.X,
            SDL_SCANCODE_X : Buttons.Y,
            SDL_SCANCODE_C : Buttons.Z,
            SDL_SCANCODE_M : Buttons.Mode ];
    }

    ubyte ioHandler(in ref Cpu, Misc.IoPortDirection dir, ubyte data, ubyte ctrl) nothrow @nogc
    {
        //debugfOut("ioHandler %s 0x%x 0x%x", dir, data, ctrl);
        ubyte result = 0;
        if(Misc.IoPortDirection.Write == dir)
        {

        }
        else
        {
            if((data & 0x40) && (ctrl & 0x40))
            {
                result = (mButtonsPressed[Buttons.Up]    ? 0 : Misc.IoPortPins.UP) |
                         (mButtonsPressed[Buttons.Down]  ? 0 : Misc.IoPortPins.DOWN) |
                         (mButtonsPressed[Buttons.Left]  ? 0 : Misc.IoPortPins.LEFT) |
                         (mButtonsPressed[Buttons.Right] ? 0 : Misc.IoPortPins.RIGHT) |
                         (mButtonsPressed[Buttons.B]     ? 0 : Misc.IoPortPins.TL) |
                         (mButtonsPressed[Buttons.C]     ? 0 : Misc.IoPortPins.TR);
            }
            else
            {
                result = (mButtonsPressed[Buttons.Up]    ? 0 : Misc.IoPortPins.UP) |
                         (mButtonsPressed[Buttons.Down]  ? 0 : Misc.IoPortPins.DOWN) |
                         (mButtonsPressed[Buttons.A]     ? 0 : Misc.IoPortPins.TL) |
                         (mButtonsPressed[Buttons.Start] ? 0 : Misc.IoPortPins.TR);
            }
        }
        //debugfOut("result: 0x%x",result);
        return result;
    }

    void processKeyboardEvent(in ref SDL_KeyboardEvent event)
    {
        auto p = event.keysym.scancode in mKeyMap;
        if(p !is null)
        {
            mButtonsPressed[*p] = (event.type == SDL_KEYDOWN);
        }
    }

private:
    bool[Buttons.max + 1] mButtonsPressed = false;
    Buttons[int] mKeyMap;
}

alias GamepadRef = SafeRef!Gamepad;