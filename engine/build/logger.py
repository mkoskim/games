#!/usr/bin/env python3
###############################################################################
#
# Debugging tool. Make it build the project, too, because we want to keep
# debug window persistent on the screen.
#
###############################################################################

import sys

if sys.version_info.major < 3:
    print("Need Python 3")
    sys.exit(-1)

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
# Compile & run
#------------------------------------------------------------------------------

class Worker(Thread):

    def __init__(self, cmd, queue):
        super(Worker, self).__init__(target = self.run)
        self.queue = queue
        self.cmd = cmd
        
    def run(self):

        import pty, os, shlex
        from subprocess import Popen, PIPE, DEVNULL, STDOUT

        self.queue.put(("logger", "Executing: " + self.cmd + "\n"))
        
        master, slave = pty.openpty()

        self.p = Popen(
            shlex.split(self.cmd),
            stdout = slave,
            stderr = STDOUT,
            stdin = DEVNULL,
            bufsize = 1,
            close_fds = True,
            preexec_fn=os.setsid,
        )

        os.close(slave)
        pipe = os.fdopen(master)
        
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

class MainWindow(Frame):

    def __init__(self, master):
        super(MainWindow, self).__init__(master, padx = 5, pady = 5)

        self.btnbar = Frame(self)
        Button(self.btnbar, text = "Build", command = self.build).pack(side=LEFT)
        Button(self.btnbar, text = "Run", command = self.run).pack(side=LEFT)
        Button(self.btnbar, text = "Build & Run", command = self.buildnrun).pack(side=LEFT)
        Button(self.btnbar, text = "Stop", command = self.stop).pack(side=LEFT)
        Button(self.btnbar, text = "Clear", command = self.clear).pack(side=LEFT)
        self.btnbar.pack(side=TOP, anchor="w")

        self.logbox = ScrolledText(self, state = DISABLED, wrap=WORD)
        self.logbox.pack(fill=BOTH, expand=1)
        self.pack(fill=BOTH, expand=1)
        
        self.logbox.tag_config("stdout")
        self.logbox.tag_config("logger", foreground="blue")
        
        self.queue = Queue()
        self.check()
        self.worker = None

    #--------------------------------------------------------------------------
    # Periodic update
    #--------------------------------------------------------------------------
    
    def check(self):
        atend = self.logbox.vbar.get()[1] == 1.0
        self.logbox.config(state = NORMAL)
        while self.queue.qsize():
            tag, msg = self.queue.get(0)
            if msg is None:
                if self.worker is not None: self.worker.join()
                self.logbox.insert(END, "Done.\n", ("logger"))
                self.worker = None
            else:
                self.logbox.insert(END, msg, tag)
        self.logbox.config(state = DISABLED)
        if atend: self.logbox.yview(END)
        self.master.after(100, self.check)

    #--------------------------------------------------------------------------
    # Commands
    #--------------------------------------------------------------------------

    def clear(self):
        self.logbox.config(state = NORMAL)
        self.logbox.delete("1.0", END)
        self.logbox.config(state = DISABLED)

    def build(self):
        self.clear()
        self.worker = Worker("make debug DMDOPTS=-color=off", self.queue)
        self.worker.start()

    def run(self):
        self.clear()
        self.worker = Worker("make run", self.queue)
        self.worker.start()

    def buildnrun(self):
        self.clear()
        self.worker = Worker("make debug run DMDOPTS=-color=off", self.queue)
        self.worker.start()

    def stop(self):
        if self.worker is not None and self.worker.is_alive():
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

root = Tk()
root.title("Logger")
root.geometry(settings["MainWindow"]["geometry"])
main = MainWindow(root)
root.protocol("WM_DELETE_WINDOW", main.on_close)
root.mainloop()
