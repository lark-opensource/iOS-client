//
//  NSData+OneKitDecorator.m
//  OneKit
//
//  Created by bob on 2019/11/7.
//

#import "NSData+OKDecorator.h"
#import "app_log_private.h"

@implementation NSData (OneKitDecorator)

- (NSData *)rsk_dataByDecorated {
    size_t length = self.length;
    if (length < 1) {
        return nil;
    }

    NSData * resultData = nil;

    size_t bufferSzie = applog_decorated_buffer_min_size(length);
    uint8_t * resultBuffer = malloc(bufferSzie * sizeof(uint8_t));
    if (resultBuffer == NULL) {
        return nil;
    }
    
    applog_decorated_private([self bytes], length, resultBuffer, &bufferSzie);
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
