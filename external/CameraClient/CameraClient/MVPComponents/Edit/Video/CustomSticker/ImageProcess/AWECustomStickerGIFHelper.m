//
//  AWECustomStickerGIFHelper.m
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/28.
//

#import "AWECustomStickerGIFHelper.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <ByteDanceKit/UIImage+BTDAdditions.h>
#import "ACCExifUtil.h"

__attribute__((overloadable)) NSData * _Nullable UIImageAnimatedGIFRepresentation(UIImage *image, NSTimeInterval duration, NSUInteger loopCount, NSError * __autoreleasing *error) {
    if (!image) {
        return nil;
    }
    
    NSArray<UIImage *> *images = image.images;
    if (!images) {
        images = @[image];
    }
    
    NSDictionary *userInfo = nil;
    {
        size_t frameCount = images.count;
        NSTimeInterval frameDuration = (duration <= 0.0 ? image.duration/frameCount : duration/frameCount);
        NSUInteger frameDelayCentiseconds = (NSUInteger)lrint(frameDuration);
        NSDictionary<NSString *, id> *frameProperties = @{
            (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                    (__bridge NSString *)kCGImagePropertyGIFDelayTime: @(frameDelayCentiseconds)
            }
        };
        
        NSMutableData *mutableData = [NSMutableData data];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData, kUTTypeGIF, frameCount, NULL);
        
        NSDictionary<NSString *, id> *imageProperties = @{ (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                                                                   (__bridge NSString *)kCGImagePropertyGIFLoopCount: @(loopCount)
        }
        };
        CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)imageProperties);
        
        for (size_t idx = 0; idx < images.count; idx++) {
            CGImageRef _Nullable cgimage = [images[idx] CGImage];
            if (cgimage) {
                CGImageDestinationAddImage(destination, (CGImageRef _Nonnull)cgimage, (__bridge CFDictionaryRef)frameProperties);
            }
        }
        
        BOOL success = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        
        if (!success) {
            userInfo = @{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Could not finalize image destination", nil)
            };
            if (error) {
                *error = [[NSError alloc] initWithDomain:@"com.compuserve.gif.image.error" code:-1 userInfo:userInfo];
            }
            return nil;
        }
        
        return [NSData dataWithData:mutableData];
    }
}

@implementation AWECustomStickerGIFHelper

+ (NSData *)compressGIFData:(NSData *)gifData withCompressRatio:(CGFloat)compressRatio
{
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)gifData, NULL);
    size_t count = CGImageSourceGetCount(source);
    UIImage *aniImage = nil;
    NSMutableArray *images = [NSMutableArray array];
    NSTimeInterval duration = 0.0f;
    for (size_t i = 0; i < count; i++) {
        CGImageRef frameRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
        duration += [self frameDurationAtIndex:i source:source];
        @autoreleasepool {
            UIImage *frameImg = [UIImage imageWithCGImage:frameRef];
            frameImg = [UIImage btd_fixImgOrientation:frameImg];
            frameImg = [UIImage btd_tryCompressImage:frameImg ifImageSizeLargeTargetSize:CGSizeMake(frameImg.size.width/compressRatio, frameImg.size.height/compressRatio)];
            [images addObject:frameImg];
        }
        CGImageRelease(frameRef);
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
    }
    aniImage = [UIImage animatedImageWithImages:images duration:duration];
    NSData *compressedData = UIImageAnimatedGIFRepresentation(aniImage,duration,INT_MAX,nil);
    CFRelease(source);
    
    return compressedData;
}

+ (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    NSDictionary *options = @{
        (__bridge NSString *)kCGImageSourceShouldCacheImmediately : @(YES),
        (__bridge NSString *)kCGImageSourceShouldCache : @(YES) // Always cache to reduce CPU usage
    };
    NSTimeInterval frameDuration = 0.1;
    NSDictionary *frameProperties = ACCImageSourceCopyPropertiesAtIndex(source, index, (__bridge CFDictionaryRef)options);
    if (!frameProperties) {
        return frameDuration;
    }
    NSDictionary *containerProperties = frameProperties[(__bridge NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTimeUnclampedProp = containerProperties[(__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp != nil) {
        frameDuration = [delayTimeUnclampedProp doubleValue];
    } else {
        NSNumber *delayTimeProp = containerProperties[(__bridge NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp != nil) {
            frameDuration = [delayTimeProp doubleValue];
        }
    }
    
    if (frameDuration < 0.011) {
        frameDuration = 0.1;
    }
    
    return frameDuration;
}

@end
