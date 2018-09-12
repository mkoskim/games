//*****************************************************************************
//
// Resource tracking
//
//*****************************************************************************

module engine.util.track;

import std.stdio;
import engine.util;

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
            if(!count[info]) count.remove(info);
            /* switch(info)
            {
                case "engine.render.scene3d.types.transform.Transform": break;
                default: writefln("%8d - removing %s", total, info);
            }*/
        }

        void rungc()
        {
            engine.util.rungc();
            debug report("Garbage collected:");
        }

        void report(string title = null)
        {
            if(title) writeln(title);
            foreach(key, value; count)
            {
                writefln("%8d %s", value, key);
            }
            writefln("%8d Total", total);
        }
    }
}


