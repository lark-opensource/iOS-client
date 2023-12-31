//
//  HEICBridge.m
//  ByteWebImage
//
//  Created by Nickyo on 2023/2/15.
//

#import "HEICBridge.h"
#import <pthread/pthread.h>
#import <libttheif_ios/ttheif_dec.h>
#import <ByteWebImage/ByteWebImage-Swift.h>

CGColorSpaceRef ByteHEICCGColorSpaceGetDeviceRGB(void) {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    });
    return colorSpace;
}

@interface HEICBridge() {
    pthread_mutex_t _lock;
}

@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) bool isAnimation;

@property (nonatomic, assign) HeifImageInfo imageInfo;
@property (nonatomic, assign) TTHEIFContext context;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) int rotation;

@property (nonatomic, assign) CGSize originSize;

@property (nonatomic, assign) BOOL hasInitContext;

@end

@implementation HEICBridge

- (void)dealloc {
    if (_isAnimation && _hasInitContext) {
        heif_anim_heif_ctx_release(&_context);
    }
    pthread_mutex_destroy(&_lock);
}

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        self.data = [data copy];
        uint8_t *heifData = (uint8_t *)self.data.bytes;
        uint32_t dataSize = (uint32_t)self.data.length;

        if (!heif_parse_meta(heifData, dataSize, &_imageInfo)) {
            return nil;
        }

        _originSize = CGSizeMake(_imageInfo.width, _imageInfo.height);
        _isAnimation = _imageInfo.is_sequence;
        _index = 0;
        _rotation = -1;
        _hasInitContext = NO;
        pthread_mutex_init(&_lock, 0);
    }
    return self;
}

- (CFTimeInterval)frameDelayAtIndex:(NSInteger)index {
    if (!_isAnimation) {
        return 0;
    }

    CFTimeInterval interval = _imageInfo.duration / 1000.0 / _imageInfo.frame_nums;
    if (interval < 0.011f) {
        interval = 0.1f;
    }
    return interval;
}

- (CGImageRef)copyImageAtIndex:(NSInteger)index decodeForDisplay:(BOOL)display cropRect:(CGRect)cropRect downsampleSize:(CGSize)downsampleSize limitSize:(CGFloat)limitSize {
    // 超出限制，不生成图片
    if (limitSize != 0 && self.originSize.width * self.originSize.height > limitSize) {
        return NULL;
    }

    CGImageRef imageRef = NULL;
    pthread_mutex_lock(&_lock);
    HeifOutputStream outputStream = [self outputStreamWithIndex:index cropRect:cropRect downsampleSize:downsampleSize];
    if (outputStream.data) {
        uint8_t *bitmap = outputStream.data;
        uint32_t rgbaSize = outputStream.size;
        BOOL alpha = YES; //RGBA未实现，直接是塞的一行255完全不透明。按理论来说，应该有一个方法能判断当前图片是否含有alpha通道
        CGSize imageSize = CGSizeMake(outputStream.width, outputStream.height);
        imageRef = [self rawImageWithBitmap:bitmap
                                   rgbaSize:rgbaSize
                                      alpha:alpha
                                  imageSize:imageSize
                             downsampleSize:downsampleSize];
    }
    pthread_mutex_unlock(&_lock);

    return imageRef;
}

- (NSInteger)imageCount {
    return (NSInteger)self.imageInfo.frame_nums;
}

- (NSInteger)loopCount {
    return 0;
}

- (CGImagePropertyOrientation)imageOrientation {
    int rotation = _rotation;
    if (rotation == -1) {
        rotation = [self rotationValue];
        _rotation = rotation;
    }
    return (CGImagePropertyOrientation)rotation;
}

#pragma mark - Process Image

// TODO: 未按顺序解码失败，需要单独抛出错误
- (HeifOutputStream)outputStreamWithIndex:(NSInteger)index cropRect:(CGRect)cropRect downsampleSize:(CGSize)downsampleSize {
    HeifOutputStream outputStream;
    if (_isAnimation) {
        // HEIF 动图必须严格按照顺序解码
        if (index != 0 && index != _index + 1) {
            outputStream.data = NULL;
        } else {
            uint8_t *heifData = (uint8_t *)self.data.bytes;
            uint32_t dataSize = (uint32_t)self.data.length;

            if (!_hasInitContext) {
                HeifDecodingParam param = [self decodingParamWithCropRect:cropRect downsampleSize:downsampleSize];
                heif_anim_heif_ctx_init(&_context, &param);
                heif_anim_parse_heif_box(&_context, heifData, dataSize);
                _hasInitContext = YES;
            }
            _index = index;

            outputStream = heif_anim_decode_one_frame(&_context, heifData, dataSize, (uint32_t)index);
        }
    } else {
        uint8_t *heifData = (uint8_t *)self.data.bytes;
        uint32_t dataSize = (uint32_t)self.data.length;
        HeifDecodingParam param = [self decodingParamWithCropRect:cropRect downsampleSize:downsampleSize];

        outputStream = heif_decode_to_rgba(heifData, dataSize, &param);
    }
    return outputStream;
}

