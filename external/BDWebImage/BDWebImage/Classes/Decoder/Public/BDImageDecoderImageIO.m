//
//  BDImageDecoderImageIO.m
//  BDWebImage
//
//  Created by lizhuoli on 2017/12/13.
//

#import "BDImageDecoderImageIO.h"
#import "BDImageDecoderFactory.h"
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

// kCGImagePropertyAPNGLoopCount这些常量虽然API标记了iOS 8支持，在iOS 8系统库的头文件里定义了，但库的实现未定义，会导致符号未找到，直接使用真实的值
static NSString *kBDImagePropertyAPNGLoopCount = @"LoopCount";
static NSString *kBDImagePropertyAPNGDelayTime = @"DelayTime";
static NSString *kBDImagePropertyAPNGUnclampedDelayTime = @"UnclampedDelayTime";

static NSString * kBDImagePropertyHEICSDictionary = @"{HEICS}";
static NSString * kBDImagePropertyHEICSLoopCount = @"LoopCount";
static NSString * kBDImagePropertyHEICSDelayTime = @"DelayTime";
static NSString * kBDImagePropertyHEICSUnclampedDelayTime = @"UnclampedDelayTime";

@interface BDImageDecoderImageIO ()
{
    CGImageSourceRef _imageSource;
    CFStringRef _imageFormat;
}

@property (atomic, strong) NSData *imageData;

@property (atomic, assign) NSUInteger frameNum;
@property (atomic, assign) NSUInteger loopNum;
@property (atomic, copy) NSArray *durations;

@property (nonatomic, assign) UIImageOrientation orientation;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) CGSize originSize;
@property (nonatomic, assign) CGSize canvasSize;
@property (nonatomic, assign) BDImageDecoderSizeType sizeType;
@property (nonatomic, strong) BDImageDecoderConfig *config;

@property (atomic, assign) BOOL hasIncrementalData;
@property (atomic, assign) BOOL finished; // ProgressiveDownload end
@end

@implementation BDImageDecoderImageIO

+ (void)initialize {
#if __IPHONE_13_0
    if (@available(iOS 13, *)) {
        // Use SDK instead of raw value
        kBDImagePropertyHEICSDictionary = (__bridge NSString *)kCGImagePropertyHEICSDictionary;
        kBDImagePropertyHEICSLoopCount = (__bridge NSString *)kCGImagePropertyHEICSLoopCount;
        kBDImagePropertyHEICSDelayTime = (__bridge NSString *)kCGImagePropertyHEICSDelayTime;
        kBDImagePropertyHEICSUnclampedDelayTime = (__bridge NSString *)kCGImagePropertyHEICSUnclampedDelayTime;
    }
#endif
}

- (void)dealloc
{
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (instancetype)initWithData:(NSData *)data
{
    return [self initWithData:data config:[BDImageDecoderConfig new]];
}

- (instancetype)initWithData:(NSData *)data config:(BDImageDecoderConfig *)config {
    self = [super init];
    if (self) {
        NSData *internalData = [data copy] ?: [NSData data];
        self.imageData = internalData;
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)internalData, NULL);
        if (imageSource){
            [self setupWithImageSource:imageSource config:config];
            CFRelease(imageSource);
        } else {
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithContentOfFile:(NSString *)file
{
    self = [super init];
    if (self) {
        CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (__bridge CFStringRef)file, kCFURLPOSIXPathStyle, NO);
        if (url) {
            CGImageSourceRef imageSource = CGImageSourceCreateWithURL(url, NULL);
            if (imageSource){
                [self setupWithImageSource:imageSource config:[BDImageDecoderConfig new]];
                CFRelease(imageSource);
            }
            CFRelease(url);
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.imageData = [NSData dataWithContentsOfFile:file];
        });
    }
    return self;
}

- (instancetype)initWithImageSource:(CGImageSourceRef)imageSource
{
    self = [super init];
    if (self){
        [self setupWithImageSource:imageSource config:[BDImageDecoderConfig new]];
    }
    return self;
}

#pragma mark progress download

- (instancetype)initWithIncrementalData:(NSData *)data config:(BDImageDecoderConfig *)config {
    self = [super init];
    if (self) {
        NSData *internalData = [data copy] ?: [NSData data];
        self.imageData = internalData;
        CGImageSourceRef imageSource = CGImageSourceCreateIncremental((__bridge CFDictionaryRef)@{});
        CGImageSourceUpdateData(imageSource, (__bridge CFDataRef)internalData, NO);
        if (imageSource){
            [self setupWithImageSource:imageSource config:config];
            CFRelease(imageSource);
        } else {
            return nil;
        }
        self.hasIncrementalData = YES;
    }
    return self;
}

