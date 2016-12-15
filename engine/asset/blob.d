//*****************************************************************************
//
// Reading data from embedded ZIP file
//
//*****************************************************************************

module engine.asset.blob;

import engine.asset.util;

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

ubyte[] extract(string filename)
{
    ArchiveMember file;

    try {
        file = archive.directory[filename];
        archive.expand(file);
    }
    catch(RangeError e) {
        //*
        // For testing: Fall back to filesystem
        return cast(ubyte[])read(filename);
        /*/
        throw new FileException(filename, "File not found");
        /**/
    }
    return file.expandedData;
}

