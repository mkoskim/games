//*****************************************************************************
//
// CPU side bitmap manipulation
//
//*****************************************************************************

module engine.ext.bitmap;

//-----------------------------------------------------------------------------

import derelict.sdl2.sdl;
import engine.ext.util;
import blob = engine.blob;

//-----------------------------------------------------------------------------

class Bitmap
{
	SDL_Surface* surface;
	SDL_Renderer* renderer;
	
	//-------------------------------------------------------------------------
	
	this(SDL_Surface* s)
	{
		surface = s;
		renderer = SDL_CreateSoftwareRenderer(surface);
		if(!renderer) throw new Exception(
		    format("CreateSoftwareRenderer failed: %s", SDL_GetError())
		);
	}
	
	this(int width, int height)
	{
		SDL_Surface* s = SDL_CreateRGBSurface(
			0,
			width,height,
			32,
			0x000000ff,
			0x0000ff00,
			0x00ff0000,
			0xff000000
		);
		if(!s) throw new Exception(
		    format("CreateRGBSurface failed: %s", SDL_GetError())
		);
		this(s);
	}

	this(string filename)
	{
		this(blob.loadimage(filename));
	}

	~this()
	{
		SDL_DestroyRenderer(renderer);
		SDL_FreeSurface(surface);
	}

	//-------------------------------------------------------------------------
	
	int width()  { return surface.w; }
	int height() { return surface.h; }

	void putpixel(int x, int y, vec4 color)
	{
		SDL_SetRenderDrawColor(renderer, 
			cast(ubyte)(color.r*255),
			cast(ubyte)(color.g*255),
			cast(ubyte)(color.b*255),
			cast(ubyte)(color.a*255)
		);
		SDL_RenderDrawPoint(renderer, x, y);
	}	
}