- (void)changeDecoderWithData:(NSData *)data finished:(BOOL)finished {
    self.imageData = [data copy];
    CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)self.data, finished);
    
    self.frameNum = CGImageSourceGetCount(_imageSource);
    if (self.frameNum > 1) {
        [self scanAndCheckFramesValid];
    }
    self.finished = finished;
}


- (BOOL)progressiveDownloading {
    return self.hasIncrementalData && !self.finished;
}


#pragma mark image source

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    //火山的 crash：https://fabric.io/zhaokaibytedancecom/ios/apps/com.ss.iphone.ugc.liveinhouse/issues/5aaf66468cb3c2fa6363f7f8?time=last-thirty-days
    //头条的 crash：https://fabric.io/news/ios/apps/com.ss.iphone.article.news/issues/5a902a648cb3c2fa63aaee32?time=last-seven-days , https://fabric.io/news/ios/apps/com.ss.iphone.article.wenda/issues/5a531af88cb3c2fa636a1897?time=last-seven-days
    if (@available(iOS 9, *)) {//iOS8 系统上 imageIO 有 bug，会导致 crash
        if (_imageSource) {
            for (size_t i = 0; i < self.frameNum; i++) {
                CGImageSourceRemoveCacheAtIndex(_imageSource, i);
            }
        }
    }
}

- (void)setupWithImageSource:(CGImageSourceRef)imageSource config:(BDImageDecoderConfig *)config
{
    if (!imageSource){
        return;
    }
    _imageSource = (CGImageSourceRef)CFRetain(imageSource);
    
    _imageFormat = CGImageSourceGetType(_imageSource);
    if (!_imageFormat) {
        return;
    }
    
    // Image Orientation
    NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
    NSUInteger exifOrientation = [[imageProperties objectForKey:(__bridge_transfer NSString *)kCGImagePropertyOrientation] unsignedIntegerValue];
    self.orientation = exifOrientation ? BDUIImageOrientationFromEXIFOrientation(exifOrientation) : UIImageOrientationUp;
    // Image Size
    NSUInteger pixelWidth = [imageProperties[(__bridge NSString *)kCGImagePropertyPixelWidth] unsignedIntegerValue];
    NSUInteger pixelHeight = [imageProperties[(__bridge NSString *)kCGImagePropertyPixelHeight] unsignedIntegerValue];
    if (pixelWidth == 0 || pixelHeight == 0) {
        return;
    }
    self.originSize = CGSizeMake(pixelWidth, pixelHeight);
    
    self.config = config;
    self.canvasSize = [self.config imageCanvasSize:self.originSize];
    self.sizeType = [self.config imageSizeType:self.originSize];
    
    // Image count
    self.frameNum = CGImageSourceGetCount(_imageSource);
    if (self.frameNum > 1) {
        [self scanAndCheckFramesValid];
    }
    
    // Rmove cache when memory waring
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)scanAndCheckFramesValid {
    
    // Loop count
    NSDictionary *properties = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyProperties(_imageSource, NULL));
    NSDictionary *imageDictionarys = [properties objectForKey:[BDImageDecoderImageIO imageDictionaryProperty:_imageFormat]];

    if (imageDictionarys) {
        NSNumber *imageLoopCount = [imageDictionarys objectForKey:[BDImageDecoderImageIO imageLoopCountProperty:_imageFormat]];
        self.loopNum = imageLoopCount == nil ? 0 : [imageLoopCount integerValue];
    }
    
    NSMutableArray<NSNumber *> *durations = [NSMutableArray array];
    for (size_t i = 0; i < self.frameNum; i++) {
        CFTimeInterval delayTime = 0;
        NSDictionary *property = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(_imageSource, i, NULL));
        NSDictionary *frameInfo = [property objectForKey:[BDImageDecoderImageIO imageDictionaryProperty:_imageFormat]];
        if (frameInfo) {
            delayTime = [[frameInfo objectForKey:[BDImageDecoderImageIO imageUnclampedDelayTimeProperty:_imageFormat]] doubleValue];
            if (delayTime == 0) {
                delayTime = [[frameInfo objectForKey:[BDImageDecoderImageIO imageDelayTimeProperty:_imageFormat]] floatValue];
            }
        }
        if (delayTime < 0.011f) delayTime = 0.1;
        
        [durations addObject:@(delayTime)];
    }
    self.durations = [durations copy];
}

