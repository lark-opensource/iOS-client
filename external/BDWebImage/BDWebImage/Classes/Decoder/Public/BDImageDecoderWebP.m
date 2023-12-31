//
//  BDImageDecoderWebP.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/30.
//

#import "BDImageDecoderWebP.h"
#import "BDImageDecoderFactory.h"
#import <Accelerate/Accelerate.h>
#if __has_include(<libwebp/webp/demux.h>)
    #import <libwebp/webp/demux.h>
#elif __has_include(<libwebp/demux.h>)
    #import <libwebp/demux.h>
#endif
#import <pthread/pthread.h>

static inline size_t BDImageByteAlign(size_t size, size_t alignment) {
    return ((size + (alignment - 1)) / alignment) * alignment;
}

static void BDCGDataProviderReleaseDataCallback(void *info, const void *data, size_t size) {
    free((void *)data);
}

@interface BDImageDecoderWebP()
{
    WebPDemuxer *_webPDemux;
    
    CGContextRef _blendContext;
    NSUInteger _lastBlendIndex;
    CGColorSpaceRef _imageColorSpace;
    
    NSMutableDictionary *_durations;
    pthread_mutex_t _durations_lock;
    
    pthread_mutex_t _lock;
}

@property (nonatomic, strong) NSData *data;
@property (nonatomic, copy) NSString *filePath;

@property (atomic, assign) NSUInteger imageNum;
@property (atomic, assign) NSUInteger loopNum;
@property (nonatomic, assign) CGSize originSize;
@property (nonatomic, assign) CGSize canvasSize;
@property (nonatomic, assign) BDImageDecoderSizeType sizeType;
@property (nonatomic, strong) BDImageDecoderConfig *config;


@property (atomic, assign) BOOL hasIncrementalData;
@property (atomic, assign) BOOL finished; // ProgressiveDownload end

@end

@implementation BDImageDecoderWebP

- (void)dealloc
{
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

- (instancetype)initWithData:(NSData *)data {
    return [self initWithData:data config:[BDImageDecoderConfig new]];
}

- (instancetype)initWithContentOfFile:(NSString *)file
{
    self = [self initWithData:[NSData dataWithContentsOfFile:file]];
    if (self) {
        self.filePath = file;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data config:(BDImageDecoderConfig *)config
{
    self = [super init];
    if (self) {
        NSData *internalData = [data copy] ?: [NSData data];
        self.data = internalData;
        WebPData webpData = {internalData.bytes, internalData.length};
        _webPDemux = WebPDemux(&webpData);
        if (!_webPDemux) {
            WebPDemuxState state;
            _webPDemux = WebPDemuxPartial(&webpData, &state);
        }
        if (!_webPDemux) return nil;
        self.imageNum = WebPDemuxGetI(_webPDemux, WEBP_FF_FRAME_COUNT);
        self.loopNum = WebPDemuxGetI(_webPDemux, WEBP_FF_LOOP_COUNT);
        uint32_t canvasWidth = WebPDemuxGetI(_webPDemux, WEBP_FF_CANVAS_WIDTH);
        uint32_t canvasHeight = WebPDemuxGetI(_webPDemux, WEBP_FF_CANVAS_HEIGHT);
        self.originSize = CGSizeMake(canvasWidth, canvasHeight);
        
        _durations = [NSMutableDictionary dictionary];
        pthread_mutex_init(&_durations_lock, 0);
        
        self.config = config;
        self.canvasSize = [self.config imageCanvasSize:self.originSize];
        self.sizeType = [self.config imageSizeType:self.originSize];
        
        // 动图下采样可能会出现马赛克，限制下按照 2 的倍数进行下采样
        NSInteger ratio = ((NSInteger)(self.originSize.width / self.canvasSize.width)) / 2;
        if (self.sizeType == BDImageDecoderDownsampledSize && ratio > 0 && self.imageNum > 1) {
            self.canvasSize = CGSizeMake(self.originSize.width / ratio / 2, self.originSize.height / ratio /2);
        }
        pthread_mutex_init(&_lock, 0);
    }
    return self;
}

#pragma mark progress download

- (instancetype)initWithIncrementalData:(NSData *)data config:(BDImageDecoderConfig *)config {
    self = [self initWithData:data config:config];
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
    CGColorSpaceRef colorSpace = BDCGColorSpaceGetDeviceRGB();
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
            _imageColorSpace = CGColorSpaceCreateWithICCProfile((__bridge CFDataRef)profileData);
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
{
    pthread_mutex_lock(&_lock);
    if (_webPDemux) {
        WebPIterator iter;
        if (!WebPDemuxGetFrame(_webPDemux, (int)(index + 1), &iter)){
            goto error;
        }
        double frameWidth = iter.width;
        double frameHeight = iter.height;
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
        if (WebPGetFeatures(payload , payloadSize, &config.input) != VP8_STATUS_OK) {
            WebPDemuxReleaseIterator(&iter);
            goto error;
        }

        double x_offset = iter.x_offset;
        double y_offset = iter.y_offset;
        switch (self.sizeType) {
            case BDImageDecoderCroppedSize: {
                CGRect cropRect = self.config.cropRect;
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
                break;
            }
            case BDImageDecoderDownsampledSize: {
                CGFloat ratio = self.canvasSize.width / self.originSize.width;
                frameWidth = round(frameWidth * ratio);
                frameHeight = round(frameHeight * ratio);
                x_offset = x_offset * ratio;
                y_offset = y_offset * ratio;
                config.options.use_scaling = 1;
                config.options.scaled_width = frameWidth;
                config.options.scaled_height = frameHeight;
                break;
            }
            default:
                break;
        }
        size_t bitsPerComponent = 8;
        size_t bitsPerPixel = 32;
        size_t bytesPerRow = BDImageByteAlign(bitsPerPixel / 8 * frameWidth, 32);
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
        
        CGDataProviderRef provider = CGDataProviderCreateWithData(pixels, pixels, length, BDCGDataProviderReleaseDataCallback);
        if (!provider) {
            free(pixels);
            goto error;
        }
        
        CGColorSpaceRef colorSpaceRef = [self imageColorSpace];
        if (!colorSpaceRef) {
            colorSpaceRef = BDCGColorSpaceGetDeviceRGB();
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
        
        if (self.imageCount == 1 && !self.config.decodeForDisplay) {
            pthread_mutex_unlock(&_lock);
            return image;
        }
        
        if (self.imageCount == 1 && self.sizeType == BDImageDecoderScaleDownSize) {
            BOOL didScaleDown = NO;
            CGImageRef tryScaleImage = BDCGImageDecompressedAndScaledDownImageCreate(image, &didScaleDown);
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
    return delay;
}

#pragma mark image info

- (NSUInteger)imageCount
{
    return self.imageNum;
}

- (NSUInteger)loopCount
{
    return self.loopNum;
}

- (BDImageCodeType)codeType {
    return BDImageCodeTypeWebP;
}

- (UIImageOrientation)imageOrientation {
    return UIImageOrientationUp;
}

#pragma mark static

+ (BOOL)canDecode:(NSData *)data {
    BDImageCodeType type = BDImageDetectType((__bridge CFDataRef)data);
    return type == BDImageCodeTypeWebP;
}

+ (BOOL)isAnimatedImage:(NSData *)data {
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
    return imageNum > 1;
}

+ (BOOL)supportProgressDecode:(NSData *)data {
    return YES;
}

+ (BOOL)supportStaticProgressDecode:(BDImageCodeType)type {
    return NO;
}

@end
