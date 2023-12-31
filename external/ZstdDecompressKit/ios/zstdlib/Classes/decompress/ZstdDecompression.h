//
//  ZstdDecompression.h
//  zstandardlib
//
//  Created by JinyDu on 2021/6/22.
//  Copyright © 2021 JinyDu. All rights reserved.
//

#ifndef ZstdDecompression_h
#define ZstdDecompression_h

#include <stdio.h>
#include <CoreFoundation/CFData.h>
#include <CoreFoundation/CFBase.h>

/**
 Creates a newly created CFData.
 The input is decompressed via the Zstd algorithm.
 
 @param bytes Input bytes.
 @param length Input length (number of bytes).
 @param dictBytes Input dictionary bytes.
 @param dictLength Input dictionary length.
 @return Return the newly created decompressed data.
 */
CF_EXPORT CFDataRef CreateZstdDecompressedDataWithDict(const void* bytes, CFIndex length, const void* dictBytes, CFIndex dictLength);

/**
 Creates a newly created CFData.
 The input is decompressed via the Zstd algorithm.
 
 @param bytes Input bytes.
 @param length Input length (number of bytes).
 @return Return the newly created decompressed data.
 */
CF_EXPORT CFDataRef CreateZstdDecompressedData(const void* bytes, CFIndex length);

/**
 Put the output into a file.
 The input is decompressed via the Zstd algorithm.
 
 @param bytes Input bytes.
 @param length Input length (number of bytes).
 @param outputFile The pointer of the file that the data write to
 @param success The result whether write to the file successfully
 */

CF_EXPORT void CreateZstdDecompressedDataByStreamToFile(const void* bytes, CFIndex length, FILE * outputFile, bool * success);


#endif /* ZstdDecompression_h */
