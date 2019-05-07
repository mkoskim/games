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
public import std.conv: to;

private import std.stdio: writeln, writefln, stdout;

//-----------------------------------------------------------------------------

class Log
{
    static opCall(C, A...)(in C[] fmt, A args)
    {
        log(format(fmt, args));
    }

    static opBinary(string op, T)(T entry) if(op == "<<")
    {
        log(to!string(entry));
    }

    static opBinaryRight(string op, T)(T entry) if(op == ">>")
    {
        log(to!string(entry));
    }

    static private auto log(string entry)
    {
        writeln(entry);
        stdout.flush();
    }

    //-------------------------------------------------------------------------

    static opIndex(string channel) { return Named(channel); }
    
    private struct Named
    {
        string channel;
        
        this(string channel) { this.channel = channel; }
        @disable this();
        
        auto opCall(C, A...)(in C[] fmt, A args)
        {
            log(format(fmt, args));
        }

        auto opBinary(string op, T)(T entry) if(op == "<<")
        {
            log(to!string(entry));
            return this;
        }
        void opBinaryRight(string op, T)(T entry) if(op == ">>")
        {
            log(to!string(entry));
        }

        private void log(string entry)
        {
            writeln(":", channel, ">", entry);
            stdout.flush();
        }
    }
}

//-----------------------------------------------------------------------------

class Watch
{
    static opIndex(string channel) { return Named(channel); }

    private struct Named
    {
        string channel;
        
        this(string channel) { this.channel = channel; }
        @disable this();
        
        ref Named update(string tag, string entry)
        {
            writeln("@", channel, ":", tag, ">", entry);
            stdout.flush();
            return this;
        }
    }

    //-------------------------------------------------------------------------

    static update(string tag, string value)
    {
        return Unnamed().update(tag, value);
    }

    private struct Unnamed
    {
        ref Unnamed update(string tag, string entry)
        {
            writeln("@", tag,">", entry);
            stdout.flush();
            return this;
        }
    }
}

