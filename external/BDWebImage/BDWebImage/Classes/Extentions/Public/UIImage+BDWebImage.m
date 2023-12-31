//
//  UIImage+DBWebImage.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/28.
//

#import "UIImage+BDWebImage.h"
#import <objc/runtime.h>
#import "BDImageDecoder.h"
#import "BDImageDecoderFactory.h"
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif
#import "BDWebImageUtil.h"
#if __has_include("BDBaseInternal.h")
#import <BDAlogProtocol/BDAlogProtocol.h>
#endif
#import "BDWebImageError.h"
#if __has_include(<libwebp/webp/encode.h>)
    #import <libwebp/webp/encode.h>
#elif __has_include(<libwebp/encode.h>)
    #import <libwebp/encode.h>
#endif
#import <Accelerate/Accelerate.h>
#import "BDImageCache.h"

@implementation UIImage (BDWebImage)
@dynamic bd_animatedImageData;

static void *kImageURL = &kImageURL;

- (void)setBd_isThumbnail:(BOOL)isThumbnail
{
    objc_setAssociatedObject(self, @selector(bd_isThumbnail), @(isThumbnail), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)bd_isThumbnail
{
    return objc_getAssociatedObject(self, @selector(bd_isThumbnail));
}

- (void)setBd_webURL:(NSURL *)webURL
{
    NSURL *url = [webURL copy];
    objc_setAssociatedObject(self, @selector(bd_webURL), url, OBJC_ASSOCIATION_RETAIN);
}

- (NSURL *)bd_webURL
{
    return objc_getAssociatedObject(self, @selector(bd_webURL));
}

- (void)setBd_requestKey:(BDImageRequestKey *)bd_requestKey {
    BDImageRequestKey *requestKey = [bd_requestKey copy];
    objc_setAssociatedObject(self, @selector(bd_requestKey), requestKey, OBJC_ASSOCIATION_RETAIN);
}

- (BDImageRequestKey *)bd_requestKey {
    return objc_getAssociatedObject(self, @selector(bd_requestKey));
}

- (void)setBd_loading:(BOOL)loading {
    objc_setAssociatedObject(self, @selector(bd_loading), @(loading), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)bd_loading {
    return [objc_getAssociatedObject(self, @selector(bd_loading)) boolValue];
}

- (void)setBd_isDidScaleDown:(BOOL)isScaleDowned {
    objc_setAssociatedObject(self, @selector(bd_isDidScaleDown), @(isScaleDowned), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)bd_isDidScaleDown {
    return [objc_getAssociatedObject(self, @selector(bd_isDidScaleDown)) boolValue];
}

@end

@implementation UIImage (BDWebImageToData)

- (NSData *)bd_imageDataRepresentation {
    return [self _bd_dataRepresentationForSystem:NO];
}

/// @param forSystem YES: used for system album (PNG/JPEG/GIF), NO: used for BDImage (PNG/JPEG/GIF/WebP)
- (NSData *)_bd_dataRepresentationForSystem:(BOOL)forSystem {
    NSData *data = nil;
    if ([self isKindOfClass:[BDImage class]]) {
        BDImage *image = (id)self;
        if (image.animatedImageData) {
            if (forSystem) { // system only support GIF and PNG
                BOOL typeSupported = image.codeType == BDImageCodeTypeGIF || image.codeType == BDImageCodeTypePNG;
                if (@available(iOS 13.0, *)) {
                    typeSupported = typeSupported || image.codeType == BDImageCodeTypeHeif;
                }
                if (typeSupported) {
                    data = image.animatedImageData;
                }
            } else {
                data = image.animatedImageData;
            }
        }
    }
    if (!data) {
        CGImageRef imageRef = self.CGImage ? (CGImageRef)CFRetain(self.CGImage) : nil;
        if (imageRef) {
//            CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
            CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
            BOOL hasAlpha = NO;
            if (alphaInfo == kCGImageAlphaPremultipliedLast ||
                alphaInfo == kCGImageAlphaPremultipliedFirst ||
                alphaInfo == kCGImageAlphaLast ||
                alphaInfo == kCGImageAlphaFirst) {
                hasAlpha = YES;
            }
            //TODO
//            if (self.imageOrientation != UIImageOrientationUp) {
//                CGImageRef rotated = YYCGImageCreateCopyWithOrientation(imageRef, self.imageOrientation, bitmapInfo | alphaInfo);
//                if (rotated) {
//                    CFRelease(imageRef);
//                    imageRef = rotated;
//                }
//            }
            @autoreleasepool {
                UIImage *newImage = [UIImage imageWithCGImage:imageRef];
                if (newImage) {
                    if (hasAlpha) {
                        data = UIImagePNGRepresentation([UIImage imageWithCGImage:imageRef]);
                    } else {
                        data = UIImageJPEGRepresentation([UIImage imageWithCGImage:imageRef], 0.9); // same as Apple's example
                    }
                }
            }
            CFRelease(imageRef);
        }
    }
    if (!data) {
        data = UIImagePNGRepresentation(self);
    }
    return data;
}

+ (nullable UIImage *)bd_staticImage:(CGImageSourceRef)imageSource
                      downsampleSize:(CGSize)downsampleSize
{
    CGImageRef cgImage;
    if (!CGSizeEqualToSize(CGSizeZero, downsampleSize)){
        CGFloat maxPixelSize = MAX(downsampleSize.width * UIScreen.mainScreen.scale, downsampleSize.height * UIScreen.mainScreen.scale);
        NSMutableDictionary *downsampleOptions = [NSMutableDictionary dictionary];
        downsampleOptions[(__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize] = @(maxPixelSize);
        downsampleOptions[(__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways] = @(YES);
        downsampleOptions[(__bridge NSString *)kCGImageSourceShouldCacheImmediately] = @(YES);
        cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)downsampleOptions);
    } else {
        cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
    }
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CFRelease(imageSource);
    return image;
}

+ (nullable UIImage *)bd_animationImage:(CGImageSourceRef)imageSource
                             frameCount:(NSUInteger)frameCount
                         downsampleSize:(CGSize)downsampleSize
{
    UIImage *animatedImage;
    NSMutableArray<BDAnimateImageFrame *> *frameArray = [NSMutableArray array];
    for (NSUInteger i = 0; i < frameCount; ++i) {
        CGImageRef imageRef;
        if (!CGSizeEqualToSize(CGSizeZero, downsampleSize)){
            // 降采样
            CGFloat maxPixelSize = MAX(downsampleSize.width * UIScreen.mainScreen.scale, downsampleSize.height * UIScreen.mainScreen.scale);
            NSMutableDictionary *downsampleOptions = [NSMutableDictionary dictionary];
            downsampleOptions[(__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize] = @(maxPixelSize);
            downsampleOptions[(__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways] = @(YES);
            downsampleOptions[(__bridge NSString *)kCGImageSourceShouldCacheImmediately] = @(YES);
            imageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, i, (__bridge CFDictionaryRef)downsampleOptions);
        } else {
            imageRef = CGImageSourceCreateImageAtIndex(imageSource, i, nil);
        }
        
        if (!imageRef) {
            continue;
        }
        
        float frameDuration = 0.1f;
        CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil);
        if (cfFrameProperties) {
            NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
            NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
            
            NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
            if (delayTimeUnclampedProp != nil) {
                frameDuration = [delayTimeUnclampedProp floatValue];
            } else {
                NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
                if (delayTimeProp != nil) {
                    frameDuration = [delayTimeProp floatValue];
                }
            }
            CFRelease(cfFrameProperties);
        }
        if (frameDuration < 0.011f) {
            frameDuration = 0.100f;
        }
        
        UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:1 orientation:UIImageOrientationUp];
        CFRelease(imageRef);
        
        BDAnimateImageFrame *frame = [[BDAnimateImageFrame alloc] init];
        frame.image = image;
        frame.nextFrameTime = frameDuration;
        [frameArray addObject:frame];
    }
    CFRelease(imageSource);
    animatedImage = [self animatedImageWithFrames:frameArray];
    return animatedImage;
}

+ (nullable UIImage *)bd_imageWithData:(nullable NSData *)data
                        downsampleSize:(CGSize)downsampleSize
{
    if (!data) {
        return nil;
    }
    
    CGImageSourceRef imageSouce = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
    if (!imageSouce) {
        return nil;
    }
    
    NSUInteger frameCount  = CGImageSourceGetCount(imageSouce);
    if (frameCount == 0) {
        CFRelease(imageSouce);
        return nil;
    }
    
    // 静图
    if (frameCount == 1) {
        return [self bd_staticImage:imageSouce downsampleSize:downsampleSize];
    }
    
    // 动图
    return [self bd_animationImage:imageSouce
                        frameCount:frameCount
                    downsampleSize:downsampleSize];
    
}

+ (nullable UIImage *)bd_imageWithData:(nullable NSData *)data
                                   url:(NSString *)url
                               isCache:(BOOL)isCache
                        downsampleSize:(CGSize)downsampleSize
{
    if (!data) {
        return nil;
    }
    
    UIImage *animatedImage;
    
    // 需要进行缓存
    if (isCache) {
        // 先查询缓存
        BDImageRequestKey *requestKey = [[BDImageRequestKey alloc] initWithURL:url
                                                                downsampleSize:downsampleSize
                                                                      cropRect:CGRectZero
                                                                 transfromName:@""
                                                                     smartCrop:NO];
        UIImage *sourceImage = [[BDImageCache sharedImageCache] imageForKey:requestKey.targetkey];
        if (sourceImage){
            animatedImage = sourceImage;
        } else {
            animatedImage = [self bd_imageWithData:data downsampleSize:downsampleSize];
            [[BDImageCache sharedImageCache] setImage:animatedImage
                                            imageData:nil
                                               forKey:requestKey.targetkey
                                             withType:BDImageCacheTypeMemory];
        }
    } else {
        animatedImage = [self bd_imageWithData:data downsampleSize:downsampleSize];
    }
    
    return animatedImage;
}

+ (nullable UIImage *) bd_imageWithGifData:(nullable NSData *)data {
    return [self bd_imageWithData:data downsampleSize:CGSizeZero];
}

+ (nullable UIImage *) bd_imageWithData:(nullable NSData *)data {
    return [self bd_imageWithData:data downsampleSize:CGSizeZero];
}

+ (UIImage *)animatedImageWithFrames:(NSArray<BDAnimateImageFrame *> *)frameArray {
    NSUInteger frameCount = frameArray.count;
    if (frameCount == 0) {
        return nil;
    }
    
    UIImage *animatedImage;
    
    NSUInteger durations[frameCount];
    for (size_t i = 0; i < frameCount; i++) {
        durations[i] = frameArray[i].nextFrameTime * 1000;
    }
    NSUInteger const gcd = gcdArray((int)frameCount, (int*)durations);
    __block NSUInteger totalDuration = 0;
    NSMutableArray<UIImage *> *animatedImages = [NSMutableArray arrayWithCapacity:frameCount];
    [frameArray enumerateObjectsUsingBlock:^(BDAnimateImageFrame * _Nonnull frame, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage *image = frame.image;
        NSUInteger duration = frame.nextFrameTime * 1000;
        totalDuration += duration;
        NSUInteger repeatCount;
        if (gcd) {
            repeatCount = duration / gcd;
        } else {
            repeatCount = 1;
        }
        for (size_t i = 0; i < repeatCount; ++i) {
            [animatedImages addObject:image];
        }
    }];
    
    animatedImage = [UIImage animatedImageWithImages:animatedImages duration:totalDuration / 1000.f];
    
    return animatedImage;
}

- (void)bd_awebpToGifDataWithCompletion:(void(^ __nullable)(NSData *gifData, NSError *error))completion {
    [self bd_animatedImageToGifDataWithCompletion:completion callerName:@"awebpToGif"];
}

- (void)bd_heifToGifDataWithCompletion:(void(^ __nullable)(NSData *gifData, NSError *error))completion {
    [self bd_animatedImageToGifDataWithCompletion: completion callerName:@"heifToGif"];
}
    
- (void)bd_animatedImageToGifDataWithCompletion:(void(^ __nullable)(NSData *gifData, NSError *error))completion callerName:(NSString *)callerName {
    
    if (!completion) {
        return;
    }
    
    if (![self isKindOfClass:[BDImage class]]
        || ([(BDImage *)self codeType] != BDImageCodeTypeWebP && [(BDImage *)self codeType] != BDImageCodeTypeHeif)
        || ![(BDImage *)self isAnimateImage]) {
        if (completion) {
            void (^errorBlock) (void) = ^{
                NSInteger errCode = [callerName isEqualToString:@"awebpToGif"] ? BDWebImageAwebpInvalid : BDWebImageAnimatedImageInvalid;
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: @"The image code type is invalid"
                                           };
                NSError *error = [[NSError alloc] initWithDomain:BDWebImageErrorDomain code:errCode userInfo:userInfo];
                completion(nil, error);
            };
            
            if ([NSThread isMainThread]) {
                errorBlock();
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorBlock();
                });
            }
#if __has_include("BDBaseInternal.h")
            BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", [NSString stringWithFormat:@"%@ code type invalid", callerName]);
#elif __has_include("BDBaseToB.h")
            NSLog(@"[BDWebImageToB] %@", [NSString stringWithFormat:@"%@ code type invalid", callerName]);
#endif
        }
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BDImage *animatedImage = (BDImage *)self;
        CGSize frameSize = CGSizeZero;
        NSInteger fameCount = animatedImage.frameCount;
        
        NSMutableData *data = [NSMutableData new];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)data, kUTTypeGIF, fameCount, NULL);
        @synchronized (self) {
            for (NSInteger i = 0; i < fameCount; i++) {
                @autoreleasepool {
                    BDAnimateImageFrame *frame = [animatedImage frameAtIndex:i];
                    UIImage *image = frame.image;
                    if (i == 0) {
                        frameSize = image.size;
                    }
                    NSDictionary *frameProperties = @{
                                                      (NSString *)kCGImagePropertyGIFDictionary: @{
                                                              (NSString *)kCGImagePropertyGIFDelayTime: [NSNumber numberWithFloat:frame.delay]
                                                              }};
                    CGImageDestinationAddImage(destination, image.CGImage, (CFDictionaryRef)frameProperties);
                }
            }
        }
        
        NSDictionary *gifProperties = @{
                                        (NSString *)kCGImagePropertyGIFDictionary: @{
                                                (NSString *)kCGImagePropertyGIFLoopCount : [NSNumber numberWithInteger:animatedImage.loopCount]
                                                }};
        
        CGImageDestinationSetProperties(destination, (CFDictionaryRef)gifProperties);
        BOOL success = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                if (success) {
                    completion(data, nil);
                } else {
                    NSInteger errCode = [callerName isEqualToString:@"awebpToGif"] ? BDWebImageAwebpConvertToGIfDataError : BDWebImageAnimatedImageConvertToGIfDataError;
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey: @"Could not finalize image destination"
                                               };
                    NSError *error = [[NSError alloc] initWithDomain:BDWebImageErrorDomain code:errCode userInfo:userInfo];
                    completion(nil, error);
                }
            }
        });
