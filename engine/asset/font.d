//*****************************************************************************
//
// Loading fonts, drawing text to various targets. It's mainly used for
// GUI purposes, but it also serves for creating floating text objects to
// rendered scenes.
//
//*****************************************************************************

module engine.asset.font;

//-----------------------------------------------------------------------------

import std.file: FileException;
import std.string: format, toStringz;
import std.conv: to;
import vfs = engine.asset.vfs;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

public import derelict.sdl2.ttf:
    TTF_STYLE_NORMAL,
    TTF_STYLE_BOLD,
    TTF_STYLE_ITALIC,
    TTF_STYLE_UNDERLINE,
    TTF_STYLE_STRIKETHROUGH;

import engine.ext.util;

import engine.gpu.texture;

//-----------------------------------------------------------------------------

class TTFError : Exception
{
    this(string msg) { super(msg); }
}

//*****************************************************************************
//*****************************************************************************

class Font
{
    //-------------------------------------------------------------------------

    static Font[string] fonts;

    private static TTF_Font* loadfont(string filename, int ptsize)
    {
        auto buffer = vfs.extract(filename);
        auto font = TTF_OpenFontRW(
            SDL_RWFromConstMem(buffer.ptr, cast(int)buffer.length),
            true, 
            ptsize
        );

        if(!font) throw new FileException(
            filename,
            format("SDL:TTF_OpenFontRW: %s",to!string(SDL_GetError()))
        );

        return font;
    }

    static Font load(string filename, int size)
    {
        string fontname = filename ~ ":" ~ to!string(size);

        if(!(fontname in fonts))
        {
            fonts[fontname] = new Font(loadfont(filename, size), fontname);
        }
        return fonts[fontname];
    }

    //-------------------------------------------------------------------------

    private
    {
        string ID;
        TTF_Font *font;

        this(TTF_Font *font, string ID)
        {
            debug Track.add(this);
            this.font = font;
            this.ID = ID;
        }

        ~this()
        {
            debug Track.remove(this);
            TTF_CloseFont(font);
        }
    }

    //-------------------------------------------------------------------------

    Font setstyle(int style)
    {
        TTF_SetFontStyle(font, style);
        return this;
    }

    Font setoutline(int width)
    {
        TTF_SetFontOutline(font, width);
        return this;
    }

    //-------------------------------------------------------------------------
    // TODO: Rendering text to bitmaps
    //-------------------------------------------------------------------------

    //-------------------------------------------------------------------------
    // Rendering text to Textures.
    // TODO: render cache could store also rendered strings.
    // TODO: We should have separate cache for different styles.
    // TODO: Maybe this helps us to create alpha bitmaps:
    //
    //      GLint swizzleMask[] = {GL_ZERO, GL_ZERO, GL_ZERO, GL_RED};
    //      glTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_RGBA, swizzleMask);
    //
    //-------------------------------------------------------------------------

    private Texture[char] rendered;

    Texture render(char c) {
        if(!(c in rendered)) {
            rendered[c] = texture(to!string(c));
        }
        return rendered[c];
    }

    Texture texture(string text) {
        SDL_Color color={255, 255, 255, 255};

        auto bitmap = TTF_RenderText_Blended(font, toStringz(text), color);
        if(!bitmap) throw new TTFError(
            format(
                "TTF_RenderText_Blended: %s ('%s')",
                to!string(TTF_GetError()),
                text
            )
        );
        auto texture = Texture.Loader.Default(bitmap);
        SDL_FreeSurface(bitmap);
        return texture;
    }

    //-------------------------------------------------------------------------
    // TODO: Creating (3D) Models from text
    //-------------------------------------------------------------------------
}

