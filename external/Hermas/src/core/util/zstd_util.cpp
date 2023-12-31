//
//  zstd_util.cpp
//  Hermas
//
//  Created by 崔晓兵 on 10/2/2022.
//

#include "zstd_util.h"
#include "log.h"

#define ZSTD_STATIC_LINKING_ONLY
#include <ZstdDecompressKit/zstd.h>

namespace hermas {

std::string zstd_compress_data(const char* bytes, size_t length, int compress_level) {
    std::string result;
    if (bytes == NULL || length == 0) {
        return result;
    }
    unsigned long long outputBufferSize = ZSTD_compressBound(length);
    char* outputBuffer = (char*)malloc((size_t)outputBufferSize);
    size_t outputSize = ZSTD_compress(outputBuffer, outputBufferSize, bytes, length, compress_level);
    
    if (ZSTD_isError(outputSize)) return result;
    
    result.append(outputBuffer, outputSize);
    
    free(outputBuffer);
    outputBuffer = NULL;
    return result;
}

std::string zstd_compress_data(const std::string& input_str, int compress_level) {
    return zstd_compress_data(input_str.c_str(), input_str.size(), compress_level);
}

std::string zstd_compress_data_usingDic(const char* input_str, size_t length, const char* cdict_str, size_t cdict_str_length, int compress_level) {
    std::string result;
    if (input_str == NULL || length == 0) {
        return result;
    }
    
    ZSTD_CCtx* cctx = ZSTD_createCCtx();
    if (cctx == NULL) {
        logd("zstd_compress_usingDic", "ZSTD_createCCtx() failed!");
        return result;
    }
    
    ZSTD_CDict *cdict = ZSTD_createCDict(cdict_str, cdict_str_length, compress_level);
    if (cdict == NULL) {
        ZSTD_freeCCtx(cctx);
        cctx = NULL;
        
        logd("createCdict", "ZSTD_createCDict() failed!");
        return result;
    }
    
    unsigned long long outputBufferSize = ZSTD_compressBound(length);
    char* outputBuffer = (char*)malloc((size_t)outputBufferSize);
    
    size_t const outputSize = ZSTD_compress_usingCDict(cctx, outputBuffer, outputBufferSize, input_str, length, cdict);
    if (ZSTD_isError(outputSize)) {
        free(outputBuffer);
        outputBuffer = NULL;
        
        ZSTD_freeCCtx(cctx);
        cctx = NULL;
        
        ZSTD_freeCDict(cdict);
        cdict = NULL;
        
        return result;
    }
    
    result.append(outputBuffer, outputSize);
    
    free(outputBuffer);
    outputBuffer = NULL;
    ZSTD_freeCCtx(cctx);
    cctx = NULL;
    ZSTD_freeCDict(cdict);
    cdict = NULL;
    
    return result;
}

std::string zstd_compress_data_usingDic(const std::string& input_str, const std::string& cdict_str, int compress_level) {
    return zstd_compress_data_usingDic(input_str.c_str(), input_str.size(), cdict_str.c_str(), cdict_str.length(), compress_level);
}

//std::string zstd_decompress_data(const char* bytes, size_t length) {
//    std::string result;
//    if (bytes == NULL || length == 0) {
//        return result;
//    }
//
//    // find the output size
//#if defined(ZSTD_STATIC_LINKING_ONLY)
//    unsigned long long outputBufferSize = ZSTD_findDecompressedSize((void *)bytes, length);
//#else
//    unsigned long long outputBufferSize = ZSTD_getDecompressedSize((void *)bytes, length);
//#endif
//    if (ZSTD_CONTENTSIZE_ERROR == outputBufferSize) {
//        return result;
//    }
//
//    if(ZSTD_CONTENTSIZE_UNKNOWN == outputBufferSize) {
//        //无法获取解压后大小采用 Stream decompress
//        return result;
//    }
//
//    // malloc the buffer
//    char* outputBuffer = (char *)malloc((size_t)outputBufferSize);
//
//    if (!outputBuffer) {
//        return result;
//    }
//
//    // decompress
//    size_t outputSize = ZSTD_decompress(outputBuffer, (size_t)outputBufferSize, bytes, length);
//
//    // if invalid output size, return NULL
//    if (outputSize != outputBufferSize) {
//        if (outputBuffer != NULL) {
//            free(outputBuffer);
//            outputBuffer = NULL;
//        }
//        return result;
//    }
//
//    // copy output data to a std::string
//    result.append(outputBuffer, outputSize);
//
//    // free output buffer
//    free(outputBuffer);
//    outputBuffer = NULL;
//
//    return result;
//
//}
//
//std::string zstd_decompress_data(const std::string& input_str) {
//    return zstd_decompress_data(input_str.c_str(), input_str.size());
//}
//
//
//std::string zstd_decompress_data_usingDic(const char* input_str, size_t length, const char* ddict_str, size_t ddict_str_length) {
//    std::string result;
//    if (input_str == NULL || length == 0) {
//        return result;
//    }
//
//    // find the output size
//#if defined(ZSTD_STATIC_LINKING_ONLY)
//    unsigned long long outputBufferSize = ZSTD_findDecompressedSize((void *)input_str, length);
//#else
//    unsigned long long outputBufferSize = ZSTD_getDecompressedSize((void *)input_str, length);
//#endif
//
//    if (ZSTD_CONTENTSIZE_ERROR == outputBufferSize) {
//        logd("zstd_decompress_usingDic", "not compressed by zstd!");
//        return result;
//    }
//
//    if(ZSTD_CONTENTSIZE_UNKNOWN == outputBufferSize) {
//        logd("zstd_decompress_usingDic", "original size unknown!");
//        return result;
//    }
//
//
//    ZSTD_DDict *ddict = ZSTD_createDDict(ddict_str, ddict_str_length);
//    if (ddict == NULL) {
//        logd("zstd_decompress_usingDic", "ZSTD_createDDict() failed!");
//        return result;
//    }
//
//    // malloc the outbuffer
//    char* outputBuffer = (char *)malloc((size_t)outputBufferSize);
//
//    unsigned const expectedDictID = ZSTD_getDictID_fromDDict(ddict);
//    unsigned const actualDictID = ZSTD_getDictID_fromFrame(outputBuffer, outputBufferSize);
//    if (expectedDictID != actualDictID) {
//        free(outputBuffer);
//        outputBuffer = NULL;
//        logd("zstd_decompress_usingDic", "DictID mismatch: expected %u got %u", expectedDictID, actualDictID);
//        return result;
//    }
//    ZSTD_DCtx* dctx = ZSTD_createDCtx();
//    if (dctx == NULL) {
//        free(outputBuffer);
//        outputBuffer = NULL;
//        logd("zstd_decompress_usingDic", "ZSTD_createDCtx() failed!");
//        return result;
//    }
//
//    size_t outputSize = ZSTD_decompress_usingDDict(dctx, outputBuffer, outputBufferSize, input_str, length, ddict);
//
//    if (outputSize != outputBufferSize && outputBuffer != NULL) {
//        free(outputBuffer);
//        outputBuffer = NULL;
//        ZSTD_freeDCtx(dctx);
//        dctx = NULL;
//        logd("zstd_decompress_usingDic", "Impossible because zstd will check this condition!");
//        return result;
//    }
//
//    result.append(outputBuffer, outputSize);
//
//    free(outputBuffer);
//    outputBuffer = NULL;
//    ZSTD_freeDCtx(dctx);
//    dctx = NULL;
//
//    return result;
//}
//
//std::string zstd_decompress_data_usingDic(const std::string& input_str, const std::string& ddict_str) {
//    return zstd_decompress_data_usingDic(input_str.c_str(), input_str.size(), ddict_str.c_str(), ddict_str.length());
//}

}

