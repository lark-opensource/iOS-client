//
//  ZstdDecompression.h
//  zstandardlib
//
//  Created by JinyDu on 2021/6/22.
//  Copyright © 2021 JinyDu. All rights reserved.
//

#include "ZstdDecompression.h"

#include <stdio.h>
#include <stdlib.h>

#define ZSTD_STATIC_LINKING_ONLY   // ZSTD_findDecompressedSize
#include "zstd.h"
#include "zstd_errors.h"
unsigned long long ZSTD_findDecompressedSize(const void* src, size_t srcSize);

//流式非字典解压到文件
void CreateZstdDecompressedDataByStreamToFile(const void* bytes, CFIndex length, FILE * outputFile, bool * success){
    if (bytes == NULL || length == 0) {
        !success ? : (*success = false);
        return;
    }
    
    size_t const buffOutSize = ZSTD_DStreamOutSize();  /* Guarantee to successfully flush at least one complete compressed block in all circumstances. */
    void*  const buffOut = malloc(buffOutSize);
    if (!buffOut) {
        !success ? : (*success = false);
        return;
    }
    
    ZSTD_DCtx* const dctx = ZSTD_createDCtx();
    
    if (!dctx) {
        !success ? : (*success = false);
        free(buffOut);
        return;
    }
    size_t lastRet = 0;

    ZSTD_inBuffer input = { bytes, length, 0 };
    while (input.pos < input.size) {
        ZSTD_outBuffer output = { buffOut, buffOutSize, 0 };
        size_t const ret = ZSTD_decompressStream(dctx, &output , &input);
        if(ZSTD_isError(ret)){
            !success ? : (*success = false);
            ZSTD_freeDCtx(dctx);
            free(buffOut);
            return;
        }
        if(fwrite(buffOut, output.pos, 1 , outputFile) != 1){
            free(buffOut);
            ZSTD_freeDCtx(dctx);
            !success ? : (*success = false);
            return;
        }
        
        lastRet = ret;
    }
    
    if (lastRet != 0) {
        fprintf(stderr, "EOF before end of stream: %zu\n", lastRet);
        ZSTD_freeDCtx(dctx);
        !success ? : (*success = false);
        free(buffOut);
        return;
    }
    !success ? : (*success = true);
    ZSTD_freeDCtx(dctx);
    free(buffOut);
    return;
}

// 流式非字典解压
CFDataRef CreateZstdDecompressedDataByStream(const void* bytes, CFIndex length)
{
    if (bytes == NULL || length == 0) {
        return NULL;
    }
    
    size_t const buffOutSize = ZSTD_DStreamOutSize();  /* Guarantee to successfully flush at least one complete compressed block in all circumstances. */
    void*  const buffOut = malloc(buffOutSize);
    if (!buffOut) {
        return NULL;
    }
    
    ZSTD_DCtx* const dctx = ZSTD_createDCtx();
    
    if (!dctx) {
        free(buffOut);
        return NULL;
    }
    
    size_t lastRet = 0;
    CFMutableDataRef cf_outputData = NULL;
        
    ZSTD_inBuffer input = { bytes, length, 0 };
    
    while (input.pos < input.size) {
        ZSTD_outBuffer output = { buffOut, buffOutSize, 0 };
        size_t const ret = ZSTD_decompressStream(dctx, &output , &input);
        if(ZSTD_isError(ret)){
            
            free(buffOut);
            if (cf_outputData) {CFRelease(cf_outputData);}
            return NULL;
        }
        
        if (!cf_outputData) {
            cf_outputData = CFDataCreateMutable(kCFAllocatorDefault, output.pos);
        } else{
            CFIndex new_length = CFDataGetLength(cf_outputData);
            CFMutableDataRef temp = CFDataCreateMutable(kCFAllocatorDefault, new_length +output.pos);
            CFDataAppendBytes(temp, CFDataGetBytePtr(cf_outputData), new_length);
            CFRelease(cf_outputData);
            cf_outputData = temp;
        }
        CFDataAppendBytes(cf_outputData, buffOut, output.pos);
        lastRet = ret;
    }
    
    if (lastRet != 0) {
        fprintf(stderr, "EOF before end of stream: %zu\n", lastRet);
        ZSTD_freeDCtx(dctx);
        free(buffOut);
        if (cf_outputData) {
            CFRelease(cf_outputData);
        }
        return NULL;
    }
    
    ZSTD_freeDCtx(dctx);
    free(buffOut);
    CFDataRef ref = CFDataCreateCopy(kCFAllocatorDefault, cf_outputData);
    if (cf_outputData) {
        CFRelease(cf_outputData);
    }
    return ref;
}


