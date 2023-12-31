//
//  ZstdCompressor.m
//  zstandardlib
//
//  Created by ByteDance on 2022/8/19.
//

#import "ZstdCompression.h"
#import "ZstdCompressor.h"
#import "zstd.h"

@implementation ZstdCompressor {
    ZSTD_CDict* cdict;
    ZSTD_CCtx* cctx;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->cdict = NULL;
        self->cctx = ZSTD_createCCtx();
        self.compressionLevel =  (int)[[self class] defaultCompressionLevel];
    }
    return self;
}

- (void)setDictioanry:(NSData *)dictionaryData
{
    const void* dict = ((NSMutableData *)[dictionaryData mutableCopy]).mutableBytes;
    cdict = ZSTD_createCDict(dict, dictionaryData.length, self.compressionLevel);
}

- (nullable NSData*)compressDataWithData:(NSData* _Nonnull)input
                               usingDict:(BOOL)_usingDict
                                   error:(NSError **)error;
{
    BOOL usingDict = (_usingDict && cdict != NULL);
    
    void* const srcBuff = ((NSMutableData *)[input mutableCopy]).mutableBytes;
    size_t srcSize = input.length;
    
    size_t const dstCapacity = ZSTD_compressBound(srcSize);
    void* const dstBuff = malloc(dstCapacity);
    size_t ret;
    
    if (usingDict) {
        ret = ZSTD_compress_usingCDict(self->cctx, dstBuff, dstCapacity, srcBuff, srcSize, cdict);
    } else {
        ret = ZSTD_compressCCtx(self->cctx, dstBuff, dstCapacity, srcBuff, srcSize, self.compressionLevel);
    }
    
    if (ZSTD_isError(ret)) {
        NSString *desc = [[NSString alloc] initWithUTF8String:ZSTD_getErrorName(ret)];
        if (*error) {
            *error = [NSError errorWithDomain:@"zstandardlib_errordomain" code:ret userInfo:@{NSLocalizedDescriptionKey:desc?:@""}];
        }
        return nil;
    }
    NSData *dst = [[NSData alloc] initWithBytesNoCopy:dstBuff length:ret];
    if (dstBuff) {
        free(dstBuff);
    }
    return dst;
}


#pragma mark -

#pragma mark - Class methods
+ (NSInteger)defaultCompressionLevel{
    static int16_t ZstdCompressionLevelDefault = 3 /* ZSTD_CLEVEL_DEFAULT */;
    return ZstdCompressionLevelDefault;
}

+ (nullable NSData*)compressDataWithData:(NSData* _Nonnull)input
                        compressionLevel:(NSInteger)compressionLevel
                              dictionary:(nullable NSData *)dictionary{
    return [self compressedDataWithBytes:input.bytes
                                  length:input.length
                        compressionLevel:compressionLevel
                              dictionary:dictionary];
}

+ (nullable NSData*)compressedDataWithBytes:(const void* _Nonnull)bytes
                                     length:(NSUInteger)length
                           compressionLevel:(NSInteger)compressionLevel
                                 dictionary:(nullable NSData *)dictionary{
    
    
    size_t const dstCapacity = ZSTD_compressBound(length);
    void* const dstBuff = malloc(dstCapacity);
    size_t ret;
    
    BOOL usingDict = NO;
    ZSTD_CDict* cdict = NULL;
    ZSTD_CCtx* cctx = NULL;
    if (dictionary.length > 0) {
        const void* dict = ((NSMutableData *)[dictionary mutableCopy]).mutableBytes;
        cdict = ZSTD_createCDict( dict, dictionary.length, (int)(compressionLevel ?: [[self class] defaultCompressionLevel]));
        usingDict = YES;
    }
    
    cctx = ZSTD_createCCtx();
    if (usingDict && cdict != NULL) {
        ret = ZSTD_compress_usingCDict(cctx, dstBuff, dstCapacity, bytes, length, cdict);
    } else {
        ret = ZSTD_compressCCtx(cctx, dstBuff, dstCapacity, bytes, length, (int)(compressionLevel ?: [[self class] defaultCompressionLevel]));
    }
    
    if (ZSTD_isError(ret)) {
//        NSString *desc = [[NSString alloc] initWithUTF8String:ZSTD_getErrorName(ret)];
//        if (*error) {
//            *error = [NSError errorWithDomain:BDTrackerCompressionZSTDErrorDomain code:ret userInfo:@{NSLocalizedDescriptionKey:desc?:@""}];
//        }
        return nil;
    }
    NSData *dst = [[NSData alloc] initWithBytesNoCopy:dstBuff length:ret];
    if (dstBuff) {
        free(dstBuff);
    }
    if (cctx) {
        ZSTD_freeCCtx(cctx);
    }
    if (cdict) {
        ZSTD_freeCDict(cdict);
    }
    
    return dst;
}


@end
