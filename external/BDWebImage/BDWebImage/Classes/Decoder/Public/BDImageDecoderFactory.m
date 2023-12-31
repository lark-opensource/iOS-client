//
//  BDImageDecoderFactory.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/29.
//

#import "BDImageDecoderFactory.h"
#import "BDImageDecoder.h"
#import "BDImageDecoderImageIO.h"
#import "BDImageDecoderWebP.h"
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif
#import "BDWebImageManager.h"
#if __has_include("BDBaseInternal.h")
#import <BDAlogProtocol/BDAlogProtocol.h>
#endif

static NSString *TAG = @"BDWebImage";

#define YY_FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))
#define YY_TWO_CC(c1,c2) ((uint16_t)(((c2) << 8) | (c1)))

static const size_t kBytesPerPixel = 4;
static const size_t kBitsPerComponent = 8;

/*
 * Defines the maximum size in MB of the decoded image when the flag `SDWebImageScaleDownLargeImages` is set
 * Suggested value for iPad1 and iPhone 3GS: 60.
 * Suggested value for iPad2 and iPhone 4: 120.
 * Suggested value for iPhone 3G and iPod 2 and earlier devices: 30.
 */
static const CGFloat kDestImageSizeMB = 60.0f;

/*
 * Defines the maximum size in MB of a tile used to decode image when the flag `SDWebImageScaleDownLargeImages` is set
 * Suggested value for iPad1 and iPhone 3GS: 20.
 * Suggested value for iPad2 and iPhone 4: 40.
 * Suggested value for iPhone 3G and iPod 2 and earlier devices: 10.
 */
static const CGFloat kSourceImageTileSizeMB = 20.0f;

static const CGFloat kBytesPerMB = 1024.0f * 1024.0f;
static const CGFloat kPixelsPerMB = kBytesPerMB / kBytesPerPixel;
static const CGFloat kDestTotalPixels = kDestImageSizeMB * kPixelsPerMB;
static const CGFloat kTileTotalPixels = kSourceImageTileSizeMB * kPixelsPerMB;

static const CGFloat kDestSeemOverlap = 2.0f;   // the numbers of pixels to overlap the seems where tiles meet.

CGColorSpaceRef BDCGColorSpaceGetDeviceRGB(void) {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 9.0, *)) {
            colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        } else {
            colorSpace = CGColorSpaceCreateDeviceRGB();
        }
    });
    return colorSpace;
}

CGImageRef BDCGImageCreateDecodedCopy(CGImageRef imageRef, BOOL decodeForDisplay) {
    if (!imageRef) return NULL;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || height == 0) return NULL;
    
    if (decodeForDisplay) { //decode with redraw (may lose some precision)
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
        BOOL hasAlpha = NO;
        if (alphaInfo == kCGImageAlphaPremultipliedLast ||
            alphaInfo == kCGImageAlphaPremultipliedFirst ||
            alphaInfo == kCGImageAlphaLast ||
            alphaInfo == kCGImageAlphaFirst) {
            hasAlpha = YES;
        }
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, BDCGColorSpaceGetDeviceRGB(), bitmapInfo);
        if (!context) return NULL;
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef); // decode
        CGImageRef newImage = CGBitmapContextCreateImage(context);
        CFRelease(context);
        return newImage;
        
    } else {
        CGColorSpaceRef space = CGImageGetColorSpace(imageRef);
        size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
        size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
        size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
        if (bytesPerRow == 0 || width == 0 || height == 0) return NULL;
        
        CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
        if (!dataProvider) return NULL;
        CFDataRef data = CGDataProviderCopyData(dataProvider); // decode
        if (!data) return NULL;
        
        CGDataProviderRef newProvider = CGDataProviderCreateWithCFData(data);
        CFRelease(data);
        if (!newProvider) return NULL;
        
        CGImageRef newImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, space, bitmapInfo, newProvider, NULL, false, kCGRenderingIntentDefault);
        CFRelease(newProvider);
        return newImage;
    }
}

