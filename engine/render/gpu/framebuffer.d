//*****************************************************************************
//*****************************************************************************
//
// Framebuffers: rendering to background buffers for compositions.
//
//*****************************************************************************
//*****************************************************************************

module engine.render.gpu.framebuffer;

import engine.render.util;
import engine.game.instance;

class Framebuffer
{
    GLuint ID;
    GLuint colorbuffer;
    GLuint depthbuffer;

    int width, height;

    bool autoclear;

    //-------------------------------------------------------------------------

    this(GLuint ID, int width, int height)
    {
        debug Track.add(this);

        this.ID = ID;
        this.width = width;
        this.height = height;

        this.autoclear = true;
    }

    this(int width, int height)
    {
        checkgl!glGenFramebuffers(1, &ID);

        this(ID, width, height);

        checkgl!glBindFramebuffer(GL_FRAMEBUFFER, ID);

        TODO("Use our fine Texture class here.");
        TODO("Does this (texture as color buffer) really work?!?");

        checkgl!glGenTextures(1, &colorbuffer);
        checkgl!glBindTexture(GL_TEXTURE_2D, colorbuffer);
        checkgl!glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

        checkgl!glGenRenderbuffers(1, &depthbuffer);
        checkgl!glBindRenderbuffer(GL_RENDERBUFFER, depthbuffer);
        checkgl!glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, width, height);
        checkgl!glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthbuffer);

        if(checkgl!glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            throw new Exception("Framebuffer creation failed!");
        }
    }

    this()
    {
        this(screen.width, screen.height);
    }

    ~this() {
        debug Track.remove(this);

        // Don't try to delete wrapped default framebuffer
        if(!ID) return ;
            
        checkgl!glDeleteFramebuffers(1, &ID);
        checkgl!glDeleteTextures(1, &colorbuffer);
        checkgl!glDeleteRenderbuffers(1, &depthbuffer);
    }

    //-------------------------------------------------------------------------

    private uint lastclear;

    void bind()
    {
        glBindFramebuffer(GL_FRAMEBUFFER, ID);
        glViewport(0, 0, width, height);

        if(autoclear && lastclear != frame) {
            clear();
            lastclear = frame;
        }
    }

    void clear()
    {
        //checkgl!glClearColor(1, 1, 1, 1);
        //checkgl!glClearColor(0.5, 0.5, 0.5, 1);
        checkgl!glClearColor(0, 0, 0, 1);
        checkgl!glClearDepth(1);
        checkgl!glDisable(GL_BLEND);
        checkgl!glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }
}
