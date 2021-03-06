//*****************************************************************************
//
// Resource tracking
//
//*****************************************************************************

module engine.util.track;

import std.stdio;
import engine.util;
import core.memory;

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

        void add(const Object what) { add(what.classinfo.toString); }
        void add(string info) {
            if(!(info in count)) count[info] = 0;
            count[info]++;
        }

        void remove(const Object what) { remove(what.classinfo.toString); }
        void remove(string info) {
            count[info]--;
            if(!count[info]) count.remove(info);
            /* switch(info)
            {
                case "engine.render.scene3d.types.transform.Transform": break;
                default: writefln("%8d - removing %s", total, info);
            }*/
        }

        void report()
        {
            auto watch = Watch["Track"];

            foreach(key, value; count)
            {
                watch.update(key, to!string(value));
            }
            watch.update("Total", to!string(total));
        }
    }

    static struct GC
    {
        static
        {
            void run()
            {
                auto before = core.memory.GC.stats();
                engine.util.rungc();
                auto after = core.memory.GC.stats();
                Log["GC"]("Freed %d kB", (before.usedSize - after.usedSize) / 1024);
            }
            
            void report()
            {
                auto stats = core.memory.GC.stats();
                Watch["GC"]
                    .update("Size", format("%.1f kB", (stats.usedSize + stats.freeSize) / 1024.0))
                    .update("Used", format("%.1f kB", stats.usedSize / 1024.0))
                    .update("Free", format("%.1f kB", stats.freeSize / 1024.0))
                ;
            }
        }
    }
}


