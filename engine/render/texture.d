//*****************************************************************************
//
// Textures
//
// TODO: Implement mipmapping
// TODO: Experiment texture compression
//
//*****************************************************************************

module engine.render.texture;

//-----------------------------------------------------------------------------
// Try to determine suitable texture format
//-----------------------------------------------------------------------------

import engine.render.util;
import blob = engine.blob;

import derelict.sdl2.sdl;

//-----------------------------------------------------------------------------
// Try to determine suitable texture format
//-----------------------------------------------------------------------------

private GLuint _GLformat(SDL_Surface *surface)
{
	//debug writeln(SDL_PIXELORDER(surface.format.format));

	auto nbOfColors = surface.format.BytesPerPixel;
	
	switch (nbOfColors) {
        case 1:
            return GL_ALPHA;
        case 3:     // no alpha channel
            if (surface.format.Rmask == 0x000000ff)
                return GL_RGB;
            else
                return GL_BGR;
        case 4:     // contains an alpha channel
            if (surface.format.Rmask == 0x000000ff)
                return GL_RGBA;
            else
                return GL_BGRA;
		default:
			return GL_RGB;
	}
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------

class Texture
{
	GLuint ID;

	uint width, height;

	//-------------------------------------------------------------------------
	// Creating texture from byte buffer
	//-------------------------------------------------------------------------
	
	this(uint w, uint h, void* buffer, GLenum format)
	{
		GLenum internal;
		
		switch(format)
		{
			case GL_BGRA: internal = GL_RGBA; break;
			case GL_BGR: internal = GL_RGB; break;
			default: internal = format; break;
		}

		//TODO("Alpha maps not working");

    	checkgl!glGenTextures(1, &ID);
    	checkgl!glBindTexture(GL_TEXTURE_2D, ID);

		width = w;
		height = h;

		//glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		//glPixelStorei(GL_PACK_ALIGNMENT, 1);

    	checkgl!glTexImage2D(GL_TEXTURE_2D,
    		0, 					// Mipmap level
    		internal, 			// Internal format
    		w, h,
    		0, 					// Border
    		format,				// Format of data
    		GL_UNSIGNED_BYTE,	// Data width
    		buffer				// Actual data
    	);
   	
   		checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
   		checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
   		//checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
   		//checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

		//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);

		checkgl!glBindTexture(GL_TEXTURE_2D, 0);
	}

	//-------------------------------------------------------------------------

	~this()
	{
		glDeleteTextures(1, &ID);
	}

	//-------------------------------------------------------------------------
	// SDL surface to texture
	//-------------------------------------------------------------------------

	this(SDL_Surface *surface)
	{
		this(
			surface.w, surface.h,
			surface.pixels,
			_GLformat(surface)
		);		
	}
	
	//-------------------------------------------------------------------------
	// Loading texture from blob file
	//-------------------------------------------------------------------------
	
	this(string filename)
	{
		SDL_Surface* img = blob.loadimage(filename);		
		this(img);
		//debug writeln("Texture.: ", filename, ": ", img.w, " x ", img.h);
		//debug writeln("- Pixels: ", img.pixels[0 .. 5]);

		SDL_FreeSurface(img);
	}
	
	//-------------------------------------------------------------------------
	// Creating single pixel "dummy" textures
	//-------------------------------------------------------------------------
	
	this(vec4 color)
	{
		ubyte[] buffer = [
			cast(ubyte)(color.r*255),
			cast(ubyte)(color.g*255),
			cast(ubyte)(color.b*255),
			cast(ubyte)(color.a*255)
		];
		this(1, 1, buffer.ptr, GL_RGBA);
	}
	
	//-------------------------------------------------------------------------
	// Creating textures from sheet
	//-------------------------------------------------------------------------

	static Texture[][] loadSheet(
		string filename,
		int texw, int texh,
		int padx = 0, int pady = 0
	)
	{
		SDL_Surface* sheet = blob.loadimage(filename);		
		//debug writeln("Texture.: ", filename, ": ", img.w, " x ", img.h);
		//debug writeln("- Pixels: ", img.pixels[0 .. 5]);

		int cols = sheet.w / (texw+padx);
		int rows = sheet.h / (texh+pady);

		Texture[][] grid = new Texture[][](rows, cols);
	
		SDL_Surface *temp = SDL_CreateRGBSurface(0, texw, texh, 32, 0, 0, 0, 0);
		SDL_Surface *sprite = SDL_ConvertSurface(temp, sheet.format, 0);
		SDL_FreeSurface(temp);
	
		SDL_Rect srcrect = {x: 0, y: 0, w: texw, h: texh};
		SDL_Rect dstrect = {x: 0, y: 0, w: texw, h: texh};

		foreach(y; 0 .. rows) foreach(x; 0 .. cols)
		{
			srcrect.y = y*(texh + pady);
			srcrect.x = x*(texw + padx);

			SDL_FillRect(sprite, &dstrect, 0);
			SDL_BlitSurface(
				sheet, &srcrect,
				sprite, &dstrect
			);

			//SDL_SaveBMP(sprite, "test.bmp");
			//throw new Exception();
		
			grid[y][x] = new Texture(sprite);
		}		
		
		SDL_FreeSurface(sheet);
		SDL_FreeSurface(sprite);

		return grid;
	}
}
