//
//  zstandardlibCompressor.m
//  zstandardlib
//
//  Created by JinyDu on 2021/6/22.
//  Copyright © 2021 JinyDu. All rights reserved.
//

#import "ZstdDecompressor.h"

#import "ZstdDecompression.h"

@implementation ZstdDecompressor

+ (NSInteger)defaultCompressionLevel
{
    static int16_t ZstdCompressionLevelDefault = 3 /* ZSTD_CLEVEL_DEFAULT */;
    return ZstdCompressionLevelDefault;
}

//+ (NSData*)compressedDataWithData:(NSData*)input
//{
//    return [self compressedDataWithData:input compressionLevel:self.defaultCompressionLevel];
//}
//
//+ (NSData*)compressedDataWithData:(NSData*)input compressionLevel:(NSInteger)compressionLevel
//{
//    return [self compressedDataWithBytes:input.bytes length:input.length compressionLevel:compressionLevel];
//}
//
//+ (NSData*)compressedDataWithBytes:(const void*)bytes length:(NSUInteger)length
//{
//    return [self compressedDataWithBytes:bytes length:length compressionLevel:self.defaultCompressionLevel];
//}
//
//+ (NSData*)compressedDataWithBytes:(const void*)bytes length:(NSUInteger)length compressionLevel:(NSInteger)compressionLevel
//{
//    return CFBridgingRelease(AWECreateZstdCompressedData(bytes, length, compressionLevel));
//}
//

+ (NSData*)decompressedDataWithData:(NSData*)input
{
    return [self decompressedDataWithBytes:input.bytes length:input.length];
}

+(BOOL)decompressedDataWithData:(NSData* _Nonnull)input fileName:(NSString * _Nonnull)filePath{
    bool success = false;
    FILE * file = fopen([filePath UTF8String], "wb");
    
    if(file == NULL){
        return false;
    }
    
    CreateZstdDecompressedDataByStreamToFile(input.bytes, input.length, file, &success);
    
    if(fclose(file) != 0){
        return false;
    }
    return success;
}

+ (NSData*)decompressedDataWithBytes:(const void*)bytes length:(NSUInteger)length
{
    return CFBridgingRelease(CreateZstdDecompressedData(bytes, length));
}
//
//+ (NSData *)compressedDataWithData:(NSData *)input dict:(NSData *)dict
//{
//    return [self compressedDataWithBytes:input.bytes length:input.length dictBytes:dict.bytes dictLength:dict.length compressionLevel:self.defaultCompressionLevel];
//}
//
//+ (NSData*)compressedDataWithBytes:(const void*)bytes length:(NSUInteger)length dictBytes:(const void*)dictBytes dictLength:(NSUInteger)dictLength  compressionLevel:(NSInteger)compressionLevel
//{
//    return CFBridgingRelease(AWECreateZstdCompressedDataWithDict(bytes,length,dictBytes,dictLength,compressionLevel));
//}

+ (NSData*)decompressedDataWithData:(NSData*)input dict:(NSData *)dict
{
    return [self decompressedDataWithBytes:input.bytes length:input.length dictBytes:dict.bytes dictLength:dict.length];
}

+ (NSData*)decompressedDataWithBytes:(const void*)bytes length:(NSUInteger)length dictBytes:(const void*)dictBytes dictLength:(NSUInteger)dictLength
{
    return CFBridgingRelease(CreateZstdDecompressedDataWithDict(bytes, length, dictBytes, dictLength));
}
@end
