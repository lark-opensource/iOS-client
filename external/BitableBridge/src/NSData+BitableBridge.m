//
//  NSData+Extension.m
//  BitableBridge
//
//  Created by maxiao on 2018/9/17.
//

#import "NSData+BitableBridge.h"

@implementation NSData (BitableBridge)

- (NSString *)toBinaryString {
    if ([self length] == 0) return nil;
    NSMutableString *hexString = [NSMutableString stringWithCapacity:[self length] * 2];
    for (NSUInteger i = 0; i < [self length]; ++i) {
        [hexString appendFormat:@"%02X", *((uint8_t *)[self bytes] + i)];
    }
    return [hexString lowercaseString];
}

+ (NSData *)dataFromBinaryString:(NSString *)binaryString {
    const char *chars = [binaryString UTF8String];
    NSMutableData *data = [NSMutableData dataWithCapacity:binaryString.length / 2];
    char byteChars[3] = {0, 0, 0};
    unsigned long wholeByte;
    for (int i = 0; i < binaryString.length; i += 2) {
        byteChars[0] = chars[i];
        byteChars[1] = chars[i + 1];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    return data;
}

@end
