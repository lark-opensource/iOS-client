//
//  ACCExifUtil.m
//  Indexer
//
//  Created by raomengyun on 2021/12/2.
//

#import "ACCExifUtil.h"
#import "ACCAPPSettingsProtocol.h"

FOUNDATION_EXTERN NSDictionary *_Nullable ACCImageSourceCopyPropertiesAtIndex(CGImageSourceRef _iio_Nonnull isrc, size_t index, CFDictionaryRef _iio_Nullable options)  IMAGEIO_AVAILABLE_STARTING(10.4, 4.0) {
    CFDictionaryRef imagePropertiesRef = CGImageSourceCopyPropertiesAtIndex(isrc, index, options);
    NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)imagePropertiesRef;
    
    // 关闭开关后剔除 GPS 信息
    if (ACCAPPSettings().disableExifPermission) {
        NSMutableDictionary *imagePropertiesMutable = [imageProperties mutableCopy];
        [imagePropertiesMutable removeObjectForKey:(__bridge NSString *)kCGImagePropertyGPSDictionary];
        imageProperties = imagePropertiesMutable.copy;
    }
    
    return imageProperties;
}

@implementation PHAsset (Exif)

- (CLLocation *)acc_location
{
    if (ACCAPPSettings().disableExifPermission) {
        return nil;
    }
    
    return self.location;
}

@end

@implementation NSURL (Exif)

- (NSDictionary *)acc_imageProperties
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)self, NULL);
    if (!imageSource) {
        return nil;
    }
    NSDictionary *metadata = ACCImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    CFRelease(imageSource);
    return metadata;
}

@end

@implementation NSData (Exif)

- (NSDictionary *)acc_imageProperties
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self, NULL);
    if (!imageSource) {
        return nil;
    }
    NSDictionary *metadata = ACCImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    CFRelease(imageSource);
    return metadata;
}

@end
