//
//  NSData+BDXBridgeAdditions.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/28.
//

#import "NSData+BDXBridgeAdditions.h"

@implementation NSData (BDXBridgeAdditions)

- (NSString *)bdx_mimeType
{
    if (self.length < 1) {
        return nil;
    }
    
    uint8_t byte;
    [self getBytes:&byte length:1];
    switch (byte) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
        case 0x25:
            return @"application/pdf";
        case 0xD0:
            return @"application/vnd";
        case 0x46:
            return @"text/plain";
        default:
            return @"application/octet-stream";
    }
}

@end
