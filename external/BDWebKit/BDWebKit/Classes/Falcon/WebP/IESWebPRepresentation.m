//
//  IESWebPRepresentation.m
//  IESWebKit
//
//  Created by li keliang on 2018/10/12.
//

#import "IESWebPRepresentation.h"
#import <BDWebCore/IWKUtils.h>

#if __has_include(<webp/decode.h>)
#import <webp/decode.h>
#import <webp/encode.h>
#import <webp/demux.h>
#import <webp/mux.h>
#else
#import <libwebp/decode.h>
#import <libwebp/encode.h>
#import <libwebp/demux.h>
#import <libwebp/mux.h>
#endif

#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>


static CGColorSpaceRef IESSharedCGColorSpace(void);
static UIImage * __nullable IESDrawnWebPImageWithCanvas(CGContextRef canvas, WebPIterator iter);
static UIImage * __nullable IESRawWebPImageWithData(WebPData webpData);
static void cleanupBuffer(void *info, const void *data, size_t size);

BOOL IESDataIsWebPFormat(NSData * __nonnull webPData) {
    const NSInteger length = 12; //R, I, F, F, -, -, -, -, W, E, B, P
    Byte firstBytes[length];
    if ([webPData length] >= length) {
        [webPData getBytes:&firstBytes length:length];
        if (firstBytes[0] == 0x52 && firstBytes[1] == 0x49 && firstBytes[2] == 0x46 && firstBytes[3] == 0x46 && firstBytes[8] == 0x57 && firstBytes[9] == 0x45 && firstBytes[10] == 0x42 && firstBytes[11] == 0x50) {
            return YES;
        }
    }
    return NO;
}

NSData * __nullable IESConvertDataWebP2APNG(NSData * __nonnull data, NSError * __autoreleasing *error) {
    NSCParameterAssert(data);
    
    if (!IESDataIsWebPFormat(data)) {
        return nil;
    }
#if DEBUG
    NSTimeInterval _time = [NSDate date].timeIntervalSince1970;
    @IWK_onExit{
        NSLog(@"[Falcon] WebP：%lf", [NSDate date].timeIntervalSince1970 - _time);
    };
#endif
    
    WebPData webpData;
    WebPDataInit(&webpData);
    webpData.bytes = data.bytes;
    webpData.size = data.length;
    WebPDemuxer *demuxer = WebPDemux(&webpData);
    if (!demuxer) {
        return nil;
    }
    
    uint32_t flags = WebPDemuxGetI(demuxer, WEBP_FF_FORMAT_FLAGS);
    
    if (!(flags & ANIMATION_FLAG)) {
        NSMutableData *mutableData = [NSMutableData data];
        CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData, kUTTypePNG, 1, NULL);
        
        if (!imageDestination) {
            return nil;
        }
        
        NSDictionary *properties = @{ (__bridge NSString *)kCGImagePropertyPNGDictionary: @{} };
        
        CGImageDestinationSetProperties(imageDestination, (__bridge CFDictionaryRef)properties);
        
        WebPDecoderConfig config;
        if (!WebPInitDecoderConfig(&config)) {
            return nil;
        }
        
        if (WebPGetFeatures(webpData.bytes, webpData.size, &config.input) != VP8_STATUS_OK) {
            return nil;
        }
        
        config.output.colorspace = config.input.has_alpha ? MODE_rgbA : MODE_RGB;
        config.options.use_threads = 1;
        
        if (WebPDecode(webpData.bytes, webpData.size, &config) != VP8_STATUS_OK) {
            return nil;
        }
        
        int width = config.input.width;
        int height = config.input.height;
        
        CGBitmapInfo bitmapInfo;
        // `CGBitmapContextCreate` does not support RGB888 on iOS. Where `CGImageCreate` supports.
        if (!config.input.has_alpha) {
            // RGB888
            bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNone;
        } else {
            // RGBA8888
            bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
        }
        
        if (config.options.use_scaling) {
            width = config.options.scaled_width;
            height = config.options.scaled_height;
        }
        
        CGDataProviderRef provider =
        CGDataProviderCreateWithData(NULL, config.output.u.RGBA.rgba, config.output.u.RGBA.size, cleanupBuffer);
        CGColorSpaceRef colorSpaceRef = IESSharedCGColorSpace();

        size_t components = config.input.has_alpha ? 4 : 3;
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        CGImageRef imageRef = CGImageCreate(width, height, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
        
        
        NSDictionary *frameProperty = @{(id)kCGImageDestinationLossyCompressionQuality : @(1), (id)(kCGImagePropertyHasAlpha): @(flags & ALPHA_FLAG), (id)(kCGImagePropertyOrientation) : @(1)};
        CGImageDestinationAddImage(imageDestination, imageRef, (CFDictionaryRef)frameProperty);
        
        if (CGImageDestinationFinalize(imageDestination) == NO) {
            mutableData = nil;
        }
        CFRelease(imageDestination);
        CGDataProviderRelease(provider);
        
        WebPDemuxDelete(demuxer);
        return [mutableData copy];
    } else {
        int canvasWidth = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
        int canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
        int loopCount = WebPDemuxGetI(demuxer, WEBP_FF_LOOP_COUNT);
        
        CGBitmapInfo bitmapInfo;
        if (!(flags & ALPHA_FLAG)) {
            bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
        } else {
            bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
        }
        CGContextRef canvas = CGBitmapContextCreate(NULL, canvasWidth, canvasHeight, 8, 0, IESSharedCGColorSpace(), bitmapInfo);
        if (!canvas) {
            WebPDemuxDelete(demuxer);
            return nil;
        }
        
        WebPIterator iter;
        if (!WebPDemuxGetFrame(demuxer, 1, &iter)) {
            WebPDemuxReleaseIterator(&iter);
            WebPDemuxDelete(demuxer);
            CGContextRelease(canvas);
            return nil;
        }
        
        
        NSMutableData *mutableData = [NSMutableData data];
        CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData, kUTTypeGIF, iter.num_frames, NULL);
        
        NSDictionary *properties = @{ (__bridge NSString *)kCGImagePropertyGIFDictionary: @{ (__bridge NSString *)kCGImagePropertyGIFLoopCount : @(loopCount)} };
        
        CGImageDestinationSetProperties(imageDestination, (__bridge CFDictionaryRef)properties);
        
        do {
            @autoreleasepool {
                UIImage *image = IESDrawnWebPImageWithCanvas(canvas, iter);
                CGImageRef imageRef = image.CGImage;
                if (!imageRef) {
                    continue;
                }
                
                int frameDuration = iter.duration;
                if (frameDuration <= 10) {
                    frameDuration = 100;
                }
                
                NSDictionary *frameProperty = @{(__bridge NSString *)kCGImagePropertyGIFDictionary : @{(__bridge NSString *)kCGImagePropertyGIFDelayTime : @(frameDuration / 1000.f)}};
                
                CGImageDestinationAddImage(imageDestination, imageRef, (CFDictionaryRef)frameProperty);
            }
        } while (WebPDemuxNextFrame(&iter));
        
        if (CGImageDestinationFinalize(imageDestination) == NO) {
            mutableData = nil;
        }
        CFRelease(imageDestination);
        
        WebPDemuxReleaseIterator(&iter);
        WebPDemuxDelete(demuxer);
        CGContextRelease(canvas);
        
        return [mutableData copy];
    }
}

