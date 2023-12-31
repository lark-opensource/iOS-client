//
//  NSData+ZstdCompression.m
//  zstandardlib
//
//  Created by ByteDance on 2022/8/19.
//
#import "ZstdCompressor.h"
#import "NSData+ZstdCompression.h"

@implementation NSData (ZstdCompression)
- (NSData *)awe_compressZstd
{
    return [self awe_compressZstdWithDict:nil];
}


- (NSData *)awe_compressZstdWithDict:(NSData *)dict
{
    return [ZstdCompressor compressDataWithData:self
                               compressionLevel:ZstdCompressor.defaultCompressionLevel
                                     dictionary:dict];
}
@end