#if __has_include("BDBaseInternal.h")
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"%@, success :%d, length :%ld, frame size :%@, frame count :%ld, gif data length :%ld", callerName, success, animatedImage.animatedImageData.length, NSStringFromCGSize(frameSize), animatedImage.frameCount, data.length);
#elif __has_include("BDBaseToB.h")
        NSLog(@"[BDWebImageToB] %@, success :%d, length :%ld, frame size :%@, frame count :%ld, gif data length :%ld", callerName, success, animatedImage.animatedImageData.length, NSStringFromCGSize(frameSize), animatedImage.frameCount, data.length);
#endif
    });
    
}

- (NSUInteger)bd_imageCost {
    NSUInteger cost = 1;
    if ([self respondsToSelector:@selector(bd_animatedImageData)]) {
        NSData *data = [self bd_animatedImageData];
        cost += data.length;
    }
    
    CGImageRef cgImage = self.CGImage;
    if (!cgImage) return cost;
    
    CGFloat height = CGImageGetHeight(cgImage);
    size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
    cost += bytesPerRow * height;
    if (cost == 0) cost = 1;
    return cost;
}

#pragma mark - encode

- (NSData *)bd_encodeWithImageTypeAndQuality:(BDImageCodeType)codeType
                               qualityFactor:(float)qualityFactor {
    NSData *data = nil;
    if ([self isKindOfClass:[BDImage class]]) { // 动图编码可能出现多线程问题，暂不支持
        BDImage *image = (id)self;
        if (image.isAnimateImage) {
            return nil;
        }
    }
    if ([self _imageIOAvaliableType:codeType]) {
        data = [self _bd_encodeByImageIO:codeType];
    } else if (codeType == BDImageCodeTypeWebP) {
        data = [self _bd_encodeByWebP:qualityFactor];
    }
    return data;
}

