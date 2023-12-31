//
//  BDImageDecoderHeic.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/30.
//

#import "BDImageDecoderHeic.h"
#import "BDImageDecoderFactory.h"
#import "BDWebImageManager.h"
#import <pthread/pthread.h>
#import <libttheif_ios/ttheif_dec.h>

@interface BDImageDecoderHeic() {
    pthread_mutex_t _lock;
}

@property (nonatomic, strong)NSData *data;
@property (nonatomic, assign)bool isAnimation;
@property (nonatomic, assign)HeifImageInfo imageInfo;
@property (nonatomic, assign)TTHEIFContext context;
@property (atomic, assign)NSInteger frames;
@property (nonatomic, assign)NSInteger index;

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, assign) CGSize originSize;
@property (nonatomic, assign) CGSize canvasSize;
@property (nonatomic, assign) BDImageDecoderSizeType sizeType;
@property (nonatomic, strong) BDImageDecoderConfig *config;


@property (atomic, assign) BOOL hasIncrementalData;
@property (atomic, assign) BOOL finished; // ProgressiveDownload end

@end

@implementation BDImageDecoderHeic

- (instancetype)initWithData:(NSData *)data config:(BDImageDecoderConfig *)config {
    self = [super init];
    if (self) {
        self.data = [data copy];
        uint32_t dataSize = (uint32_t)self.data.length;
        uint8_t *heifData = (uint8_t *)self.data.bytes;
        BOOL result = heif_parse_simple_meta(heifData, dataSize, &_imageInfo);
        if (!result) {
            return nil;
        }
        
        self.originSize = CGSizeMake(_imageInfo.width, _imageInfo.height);
        
        self.config = config;
        self.canvasSize = [self.config imageCanvasSize:self.originSize];
        self.sizeType = [self.config imageSizeType:self.originSize];
        
        _isAnimation = _imageInfo.is_sequence;
        if (_isAnimation) {
            HeifDecodingParam decodingParam;
            decodingParam.use_wpp = [BDWebImageManager sharedManager].enableMultiThreadHeicDecoder;
            switch (self.sizeType) {
                // heif animation image cropping is not supported
                case BDImageDecoderCroppedSize: {
                    CGRect rect = self.config.cropRect;
                    decodingParam.decode_rect = true;
                    decodingParam.in_sample = 0;
                    decodingParam.rect.x = rect.origin.x;
                    decodingParam.rect.y = rect.origin.y;
                    decodingParam.rect.w = rect.size.width;
                    decodingParam.rect.h = rect.size.height;
                    break;
                }
                case BDImageDecoderDownsampledSize: {
                    CGFloat ratio = self.originSize.width / self.canvasSize.width;
                    decodingParam.decode_rect = false;
                    decodingParam.in_sample = ratio;
                    break;
                }
                default: {
                    decodingParam.decode_rect = false;
                    decodingParam.in_sample = 1;
                    break;
                }
            }
            heif_anim_heif_ctx_init(&_context, &decodingParam);
            heif_anim_parse_heif_box(&_context, heifData, dataSize);
            self.frames = heif_anim_get_current_frame_index(&_context, dataSize);
            _index = 0;
        }
        pthread_mutex_init(&_lock, 0);
    }
    return self;
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

- (void)dealloc
{
    if (_isAnimation) {
        heif_anim_heif_ctx_release(&_context);
    }
    
    pthread_mutex_destroy(&_lock);
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
    if (_isAnimation) {
        uint32_t dataSize = (uint32_t)self.data.length;
        self.frames = heif_anim_get_current_frame_index(&_context, dataSize);
    }
    self.finished = finished;
    pthread_mutex_unlock(&_lock);
}

- (BOOL)progressiveDownloading {
    return self.hasIncrementalData && !self.finished;
}

#pragma mark decode

- (CFTimeInterval)frameDelayAtIndex:(NSUInteger)index {
    CFTimeInterval duration = 0;
    if (_isAnimation) {
        duration = _imageInfo.duration / 1000.0 / _imageInfo.frame_nums;
    }
    if (duration < 0.011f) {
        duration = 0.1f;
    }
    return duration;
}

- (CGImageRef)copyImageAtIndex:(NSUInteger)index CF_RETURNS_RETAINED {
    CGImageRef imageRef = NULL;
    pthread_mutex_lock(&_lock);
    HeifOutputStream outputStream;
    if (_isAnimation) {
        outputStream = [self decodeAnimatedImageAtIndex:index];
    } else {
        outputStream = [self decodeStaticImage];
    }
    if (outputStream.data) {
        uint8_t *rgba = outputStream.data;
        uint32_t rgbaSize = outputStream.size;
        BOOL alpha = YES; //RGBA未实现，直接是塞的一行255完全不透明。按理论来说，应该有一个方法能判断当前图片是否含有alpha通道
        imageRef = [self bd_rawImageWithBitmap:rgba rgbaSize:rgbaSize alpha:alpha imageSize:CGSizeMake(outputStream.width, outputStream.height)];
    }
    pthread_mutex_unlock(&_lock);
    
    return imageRef;
}

- (HeifOutputStream)decodeStaticImage {
    uint32_t dataSize = (uint32_t)self.data.length;
    uint8_t *heifData = (uint8_t *)self.data.bytes;

    HeifDecodingParam decodingParam;
    decodingParam.use_wpp = [BDWebImageManager sharedManager].enableMultiThreadHeicDecoder;
    switch (self.sizeType) {
        case BDImageDecoderCroppedSize: {
            CGRect rect = self.config.cropRect;
            decodingParam.decode_rect = true;
            decodingParam.in_sample = 0;
            decodingParam.rect.x = rect.origin.x;
            decodingParam.rect.y = rect.origin.y;
            decodingParam.rect.w = rect.size.width;
            decodingParam.rect.h = rect.size.height;
            break;
        }
        case BDImageDecoderDownsampledSize: {
            CGFloat ratio = self.originSize.width / self.canvasSize.width;
            decodingParam.decode_rect = false;
            decodingParam.in_sample = ratio;
            break;
        }
        default: {
            decodingParam.decode_rect = false;
            decodingParam.in_sample = 1;
            break;
        }
    }
    
    HeifOutputStream outputStream = heif_decode_to_rgba(heifData, dataSize, &decodingParam);
    return outputStream;
}

- (HeifOutputStream)decodeAnimatedImageAtIndex:(NSUInteger)index {
    // heif 动图必须严格按照顺序解码
    if (index != 0 && index != _index + 1) {
        HeifOutputStream stream;
        stream.exif_data = NULL;
        stream.exif_size = 0;
        stream.data = NULL;
        stream.size = 0;
        return stream;
    }
    
    _index = index;
    
    uint32_t dataSize = (uint32_t)self.data.length;
    uint8_t *heifData = (uint8_t *)self.data.bytes;
    HeifOutputStream outputStream = heif_anim_decode_one_frame(&_context, heifData, dataSize, (uint32_t)index);
    return outputStream;
}

// 直接通过rgba，创建一个CGImage并生成UIImage
- (nullable CGImageRef)bd_rawImageWithBitmap:(uint8_t *)rgba rgbaSize:(uint32_t)rgbaSize alpha:(BOOL)alpha imageSize:(CGSize)imageSize CF_RETURNS_RETAINED {
    
    int width = imageSize.width;
    int height = imageSize.height;
    
    // Construct a UIImage from the decoded RGBA value array
    CGDataProviderRef provider =CGDataProviderCreateWithData(NULL, rgba, rgbaSize, freeImageData);
    if (!provider) {
        free(rgba);
        return NULL;
    }
    
    CGColorSpaceRef colorSpaceRef = BDCGColorSpaceGetDeviceRGB();
    CGBitmapInfo bitmapInfo = alpha ? kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast : kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
    size_t components = alpha ? 4 : 3;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    CGDataProviderRelease(provider);
    
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpaceRef, bitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef newImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    CGImageRelease(imageRef);
    
    return newImage;
}

// 这是用于在rgba渲染到CGImageRef后，销毁rgba数据用的，不free的话会内存泄漏
static void freeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

#pragma mark BDThumbImageDecoder

+ (BOOL)supportDecodeThumbFromHeicData {
    return YES;
}

+ (NSInteger)parseThumbLocationForHeicData:(NSData*)heifData minDataSize:(NSInteger*)minDataSize {
    uint8_t* data = (uint8_t*)heifData.bytes;
    uint32_t dataSize = (uint32_t)heifData.length;
    
    HeifImageInfo imageInfo;
    if(heifData == NULL || dataSize <= 0) {
        return BDImageHeicThumbLocationNotFound;
    }
    
    int ret = heif_parse_thumb(data, dataSize, &imageInfo);
    if ((ret == BDImageHeicThumbLocationFounded) && minDataSize) {
        *minDataSize = imageInfo.thum_size + imageInfo.thum_offset;
    }
    return ret;
}

//remove thumbnail data from downloaded data
+ (NSMutableData *)heicRepackData:(NSData *)data{
    if (data.length <= 0) {
        return nil;
    }
    uint32_t dataSize = (uint32_t)data.length;
    uint8_t* heifData = (uint8_t *)data.bytes;
    HeifOutputStream outputStream = heif_repack_data(heifData, dataSize);
    NSMutableData *ret = [NSMutableData dataWithBytes:outputStream.data length:outputStream.size];
    heif_release_output_stream(&outputStream);
    return ret;
}

- (CGImageRef)decodeThumbImage {
    CGImageRef imageRef = NULL;
    pthread_mutex_lock(&_lock);
    uint8_t *heifData = (uint8_t *)self.data.bytes;
    uint32_t dataSize = (uint32_t)self.data.length;

    HeifOutputStream outputStream = heif_decode_thumb_to_rgba(heifData, dataSize);
    if (outputStream.data) {
        uint8_t *rgba = outputStream.data;
        uint32_t rgbaSize = outputStream.size;
        BOOL alpha = YES;
        imageRef = [self bd_rawImageWithBitmap:rgba rgbaSize:rgbaSize alpha:alpha imageSize:CGSizeMake(outputStream.width, outputStream.height)];
        outputStream.data = NULL;
        heif_release_output_stream(&outputStream);
    }
    pthread_mutex_unlock(&_lock);
    return imageRef;
}

#pragma mark image info

- (NSUInteger)imageCount {
    return self.frames > 0 ? self.imageInfo.frame_nums : 1;
}

- (NSUInteger)loopCount {
    return 0;
}

- (BDImageCodeType)codeType {
    if (_isAnimation) {
        return BDImageCodeTypeHeif;
    }
    return BDImageCodeTypeHeic;
}

- (UIImageOrientation)imageOrientation {
    return UIImageOrientationUp;
}

#pragma mark static

// 检测HEIF格式是否为解码库所识别的
+ (BOOL)canDecode:(NSData *)data {
    uint32_t dataSize = (uint32_t)data.length;
    uint8_t *heifData = (uint8_t *)data.bytes;
    
    if(heifData == NULL || dataSize <= 0) {
        return NO;
    }
    
//    return 0 == check_heif_file(heifData, dataSize) && heif_judge_file_type(heifData,dataSize);
    return heif_judge_file_type(heifData,dataSize);

}

+ (BOOL)isAnimatedImage:(NSData *)data {
    uint32_t dataSize = (uint32_t)data.length;
    uint8_t *heifData = (uint8_t *)data.bytes;
    
    if(heifData == NULL || dataSize <= 0) {
        return NO;
    }
    
    HeifImageInfo info;
    
    BOOL result = heif_parse_simple_meta(heifData, dataSize, &info);
    return result && info.is_sequence;
}

+ (BOOL)isStaticHeicImage:(NSData *)data {
    uint32_t dataSize = (uint32_t)data.length;
    uint8_t *heifData = (uint8_t *)data.bytes;
    
    if(heifData == NULL || dataSize <= 0) {
        return NO;
    }
    
    if (!heif_judge_file_type(heifData,dataSize)) {
        return NO;
    }
    
    HeifImageInfo info;
    BOOL result = heif_parse_simple_meta(heifData, dataSize, &info);
    return result && !info.is_sequence;
}

+ (BOOL)supportProgressDecode:(NSData *)data {
    return YES;
}

+ (BOOL)supportStaticProgressDecode:(BDImageCodeType)type {
    return NO;
}

@end