#pragma mark decode

- (CGImageRef)copyImageAtIndex:(NSUInteger)index
{
    if (_imageSource) {
        CGImageRef imageRef;
        switch (self.sizeType) {
            case BDImageDecoderCroppedSize: {
                CGImageRef source = CGImageSourceCreateImageAtIndex(_imageSource, index, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});
                imageRef = CGImageCreateWithImageInRect(source, self.config.cropRect);
                CGImageRelease(source);
                break;
            }
            case BDImageDecoderDownsampledSize: {
                CGFloat maxPixelSize = MAX(self.canvasSize.width, self.canvasSize.height);
                NSMutableDictionary *downsampleOptions = [NSMutableDictionary dictionary];
                downsampleOptions[(__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize] = @(maxPixelSize);
                downsampleOptions[(__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways] = @(YES);
                downsampleOptions[(__bridge NSString *)kCGImageSourceShouldCacheImmediately] = @(YES);
                imageRef = CGImageSourceCreateThumbnailAtIndex(_imageSource, index, (__bridge CFDictionaryRef)downsampleOptions);
                break;
            }
            default:
                imageRef = CGImageSourceCreateImageAtIndex(_imageSource, index, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});
                break;
        }
        
        // Downsample 使用 CGImageSourceCreateThumbnailAtIndex 会触发预解码，不走原有的预解码逻辑
        if (imageRef && self.config.decodeForDisplay && self.sizeType != BDImageDecoderDownsampledSize) {
            if (self.sizeType == BDImageDecoderScaleDownSize) {
                BOOL didScaleDown = NO;
                CGImageRef mayScaleDownImg = BDCGImageDecompressedAndScaledDownImageCreate(imageRef, &didScaleDown);
                CGImageRelease(imageRef);
                return mayScaleDownImg;
            }
            else {
                CGImageRef decoded = BDCGImageCreateDecodedCopy(imageRef, YES);
                CGImageRelease(imageRef);
                return decoded;
            }
        }
        return imageRef;
    }
    return NULL;
}

- (CFTimeInterval)frameDelayAtIndex:(NSUInteger)index
{
    if (index >= self.durations.count) {
        return 0.1;
    }
    return [self.durations[index] doubleValue];
}

#pragma mark image info

- (BDImageCodeType)codeType {
    if (CFStringCompare(_imageFormat, kUTTypeJPEG, 0) == kCFCompareEqualTo) {
        return BDImageCodeTypeJPEG;
    } else if (CFStringCompare(_imageFormat, kUTTypePNG, 0) == kCFCompareEqualTo) {
        return BDImageCodeTypePNG;
    } else if (CFStringCompare(_imageFormat, kBDUTTypeHEIC, 0) == kCFCompareEqualTo) {
        return BDImageCodeTypeHeic;
    } else if (CFStringCompare(_imageFormat, kBDUTTypeHEIF, 0) == kCFCompareEqualTo) {
        return BDImageCodeTypeHeif;
    } else if (CFStringCompare(_imageFormat, kBDUTTypeWebP, 0) == kCFCompareEqualTo) {
        return BDImageCodeTypeWebP;
    } else if (CFStringCompare(_imageFormat, kBDUTTypeHEICS, 0) == kCFCompareEqualTo) {
        return BDImageCodeTypeHeif;
    } else if (CFStringCompare(_imageFormat, kUTTypeGIF, 0) == kCFCompareEqualTo) {
        return BDImageCodeTypeGIF;
    } else if (CFStringCompare(_imageFormat, kUTTypeJPEG2000, 0) == kCFCompareEqualTo) {
        return BDImageCodeTypeJPEG2000;
    } else if (CFStringCompare(_imageFormat, kUTTypeTIFF, 0) == kCFCompareEqualTo) {
        return BDImageCodeTypeTIFF;
    } else if (CFStringCompare(_imageFormat, kUTTypeBMP, 0) == kCFCompareEqualTo) {
        return BDImageCodeTypeBMP;
    } else if (CFStringCompare(_imageFormat, kUTTypeICO, 0) == kCFCompareEqualTo) {
        return BDImageCodeTypeICO;
    } else if (CFStringCompare(_imageFormat, kUTTypeAppleICNS, 0) == kCFCompareEqualTo) {
        return BDImageCodeTypeICNS;
    } else {
        return BDImageCodeTypeJPEG;
    }
}

