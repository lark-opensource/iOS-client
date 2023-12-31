//
//  CJPayCardOCRUtil.m
//  CJPay
//
//  Created by 尚怀军 on 2020/5/21.
//

#import "CJPayCardOCRUtil.h"
#import "CJPayUIMacro.h"

@implementation CJPayCardOCRUtil

// 异步压缩图片 size单位为KB
+ (void)compressWithImage:(UIImage *)image
                     size:(CGFloat)size
          completionBlock:(void(^)(NSData *imageData))completionBlock {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *compressImageData = [self compressSizeWithImage:image size:size minScale:0.5];
        if (compressImageData.length / 1024 > size) {
            compressImageData = [self compressQualityWithImage:[UIImage imageWithData:compressImageData] size:size minQuality:0.5];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CJ_CALL_BLOCK(completionBlock, compressImageData);
        });
    });
}

+ (void)compressWithImageV2:(UIImage *)image
                     size:(CGFloat)size
            completionBlock:(void(^)(NSData *imageData))completionBlock {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *resImage = [self resizeScaleImage:image scale:0.1 size:size];
        dispatch_async(dispatch_get_main_queue(), ^{
            CJ_CALL_BLOCK(completionBlock, UIImageJPEGRepresentation(resImage, 1.0));
        });
    });
}
// 压质量
+ (NSData *)compressQualityWithImage:(UIImage *)image
                                size:(CGFloat)size
                          minQuality:(CGFloat)minimumQuality {
    NSData * imgData;
    CGFloat imgDataBytes;
    CGFloat maxQuality = 1;
    CGFloat minQuality = minimumQuality;
    CGFloat curQuality = (maxQuality + minQuality) / 2;
    while (maxQuality - minQuality >= 0.01) {
        @autoreleasepool {
            imgData = UIImageJPEGRepresentation(image, curQuality);
            imgDataBytes = imgData.length / 1024;
            if (imgDataBytes == size) {
                break;
            }
            
            if (imgDataBytes > size ) {
                maxQuality = curQuality;
            } else {
                minQuality = curQuality;
            }
            curQuality = (maxQuality + minQuality) / 2;
        }
    }
    return imgData;
}

+ (UIImage *)resizeScaleImage:(UIImage *)iamgeOri scale:(CGFloat)scale size:(CGFloat) size{
    UIImage *originalImage = iamgeOri;
    UIImage *resultImg = iamgeOri;
    @autoreleasepool {
        CGSize imgSize = resultImg.size;
        NSData *imageData = UIImageJPEGRepresentation(resultImg, 1.0);
        CGFloat targetMinEdge = sqrtf(size * 1024 / (MAX(imgSize.width, imgSize.height) / MIN(imgSize.width, imgSize.height)));
        CGFloat targetScale = targetMinEdge / MIN(imgSize.width, imgSize.height);
        CGSize targetSize = CGSizeMake(imgSize.width * targetScale, imgSize.height * targetScale);
        
        CFDataRef data = (__bridge CFDataRef)imageData;
        CFStringRef optionKeys[1];
        CFTypeRef optionValues[4];
        optionKeys[0] = kCGImageSourceShouldCache;
        optionValues[0] = (CFTypeRef)kCFBooleanFalse;
        CFDictionaryRef sourceOption = CFDictionaryCreate(kCFAllocatorDefault, (const void **)optionKeys, (const void **)optionValues, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CGImageSourceRef imageSource = CGImageSourceCreateWithData(data, sourceOption);
        CFRelease(sourceOption);
        if (!imageSource) {
            CJPayLogInfo(@"imageSource is Null!");
            return nil;
        }
        //获取原图片属性
        int imageSize = (int)MAX(targetSize.height, targetSize.width);
        CFStringRef keys[5];
        CFTypeRef values[5];
        //创建缩略图等比缩放大小，会根据长宽值比较大的作为imageSize进行缩放
        keys[0] = kCGImageSourceThumbnailMaxPixelSize;
        CFNumberRef thumbnailSize = CFNumberCreate(NULL, kCFNumberIntType, &imageSize);
        values[0] = (CFTypeRef)thumbnailSize;
        keys[1] = kCGImageSourceCreateThumbnailFromImageAlways;
        values[1] = (CFTypeRef)kCFBooleanTrue;
        keys[2] = kCGImageSourceCreateThumbnailWithTransform;
        values[2] = (CFTypeRef)kCFBooleanTrue;
        keys[3] = kCGImageSourceCreateThumbnailFromImageIfAbsent;
        values[3] = (CFTypeRef)kCFBooleanTrue;
        keys[4] = kCGImageSourceShouldCacheImmediately;
        values[4] = (CFTypeRef)kCFBooleanTrue;
        
        CFDictionaryRef options = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)values, 4, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CGImageRef thumbnailImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options);
        resultImg = [UIImage imageWithCGImage:thumbnailImage];
        CFRelease(thumbnailSize);
        CFRelease(options);
        CFRelease(imageSource);
        CFRelease(thumbnailImage);
    }
    
    return resultImg;
}

// 缩大小
+ (NSData *)compressSizeWithImage:(UIImage *)image
                             size:(CGFloat)size
                         minScale:(CGFloat)minimumScale {
    NSData * imgData;
    CGFloat imgDataBytes;
    UIImage *scaleImage;
    CGFloat maxScale = 1;
    CGFloat minScale = minimumScale;
    CGFloat curScale = (maxScale + minScale) / 2;
    
    while (maxScale - minScale >= 0.01) {
        @autoreleasepool {
            scaleImage = [image cj_scaleToSize:CGSizeMake(image.size.width * curScale, image.size.height * curScale)];
            imgData = UIImageJPEGRepresentation(scaleImage, 1);
            imgDataBytes = imgData.length / 1024;
            if (imgDataBytes == size) {
                break;
            }
            
            if (imgDataBytes > size ) {
                maxScale = curScale;
            } else {
                minScale = curScale;
            }
            curScale = (maxScale + minScale) / 2;
        }
    }
    return imgData;
}

@end
