//*****************************************************************************
//
// Reading data from embedded ZIP file
//
//*****************************************************************************

module engine.asset.blob;

import engine.asset.util;

//-----------------------------------------------------------------------------
// Fall back to filesystem if requested file is not in BLOB
//-----------------------------------------------------------------------------

bool fallback = false;

//-----------------------------------------------------------------------------
// Blob archive
//-----------------------------------------------------------------------------

private ZipArchive archive;

static this()
{
    archive = new ZipArchive(cast(ubyte[])import("BLOB.zip"));
}

//-----------------------------------------------------------------------------
// Extracting file from archive
//-----------------------------------------------------------------------------

import std.zip;
import std.file: FileException, read;
import core.exception: RangeError;

void[] extract(string filename)
{
    try
    {
        ArchiveMember file = archive.directory[filename];
        archive.expand(file);
        return file.expandedData;
    }
    catch(RangeError e)
    {
        if(fallback) {
            return read(filename);
        } else {
            throw new FileException(filename, "File not found");
        }
    }
}

//-----------------------------------------------------------------------------

string text(string filename)
{
    return cast(string)extract(filename);
}


