//
//  UIImage+CJPay.m
//  CJPay
//
//  Created by 王新华 on 2/24/20.
//

#import "UIImage+CJPay.h"
#import "NSBundle+CJPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"

@implementation UIImage(CJPay)

+ (nullable UIImage *)cj_imageWithName:(NSString *)imageName {
    static NSBundle *bundle = nil;
    
    if (!bundle) {
        bundle = [NSBundle cj_customPayBundle];
    }
    
    if (!bundle) {
        [CJMonitor trackService:@"wallet_rd_bundle_load" extra:@{@"imageName" : CJString(imageName)}];
    }
    UIImage *image =  [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    return image;
}

+ (UIImage *)cj_imageWithColor: (UIColor *)color {
    
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

+ (UIImage *)cj_roundImageWithColor: (UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 12.f, 12.f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetShouldAntialias(context, YES);
    CGContextAddArc(context, 6, 6, 6, 0, 2 * CJPI, 0);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillPath(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)cj_rightAngleImageWithColor:(UIColor *)color
                                   width:(CGFloat)lineWidth
                                    rect:(CGRect)rect {
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetShouldAntialias(context, YES);
    [bezierPath moveToPoint:CGPointMake(0, 0)];
    [bezierPath addLineToPoint:CGPointMake(0, rect.size.height)];
    [bezierPath addLineToPoint:CGPointMake(lineWidth, rect.size.height)];
    [bezierPath addLineToPoint:CGPointMake(lineWidth, lineWidth)];
    [bezierPath addLineToPoint:CGPointMake(rect.size.width, lineWidth)];
    [bezierPath addLineToPoint:CGPointMake(rect.size.width, 0)];
    [bezierPath addLineToPoint:CGPointMake(0, 0)];
    [bezierPath closePath];
    CGContextAddPath(context, bezierPath.CGPath);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillPath(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)cj_imageWithAnotherImage:(UIImage *)anotherImage {
    CGSize size = self.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    [anotherImage drawInRect:CGRectMake(0, 0, size.width, size.height) blendMode:kCGBlendModeNormal alpha:1.0];
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    return resultImage;
}

- (UIImage *)cj_scaleToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaleImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaleImage;
}

+ (UIImage *)cj_imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // Get a CMSampleBuffer's Core Video image buffer for the media data
      CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
      // Lock the base address of the pixel buffer
      CVPixelBufferLockBaseAddress(imageBuffer, 0);
      
      // Get the number of bytes per row for the pixel buffer
      void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
      
      // Get the number of bytes per row for the pixel buffer
      size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
      // Get the pixel buffer width and height
      size_t width = CVPixelBufferGetWidth(imageBuffer);
      size_t height = CVPixelBufferGetHeight(imageBuffer);
      
      // Create a device-dependent RGB color space
      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
      
      // Create a bitmap graphics context with the sample buffer data
      CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
      // Create a Quartz image from the pixel data in the bitmap graphics context
      CGImageRef quartzImage = CGBitmapContextCreateImage(context);
      // Unlock the pixel buffer
      CVPixelBufferUnlockBaseAddress(imageBuffer,0);
      
      // Free up the context and color space
      CGContextRelease(context);
      CGColorSpaceRelease(colorSpace);
      
      // Create an image object from the Quartz image
      //UIImage *image = [UIImage imageWithCGImage:quartzImage];
      UIImage *image = [UIImage imageWithCGImage:quartzImage];
      
      // Release the Quartz image
      CGImageRelease(quartzImage);
      
      return (image);
}

- (UIImage *)cj_changeWithColor:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, self.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    CGContextClipToMask(context, rect, self.CGImage);
    [color setFill];
    CGContextFillRect(context, rect);
    UIImage*newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
