//*****************************************************************************
//
// Reading data from embedded ZIP file
//
//*****************************************************************************

module engine.blob.extract;

import engine.blob.util;

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
        /*
        // For testing: Fall back to filesystem
        return cast(ubyte[])read(filename);
        /*/
        throw new FileException(filename, "File not found");
        /**/
    }
    return file.expandedData;
}

//-----------------------------------------------------------------------------
// Method 1: BLOB is linked as section (see blob.S)
//-----------------------------------------------------------------------------

/*
private extern(C) {
    extern __gshared ubyte __BLOB_zip;
    extern __gshared uint  __BLOB_zip_size;
}

static this()
{
    ubyte[] buffer = (&__BLOB_zip)[0 .. __BLOB_zip_size];
    archive = new ZipArchive(buffer);
}
/**/

//-----------------------------------------------------------------------------
// Method 2: BLOB is concatenated to exe image (cat BLOB.zip >> exe). Don't
// work at the moment, ZipArchive does not like random data at the beginning
// of the "ZIP file"...
//-----------------------------------------------------------------------------

/*
static this()
{
    import std.mmfile;
    import std.stdio;
    
    auto exeimage = new MmFile("/proc/self/exe");
    archive = new ZipArchive(exeimage[]);
}
/**/

