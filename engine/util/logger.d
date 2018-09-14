//*****************************************************************************
//
// Logging library
//
//*****************************************************************************

module engine.util.logger;

/******************************************************************************
*******************************************************************************

Design principles:

1) Logging library is meant to be used with engine/build/logger.py utility

2) Log group & category configurations all happen here at game side

3) We try to follow "natural" way of writing log lines

TODO: Some sort of command interface, so that user can turn on/off trace
groups from logger. Read commands from stdin, and act accordingly.

Sketching the interface:

- We want to send log lines to specific tabs
- We might want to tag the line for filtering
- We have two kinds of tabs: "terminals" and "watch windows"
- Terminals just dump lines
- Watch windows use tags to update watch lines

- We might want to send "dummy" lines at startup just to inform logger
  about the presence of the group. Logger adds tabs when it meets a new
  tab.

*******************************************************************************
******************************************************************************/

public import std.string: format;

private import std.stdio: writeln, writefln, stdout;

//-----------------------------------------------------------------------------

class Log
{
    static opCall(string channel) { return new Named(channel); }
    static opBinary(string op)(string entry)
    {
        static if(op == "<<")
        {
            return new Unnamed() << entry;
        }
        else static assert(0, "Operator " ~ op ~ " not implemented.");
    }

    private static class Named
    {
        string channel;
        
        this(string channel) { this.channel = channel; }
        
        auto opBinary(string op)(string entry)
        {
            static if(op == "<<")
            {
                writeln(":", channel, ">", entry);
                stdout.flush();
                return this;
            }
            else static assert(0, "Operator " ~ op ~ " not implemented.");
        }
    }

    private static class Unnamed
    {
        auto opBinary(string op)(string entry)
        {
            static if(op == "<<")
            {
                writeln(entry);
                stdout.flush();
                return this;
            }
            else static assert(0, "Operator " ~ op ~ " not implemented.");
        }
    }
}

//-----------------------------------------------------------------------------

class Watch
{
    static opCall(string channel) { return new Named(channel); }
    static update(string tag, string value)
    {
        return (new Unnamed()).update(tag, value);
    }

    private static class Named
    {
        string channel;
        
        this(string channel) { this.channel = channel; }
        
        auto update(string tag, string entry)
        {
            writeln("@", channel, ":", tag, ">", entry);
            stdout.flush();
            return this;
        }
    }

    private static class Unnamed
    {
        //this() { }
        
        auto update(string tag, string entry)
        {
            writeln("@", tag,">", entry);
            stdout.flush();
            return this;
        }
    }
}

