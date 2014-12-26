//*****************************************************************************
//
// Reading data from embedded ZIP file
//
//*****************************************************************************

module engine.blob.extract;

//-----------------------------------------------------------------------------

private extern(C) {
	extern __gshared ubyte __BLOB_zip;
	extern __gshared uint  __BLOB_zip_size;
}

//-----------------------------------------------------------------------------
// Extracting file from archive
//-----------------------------------------------------------------------------

import std.zip;
import std.file: FileException;
import core.exception: RangeError;

ubyte[] extract(string filename)
{
    ubyte[] buffer = (&__BLOB_zip)[0 .. __BLOB_zip_size];
    ZipArchive archive = new ZipArchive(buffer);
    ArchiveMember file;

    try {
        file = archive.directory[filename];
        archive.expand(file);
    }
    catch(RangeError e) {
        throw new FileException(filename, "File not found");
    }
    return file.expandedData;
}