- (NSData *)data {
    return self.imageData;
}

- (NSUInteger)imageCount
{
    return self.frameNum;
}

- (NSUInteger)loopCount
{
    return self.loopNum;
}

- (UIImageOrientation)imageOrientation
{
    return self.orientation;
}

#pragma mark - image info key

+ (NSString *)imageDictionaryProperty:(CFStringRef)imageType {
    if (CFStringCompare(imageType, kUTTypeGIF, 0) == kCFCompareEqualTo) {
        return (__bridge NSString *)kCGImagePropertyGIFDictionary;
    } else if (CFStringCompare(imageType, kUTTypePNG, 0) == kCFCompareEqualTo) {
        return (__bridge NSString *)kCGImagePropertyPNGDictionary;
    } else if (CFStringCompare(imageType, kBDUTTypeHEICS, 0) == kCFCompareEqualTo) {
        return kBDImagePropertyHEICSDictionary;
    } else {
        return (__bridge NSString *)kCGImagePropertyGIFDictionary;
    }
}

+ (NSString *)imageUnclampedDelayTimeProperty:(CFStringRef)imageType {
    if (CFStringCompare(imageType, kUTTypeGIF, 0) == kCFCompareEqualTo) {
        return (__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime;
    } else if (CFStringCompare(imageType, kUTTypePNG, 0) == kCFCompareEqualTo) {
        return kBDImagePropertyAPNGUnclampedDelayTime;
    } else if (CFStringCompare(imageType, kBDUTTypeHEICS, 0) == kCFCompareEqualTo) {
        return kBDImagePropertyHEICSUnclampedDelayTime;
    } else {
        return (__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime;
    }
}

+ (NSString *)imageDelayTimeProperty:(CFStringRef)imageType {
    if (CFStringCompare(imageType, kUTTypeGIF, 0) == kCFCompareEqualTo) {
        return (__bridge NSString *)kCGImagePropertyGIFDelayTime;
    } else if (CFStringCompare(imageType, kUTTypePNG, 0) == kCFCompareEqualTo) {
        return kBDImagePropertyAPNGDelayTime;
    } else if (CFStringCompare(imageType, kBDUTTypeHEICS, 0) == kCFCompareEqualTo) {
        return kBDImagePropertyHEICSDelayTime;
    } else {
        return (__bridge NSString *)kCGImagePropertyGIFDelayTime;
    }
}

+ (NSString *)imageLoopCountProperty:(CFStringRef)imageType {
    if (CFStringCompare(imageType, kUTTypeGIF, 0) == kCFCompareEqualTo) {
        return (__bridge NSString *)kCGImagePropertyGIFLoopCount;
    } else if (CFStringCompare(imageType, kUTTypePNG, 0) == kCFCompareEqualTo) {
        return kBDImagePropertyAPNGLoopCount;
    } else if (CFStringCompare(imageType, kBDUTTypeHEICS, 0) == kCFCompareEqualTo) {
        return kBDImagePropertyHEICSLoopCount;
    } else {
        return (__bridge NSString *)kCGImagePropertyGIFLoopCount;
    }
}

#pragma mark static

+ (BOOL)canDecode:(NSData *)data {
    BOOL canDecode = NO;
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (imageSource){
        NSArray *supportFormats = (__bridge NSArray *)CGImageSourceCopyTypeIdentifiers();
        NSString *imageFormat = (__bridge NSString *)CGImageSourceGetType(imageSource);
        if ([supportFormats containsObject:imageFormat]) {
            canDecode = YES;
        }
        CFRelease(imageSource);
    }
    return canDecode;
}

+ (BOOL)isAnimatedImage:(NSData *)data {
    BOOL animatedImage = NO;
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (imageSource){
        NSInteger imageCount = CGImageSourceGetCount(imageSource);
        animatedImage = imageCount > 1;
        CFRelease(imageSource);
    }
    return animatedImage;
}

+ (BOOL)supportProgressDecode:(NSData *)data {
    return YES;
}

+ (BOOL)supportStaticProgressDecode:(BDImageCodeType)type {
    return type == BDImageCodeTypeJPEG || type == BDImageCodeTypeJPEG2000;
}

@end
