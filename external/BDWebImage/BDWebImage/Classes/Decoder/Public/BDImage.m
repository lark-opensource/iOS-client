//
//  BDImage.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/29.
//

#import "BDImage.h"
//#import "BDWebImageRequest.h"
#import "BDImagePerformanceRecoder.h"
#import "BDWebImageCompat.h"
#import "BDImageDecoder.h"
#import "BDImageDecoderFactory.h"
#import "BDWebImageError.h"
#import "UIImage+BDWebImage.h"
#import "BDWebImageManager.h"
#import <objc/runtime.h>

static NSArray *_BD_NSBundlePreferredScales() {
    static NSArray *scales;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat screenScale = [UIScreen mainScreen].scale;
        if (screenScale <= 1) {
            scales = @[@1, @2, @3];
        } else if (screenScale <= 2) {
            scales = @[@2, @3, @1];
        } else {
            scales = @[@3, @2, @1];
        }
    });
    return scales;
}

static NSString *_BD_NSStringByAppendingNameScale(NSString *string, CGFloat scale) {
    if (!string)
        return nil;
    if (fabs(scale - 1) <= __FLT_EPSILON__ || string.length == 0 || [string hasSuffix:@"/"])
        return string.copy;
    return [string stringByAppendingFormat:@"@%@x", @(scale)];
}


@implementation BDAnimateImageFrame
@end


@interface BDImage ()

@property (nonatomic, readwrite) BDImageCodeType codeType; //原始数据编码格式
@property (nonatomic, readwrite) NSString *filePath;       //原始文件地址,仅通过URL初始化时存在
//@property (nonatomic, readwrite)BOOL isAnimateImage;//动图[gif|webp|apng],且帧数大于一
//@property (nonatomic, readwrite)NSUInteger frameCount;//帧数
@property (nonatomic, readwrite) NSUInteger loopCount; //循环次数
@property (nonatomic, readwrite) BOOL isAllFramesLoaded; //动图是否缓存所有帧
@property (atomic, copy) NSArray<BDAnimateImageFrame *> *framesCache;
@property (nonatomic, readwrite) NSTimeInterval allFramesDuration; //动图总耗时
@end


@implementation BDImage

+ (nullable BDImage *)imageNamed:(NSString *)name {
    if (name.length == 0)
        return nil;
    if ([name hasSuffix:@"/"])
        return nil;

    NSString *res = name.stringByDeletingPathExtension;
    NSString *ext = name.pathExtension;
    NSString *path = nil;
    CGFloat scale = 1;

    // If no extension, guess by system supported (same as UIImage).
    NSArray *exts = ext.length > 0 ? @[ext] : @[@"", @"png", @"jpeg", @"jpg", @"gif", @"webp", @"apng"];
    NSArray *scales = _BD_NSBundlePreferredScales();
    for (int s = 0; s < scales.count; s++) {
        scale = ((NSNumber *)scales[s]).floatValue;
        NSString *scaledName = _BD_NSStringByAppendingNameScale(res, scale);
        for (NSString *e in exts) {
            path = [[NSBundle mainBundle] pathForResource:scaledName ofType:e];
            if (path)
                break;
        }
        if (path)
            break;
    }
    if (path.length == 0)
        return nil;

    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data.length == 0)
        return nil;
    return [BDImage imageWithData:data scale:scale];
}

+ (BDImage *)imageWithContentsOfFile:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    return (BDImage *)[BDImage imageWithData:data scale:BDScaledFactorForKey(path)];
}

+ (BDImage *)imageWithData:(NSData *)data {
    return [BDImage imageWithData:data scale:1];
}

+ (BDImage *)imageWithData:(NSData *)data scale:(CGFloat)scale {
    return [BDImage imageWithData:data scale:scale decodeForDisplay:YES error:NULL];
}

+ (BDImage *)imageWithData:(NSData *)data scale:(CGFloat)scale decodeForDisplay:(BOOL)decode error:(NSError *__autoreleasing *)error {
    return [self imageWithData:data scale:scale decodeForDisplay:decode shouldScaleDown:NO error:error];
}

+ (nullable BDImage *)imageWithData:(NSData *)data scale:(CGFloat)scale decodeForDisplay:(BOOL)decode shouldScaleDown:(BOOL)shouldScaleDown error:(NSError *__autoreleasing *)error {
    return [self imageWithData:data scale:scale decodeForDisplay:decode shouldScaleDown:shouldScaleDown downsampleSize:CGSizeZero cropRect:CGRectZero error:error];
}

+ (nullable BDImage *)imageWithData:(NSData *)data scale:(CGFloat)scale decodeForDisplay:(BOOL)decode shouldScaleDown:(BOOL)shouldScaleDown downsampleSize:(CGSize)size cropRect:(CGRect)cropRect error:(NSError *__autoreleasing *)error {
    if (data.length == 0) {
        if (error)
            *error = [NSError errorWithDomain:BDWebImageErrorDomain code:BDWebImageBadImageData userInfo:@{ NSLocalizedDescriptionKey: @"empty image data" }];
        return nil;
    }
    BDImageCodeType type = BDImageCodeTypeUnknown;
    Class decoderClass = [BDImageDecoderFactory decoderForImageData:data type:&type];
    if (!decoderClass) {
        if (error) {
            *error = [NSError errorWithDomain:BDWebImageErrorDomain code:BDWebImageBadImageData userInfo:@{ NSLocalizedDescriptionKey: @"Can not decode data" }];
        }
        return nil;
    }
    BDImageDecoderConfig *config = [BDImageDecoderConfig new];
    config.decodeForDisplay = decode;
    config.shouldScaleDown = shouldScaleDown;
    config.scale = scale;
    config.downsampleSize = size;
    config.cropRect = cropRect;

    id<BDImageDecoder> decoder = [[decoderClass alloc] initWithData:data config:config];
    BDImage *image = [[BDImage alloc] initWithCoderInternal:decoder];

    if (!image) {
        if (error)
            *error = [NSError errorWithDomain:BDWebImageErrorDomain code:BDWebImageEmptyImage userInfo:@{ NSLocalizedDescriptionKey: @"decode image failed" }];
        return nil;
    }

    return image;
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [self initWithData:data scale:BDScaledFactorForKey(path)];
}

