//*****************************************************************************
//
// Resource tracking
//
//*****************************************************************************

module engine.game.track;

import std.stdio;

class Track
{
    static 
    {
        int[ClassInfo] count;

        void add(Object what) {
            ClassInfo info = what.classinfo;
            if(!(info in count)) count[info] = 0;
            count[info]++;
        }
        
        void remove(Object what) {
            count[what.classinfo]--;
        }

        void rungc()
        {
            import core.memory: GC;
            GC.collect();
            debug report("Garbage collected:");
        }

        void report(string title)
        {
            writeln(title);
            foreach(key, value; count)
            {
                writefln("%8d %s", value, key.name);
            }
        }
    }
}


