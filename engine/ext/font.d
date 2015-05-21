//*****************************************************************************
//
// Loading fonts, drawing text to various targets.
//
//*****************************************************************************

module engine.ext.font;

//-----------------------------------------------------------------------------

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

import engine.ext.util;
//import std.conv: to;

import engine.render.texture;

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

    static Font load(string filename, int size)
    {
        string fontname = filename ~ ":" ~ to!string(size);

        if(!(fontname in fonts))
        {
            fonts[fontname] = new Font(blob.loadfont(filename, size), fontname);
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
            this.font = font;
            this.ID = ID;
        }

        ~this()
        {
            TODO("Segfaults");
            //TTF_CloseFont(font); font = null;
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
    // Rendering text to Textures. TODO: render cache could store also
    // rendered strings.
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

        auto bitmap = TTF_RenderText_Blended(font, std.string.toStringz(text), color);
        if(!bitmap) throw new TTFError(
            format(
                "TTF_RenderText_Blended: %s ('%s')",
                to!string(TTF_GetError()),
                text
            )
        );
        auto texture = new Texture(bitmap);
        SDL_FreeSurface(bitmap);
        return texture;
    }

    //-------------------------------------------------------------------------
    // TODO: Creating (3D) Models from text
    //-------------------------------------------------------------------------
}

