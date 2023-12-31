//
//  NSData+BDBCAdditions.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2020/12/24.
//

#import "NSData+BDCTAdditions.h"


@implementation NSData (BDBCAdditions)

+ (NSData *)bdct_saveImageWithImageData:(NSData *)data properties:(NSDictionary *)properties {
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionaryWithDictionary:properties];

    CGImageSourceRef imageRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    CFStringRef uti = CGImageSourceGetType(imageRef);

    NSMutableData *dataM = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dataM, uti, 1, NULL);
    if (!destination) {
        return nil;
    }

    CGImageDestinationAddImageFromSource(destination, imageRef, 0, (__bridge CFDictionaryRef)dataDic);
    BOOL check = CGImageDestinationFinalize(destination);
    if (!check) {
        return nil;
    }
    CFRelease(destination);
    CFRelease(uti);

    return dataM;
}

- (NSDictionary *)bdct_imageMetaData {
    CGImageSourceRef source = CGImageSourceCreateWithData((CFMutableDataRef)self, NULL);
    NSDictionary *metadata = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
    CFRelease(source);
    return metadata;
}

@end