BOOL BDCGImageRefContainsAlpha(CGImageRef imageRef) {
    if (!imageRef) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

BOOL BDCGImageShouldScaleDownImage(CGImageRef sourceImageRef) {
    BOOL shouldScaleDown = YES;
    
    CGSize sourceResolution = CGSizeZero;
    sourceResolution.width = CGImageGetWidth(sourceImageRef);
    sourceResolution.height = CGImageGetHeight(sourceImageRef);
    float sourceTotalPixels = sourceResolution.width * sourceResolution.height;
    float imageScale = kDestTotalPixels / sourceTotalPixels;
    if (imageScale < 1) {
        shouldScaleDown = YES;
    } else {
        shouldScaleDown = NO;
    }
    
    return shouldScaleDown;
}
CGImageRef BDCGImageDecompressedAndScaledDownImageCreate(CGImageRef imageRef, BOOL *isDidScaleDown) {
    if (!BDCGImageShouldScaleDownImage(imageRef)) {
        CGImageRef decodedImgRef = BDCGImageCreateDecodedCopy(imageRef, YES);
        return decodedImgRef;
    }
    
    CGContextRef destContext;
    
    // autorelease the bitmap context and all vars to help system to free memory when there are memory warning.
    // on iOS7, do not forget to call [[SDImageCache sharedImageCache] clearMemory];
    @autoreleasepool {
        CGImageRef sourceImageRef = imageRef;
        
        CGSize sourceResolution = CGSizeZero;
        sourceResolution.width = CGImageGetWidth(sourceImageRef);
        sourceResolution.height = CGImageGetHeight(sourceImageRef);
        CGFloat sourceTotalPixels = sourceResolution.width * sourceResolution.height;
        // Determine the scale ratio to apply to the input image
        // that results in an output image of the defined size.
        // see kDestImageSizeMB, and how it relates to destTotalPixels.
        CGFloat imageScale = sqrt(kDestTotalPixels / sourceTotalPixels);
        CGSize destResolution = CGSizeZero;
        destResolution.width = (int)(sourceResolution.width * imageScale);
        destResolution.height = (int)(sourceResolution.height * imageScale);
        
        // device color space
        CGColorSpaceRef colorspaceRef = BDCGColorSpaceGetDeviceRGB();
        BOOL hasAlpha = BDCGImageRefContainsAlpha(sourceImageRef);
        // iOS display alpha info (BGRA8888/BGRX8888)
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        
        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use kCGImageAlphaNoneSkipLast
        // to create bitmap graphics contexts without alpha info.
        destContext = CGBitmapContextCreate(NULL,
                                            destResolution.width,
                                            destResolution.height,
                                            kBitsPerComponent,
                                            0,
                                            colorspaceRef,
                                            bitmapInfo);
        
        if (destContext == NULL) {
            CGImageRetain(imageRef);
            return imageRef;
        }
        CGContextSetInterpolationQuality(destContext, kCGInterpolationHigh);
        
        // Now define the size of the rectangle to be used for the
        // incremental blits from the input image to the output image.
        // we use a source tile width equal to the width of the source
        // image due to the way that iOS retrieves image data from disk.
        // iOS must decode an image from disk in full width 'bands', even
        // if current graphics context is clipped to a subrect within that
        // band. Therefore we fully utilize all of the pixel data that results
        // from a decoding opertion by achnoring our tile size to the full
        // width of the input image.
        CGRect sourceTile = CGRectZero;
        sourceTile.size.width = sourceResolution.width;
        // The source tile height is dynamic. Since we specified the size
        // of the source tile in MB, see how many rows of pixels high it
        // can be given the input image width.
        sourceTile.size.height = (int)(kTileTotalPixels / sourceTile.size.width );
        sourceTile.origin.x = 0.0f;
        // The output tile is the same proportions as the input tile, but
        // scaled to image scale.
        CGRect destTile;
        destTile.size.width = destResolution.width;
        destTile.size.height = sourceTile.size.height * imageScale;
        destTile.origin.x = 0.0f;
        // The source seem overlap is proportionate to the destination seem overlap.
        // this is the amount of pixels to overlap each tile as we assemble the ouput image.
        float sourceSeemOverlap = (int)((kDestSeemOverlap/destResolution.height)*sourceResolution.height);
        CGImageRef sourceTileImageRef;
        // calculate the number of read/write operations required to assemble the
        // output image.
        int iterations = (int)( sourceResolution.height / sourceTile.size.height );
        // If tile height doesn't divide the image height evenly, add another iteration
        // to account for the remaining pixels.
        int remainder = (int)sourceResolution.height % (int)sourceTile.size.height;
        if(remainder) {
            iterations++;
        }
        // Add seem overlaps to the tiles, but save the original tile height for y coordinate calculations.
        float sourceTileHeightMinusOverlap = sourceTile.size.height;
        sourceTile.size.height += sourceSeemOverlap;
        destTile.size.height += kDestSeemOverlap;
        for( int y = 0; y < iterations; ++y ) {
            @autoreleasepool {
                sourceTile.origin.y = y * sourceTileHeightMinusOverlap + sourceSeemOverlap;
                destTile.origin.y = destResolution.height - (( y + 1 ) * sourceTileHeightMinusOverlap * imageScale + kDestSeemOverlap);
                sourceTileImageRef = CGImageCreateWithImageInRect( sourceImageRef, sourceTile );
                if( y == iterations - 1 && remainder ) {
                    float dify = destTile.size.height;
                    destTile.size.height = CGImageGetHeight( sourceTileImageRef ) * imageScale;
                    dify -= destTile.size.height;
                    destTile.origin.y += dify;
                }
                CGContextDrawImage( destContext, destTile, sourceTileImageRef );
                CGImageRelease( sourceTileImageRef );
            }
        }
        
        CGImageRef destImageRef = CGBitmapContextCreateImage(destContext);
        CGContextRelease(destContext);
        if (destImageRef == NULL) {
            CGImageRetain(imageRef);
            return imageRef;
        }
        *isDidScaleDown = YES;
        return destImageRef;
    }
}

CFStringRef BDUTTypeFromBDImageType(BDImageCodeType type) {
    switch (type) {
        case BDImageCodeTypeJPEG:
            return kUTTypeJPEG;
        case BDImageCodeTypePNG:
            return kUTTypePNG;
        case BDImageCodeTypeBMP:
            return kUTTypeBMP;
        case BDImageCodeTypeGIF:
            return kUTTypeGIF;
        case BDImageCodeTypeICO:
            return kUTTypeICO;
        case BDImageCodeTypeICNS:
            return kUTTypeAppleICNS;
        case BDImageCodeTypeTIFF:
            return kUTTypeTIFF;
        case BDImageCodeTypeJPEG2000:
            return kUTTypeJPEG2000;
        case BDImageCodeTypeWebP:
            return kBDUTTypeWebP;
        case BDImageCodeTypeHeic:
            return kBDUTTypeHEIC;
        case BDImageCodeTypeHeif:
            return kBDUTTypeHEIF;
        default:
            return kUTTypePNG;
    }
}

BDImageCodeType BDImageDetectType(CFDataRef data) {
    if (!data) return BDImageCodeTypeUnknown;
    CFIndex length = CFDataGetLength(data);
    if (length < 16) return BDImageCodeTypeUnknown;
    
    const char *bytes = (char *)CFDataGetBytePtr(data);
    
    // JPG             FF D8 FF
    if (memcmp(bytes,"\377\330\377",3) == 0) return BDImageCodeTypeJPEG;
    
    // JP2
    if (memcmp(bytes + 4, "\152\120\040\040\015", 5) == 0) return BDImageCodeTypeJPEG2000;
    
    uint32_t magic4 = *((uint32_t *)bytes);
    switch (magic4) {
        case YY_FOUR_CC(0x4D, 0x4D, 0x00, 0x2A): { // big endian TIFF
            return BDImageCodeTypeTIFF;
        } break;
            
        case YY_FOUR_CC(0x49, 0x49, 0x2A, 0x00): { // little endian TIFF
            return BDImageCodeTypeTIFF;
        } break;
            
        case YY_FOUR_CC(0x00, 0x00, 0x01, 0x00): { // ICO
            return BDImageCodeTypeICO;
        } break;
            
        case YY_FOUR_CC(0x00, 0x00, 0x02, 0x00): { // CUR
            return BDImageCodeTypeICO;
        } break;
            
        case YY_FOUR_CC('i', 'c', 'n', 's'): { // ICNS
            return BDImageCodeTypeICNS;
        } break;
            
        case YY_FOUR_CC('G', 'I', 'F', '8'): { // GIF
            return BDImageCodeTypeGIF;
        } break;
            
        case YY_FOUR_CC(0x89, 'P', 'N', 'G'): {  // PNG
            uint32_t tmp = *((uint32_t *)(bytes + 4));
            if (tmp == YY_FOUR_CC('\r', '\n', 0x1A, '\n')) {
                return BDImageCodeTypePNG;
            }
        } break;
            
        case YY_FOUR_CC('R', 'I', 'F', 'F'): { // WebP
            uint32_t tmp = *((uint32_t *)(bytes + 8));
            if (tmp == YY_FOUR_CC('W', 'E', 'B', 'P')) {
                return BDImageCodeTypeWebP;
            }
        } break;
    }
    
    uint16_t magic2 = *((uint16_t *)bytes);
    switch (magic2) {
        case YY_TWO_CC('B', 'A'):
        case YY_TWO_CC('B', 'M'):
        case YY_TWO_CC('I', 'C'):
        case YY_TWO_CC('P', 'I'):
        case YY_TWO_CC('C', 'I'):
        case YY_TWO_CC('C', 'P'): { // BMP
            return BDImageCodeTypeBMP;
        }
        case YY_TWO_CC(0xFF, 0x4F): { // JPEG2000
            return BDImageCodeTypeJPEG2000;
        }
    }
    uint8_t c = *((uint8_t *)bytes);
    if (c == 0x00) {
        if (length >= 12) {
            //http://nokiatech.github.io/heif/technical.html
            //....ftypheic ....ftypheix ....ftyphevc ....ftyphevx（ImageIO）; mif1,msf1（libttheif_dec）
            uint32_t ftmp = *((uint32_t *)(bytes + 4));
            if (ftmp == YY_FOUR_CC('f', 't', 'y', 'p')) {
                uint32_t etmp = *((uint32_t *)(bytes + 8));
                switch (etmp) {
                    case YY_FOUR_CC('h', 'e', 'i', 'c'):
                    case YY_FOUR_CC('h', 'e', 'i', 'x'):
                    case YY_FOUR_CC('h', 'e', 'v', 'c'):
                    case YY_FOUR_CC('h', 'e', 'v', 'x'):
                        return BDImageCodeTypeHeic;
                    case YY_FOUR_CC('m', 'i', 'f', '1'):
                    case YY_FOUR_CC('m', 's', 'f', '1'):
                        return BDImageCodeTypeHeif;
                }
            }
        }
    }
    
    // AVIF
    Class<BDImageDecoder> cls = NSClassFromString(@"BDImageDecoderAVIF");
    if (cls && [cls respondsToSelector:@selector(canDecode:)] && [cls canDecode:(__bridge NSData *)data]) {
        return BDImageCodeTypeAVIF;
    }
    
    return BDImageCodeTypeUnknown;
}


UIImageOrientation BDUIImageOrientationFromEXIFOrientation(NSUInteger exifOrientation)
{
    // CGImagePropertyOrientation is available on iOS 8 above.
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    switch (exifOrientation) {
        case kCGImagePropertyOrientationUp:
            imageOrientation = UIImageOrientationUp;
            break;
        case kCGImagePropertyOrientationDown:
            imageOrientation = UIImageOrientationDown;
            break;
        case kCGImagePropertyOrientationLeft:
            imageOrientation = UIImageOrientationLeft;
            break;
        case kCGImagePropertyOrientationRight:
            imageOrientation = UIImageOrientationRight;
            break;
        case kCGImagePropertyOrientationUpMirrored:
            imageOrientation = UIImageOrientationUpMirrored;
            break;
        case kCGImagePropertyOrientationDownMirrored:
            imageOrientation = UIImageOrientationDownMirrored;
            break;
        case kCGImagePropertyOrientationLeftMirrored:
            imageOrientation = UIImageOrientationLeftMirrored;
            break;
        case kCGImagePropertyOrientationRightMirrored:
            imageOrientation = UIImageOrientationRightMirrored;
            break;
        default:
            break;
    }
    return imageOrientation;
}

// Convert an iOS orientation to an EXIF image orientation.
CGImagePropertyOrientation BDExifOrientationFromImageOrientation(UIImageOrientation imageOrientation) {
    CGImagePropertyOrientation exifOrientation = kCGImagePropertyOrientationUp;
    switch (imageOrientation) {
        case UIImageOrientationUp:
            exifOrientation = kCGImagePropertyOrientationUp;
            break;
        case UIImageOrientationDown:
            exifOrientation = kCGImagePropertyOrientationDown;
            break;
        case UIImageOrientationLeft:
            exifOrientation = kCGImagePropertyOrientationLeft;
            break;
        case UIImageOrientationRight:
            exifOrientation = kCGImagePropertyOrientationRight;
            break;
        case UIImageOrientationUpMirrored:
            exifOrientation = kCGImagePropertyOrientationUpMirrored;
            break;
        case UIImageOrientationDownMirrored:
            exifOrientation = kCGImagePropertyOrientationDownMirrored;
            break;
        case UIImageOrientationLeftMirrored:
            exifOrientation = kCGImagePropertyOrientationLeftMirrored;
            break;
        case UIImageOrientationRightMirrored:
            exifOrientation = kCGImagePropertyOrientationRightMirrored;
            break;
        default:
            break;
    }
    return exifOrientation;
}

@implementation BDImageDecoderFactory

+ (Class)HEIFDecoderForData:(NSData *)data isStaticSystemFirst:(BOOL)isStaticSystemFirst isAnimatedCustomFirst:(BOOL)isAnimatedCustomFirst {
    Class decoder = nil;
    
    BOOL isAnimdtedImage = NO;
    BOOL canCustomDecode = NO;
    Class<BDImageDecoder> cls = NSClassFromString(@"BDImageDecoderHeic");
    if (cls) {
        if ([cls respondsToSelector:@selector(canDecode:)] && [cls canDecode:data]) {
            canCustomDecode = YES;
        }
        if ([cls respondsToSelector:@selector(isAnimatedImage:)] && [cls isAnimatedImage:data]) {
            isAnimdtedImage = YES;
        }
    }
    
    // 没有依赖 HEIC podspec 或者 无法解码
    if (!canCustomDecode) {
        if (@available(iOS 11.0, *)) {
            decoder = [BDImageDecoderImageIO class];
        }
        return decoder;
    }
    
    if (isAnimdtedImage) {
        // heif 动图系统解码仅在 iOS 13 以上支持，系统解码性能有问题，推荐用软解
        if (@available(iOS 13.0, *)) {
            decoder = [BDImageDecoderImageIO class];
        }
        // 兜底，iOS 低版本 / 业务方指定使用软解
        if (isAnimatedCustomFirst || decoder == nil) {
            decoder = cls;
        }
    } else {
        // heif 静图系统解码仅在 iOS 11 上支持
        if (@available(iOS 11.0, *)) {
            decoder = [BDImageDecoderImageIO class];
        }
        // iOS 11以下/业务方指定优先使用软解
        if (!isStaticSystemFirst || decoder == nil) {
            decoder = cls;
        }
    }
    
    return decoder;
}


/// 寻找适合这份图片数据的 AVIF 解码器
///
/// @param data 图片数据
+ (Class)AVIFDecoderForData:(NSData *)data {
    Class<BDImageDecoder> cls = NSClassFromString(@"BDImageDecoderAVIF");
    if (!cls) {
        return nil;
    }
    
    // 无法通过 runtime 反射出 AVIF decoder、或者该 decoder 无法解码该图片数据
    if (![cls respondsToSelector:@selector(canDecode:)] || ![cls canDecode:data]) {
        return nil;
    }
    
    return cls;
    
}

//这个地方 decoder 的生成不符合开闭原则，可以参考 SD 加入 canDecoderFromData 改进一下
+ (Class)decoderForImageData:(NSData *)data type:(BDImageCodeType *)type
{
    *type = BDImageDetectType((__bridge CFDataRef)data);
    switch (*type) {
        case BDImageCodeTypeUnknown:
        case BDImageCodeTypeJPEG:
        case BDImageCodeTypeJPEG2000:
        case BDImageCodeTypeTIFF:
        case BDImageCodeTypeBMP:
        case BDImageCodeTypeICO:
        case BDImageCodeTypeICNS:
        case BDImageCodeTypeGIF:
        case BDImageCodeTypePNG:
        {
            return [BDImageDecoderImageIO class];
            break;
        }
        case BDImageCodeTypeWebP:
        {
            return [BDImageDecoderWebP class];
            break;
        }
        case BDImageCodeTypeHeif:
        case BDImageCodeTypeHeic:
        {
            return [self HEIFDecoderForData:data isStaticSystemFirst:[BDWebImageManager sharedManager].isSystemHeicDecoderFirst isAnimatedCustomFirst:[BDWebImageManager sharedManager].isCustomSequenceHeicsDecoderFirst];
            break;
        }
        case BDImageCodeTypeAVIF: {
            return [self AVIFDecoderForData:data];
        }
        default:
            NSCAssert(NO, @"Attention, no decoder");
            return Nil;
            break;
    }
}

@end
