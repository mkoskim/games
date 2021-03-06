#!/usr/bin/env python3
###############################################################################
#
# Debugging tool. Make it build the project, too, because we want to keep
# debug window persistent on the screen.
#
###############################################################################

#------------------------------------------------------------------------------
# Check Python version
#------------------------------------------------------------------------------

import sys

if sys.version_info.major < 3:
    print("Python version:",  ".".join(map(str, sys.version_info[:3])))
    print("Need Python 3")
    exit(-1)

#------------------------------------------------------------------------------
# Check platform, and create platform check shortcuts
#------------------------------------------------------------------------------

import platform

#print("Platform:", platform.system())

platform.windows = (platform.system() == "Windows")
platform.linux   = (platform.system() == "linux")

###############################################################################
#
# Parse arguments
#
###############################################################################

def parseargs():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("-C",   type=str, metavar="<dir>", dest="cwd", default = None, help = "Specify working directory")
    parser.add_argument("exe", type=str, nargs="?", default = "scons run", help = "Specify binary file")

    return parser.parse_args()

args = parseargs()

#------------------------------------------------------------------------------

if args.cwd != None:
    import os
    os.chdir(args.cwd)

###############################################################################
#
# Settings, and default settings. To be done... Remember to save options
# at exit.
#
###############################################################################

def migrate(settings, defaults):
    return defaults
    
settings = migrate(
    None,
    {
        "SettingsVersion": 1,
        "MainWindow": {
            "geometry": "900x600",
        },
    }
)

###############################################################################
#
# Run build & game with threads, so that you can read stdout & stderr
#
###############################################################################

from threading import Thread
from queue import Queue

#------------------------------------------------------------------------------
# Running subprocesses
#------------------------------------------------------------------------------

def cmd2pipe(cmd):
    from subprocess import Popen, PIPE, DEVNULL, STDOUT
    
    if(platform.windows):
        return Popen(
            cmd,
            shell = True,
            stdout = PIPE,
            stderr = STDOUT,
            stdin = DEVNULL,
            bufsize = 0,
            close_fds = True,
            universal_newlines = True,
        )
    else:
        import pty, os
        master, slave = pty.openpty()

        p = Popen(
            cmd,
            shell = True,
            stdout = slave,
            stderr = STDOUT,
            stdin = DEVNULL,
            bufsize = 1,
            close_fds = True,
            universal_newlines = True,
            preexec_fn=os.setsid,
        )

        os.close(slave)
        p.stdout = os.fdopen(master)
        return p

#------------------------------------------------------------------------------
# Compile & run
#------------------------------------------------------------------------------

class Worker(Thread):

    def __init__(self, cmd, queue):
        super(Worker, self).__init__(target = self.run)
        self.queue = queue
        self.cmd = cmd

    def spawn(self):
        self.queue.put(("logger", "Executing: " + self.cmd + "\n"))
        self.p = cmd2pipe(self.cmd)
        return self.p.stdout
        
    def run(self):
        pipe = self.spawn()
        try:
            for msg in pipe:
                self.queue.put(("stdout", msg))
        except OSError:
            pass  

        pipe.close()
        self.queue.put((None, None))
        self.err = self.p.wait()

    def stop(self):
        import os, signal
        self.queue.put(("logger", "Killing\n"))
        os.killpg(os.getpgid(self.p.pid), signal.SIGTERM)
        #self.pipe.close()

###############################################################################
#
# Simple GUI
#
###############################################################################

from   tkinter import *
import tkinter.ttk as ttk
from tkinter.scrolledtext import ScrolledText

#------------------------------------------------------------------------------
# Text box for log lines
#------------------------------------------------------------------------------

class LogView(ScrolledText):

    def __init__(self, master, **kw):
        super(LogView, self).__init__(master)
        self.configure(kw)

    def add(self, tab, tag, entry, color):
        atend = self.vbar.get()[1] == 1.0
        self.config(state = NORMAL)

        if tab is None:
            self.insert(END, entry + "\n", color)
        else:
            self.insert(END, "%s:%s\n" % (tab, entry), color)

        self.config(state = DISABLED)
        if atend: self.yview(END)

    def clear(self):
        self.config(state = NORMAL)
        self.delete("1.0", END)
        self.config(state = DISABLED)
                
#------------------------------------------------------------------------------
# Listbox for updated values
#------------------------------------------------------------------------------

