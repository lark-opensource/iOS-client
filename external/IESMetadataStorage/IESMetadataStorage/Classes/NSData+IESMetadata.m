//
//  NSData+IESMetadata.m
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/26.
//

#import "NSData+IESMetadata.h"

#include <zlib.h>

@implementation NSData (IESMetadata)

- (uint32_t)iesmetadata_crc32
{
    uint32_t crc = (uint32_t)crc32(0L, Z_NULL, 0);
    crc = (uint32_t)crc32(crc, self.bytes, (uInt)self.length);
    return crc;
}

- (BOOL)iesmetadata_checkCrc32:(uint32_t)crc32
{
    return [self iesmetadata_crc32] == crc32;
}

@end