// 流式带字典解压
CFDataRef CreateZstdDecompressedDataByStreamWithDict(const void* bytes, CFIndex length, const void* dictBytes, CFIndex dictLength)
{
    if (bytes == NULL || length == 0) {
        return NULL;
    }
    
    size_t const buffOutSize = ZSTD_DStreamOutSize();  /* Guarantee to successfully flush at least one complete compressed block in all circumstances. */
    void*  const buffOut = malloc(buffOutSize);
    if (!buffOut) {
        return NULL;
    }
    
    ZSTD_DCtx* const dctx = ZSTD_createDCtx();
    
    if (!dctx) {
        free(buffOut);
        return NULL;
    }
    
    size_t rtn = ZSTD_DCtx_loadDictionary(dctx, dictBytes, dictLength);
    if (ZSTD_isError(rtn)) {
        free(buffOut);
        return NULL;
    }
    size_t lastRet = 0;
    CFMutableDataRef cf_outputData = NULL;
        
    ZSTD_inBuffer input = { bytes, length, 0 };
    while (input.pos < input.size) {
        ZSTD_outBuffer output = { buffOut, buffOutSize, 0 };
        size_t const ret = ZSTD_decompressStream(dctx, &output , &input);
        if(ZSTD_isError(ret)){
            ZSTD_ErrorCode code = ZSTD_getErrorCode(ret);
            free(buffOut);
            if (cf_outputData) {CFRelease(cf_outputData);}
            return NULL;
        }
        if (!cf_outputData) {
            cf_outputData = CFDataCreateMutable(kCFAllocatorDefault, output.pos);
        } else{
            CFIndex new_length = CFDataGetLength(cf_outputData);
            CFMutableDataRef temp = CFDataCreateMutable(kCFAllocatorDefault, new_length +output.pos);
            CFDataAppendBytes(temp, CFDataGetBytePtr(cf_outputData), new_length);
            CFRelease(cf_outputData);
            cf_outputData = temp;
        }
        CFDataAppendBytes(cf_outputData, buffOut, output.pos);
        lastRet = ret;
    }
    
    if (lastRet != 0) {
        fprintf(stderr, "EOF before end of stream: %zu\n", lastRet);
        ZSTD_freeDCtx(dctx);
        free(buffOut);
        if (cf_outputData) {
            CFRelease(cf_outputData);
        }
        return NULL;
    }
    
    ZSTD_freeDCtx(dctx);
    free(buffOut);
    CFDataRef ref = CFDataCreateCopy(kCFAllocatorDefault, cf_outputData);
    if (cf_outputData) {
        CFRelease(cf_outputData);
    }
    return ref;
}


CFDataRef CreateZstdDecompressedDataWithDict(const void* bytes, CFIndex length, const void* dictBytes, CFIndex dictLength)
{
    if (bytes == NULL || length == 0) {
        return NULL;
    }

    // find the output size
    unsigned long long outputBufferSize = ZSTD_findDecompressedSize(bytes, length);
    if (ZSTD_CONTENTSIZE_ERROR == outputBufferSize){
        return NULL;
    }
    
    if(ZSTD_CONTENTSIZE_UNKNOWN == outputBufferSize) {
        //无法获取解压后大小采用 Stream decompress
        return CreateZstdDecompressedDataByStreamWithDict(bytes, length, dictBytes, dictLength);
    }
    UInt8* outputBuffer = malloc((size_t)outputBufferSize);
    
    ZSTD_DCtx *dctx = ZSTD_createDCtx();
    // decompress
    size_t outputSize = ZSTD_decompress_usingDict(dctx, outputBuffer, (size_t)outputBufferSize, bytes, length, dictBytes, (size_t) dictLength);

    // if invalid output size, return NULL
    if (outputSize != outputBufferSize) {
        if (outputBuffer != NULL) {
            ZSTD_freeDCtx(dctx);
            free(outputBuffer);
            outputBuffer = NULL;
        }
        return NULL;
    }

    // copy output data to a new NSData
    CFDataRef outputData = CFDataCreate(kCFAllocatorDefault, outputBuffer, (CFIndex)outputBufferSize);

    // free output buffer
    free(outputBuffer);
    outputBuffer = NULL;
    ZSTD_freeDCtx(dctx);
    return outputData;
}

CFDataRef CreateZstdDecompressedData(const void* bytes, CFIndex length)
{
    if (bytes == NULL || length == 0) {
        return NULL;
    }

    // find the output size
    unsigned long long outputBufferSize = ZSTD_findDecompressedSize(bytes, length);
    if (ZSTD_CONTENTSIZE_ERROR == outputBufferSize){
        return NULL;
    }

    if(ZSTD_CONTENTSIZE_UNKNOWN == outputBufferSize) {
        //无法获取解压后大小采用 Stream decompress
        return CreateZstdDecompressedDataByStream(bytes, length);
    }

    // malloc the buffer
    UInt8* outputBuffer = malloc((size_t)outputBufferSize);

    // decompress
    size_t outputSize = ZSTD_decompress(outputBuffer, (size_t)outputBufferSize, bytes, length);

    // if invalid output size, return NULL
    if (outputSize != outputBufferSize) {
        if (outputBuffer != NULL) {
            free(outputBuffer);
            outputBuffer = NULL;
        }
        return NULL;
    }

    // copy output data to a new NSData
    CFDataRef outputData = CFDataCreate(kCFAllocatorDefault, outputBuffer, (CFIndex)outputBufferSize);

    // free output buffer
    free(outputBuffer);
    outputBuffer = NULL;

    return outputData;
}
