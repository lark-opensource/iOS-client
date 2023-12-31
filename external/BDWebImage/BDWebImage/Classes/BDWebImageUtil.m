//
//  BDWebImageUtil.m
//  BDWebImage
//
//  Created by Lin Yong on 2019/2/11.
//

#import "BDWebImageUtil.h"
#if __has_include("BDWebImage.h")
#import "BDWebImage.h"
#else
#import "BDWebImageToB.h"
#endif

@class BDImage;
@interface UIImage (_Tmp)

+ (BDImage *)imageWithData:(NSData *)data
                     scale:(CGFloat)scale
          decodeForDisplay:(BOOL)decode
           shouldScaleDown:(BOOL)shouldScaleDown
            downsampleSize:(CGSize)size
                  cropRect:(CGRect)cropRect
                     error:(NSError *__autoreleasing *)error;

@end

@implementation BDWebImageUtil

+ (UIImage *)decodeImageData:(NSData *)data
                  imageClass:(__unsafe_unretained Class)imageClass
                       scale:(CGFloat)scale
            decodeForDisplay:(BOOL)decode
             shouldScaleDown:(BOOL)scaleDown
{
    NSError *error = nil;
    return [self decodeImageData:data imageClass:imageClass scale:scale decodeForDisplay:decode shouldScaleDown:scaleDown downsampleSize:CGSizeZero cropRect:CGRectZero error:&error];
}

+ (UIImage *)decodeImageData:(NSData *)data
                  imageClass:(__unsafe_unretained Class)imageClass
                       scale:(CGFloat)scale
            decodeForDisplay:(BOOL)decode
             shouldScaleDown:(BOOL)scaleDown
              downsampleSize:(CGSize)size
                    cropRect:(CGRect)cropRect
                       error:(NSError *__autoreleasing *)error
{
    if (imageClass == UIImage.class) {
        return [imageClass imageWithData:data scale:scale];
    }
    
    SEL selector = @selector(imageWithData:scale:decodeForDisplay:shouldScaleDown:error:);
    if ([imageClass respondsToSelector:selector]) {
        return (UIImage *)[imageClass imageWithData:data
                                              scale:scale
                                   decodeForDisplay:decode
                                    shouldScaleDown:scaleDown
                                     downsampleSize:size
                                           cropRect:cropRect
                                              error:error];
    }
    else {
        return nil;
    }
}

+ (NSInteger)isWhiteOrBlackImage:(UIImage *)image samplingPoint:(NSInteger)samplingPoint
{
    NSInteger result = 0;
    
    // 把图片放到data buffer
    CGImageRef imageRef = [image CGImage];
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger bytesPerPixel = CGImageGetBitsPerPixel(imageRef) / 8;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    
    CGDataProviderRef dataProvider;
    @try {
        dataProvider = CGImageGetDataProvider(imageRef);
    } @catch (NSException *exception) {
        dataProvider = NULL;    // 往下走会进行判断失败
    }
    if (!dataProvider) {
        return -1;
    }
    
    CFDataRef dataRef = CGDataProviderCopyData(dataProvider);
    if (!dataRef) {
        return -1;
    }
    
    uint8_t *rawData = (uint8_t *)CFDataGetBytePtr(dataRef);
    
    // 获取第一个像素值
    float firstPixelValue = [self getRGBAsFromImage:image
                                                row:0
                                                col:0
                                        bytesPerRow:bytesPerRow
                                      bytesPerPixel:bytesPerPixel
                                           hasAlpha:hasAlpha
                                            rawData:rawData];
    if (firstPixelValue == -1){
        result = 3; // transparent_suspected
    }else if(firstPixelValue == 0){
        result = 1; // black_suspected
    }else if(firstPixelValue == 255){
        result = 2; // white_suspected
    }else{
        if (dataRef) {
            CFRelease(dataRef); // free non-converted rgba buffer
            dataRef = NULL;
        }
        return 0;       // 获取的像素不为 黑/白，说明该图片肯定没有出现 白屏/黑屏
    }
    
    for (int i = 0; i < samplingPoint; i++){
        // -3是为了防止当图片是灰度图的时候出现溢出现象
        uint32_t row = arc4random_uniform(image.size.width - 3);
        uint32_t col = arc4random_uniform(image.size.height - 3);
        
        float tmpPixelValue = [self getRGBAsFromImage:image
                                                  row:row
                                                  col:col
                                          bytesPerRow:bytesPerRow
                                        bytesPerPixel:bytesPerPixel
                                             hasAlpha:hasAlpha
                                              rawData:rawData];
        
        // 一旦发现有一个像素点的值不是 白/黑， 那么就认为该图像是正常的
        if (tmpPixelValue != firstPixelValue){
            result = 0;
            break;
        }
    }
    
    if (dataRef) {
        CFRelease(dataRef); // free non-converted rgba buffer
        dataRef = NULL;
    }
    
    return result;
}