- (instancetype)initWithData:(NSData *)data {
    return [self initWithData:data scale:1];
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    if (data.length == 0) {
        return nil;
    }
    BDImageCodeType type = BDImageCodeTypeUnknown;
    Class decoderClass = [BDImageDecoderFactory decoderForImageData:data type:&type];
    if (!decoderClass) {
        return nil;
    }
    BDImageDecoderConfig *config = [BDImageDecoderConfig new];
    config.scale = scale;
    id<BDImageDecoder> decoder = [[decoderClass alloc] initWithData:data config:config];
    return [self initWithCoderInternal:decoder];
}

- (instancetype)initWithCoderInternal:(id<BDImageDecoder>)decoder {
    CGImageRef cgImage = [decoder copyImageAtIndex:0];
    if (cgImage) {
        self = [self initWithCGImage:cgImage scale:decoder.config.scale ?: 1 orientation:decoder.imageOrientation ?: UIImageOrientationUp];
        CGImageRelease(cgImage);
    } else {
        return nil;
    }
    if (decoder.imageCount > 1 || decoder.progressiveDownloading) {
        self.decoder = decoder;
    }
    _codeType = decoder.codeType;
    _filePath = decoder.filePath;
    _loopCount = decoder.loopCount;
    Class heicDecoderCls = NSClassFromString(@"BDImageDecoderHeic");
    if(heicDecoderCls && [decoder isKindOfClass:heicDecoderCls]) {
        _isCustomHeicDecoder = YES;
    }
    
    self.hasDownsampled = decoder.sizeType == BDImageDecoderDownsampledSize;
    self.hasCroped = decoder.sizeType == BDImageDecoderCroppedSize;
    self.originSize = decoder.originSize;
    [self setBd_isDidScaleDown:(decoder.sizeType == BDImageDecoderScaleDownSize)];
    self.framesCache = [[NSArray alloc] init];
    self.isAllFramesLoaded = NO;
    return self;
}

- (BDImageCodeType)codeType {
    return self.decoder ? self.decoder.codeType : _codeType;
}
- (NSString *)filePath {
    return self.decoder ? self.decoder.filePath : _filePath;
}

- (BOOL)isAnimateImage {
    return self.decoder.imageCount > 1;
}

- (NSUInteger)frameCount {
    return self.decoder ? self.decoder.imageCount : 1;
}

- (NSUInteger)loopCount {
    return self.decoder ? self.decoder.loopCount : _loopCount;
}

- (nullable BDAnimateImageFrame *)frameAtIndex:(NSInteger)index {
    if (self.isAllFramesLoaded && self.framesCache.count > index) {
        return [self.framesCache objectAtIndex:index];
    }
    
    CGImageRef cgImage = [_decoder copyImageAtIndex:index];
    if (cgImage) {
        UIImage *image = [UIImage imageWithCGImage:cgImage scale:self.scale orientation:UIImageOrientationUp];
        CGImageRelease(cgImage);
        BDAnimateImageFrame *frame = [[BDAnimateImageFrame alloc] init];
        frame.image = image;
        frame.delay = [_decoder frameDelayAtIndex:index];
        return frame;
    }
    return nil;
}

- (NSData *)animatedImageData {
    return _decoder.data;
}

- (NSData *)bd_animatedImageData {
    return [self animatedImageData];
}

- (void)changeImageWithData:(NSData*)data finished:(BOOL)finished {
    [_decoder changeDecoderWithData:data finished:finished];
}

#pragma mark - preload frames

/// 缓存所有动图帧，兼容原生 UIImageView 动图接口
- (void)preloadAllFrames {
    NSInteger imageCount = _decoder.imageCount;
    if (imageCount < 1 || self.isAllFramesLoaded) {
        return;
    }
    NSMutableArray<BDAnimateImageFrame *> *arr = [[NSMutableArray alloc] initWithCapacity:imageCount];
    NSTimeInterval duration = 0;
    for (NSInteger i = 0; i < imageCount; i++) {
        BDAnimateImageFrame *frame = [self frameAtIndex:i];
        if (frame == nil) {
            break;
        }
        duration += frame.delay;
        [arr addObject:frame];
    }
    if (arr.count == imageCount) {
        self.isAllFramesLoaded = YES;
        self.allFramesDuration = duration;
        self.framesCache = [arr copy];
    }
}

/// 原生 UIImageView 播放动图时会调 images 获取动图帧进行播放
- (NSArray<UIImage *> *)images {
    if (!self.isAllFramesLoaded) {
        return nil;
    }
    NSMutableArray<UIImage *> *arr = [[NSMutableArray alloc] initWithCapacity:_decoder.imageCount];
    for (BDAnimateImageFrame *frame in self.framesCache) {
        [arr addObject:frame.image];
    }
    return [arr copy];
}

/// 原生 UIImageView 播放动图时会调 duration 获取动图播放时长
- (NSTimeInterval)duration {
    if (self.isAllFramesLoaded) {
        return self.allFramesDuration;
    }
    return 0;
}

#pragma mark - deprecated

+ (void)setBd_IsHeicSerialPreDecode:(BOOL)bd_IsHeicSerialPreDecode {
}

+ (BOOL)bd_IsHeicSerialPreDecode {
    return NO;
}

@end