#pragma mark - Private

static CGColorSpaceRef IESSharedCGColorSpace(void) {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    });
    return colorSpace;
}

static void cleanupBuffer(void *info, const void *data, size_t size) {
    free((void *)data);
}

static UIImage * __nullable IESRawWebPImageWithData(WebPData webpData) {
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }
    
    if (WebPGetFeatures(webpData.bytes, webpData.size, &config.input) != VP8_STATUS_OK) {
        return nil;
    }
    
    config.output.colorspace = config.input.has_alpha ? MODE_rgbA : MODE_RGB;
    config.options.use_threads = 1;
    
    // Decode the WebP image data into a RGBA value array
    if (WebPDecode(webpData.bytes, webpData.size, &config) != VP8_STATUS_OK) {
        return nil;
    }
    
    int width = config.input.width;
    int height = config.input.height;
    if (config.options.use_scaling) {
        width = config.options.scaled_width;
        height = config.options.scaled_height;
    }
    
    // Construct a UIImage from the decoded RGBA value array
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, config.output.u.RGBA.rgba, config.output.u.RGBA.size, cleanupBuffer);
    CGColorSpaceRef colorSpaceRef = IESSharedCGColorSpace();
    CGBitmapInfo bitmapInfo;
    // `CGBitmapContextCreate` does not support RGB888 on iOS. Where `CGImageCreate` supports.
    if (!config.input.has_alpha) {
        // RGB888
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNone;
    } else {
        // RGBA8888
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
    }
    size_t components = config.input.has_alpha ? 4 : 3;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    CGDataProviderRelease(provider);
    
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return image;
}

static UIImage * __nullable IESDrawnWebPImageWithCanvas(CGContextRef canvas, WebPIterator iter) {
    UIImage *image = IESRawWebPImageWithData(iter.fragment);
    if (!image) {
        return nil;
    }
    
    size_t canvasWidth = CGBitmapContextGetWidth(canvas);
    size_t canvasHeight = CGBitmapContextGetHeight(canvas);
    CGSize size = CGSizeMake(canvasWidth, canvasHeight);
    CGFloat tmpX = iter.x_offset;
    CGFloat tmpY = size.height - iter.height - iter.y_offset;
    CGRect imageRect = CGRectMake(tmpX, tmpY, iter.width, iter.height);
    BOOL shouldBlend = iter.blend_method == WEBP_MUX_BLEND;
    
    if (!shouldBlend) {
        CGContextClearRect(canvas, imageRect);
    }
    CGContextDrawImage(canvas, imageRect, image.CGImage);
    CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);
    
    image = [[UIImage alloc] initWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    
    if (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
        CGContextClearRect(canvas, imageRect);
    }
    
    return image;
}