/**
 计算图像中指定位置像素值
 */
+ (float)getRGBAsFromImage:(UIImage*)image
                       row:(int)row
                       col:(int)col
               bytesPerRow:(NSUInteger)bytesPerRow
             bytesPerPixel:(NSUInteger)bytesPerPixel
                  hasAlpha:(BOOL)hasAlpha
                   rawData:(uint8_t *)rawData
{
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    NSUInteger byteIndex = (bytesPerRow * col) + row * bytesPerPixel;

    CGFloat alpha, red, green, blue;
    if (hasAlpha){
        alpha = ((CGFloat) rawData[byteIndex + 3]) / 255.0f;
    }else{
        alpha = 1.0f;
    }
     
    if (alpha == 0){    // 透明
        return -1;
    }else{
        red  = ((CGFloat) rawData[byteIndex]) / alpha;
        green = ((CGFloat) rawData[byteIndex + 1]) / alpha;
        blue = ((CGFloat) rawData[byteIndex + 2]) / alpha;
    }

    return (red + green + blue) / 3;
}

int gcdArray(int n, int a[n])
{
    switch (n) {
        case 0: {
            return 0;
        }
            break;
        case 1: {
            return a[0];
        }
            break;
        case 2: {
            return gcd(a[0], a[1]);
        }
            break;
        default: {
            int h = n / 2;
            return gcd(gcdArray(h, &a[0]), gcdArray(n - h, &a[h]));
        }
            break;
    }
}

unsigned gcd(unsigned x, unsigned y)
{
    unsigned wk;
    if(x < y) {
        wk = x;
        x = y;
        y = wk;
    }
    while(y){
        wk = x % y;
        x = y;
        y = wk;
    }
    return x;
}

BOOL isAnimatedImageData(NSData *_Nonnull data)
{
    CFDataRef dataRef = (__bridge CFDataRef)data;
    if (BDImageDetectType(dataRef) == BDImageCodeTypeWebP) {
        const char *bytes = (char *)CFDataGetBytePtr(dataRef);
        if (bytes[15] == 'L' || bytes[15] == 'X') {
            if ((bytes[20] & 0x02) == 0x02) {
                return YES;
            }
        }
    }
    if (BDImageDetectType(dataRef) == BDImageCodeTypeGIF) {
        return YES;
    }
    if (BDImageDetectType(dataRef) == BDImageCodeTypePNG) {
        const char *bytes = (char *)CFDataGetBytePtr(dataRef);
        if (bytes[37] == 'a' && bytes[38] == 'c' && bytes[39] == 'T' && bytes[40] == 'L') {
            return YES;
        }
    }
    Class cls = NSClassFromString(@"BDImageDecoderHeic");
    if (cls) {
        if ([cls respondsToSelector:@selector(canDecode:)] && [cls canDecode:data] && [cls respondsToSelector:@selector(isAnimatedImage:)] && [cls isAnimatedImage:data]) {
            return YES;
        }
    }
    return NO;
}

@end
