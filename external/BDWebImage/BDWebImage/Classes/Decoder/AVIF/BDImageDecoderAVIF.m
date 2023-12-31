//
//  BDImageDecoderAVIF.m
//  BDALog
//
//  Created by bytedance on 12/28/20.
//

#import "BDImageDecoderAVIF.h"
#import "BDImageDecoderFactory.h"
#import "BDImageDecoderAVIFConversion.h"

#import <libavif/avif.h>
#import <pthread.h>

@interface BDImageDecoderAVIF (){
    avifDecoder * _decoder;
    NSUInteger _frameCount;
    CFTimeInterval _duration;
    pthread_mutex_t _decode_lock;
}

@property (nonatomic, strong) NSData *data;
@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, assign) CGSize originSize;
@property (nonatomic, assign) CGSize canvasSize;
@property (nonatomic, assign) BDImageDecoderSizeType sizeType;
@property (nonatomic, strong) BDImageDecoderConfig *config;

@property (atomic, assign) BOOL hasIncrementalData;
@property (atomic, assign) BOOL finished; // ProgressiveDownload end

@end

@implementation BDImageDecoderAVIF

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

- (instancetype)initWithData:(NSData *)data config:(BDImageDecoderConfig *)config{
    self = [super init];
    if (self) {
        self.data = [data copy];
        _decoder = avifDecoderCreate();
        avifDecoderSetIOMemory(_decoder, data.bytes, data.length);
        // Disable strict mode to keep some AVIF image compatible
        _decoder->strictFlags = AVIF_STRICT_DISABLED;
        avifDecoderParse(_decoder);
        _frameCount = _decoder->imageCount;
        _duration = _decoder->duration;
        
        self.originSize = CGSizeMake(_decoder->image->width, _decoder->image->height);
        
        self.config = config;
        self.canvasSize = [self.config imageCanvasSize:self.originSize];
        self.sizeType = [self.config imageSizeType:self.originSize];
        pthread_mutex_init(&_decode_lock, NULL);
    }
    return self;
}

- (void)dealloc
{
    if (_decoder) {
        avifDecoderDestroy(_decoder);
    }
}

#pragma mark progress download

- (instancetype)initWithIncrementalData:(NSData *)data config:(BDImageDecoderConfig *)config {
    self = [self initWithData:data config:config];
    if (self) {
        self.hasIncrementalData = NO;
    }
    return self;
}

- (void)changeDecoderWithData:(NSData *)data finished:(BOOL)finished {
    self.finished = finished;
}

- (BOOL)progressiveDownloading {
    return self.hasIncrementalData && !self.finished;
}

#pragma mark decode

- (CGImageRef)decodeStaticImage
{
    avifResult nextImageResult = avifDecoderNextImage(_decoder);
    if (nextImageResult != AVIF_RESULT_OK) {
        avifDecoderDestroy(_decoder);
        return nil;
    }
    CGImageRef imageRef = BDCreateCGImageFromAVIF(_decoder->image);
    if (!imageRef) {
        return nil;
    }
    return imageRef;
}

- (CGImageRef)decodeAnimatedImageAtIndex:(NSUInteger)index
{
    if (index >= _frameCount) {
        return nil;
    }

    // 由于初始化时会对第 0 帧进行一次解码，因此_decoder->imageIndex的值会增1(初始为-1)，
    // 再次对第 0 帧进行解码的时候_decoder->imageIndex为 0 ，那么调用avifDecoderNthImage方法的时候就会有问题
    // 因此需要在 index == 0 的时候对decoder进行重新初始化
    if (index == 0){
        avifDecoder *decoder = avifDecoderCreate();
        avifDecoderSetIOMemory(decoder, self.data.bytes, self.data.length);
        // Disable strict mode to keep some AVIF image compatible
        decoder->strictFlags = AVIF_STRICT_DISABLED;

        avifResult decodeResult = avifDecoderParse(decoder);
        if (decodeResult != AVIF_RESULT_OK) {
            avifDecoderDestroy(decoder);
            return nil;
        }
        avifDecoderDestroy(_decoder);
        _decoder = decoder;
    }
    
    avifResult nextImageResult = avifDecoderNthImage(_decoder, (uint32_t)index);
    if (nextImageResult != AVIF_RESULT_OK || nextImageResult == AVIF_RESULT_NO_IMAGES_REMAINING) {
        return nil;
    }
    
    CGImageRef const image = BDCreateCGImageFromAVIF(_decoder->image);
    
    return image;
}

- (CGImageRef)copyImageAtIndex:(NSUInteger)index
{
    if (_decoder == nil) {
        return nil;
    }
    pthread_mutex_lock(&_decode_lock);
    
    CGImageRef imageRef = NULL;
    if (_decoder->imageCount <= 1) {
        imageRef = [self decodeStaticImage];                // 静图
    }else{
        imageRef = [self decodeAnimatedImageAtIndex:index]; // 动图
    }

    pthread_mutex_unlock(&_decode_lock);
    
    return imageRef;
}

- (CFTimeInterval)frameDelayAtIndex:(NSUInteger)index
{
    CFTimeInterval duration = 0;
    if (_frameCount > 0) {
        duration = _duration / _frameCount;
    }
    if (duration < 0.011f) {
        duration = 0.1f;
    }
    return duration;
}

#pragma mark image info

- (NSUInteger)imageCount {
    return _frameCount;
}

- (NSUInteger)loopCount {
    return 0;
}

- (BDImageCodeType)codeType {
    return BDImageCodeTypeAVIF;
}

- (UIImageOrientation)imageOrientation {
    return UIImageOrientationUp;
}

#pragma mark - BDImageDecoderExt -

+ (BOOL)canDecode:(NSData *)data
{
    avifDecoder * decoder = avifDecoderCreate();
    avifDecoderSetIOMemory(decoder, data.bytes, data.length);
    // Disable strict mode to keep some AVIF image compatible
    decoder->strictFlags = AVIF_STRICT_DISABLED;
    
    avifResult decodeResult = avifDecoderParse(decoder);
    if (decodeResult != AVIF_RESULT_OK) {
        avifDecoderDestroy(decoder);
        return NO;
    }
    avifDecoderDestroy(decoder);
    return YES;
}

+ (BOOL)supportProgressDecode:(NSData *)data {
    return NO;
}

+ (BOOL)supportStaticProgressDecode:(BDImageCodeType)type {
    return NO;
}

@end
