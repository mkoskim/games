    .global __BLOB_zip
    .global __BLOB_zip_size
    .section .rodata
__BLOB_zip:
    .incbin "BLOB.zip"
1:
__BLOB_zip_size:
    .int 1b - __BLOB_zip