- (NSData *)bd_encodeWithImageType:(BDImageCodeType)codeType {
    return [self bd_encodeWithImageTypeAndQuality:codeType qualityFactor:80];
}

- (NSData *)_bd_encodeByImageIO:(BDImageCodeType)codeType {
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = BDUTTypeFromBDImageType(codeType);
    // Create an image destination.
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, 1, NULL);
    if (!imageDestination) {
        // Handle failure.
        return nil;
    }
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    CGImagePropertyOrientation exifOrientation = BDExifOrientationFromImageOrientation(self.imageOrientation);
    properties[(__bridge NSString *)kCGImagePropertyOrientation] = @(exifOrientation);
    properties[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] = @(1);
    
    // Add your image to the destination.
    CGImageDestinationAddImage(imageDestination, self.CGImage, (__bridge CFDictionaryRef)properties);
    
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO) {
        // Handle failure.
        imageData = nil;
    }
    
    CFRelease(imageDestination);
    
    return [imageData copy];
}

- (NSData *)_bd_encodeByWebP:(float)qualityFactor {
    NSData *webpData;
    CGImageRef imageRef = self.CGImage;
    if (!imageRef) {
        return nil;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || width > WEBP_MAX_DIMENSION) {
        return nil;
    }
    if (height == 0 || height > WEBP_MAX_DIMENSION) {
        return nil;
    }
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    size_t components = bitsPerPixel / bitsPerComponent;
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    BOOL byteOrderNormal = NO;
    switch (byteOrderInfo) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: break;
    }
    // If we can not get bitmap buffer, early return
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    if (!dataProvider) {
        return nil;
    }
    
    BOOL isRGB = CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelRGB;
    BOOL isRGB888 = isRGB && byteOrderNormal && alphaInfo == kCGImageAlphaNone && components == 3;
    BOOL isRGBA8888 = isRGB && byteOrderNormal && alphaInfo == kCGImageAlphaLast && components == 4;
    CFDataRef dataRef;
    uint8_t *rgba = NULL;
    // We could not assume that input CGImage's color mode is always RGB888/RGBA8888. Convert all other cases to target color mode using vImage
    if (isRGB888 || isRGBA8888) {
        dataRef = CGDataProviderCopyData(dataProvider);
        if (!dataRef) {
            return nil;
        }
        // If the input CGImage is already RGB888/RGBA8888
        rgba = (uint8_t *)CFDataGetBytePtr(dataRef);
    } else {
        // Convert all other cases to target color mode using vImage
        vImageConverterRef convertor = NULL;
        vImage_Error error = kvImageNoError;
        
        vImage_CGImageFormat srcFormat = {
            .bitsPerComponent = (uint32_t)bitsPerComponent,
            .bitsPerPixel = (uint32_t)bitsPerPixel,
            .colorSpace = colorSpace,
            .bitmapInfo = bitmapInfo,
            .renderingIntent = CGImageGetRenderingIntent(imageRef)
        };
        
        CGColorSpaceRef colorSpace;
        if (@available(iOS 9.0, tvOS 9.0, *)) {
            colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        } else {
            colorSpace = CGColorSpaceCreateDeviceRGB();
        }
        vImage_CGImageFormat destFormat = {
            .bitsPerComponent = 8,
            .bitsPerPixel = hasAlpha ? 32 : 24,
            .colorSpace = colorSpace,
            .bitmapInfo = hasAlpha ? kCGImageAlphaLast | kCGBitmapByteOrderDefault : kCGImageAlphaNone | kCGBitmapByteOrderDefault // RGB888/RGBA8888 (Non-premultiplied to works for libwebp)
        };
        
        convertor = vImageConverter_CreateWithCGImageFormat(&srcFormat, &destFormat, NULL, kvImageNoFlags, &error);
        if (error != kvImageNoError) {
            return nil;
        }
        
        vImage_Buffer src;
        error = vImageBuffer_InitWithCGImage(&src, &srcFormat, nil, imageRef, kvImageNoFlags);
        if (error != kvImageNoError) {
            vImageConverter_Release(convertor);
            free(src.data);
            return nil;
        }

        vImage_Buffer dest;
        
        error = vImageBuffer_Init(&dest, height, width, destFormat.bitsPerPixel, kvImageNoFlags);
        if (error != kvImageNoError) {
            vImageConverter_Release(convertor);
            free(src.data);
            return nil;
        }
        
        // Convert input color mode to RGB888/RGBA8888
        error = vImageConvert_AnyToAny(convertor, &src, &dest, NULL, kvImageNoFlags);
        free(src.data);
        vImageConverter_Release(convertor);
        if (error != kvImageNoError) {
            free(dest.data);
            return nil;
        }
        rgba = dest.data; // Converted buffer
        bytesPerRow = dest.rowBytes; // Converted bytePerRow
        dataRef = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, rgba, bytesPerRow * height, kCFAllocatorDefault);;
    }
    
    uint8_t *data = NULL; // Output WebP data
    // Encode RGB888/RGBA8888 buffer to WebP data
    size_t size;
    if (hasAlpha) {
        size = WebPEncodeRGBA(rgba, (int)width, (int)height, (int)bytesPerRow, qualityFactor, &data);
    } else {
        size = WebPEncodeRGB(rgba, (int)width, (int)height, (int)bytesPerRow, qualityFactor, &data);
    }
    if (dataRef) {
        CFRelease(dataRef); // free non-converted rgba buffer
        dataRef = NULL;
    }
    
    if (size) {
        // success
        webpData = [NSData dataWithBytes:data length:size];
    }
    if (data) {
        WebPFree(data);
    }
    
    return webpData;
}

- (BOOL)_imageIOAvaliableType:(BDImageCodeType)codeType {
    switch (codeType) {
        case BDImageCodeTypeJPEG:
        case BDImageCodeTypeJPEG2000:
        case BDImageCodeTypeTIFF:
        case BDImageCodeTypeBMP:
        case BDImageCodeTypeICO:
        case BDImageCodeTypeICNS:
        case BDImageCodeTypeGIF:
        case BDImageCodeTypePNG:
        case BDImageCodeTypeHeif:
        case BDImageCodeTypeHeic: {
            return YES;
            break;
        }
        default:
            return NO;
            break;
    }
}


@end
