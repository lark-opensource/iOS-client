//
//  LarkSafetyUtils.m
//  LarkApp
//
//  Created by KT on 2019/7/18.
//

#import "LarkSafetyUtils.h"
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>

// 防止exit函数被hook, 逆向阻止App退出
__attribute__((always_inline)) void Lark_ExitApp(void) {
#ifdef __arm64__
    __asm__("mov X0, #1 \t\n"
            "mov w16, #1 \t\n" // ip1 指针
            "svc #0x80 \t\n"

            "mov x1, #0\n" // 防止暴力 svc patch with nop
            "mov sp, x1\n"
            "mov x29, x1\n"
            "mov x30, x1\n"
            "ret"
            );
#elif __arm__
    __asm__(
            "mov r0, #1 \t\n"
            "mov ip, #1 \t\n"
            "svc #0x80 \t\n"

            "mov r1, #0\n"
            "mov sp, r1\n"
            "mov fp, r1\n"
            "mov lr, r1\n"
            "mov pc, lr"
            );
#endif
    return;
}

@implementation LarkSafetyUtils

/**
 模糊Image (比UIBlurEffect有更多控制)

 @param image 传入需要被模糊的图片
 @param radius 模糊半径
 @param iterations 迭代次数
 @param tintColor Color
 @return 模糊后Image
 */
+ (UIImage *)blurredImage:(UIImage *)image
               withRadius:(CGFloat)radius
               iterations:(NSUInteger)iterations
                tintColor:(UIColor *)tintColor
{
    if (!image || radius <= 0 || iterations <= 0) {
        return nil;
    }

    //image must be nonzero size
    if (floorf(image.size.width) * floorf(image.size.height) <= 0.0f) return image;

    //boxsize must be an odd integer
    uint32_t boxSize = (uint32_t)(radius * image.scale);
    if (boxSize % 2 == 0) boxSize ++;

    //create image buffers
    CGImageRef imageRef = image.CGImage;

    //convert to ARGB if it isn't
    if (CGImageGetBitsPerPixel(imageRef) != 32 ||
        CGImageGetBitsPerComponent(imageRef) != 8 ||
        !((CGImageGetBitmapInfo(imageRef) & kCGBitmapAlphaInfoMask)))
    {
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        //    [self drawAtPoint:CGPointZero];
        imageRef = UIGraphicsGetImageFromCurrentImageContext().CGImage;
        UIGraphicsEndImageContext();
    }

    vImage_Buffer buffer1, buffer2;
    buffer1.width = buffer2.width = CGImageGetWidth(imageRef);
    buffer1.height = buffer2.height = CGImageGetHeight(imageRef);
    buffer1.rowBytes = buffer2.rowBytes = CGImageGetBytesPerRow(imageRef);
    size_t bytes = buffer1.rowBytes * buffer1.height;
    buffer1.data = malloc(bytes);
    buffer2.data = malloc(bytes);

    //create temp buffer
    void *tempBuffer = malloc((size_t)vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, NULL, 0, 0, boxSize, boxSize,
                                                                 NULL, kvImageEdgeExtend + kvImageGetTempBufferSize));

    //copy image data
    CFDataRef dataSource = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    memcpy(buffer1.data, CFDataGetBytePtr(dataSource), bytes);
    CFRelease(dataSource);

    for (NSUInteger i = 0; i < iterations; i++)
    {
        //perform blur
        vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);

        //swap buffers
        void *temp = buffer1.data;
        buffer1.data = buffer2.data;
        buffer2.data = temp;
    }

    //free buffers
    free(buffer2.data);
    free(tempBuffer);

    //create image context from buffer
    CGContextRef ctx = CGBitmapContextCreate(buffer1.data, buffer1.width, buffer1.height,
                                             8, buffer1.rowBytes, CGImageGetColorSpace(imageRef),
                                             CGImageGetBitmapInfo(imageRef));

    //apply tint
    if (tintColor && CGColorGetAlpha(tintColor.CGColor) > 0.0f)
    {
        CGContextSetFillColorWithColor(ctx, [tintColor colorWithAlphaComponent:0.25].CGColor);
        CGContextSetBlendMode(ctx, kCGBlendModePlusLighter);
        CGContextFillRect(ctx, CGRectMake(0, 0, buffer1.width, buffer1.height));
    }

    //create image from context
    imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *blurImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    free(buffer1.data);
    return blurImage;
}

@end
