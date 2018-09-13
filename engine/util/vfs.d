//*****************************************************************************
//
// Game VFS (Virtual File System). Main feature at the moment: loading
// assets from embedded zip file. It is intended to extend this later
// with "mount" feature, to make filesystem unions.
//
//*****************************************************************************

module engine.util.vfs;

import engine.util;

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