class WatchView(ttk.Treeview):

    def __init__(self, master, **kw):
        super(WatchView, self).__init__(master)
        self.configure(kw)
        self.configure(columns=("Value"))
        
        self.heading("#0", text="Tag")
        self.heading("#1", text="Value")
        self.column("#0", anchor="w", stretch=YES)
        self.column("#1", anchor="e", stretch=NO, width=100)
        
    def add(self, tab, tag, entry, color):
        gid = tab
        iid = tab + ":" + tag
        
        try:
            self.item(iid, values=('"%s"' % entry))
        except TclError:
            if not self.exists(gid):
                self.insert('', END, iid = gid, text = tab, open = True)

            self.insert(
                gid, END,
                iid=iid,
                text=tag,
                values=(entry)
            )

    def clear(self):
        self.delete(*self.get_children())

class MainWindow(Frame):

    def __init__(self, master):
        super(MainWindow, self).__init__(master, padx = 5, pady = 5)

        self.btnbar = Frame(self)
        Button(self.btnbar, text = "Build", command = self.build).pack(side=LEFT)
        Button(self.btnbar, text = "Run", command = self.run).pack(side=LEFT)
        Button(self.btnbar, text = "Build & Run", command = self.buildnrun).pack(side=LEFT)
        Button(self.btnbar, text = "Clean", command = self.clean).pack(side=LEFT)
        Button(self.btnbar, text = "Stop", command = self.stop).pack(side=LEFT)
        ttk.Separator(self.btnbar, orient=VERTICAL).pack(side=LEFT, fill = Y, padx = 5)
        Button(self.btnbar, text = "Clear", command = self.clear).pack(side=LEFT)
        self.btnbar.pack(side=TOP, anchor="w")

        paned = PanedWindow(self, orient = HORIZONTAL)
        paned.pack(fill = BOTH, expand = 1)
        
        self.logbox = LogView(paned, state = DISABLED, wrap=WORD)
        paned.add(self.logbox)
        
        self.logbox.tag_config("stdout")
        self.logbox.tag_config("logger", foreground="blue")
        
        self.watchbox = WatchView(paned)
        paned.add(self.watchbox)
        
        self.pack(fill=BOTH, expand=1)

        self.queue = Queue()
        self.check()
        self.worker = None

    #--------------------------------------------------------------------------
    # Log line parsing
    #--------------------------------------------------------------------------

    def parse(self, entry, color):
        tab, tag = None, None
        
        if entry[0] == "@":
            tag, entry = entry[1:].split(">", 1)
            if tag.find(":") != -1:
                tab, tag = tag.split(":", 1)
            self.watchbox.add(tab, tag, entry.strip(), color)
        else:
            if entry[0] == ":":
                tab, entry = entry[1:].split(">", 1)
            self.logbox.add(tab, tag, entry.strip(), color)

    #--------------------------------------------------------------------------
    # Periodic update
    #--------------------------------------------------------------------------
    
    def check(self):
        while self.queue.qsize():
            color, msg = self.queue.get(0)
            if msg is None:
                if self.worker is not None: self.worker.join()
                self.logbox.add(None, None, "Done.\n", ("logger"))
                self.worker = None
            else:
                self.parse(msg, color)
        self.master.after(100, self.check)

    #--------------------------------------------------------------------------
    # Commands
    #--------------------------------------------------------------------------

    def clear(self):
        self.logbox.clear()
        self.watchbox.clear()

    def build(self):
        self.clear()
        self.worker = Worker("scons", self.queue)
        self.worker.start()

    def run(self):
        self.clear()
        self.worker = Worker(args.exe, self.queue)
        self.worker.start()

    def buildnrun(self):
        self.clear()
        self.worker = Worker("scons run", self.queue)
        self.worker.start()

    def clean(self):
        self.worker = Worker("scons -c", self.queue)
        self.worker.start()

    def stop(self):
        if platform.windows:
            self.queue.put(("logger", "Windows: Stop not yet implemented.\n"))
        elif self.worker is not None and self.worker.is_alive():
            self.worker.stop()
            self.worker.join()
            self.worker = None

    #--------------------------------------------------------------------------
    # Stop thread & process when exiting
    #--------------------------------------------------------------------------

    def on_close(self):
        self.stop()
        global root
        root.destroy()

###############################################################################
#
#
#
###############################################################################

import os

root = Tk()
root.title("Logger: {}".format(os.getcwd()))
root.geometry(settings["MainWindow"]["geometry"])
main = MainWindow(root)
root.protocol("WM_DELETE_WINDOW", main.on_close)
root.mainloop()

