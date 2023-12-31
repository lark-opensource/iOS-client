//
//  WebpBridge.m
//  ByteWebImage
//
//  Created by xiongmin on 2021/5/10.
//
//  Included OSS: SDWebImageWebPCoder
//  Copyright (c) Olivier Poitrey <rs@dailymotion.com>
//  spdx license identifier: MIT

#import "WebpBridge.h"

#import <Accelerate/Accelerate.h>
#if __has_include(<libwebp/webp/demux.h>)
    #import <libwebp/webp/demux.h>
#elif __has_include(<libwebp/demux.h>)
    #import <libwebp/demux.h>
#endif
#import <pthread/pthread.h>
#import <ByteWebImage/ByteWebImage-Swift.h>

CGColorSpaceRef ByteCGColorSpaceGetDeviceRGB(void) {
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

CGImageRef ByteCGImageCreateDecodedCopy(CGImageRef imageRef, BOOL decodeForDisplay) {
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
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, ByteCGColorSpaceGetDeviceRGB(), bitmapInfo);
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

BOOL ByteCGImageRefContainsAlpha(CGImageRef imageRef) {
    if (!imageRef) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

BOOL ByteCGImageShouldScaleDownImage(CGImageRef sourceImageRef) {
    BOOL shouldScaleDown = YES;

    CGSize sourceResolution = CGSizeZero;
    sourceResolution.width = CGImageGetWidth(sourceImageRef);
    sourceResolution.height = CGImageGetHeight(sourceImageRef);
    float sourceTotalPixels = sourceResolution.width * sourceResolution.height;
    float imageScale = ImageDecoderUtilsBridge.destTotalPixels / sourceTotalPixels;
    if (imageScale < 1) {
        shouldScaleDown = YES;
    } else {
        shouldScaleDown = NO;
    }

    return shouldScaleDown;
}

CGImageRef ByteDecompressedAndScaledDownImageCreate(CGImageRef imageRef, BOOL *isDidScaleDown) {
    if (!ByteCGImageShouldScaleDownImage(imageRef)) {
        CGImageRef decodedImgRef = ByteCGImageCreateDecodedCopy(imageRef, YES);
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
        CGFloat imageScale = sqrt(ImageDecoderUtilsBridge.destTotalPixels / sourceTotalPixels);
        CGSize destResolution = CGSizeZero;
        destResolution.width = (int)(sourceResolution.width * imageScale);
        destResolution.height = (int)(sourceResolution.height * imageScale);

        // device color space
        CGColorSpaceRef colorspaceRef = ByteCGColorSpaceGetDeviceRGB();
        BOOL hasAlpha = ByteCGImageRefContainsAlpha(sourceImageRef);
        // iOS display alpha info (BGRA8888/BGRX8888)
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;

        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use kCGImageAlphaNoneSkipLast
        // to create bitmap graphics contexts without alpha info.
        destContext = CGBitmapContextCreate(NULL,
                                            destResolution.width,
                                            destResolution.height,
                                            ImageDecoderUtilsBridge.bitsPerComponent,
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
        sourceTile.size.height = (int)([ImageDecoderUtilsBridge tileTotalPixels] / sourceTile.size.width );
        sourceTile.origin.x = 0.0f;
        // The output tile is the same proportions as the input tile, but
        // scaled to image scale.
        CGRect destTile;
        destTile.size.width = destResolution.width;
        destTile.size.height = sourceTile.size.height * imageScale;
        destTile.origin.x = 0.0f;
        // The source seem overlap is proportionate to the destination seem overlap.
        // this is the amount of pixels to overlap each tile as we assemble the ouput image.
        float sourceSeemOverlap = (int)(([ImageDecoderUtilsBridge destSeemOverlap]/destResolution.height)*sourceResolution.height);
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
        destTile.size.height += [ImageDecoderUtilsBridge destSeemOverlap];
        for( int y = 0; y < iterations; ++y ) {
            @autoreleasepool {
                sourceTile.origin.y = y * sourceTileHeightMinusOverlap + sourceSeemOverlap;
                destTile.origin.y = destResolution.height - (( y + 1 ) * sourceTileHeightMinusOverlap * imageScale + [ImageDecoderUtilsBridge destSeemOverlap]);
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


static void ByteCGDataProviderReleaseDataCallback(void *info, const void *data, size_t size) {
    free((void *)data);
}

@interface WebpBridge () {
    WebPDemuxer *_webPDemux;

    CGContextRef _blendContext;
    NSUInteger _lastBlendIndex;
    CGColorSpaceRef _imageColorSpace;

    NSMutableDictionary *_durations;
    pthread_mutex_t _durations_lock;

    pthread_mutex_t _lock;
}

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSString *filePath;

@property (atomic, assign) NSUInteger imageNum;
@property (atomic, assign) NSUInteger loopNum;
@property (nonatomic, assign) CGSize originSize;
@property (nonatomic, assign) CGSize canvasSize;
@property (nonatomic, assign) BOOL didScaleDown;
@property (nonatomic, assign) BOOL hasCrop;
@property (nonatomic, assign) BOOL hasDownsample;


@property (atomic, assign) BOOL hasIncrementalData;
@property (atomic, assign) BOOL finished; // ProgressiveDownload end

@end

@implementation WebpBridge

- (void)dealloc {
    if (_webPDemux) {
        WebPDemuxDelete(_webPDemux);
    }
    if (_blendContext) {
        CGContextRelease(_blendContext);
    }
    if (_imageColorSpace) {
        CGColorSpaceRelease(_imageColorSpace);
    }
    pthread_mutex_destroy(&_durations_lock);
    pthread_mutex_destroy(&_lock);
}

- (instancetype)initWithContentOfFile:(NSString *)file {
    self = [self initWithData:[NSData dataWithContentsOfFile:file]];
    if (self) {
        self.filePath = file;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        NSData *internalData = [data copy] ?: [NSData data];
        self.data = internalData;
        WebPData webpData = {internalData.bytes, internalData.length};
        _webPDemux = WebPDemux(&webpData);
        if (!_webPDemux && ![ImageDecoderUtilsBridge forbiddenWebPPartial]) {
            WebPDemuxState state;
            _webPDemux = WebPDemuxPartial(&webpData, &state);
        }
        if (!_webPDemux) return nil;
        self.imageNum = WebPDemuxGetI(_webPDemux, WEBP_FF_FRAME_COUNT);
        self.loopNum = WebPDemuxGetI(_webPDemux, WEBP_FF_LOOP_COUNT);
        uint32_t canvasWidth = WebPDemuxGetI(_webPDemux, WEBP_FF_CANVAS_WIDTH);
        uint32_t canvasHeight = WebPDemuxGetI(_webPDemux, WEBP_FF_CANVAS_HEIGHT);
        self.originSize = CGSizeMake(canvasWidth, canvasHeight);
        self.canvasSize = CGSizeMake(canvasWidth, canvasHeight);
        _durations = [NSMutableDictionary dictionary];
        pthread_mutex_init(&_durations_lock, 0);
        pthread_mutex_init(&_lock, 0);
    }
    return self;
}

#pragma mark progress download

- (instancetype)initWithIncrementalData:(NSData *)data {
    self = [self initWithData:data];
    if (self) {
        self.hasIncrementalData = YES;
    }
    return self;
}

- (void)changeDecoderWithData:(NSData *)data finished:(BOOL)finished {
    pthread_mutex_lock(&_lock);
    self.data = [data copy];
    WebPData webpData = {self.data.bytes, self.data.length};
    if (_webPDemux) {
        WebPDemuxDelete(_webPDemux);
    }
    _webPDemux = WebPDemux(&webpData);
    if (!_webPDemux) {
        WebPDemuxState state;
        _webPDemux = WebPDemuxPartial(&webpData, &state);
    }
    if (!_webPDemux) {
        pthread_mutex_unlock(&_lock);
        return;
    }
    self.imageNum = WebPDemuxGetI(_webPDemux, WEBP_FF_FRAME_COUNT);
    self.loopNum = WebPDemuxGetI(_webPDemux, WEBP_FF_LOOP_COUNT);
    self.finished = finished;
    pthread_mutex_unlock(&_lock);
}

- (BOOL)progressiveDownloading {
    return self.hasIncrementalData && !self.finished;
}

#pragma mark decode

- (CGContextRef)blendContext
{
    CGColorSpaceRef colorSpace = ByteCGColorSpaceGetDeviceRGB();
    if (!_blendContext) {
        _blendContext = CGBitmapContextCreate(NULL, self.canvasSize.width, self.canvasSize.height, 8, 0, colorSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    }
    return _blendContext;
}

/** 解决带有ICC Profile的WebP格式图片，饱和度显示有偏差的问题 */
- (CGColorSpaceRef)imageColorSpace {
    if (_imageColorSpace) {
        return _imageColorSpace;
    }

    uint32_t flags = WebPDemuxGetI(_webPDemux, WEBP_FF_FORMAT_FLAGS);
    if ((flags & ICCP_FLAG) != 0) {
        WebPChunkIterator chunk_iter;
        int result = WebPDemuxGetChunk(_webPDemux, "ICCP", 1, &chunk_iter);
        if (result) {
            NSData *profileData = [NSData dataWithBytes:chunk_iter.chunk.bytes length:chunk_iter.chunk.size];
            _imageColorSpace = CGColorSpaceCreateWithICCData((__bridge CFDataRef)profileData);
            WebPDemuxReleaseChunkIterator(&chunk_iter);

            CGColorSpaceModel model = CGColorSpaceGetModel(_imageColorSpace);
            if (model != kCGColorSpaceModelRGB) {
                CGColorSpaceRelease(_imageColorSpace);
                _imageColorSpace = NULL;
            }
        }
    }
    return _imageColorSpace;
}

- (CGImageRef)copyImageAtIndex:(NSUInteger)index
              decodeForDisplay:(BOOL)display
                      cropRect:(CGRect)cropRect
                downsampleSize:(CGSize)downsampleSize
                  gifLimitSize:(CGFloat)gifLimit {
    pthread_mutex_lock(&_lock);
    if (_webPDemux) {
        WebPIterator iter;
        if (!WebPDemuxGetFrame(_webPDemux, (int)(index + 1), &iter)) {
            goto error;
        }
        double frameWidth = iter.width;
        double frameHeight = iter.height;
        if (gifLimit != 0 && frameWidth * frameHeight > gifLimit && self.imageCount > 1) {
            // 超大gif 不解码
            goto error;
        }
        CFTimeInterval duration = iter.duration / 1000.0;
        if (duration < 0.011f) {
            duration = 0.1f;
        }
        pthread_mutex_lock(&_durations_lock);
        [_durations setObject:@(duration) forKey:@(index)];
        pthread_mutex_unlock(&_durations_lock);
        if (frameWidth < 1 || frameHeight < 1) {
            goto error;
        }

        const uint8_t *payload = iter.fragment.bytes;
        size_t payloadSize = iter.fragment.size;

        WebPDecoderConfig config;
        if (!WebPInitDecoderConfig(&config)) {
            WebPDemuxReleaseIterator(&iter);
            goto error;
        }
        if (WebPGetFeatures(payload, payloadSize, &config.input) != VP8_STATUS_OK) {
            WebPDemuxReleaseIterator(&iter);
            goto error;
        }

        double x_offset = iter.x_offset;
        double y_offset = iter.y_offset;
        if (!CGRectEqualToRect(cropRect, CGRectZero)) {
            CGRect frameRect = CGRectMake(x_offset, y_offset, frameWidth, frameHeight);
            CGRect targetRect = CGRectIntersection(frameRect, cropRect);
            x_offset = targetRect.origin.x - cropRect.origin.x;
            y_offset = targetRect.origin.y - cropRect.origin.y;
            frameWidth = targetRect.size.width;
            frameHeight = targetRect.size.height;
            config.options.use_cropping = 1;
            config.options.crop_left = targetRect.origin.x - frameRect.origin.x;
            config.options.crop_top = targetRect.origin.y - frameRect.origin.y;
            config.options.crop_width = targetRect.size.width;
            config.options.crop_height = targetRect.size.height;
            self.hasCrop = YES;
        } else if (!(downsampleSize.width < 0 || downsampleSize.height < 0) && // downsampleSize.shouldNotDownsample
                   downsampleSize.width * downsampleSize.height <
                   self.originSize.width * self.originSize.height) {
            int targetPixels = downsampleSize.width * downsampleSize.height;
            CGSize scaledSize = [ImageDecoderUtilsBridge downsampleSizeFor:self.originSize targetPixels: targetPixels];
            frameWidth = scaledSize.width;
            frameHeight = scaledSize.height;
            CGFloat lengthRatio = scaledSize.width / self.originSize.width;
            x_offset = x_offset * lengthRatio;
            y_offset = y_offset * lengthRatio;
            config.options.use_scaling = 1;
            config.options.scaled_width = frameWidth;
            config.options.scaled_height = frameHeight;
            self.hasDownsample = YES;
        }
        size_t bitsPerComponent = 8;
        size_t bitsPerPixel = 32;

        size_t bytesPerRow = [ImageDecoderUtilsBridge imageByteAlignWithSize:bitsPerPixel / 8 * frameWidth alignment:32];
        size_t length = bytesPerRow * frameHeight;
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst;

        void *pixels = calloc(1, length);
        if (!pixels) {
            WebPDemuxReleaseIterator(&iter);
            goto error;
        }

        config.output.colorspace = MODE_bgrA;
        config.output.is_external_memory = 1;
        config.output.u.RGBA.rgba = pixels;
        config.output.u.RGBA.stride = (int)bytesPerRow;
        config.output.u.RGBA.size = length;
        VP8StatusCode result = WebPDecode(payload, payloadSize, &config); // decode
        if ((result != VP8_STATUS_OK) && (result != VP8_STATUS_NOT_ENOUGH_DATA)) {
            WebPDemuxReleaseIterator(&iter);
            free(pixels);
            goto error;
        }
        WebPDemuxReleaseIterator(&iter);

        CGDataProviderRef provider = CGDataProviderCreateWithData(pixels, pixels, length, ByteCGDataProviderReleaseDataCallback);
        if (!provider) {
            free(pixels);
            goto error;
        }

        CGColorSpaceRef colorSpaceRef = [self imageColorSpace];
        if (!colorSpaceRef) {
            colorSpaceRef = ByteCGColorSpaceGetDeviceRGB();
        }

        CGImageRef image = CGImageCreate(frameWidth,
                                         frameHeight,
                                         bitsPerComponent,
                                         bitsPerPixel,
                                         bytesPerRow,
                                         colorSpaceRef,
                                         bitmapInfo,
                                         provider,
                                         NULL,
                                         false,
                                         kCGRenderingIntentDefault);
        CFRelease(provider);

        if (self.imageCount == 1 && !display) {
            pthread_mutex_unlock(&_lock);
            return image;
        }

        if (self.imageCount == 1 && !(downsampleSize.width < 0 && downsampleSize.height < 0)) {
            self.didScaleDown = NO;
            CGImageRef tryScaleImage = ByteDecompressedAndScaledDownImageCreate(image, &_didScaleDown);
            if (tryScaleImage) {
                CGImageRelease(image);
                pthread_mutex_unlock(&_lock);
                return tryScaleImage;
            }
        }

        if (index == 0 && self.imageCount > 1) {
            CGContextClearRect([self blendContext], CGRectMake(0, 0, self.canvasSize.width, self.canvasSize.height));
        }

        CGRect rect = CGRectMake(x_offset, self.canvasSize.height - y_offset - frameHeight, frameWidth, frameHeight);
        if (iter.blend_method == WEBP_MUX_NO_BLEND) {
            CGContextClearRect([self blendContext], rect);
        }
        CGContextDrawImage([self blendContext], rect, image);
        CGImageRelease(image);
        CGImageRef newImage = CGBitmapContextCreateImage([self blendContext]);
        if (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
            CGContextClearRect([self blendContext], rect);
        }
        pthread_mutex_unlock(&_lock);
        return newImage;
    }

error:
    pthread_mutex_unlock(&_lock);
    return NULL;
}

- (CFTimeInterval)frameDelayAtIndex:(NSUInteger)index
{
    pthread_mutex_lock(&_durations_lock);
    CFTimeInterval delay = [[_durations objectForKey:@(index)] doubleValue];
    pthread_mutex_unlock(&_durations_lock);
    if (delay <= 0) {
        pthread_mutex_lock(&_lock);
        if (_webPDemux) {
            WebPIterator iter;
            if (!WebPDemuxGetFrame(_webPDemux, (int)(index + 1), &iter)) {
                goto error2;
            }
            CFTimeInterval duration = iter.duration / 1000.0;
            if (duration < 0.011f) {
                duration = 0.1f;
            }
            delay = duration;
            pthread_mutex_lock(&_durations_lock);
            [_durations setObject:@(duration) forKey:@(index)];
            pthread_mutex_unlock(&_durations_lock);
        }
    error2:
        pthread_mutex_unlock(&_lock);
    }
    return delay;
}

#pragma mark image info

- (NSUInteger)imageCount
{
    return _imageNum;
}

- (NSUInteger)loopCount
{
    return _loopNum;
}

- (CGSize)canvasSize {
    return _canvasSize;
}

- (CGSize)originSize {
    return _originSize;
}


- (UIImageOrientation)imageOrientation {
    return UIImageOrientationUp;
}

- (BOOL)hasDownsample {
    return _hasDownsample;
}

- (BOOL)didScaleDown {
    return _didScaleDown;
}

- (BOOL)hasCrop {
    return _hasCrop;
}

#pragma mark static

+ (BOOL)isAnimatedImage:(NSData *)data {
    NSInteger imageNum = [self imageCount:data];
    return imageNum > 1;
}

+ (NSInteger)imageCount:(NSData *)data {
    WebPData webpData = {data.bytes, data.length};
    WebPDemuxer *webPDemux = WebPDemux(&webpData);
    if (!webPDemux) {
        WebPDemuxState state;
        webPDemux = WebPDemuxPartial(&webpData, &state);
    }
    if (!webPDemux) return NO;
    NSInteger imageNum = WebPDemuxGetI(webPDemux, WEBP_FF_FRAME_COUNT);
    if (webPDemux) {
        WebPDemuxDelete(webPDemux);
    }
    return imageNum;
}

+ (BOOL)supportProgressDecode:(NSData *)data {
    return YES;
}

@end
