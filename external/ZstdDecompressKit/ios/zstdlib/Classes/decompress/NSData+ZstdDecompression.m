//
//  NSData+ZstdCompression.m
//  zstandardlib
//
//  Created by JinyDu on 2021/6/22.
//  Copyright © 2021 JinyDu. All rights reserved.
//

#import "NSData+ZstdDecompression.h"
#import "ZstdDecompressor.h"

@implementation NSData (ZstdDecompression)
- (NSData *)zstd_decompress
{
    return [ZstdDecompressor decompressedDataWithData:self];
}

- (BOOL)zstd_decompressToFileName:(NSString *)fileName
{
    return [ZstdDecompressor decompressedDataWithData:self fileName:fileName];
}

- (NSData *)zstd_decompressWithDict:(NSData *)dict
{
    return [ZstdDecompressor decompressedDataWithData:self dict:dict];
}

@end
