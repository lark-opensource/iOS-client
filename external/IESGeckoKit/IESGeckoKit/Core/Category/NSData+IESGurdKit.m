//
//  NSData+IESGurdKit.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/22.
//

#import "NSData+IESGurdKit.h"

#include <zlib.h>

@implementation NSData (IESGurdKit)

- (uint32_t)iesgurdkit_crc32
{
    uint32_t crc = (uint32_t)crc32(0L, Z_NULL, 0);
    crc = (uint32_t)crc32(crc, self.bytes, (uInt)self.length);
    return crc;
}

@end
