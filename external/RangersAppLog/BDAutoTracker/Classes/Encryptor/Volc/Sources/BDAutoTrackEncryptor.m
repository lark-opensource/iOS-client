//
//  BDAutoTrackEncryptor.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/6/6.
//

#import "BDAutoTrackEncryptor.h"
#import <VolcEngineEncryptor/VolcEngineEncryptor.h>

@implementation BDAutoTrackEncryptor

- (NSData *)encryptData:(NSData *)data error:(NSError * __autoreleasing *)error
{
    return [self decorated:data];
    
}
- (NSData *)decorated:(NSData *)data
{
    size_t length = data.length;
    if (length < 1) {
        return nil;
    }

    NSData * resultData = nil;

    size_t bufferSzie = applog_decorated_buffer_min_size(length);
    uint8_t * resultBuffer = malloc(bufferSzie * sizeof(uint8_t));
    if (resultBuffer == NULL) {
        return nil;
    }
    volc_applog_decorated([data bytes], length, resultBuffer, &bufferSzie);
    NSCAssert(bufferSzie > 0, @"applog_decorated failed, contact duanwenbin by lark");
    if (bufferSzie > 0) {
        size_t expectSize = applog_decorated_buffer_min_size(length);
        NSCAssert(expectSize == bufferSzie, @"must equal or will leak");
        resultData = [NSData dataWithBytesNoCopy:resultBuffer length:bufferSzie];
        NSCAssert(resultData.length == expectSize, @"error, contact duanwenbin by lark");
    } else {
        free(resultBuffer);
    }
    return resultData;
}


@end
