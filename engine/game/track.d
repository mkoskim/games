//*****************************************************************************
//
// Resource tracking
//
//*****************************************************************************

module engine.game.track;

import std.stdio;
import engine.game.util;

debug abstract class Track
{
    static 
    {
        int[string] count;

        int total() {
            int sum = 0;
            foreach(key, value; count) sum += value;
            return sum;
        }

        void add(Object what) { add(what.classinfo.toString); }
        void add(string info) {
            if(!(info in count)) count[info] = 0;
            count[info]++;
        }

        void remove(Object what) { remove(what.classinfo.toString); }
        void remove(string info) {
            count[info]--;

            /* switch(info)
            {
                case "engine.render.scene3d.types.transform.Transform": break;
                default: writefln("%8d - removing %s", total, info);
            }*/
        }

        void rungc()
        {
            engine.game.util.rungc();
            debug report("Garbage collected:");
        }

        void report(string title = null)
        {
            if(title) writeln(title);
            foreach(key, value; count)
            {
                writefln("%8d %s", value, key);
            }
            writefln("%8d", total);
        }
    }
}