- (HeifDecodingParam)decodingParamWithCropRect:(CGRect)cropRect downsampleSize:(CGSize)downsampleSize {
    HeifDecodingParam param;
    param.use_wpp = NO; //BDWebImageManager.sharedManager.enableMultiThreadHeicDecoder;
    if (!CGRectIsEmpty(cropRect)) {
        param.decode_rect = true;
        param.in_sample = 0;
        param.rect.x = cropRect.origin.x;
        param.rect.y = cropRect.origin.y;
        param.rect.w = cropRect.size.width;
        param.rect.h = cropRect.size.height;
    } else if (downsampleSize.width > 0 && downsampleSize.height > 0) {
        CGFloat target = downsampleSize.width * downsampleSize.height;
        CGFloat origin = self.originSize.width * self.originSize.height;
        CGFloat radio = sqrt(origin / target);

        param.decode_rect = false;
        param.in_sample = radio;
    } else {
        param.decode_rect = false;
        param.in_sample = 1;
    }
    return param;
}

/// 直接通过rgba，创建一个CGImage并生成UIImage
- (CGImageRef)rawImageWithBitmap:(uint8_t *)bitmap
                        rgbaSize:(uint32_t)rgbaSize
                           alpha:(BOOL)alpha
                       imageSize:(CGSize)imageSize
                  downsampleSize:(CGSize)downsampleSize CF_RETURNS_RETAINED {
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bitmap, rgbaSize, freeImageData);
    if (!provider) {
        free(bitmap);
        return NULL;
    }

    int width = imageSize.width;
    int height = imageSize.height;

    CGColorSpaceRef colorSpaceRef = ByteHEICCGColorSpaceGetDeviceRGB();

    // heif_decode_to_rgba 接口返回的 alpha 并没有 Pre-mutiplied
    CGBitmapInfo originalBitmapInfo = alpha ? kCGBitmapByteOrder32Big | kCGImageAlphaLast :
    kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
    size_t components = alpha ? 4 : 3;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, 8, components * 8, components * width, colorSpaceRef, originalBitmapInfo, provider, NULL, NO, renderingIntent);

    CGDataProviderRelease(provider);

    CGBitmapInfo renderBitmapInfo = alpha ? kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast : kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
    NSInteger pixels = downsampleSize.width * downsampleSize.height;
    // ttheif 的降采样很粗糙，in_sample 只能传整数，所以这里在重绘的时候顺便做下精确降采样
    CGSize canvasSize = [ImageDecoderUtilsBridge downsampleSizeFor:imageSize targetPixels:pixels];
    CGContextRef context = CGBitmapContextCreate(NULL, canvasSize.width, canvasSize.height, 8, 0, colorSpaceRef, renderBitmapInfo);
    CGContextDrawImage(context, CGRectMake(0, 0, canvasSize.width, canvasSize.height), imageRef);
    CGImageRef newImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);

    CGImageRelease(imageRef);

    return newImage;
}

/// 在 RGBA 渲染到 CGImageRef 后，销毁rgba数据
static void freeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

/// libttheif_ios 库内部解析 rotation 失败，解析 exif 需要引入 exif.a，库开发者认为引入的新库过大，因此需要业务方自行解析
/// https://bytedance.feishu.cn/docx/EdC5d8rBVo1Fhcx5ZKScAGHDnod
- (uint32_t)rotationValue {
    uint8_t *exif = _imageInfo.exif_data;
    uint32_t length = _imageInfo.exif_size;

    // 确保header完整
    if (length < 16) {
        return 0;
    }
    // 判断大小端
    uint8_t endianData = (uint8_t)(exif[6]);
    BOOL littleEndian = NO;
    if (endianData == 0x49) {
        littleEndian = YES;
    } else if (endianData == 0x4D) {
        littleEndian = NO;
    } else {
        return 0;
    }
    // 获取 IFD 数量
    uint32_t ifdCount = [self mergeValue:(uint32_t)(exif[14]) with:(uint32_t)(exif[15]) littleEndian:littleEndian];
    if (ifdCount <= 0 || length < 16 + ifdCount * 12) {
        return 0;
    }
    // 遍历 IFD
    for (uint32_t i = 0; i < ifdCount; i++) {
        uint32_t tag = [self mergeValue:(uint32_t)(exif[16 + i * 12]) with:(uint32_t)(exif[16 + i * 12 + 1]) littleEndian:littleEndian];
        // 找到 tag 为 0x112 的 ifd，内容为orientation
        if (tag == 0x112) {
            // 获取当前偏移+8 length=2 的数据
            uint32_t value = [self mergeValue:(uint32_t)(exif[16 + i * 12 + 8]) with:(uint32_t)(exif[16 + i * 12 + 9]) littleEndian:littleEndian];
            return value;
        }
    }
    return 0;
}

- (uint32_t)mergeValue:(uint32_t)lhs with:(uint32_t)rhs littleEndian:(BOOL)littleEndian {
    if (littleEndian) {
        return (rhs << 8) + lhs;
    } else {
        return (lhs << 8) + rhs;
    }
}

@end
