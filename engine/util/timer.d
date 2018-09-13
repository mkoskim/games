//*****************************************************************************
//*****************************************************************************
//
// Timer multiplexing with TimerQueue and queueable Timers.
//
//*****************************************************************************
//*****************************************************************************

module engine.util.timer;

import engine.util;

//*****************************************************************************
//
// TimerQueue
//
//*****************************************************************************

class Timer
{
    static struct Queue
    {
        private Timer root = null;

        void tick(float ticks)
        {
            while(root)
            {
                if(root.delta > ticks)
                {
                    root.delta -= ticks;
                    break;
                }
                else
                {
                    ticks -= root.delta;
                    root.callback();
                    root.stop();
                }
            }
        }
        
        Timer add(float time, void delegate() callback)
        {
            auto timer = new Timer();
            timer.start(&this, time, callback);
            return timer;
        }
    }

    private void delegate() callback;
    private Timer  prev, next;
    private float  delta;
    private Queue* queue;

    //--------------------------------------------------------------------------
    
    void start(Queue *queue, float time, void delegate() callback)
    {
        stop();

        this.callback = callback;
        this.queue = queue;

        if(queue.root is null)
        {
            queue.root = this;
            delta = time;
            prev  = null;
            next  = null;
        }
        else
        {
            //------------------------------------------------------------------
            // Look for place to insert
            //------------------------------------------------------------------

            Timer node = queue.root;

            while(!(node.next is null) && node.delta < time)
            {
                time -= node.delta;
                node  = node.next;
            }

            //------------------------------------------------------------------
            // Insert timer, either before or after the found node, depending
            // on the delta.
            //------------------------------------------------------------------

            if(node.delta < time)
            {
                next = node.next;
                prev = node;
                node.next = this;
                delta = time - node.delta;
            }
            else
            {
                next = node;
                prev = node.prev;
                node.prev  = this;
                if(prev is null) queue.root = this;
                delta = time;
                node.delta -= time;
            }
        }
    }

    //--------------------------------------------------------------------------

    void stop()
    {
        if(!(prev is null))
        {
            prev.next = next;
        }
        else if(!(queue is null))
        {
            queue.root = next;
        }

        if(!(next is null)) next.prev = prev;

        prev = next = null;
        queue = null;
    }
}

