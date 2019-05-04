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
            string group = "Track";

            foreach(key, value; count)
            {
                Watch(group).update(key, to!string(value));
            }
            Watch(group).update("Total", to!string(total));
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
                Log << format("GC: freed %d kB",
                    (before.usedSize - after.usedSize) / 1024
                );
            }
            
            void report(string group)
            {
                auto stats = core.memory.GC.stats();
                Watch(group)
                    .update("Size", format("%.1f kB", (stats.usedSize + stats.freeSize) / 1024.0))
                    .update("Used", format("%.1f kB", stats.usedSize / 1024.0))
                    .update("Free", format("%.1f kB", stats.freeSize / 1024.0))
                ;
            }
        }
    }
}


