//
//  UIImage+ACCAdditions.m
//  CameraClient
//
//  Created by Liu Deping on 2019/12/3.
//

#import "UIImage+ACCUIKit.h"
#import <Accelerate/Accelerate.h>

@implementation UIImage (ACCUIKit)

- (UIImage *)acc_ImageWithTintColor:(UIColor *)tintColor
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
    [self drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tintedImage;
}

+ (UIImage*)acc_imageWithColor:(UIColor *)color size:(CGSize)size
{
    if (!color || size.width <= 0 || size.height <= 0) return nil;
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)acc_blurredImageWithRadius:(CGFloat)radius
{
    CGImageRef imageRef = self.CGImage;
    CGFloat imageScale = self.scale;
    UIImageOrientation imageOrientation = self.imageOrientation;
    
    // Image must be nonzero size
    if (CGImageGetWidth(imageRef) * CGImageGetHeight(imageRef) == 0) {
        return self;
    }
    
    //convert to ARGB if it isn't
    if (CGImageGetBitsPerPixel(imageRef) != 32 ||
        CGImageGetBitsPerComponent(imageRef) != 8 ||
        !((CGImageGetBitmapInfo(imageRef) & kCGBitmapAlphaInfoMask))) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
        [self drawAtPoint:CGPointZero];
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
    
    // A description of how to compute the box kernel width from the Gaussian
    // radius (aka standard deviation) appears in the SVG spec:
    // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
    uint32_t boxSize = floor((radius * imageScale * 3 * sqrt(2 * M_PI) / 4 + 0.5) / 2);
    boxSize |= 1; // Ensure boxSize is odd
    
    //create temp buffer
    void *tempBuffer = malloc((size_t)vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, NULL, 0, 0, boxSize, boxSize,
                                                                 NULL, kvImageEdgeExtend + kvImageGetTempBufferSize));
    
    //copy image data
    CFDataRef dataSource = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    memcpy(buffer1.data, CFDataGetBytePtr(dataSource), bytes);
    CFRelease(dataSource);
    
    //perform blur
    vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    vImageBoxConvolve_ARGB8888(&buffer2, &buffer1, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    
    //free buffers
    free(buffer2.data);
    free(tempBuffer);
    
    //create image context from buffer
    CGContextRef ctx = CGBitmapContextCreate(buffer1.data, buffer1.width, buffer1.height,
                                             8, buffer1.rowBytes, CGImageGetColorSpace(imageRef),
                                             CGImageGetBitmapInfo(imageRef));
    
    //create image from context
    imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *outputImage = [UIImage imageWithCGImage:imageRef scale:imageScale orientation:imageOrientation];
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    free(buffer1.data);
    return outputImage;
}

+ (instancetype)acc_captureWithView:(UIView *)view scope:(CGRect)scope {
    
    if (scope.origin.x > view.frame.size.width) {
        scope.origin.x = 0;
    }
    
    if (scope.origin.y > view.frame.size.height) {
        scope.origin.y = 0;
    }
    
    if ((scope.origin.x + scope.size.width) > view.frame.size.width) {
        scope.size.width = view.frame.size.width - scope.origin.x;
    }
    
    if ((scope.origin.y + scope.size.height) > view.frame.size.height) {
        scope.size.height = view.frame.size.height - scope.origin.y;
    }
    
    scope.origin.x = scope.origin.x * [UIScreen mainScreen].scale;
    scope.origin.y = scope.origin.y * [UIScreen mainScreen].scale;
    scope.size.width = scope.size.width * [UIScreen mainScreen].scale;
    scope.size.height = scope.size.height * [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef img = CGImageCreateWithImageInRect(newImage.CGImage, scope);
    UIImage *resultImg = [UIImage imageWithCGImage:img];
    CGImageRelease(img);
    return resultImg;
}

- (UIImage *)acc_imageByCropToRect:(CGRect)rect
{
    rect.origin.x *= self.scale;
    rect.origin.y *= self.scale;
    rect.size.width *= self.scale;
    rect.size.height *= self.scale;
    if (rect.size.width <= 0 || rect.size.height <= 0) return nil;
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return image;
}

#pragma mark -
+ (UIImage *)acc_imageWithSize:(CGSize)size
               backgroundColor:(UIColor *)backgroundColor {
    return [UIImage acc_imageWithSize:size
                         cornerRadius:0
                          borderWidth:0
                          borderColor:nil
                      backgroundColor:backgroundColor];
}

+ (UIImage *)acc_imageWithSize:(CGSize)size
                  cornerRadius:(CGFloat)cornerRadius
               backgroundColor:(UIColor *)backgroundColor {
    return [UIImage acc_imageWithSize:size
                         cornerRadius:cornerRadius
                          borderWidth:0
                          borderColor:nil
                      backgroundColor:backgroundColor];
}

+ (UIImage *)acc_imageWithSize:(CGSize)size
                   borderWidth:(CGFloat)borderWidth
                   borderColor:(UIColor *)borderColor
               backgroundColor:(UIColor *)backgroundColor {
    return [UIImage acc_imageWithSize:size
                         cornerRadius:0
                          borderWidth:borderWidth
                          borderColor:borderColor
                      backgroundColor:backgroundColor];
}

+ (UIImage *)acc_imageWithSize:(CGSize)size
                  cornerRadius:(CGFloat)cornerRadius
                   borderWidth:(CGFloat)borderWidth
                   borderColor:(UIColor *)borderColor
               backgroundColor:(UIColor *)backgroundColor {
    return [UIImage acc_imageWithSize:size
                         cornerRadius:cornerRadius
                          borderWidth:borderWidth
                          borderColor:borderColor
                     backgroundColors:@[backgroundColor?:[UIColor whiteColor]]];
}

+ (UIImage *)acc_imageWithSize:(CGSize)size
                  cornerRadius:(CGFloat)cornerRadius
                   borderWidth:(CGFloat)borderWidth
                   borderColor:(UIColor *)borderColor
              backgroundColors:(NSArray *)backgroundColors {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    
    // border
    if ((borderWidth > 0.0f) && borderColor && [borderColor isKindOfClass:[UIColor class]]) {
        CGRect borderRect = CGRectMake(0, 0, size.width, size.height);
        UIBezierPath * borderBezierPath = [UIBezierPath bezierPathWithRoundedRect:borderRect
                                                                     cornerRadius:cornerRadius];
        [borderColor setFill];
        [borderBezierPath fill];
    }
    
    // background
    if (backgroundColors && backgroundColors.count>0) {
        // background bezier path
        CGFloat doubleBorderWidth = borderWidth * 2;
        CGRect backgroundRect = CGRectMake(borderWidth,
                                           borderWidth,
                                           size.width - doubleBorderWidth,
                                           size.height - doubleBorderWidth);
        UIBezierPath * backgroundBezierPath = [UIBezierPath bezierPathWithRoundedRect:backgroundRect
                                                                         cornerRadius:cornerRadius];
        
        if (backgroundColors.count==1) {
            // pure color
            UIColor * backgroundColor = [backgroundColors firstObject];
            [backgroundColor setFill];
            [backgroundBezierPath fill];
        }
        else {
            // gradient color
            [backgroundBezierPath addClip];
            
            UIColor * myStartColor = [backgroundColors firstObject];
            UIColor * myEndColor = [backgroundColors lastObject];
            
            CGGradientRef myGradient;
            CGColorSpaceRef myColorspace;
            size_t num_locations = 2;
            CGFloat locations[2] = { 0.0, 1.0 };
            
            const CGFloat * startColorComponents = CGColorGetComponents(myStartColor.CGColor);
            size_t num_s = CGColorGetNumberOfComponents(myStartColor.CGColor);
            CGFloat s_red = startColorComponents[0];
            CGFloat s_green = num_s==2?s_red:startColorComponents[1];
            CGFloat s_blue = num_s==2?s_red:startColorComponents[2];
            CGFloat s_alpha = num_s==2?startColorComponents[1]:startColorComponents[3];
            
            const CGFloat * endColorComponents = CGColorGetComponents(myEndColor.CGColor);
            size_t num_e = CGColorGetNumberOfComponents(myEndColor.CGColor);
            CGFloat e_red = endColorComponents[0];
            CGFloat e_green = num_e==2?e_red:endColorComponents[1];
            CGFloat e_blue = num_e==2?e_red:endColorComponents[2];
            CGFloat e_alpha = num_e==2?endColorComponents[1]:endColorComponents[3];
            
            CGFloat components[8] = {
                s_red, s_green, s_blue, s_alpha,  // Start color
                e_red, e_green, e_blue, e_alpha // End color
            };
            
            myColorspace = CGColorSpaceCreateDeviceRGB();
            myGradient = CGGradientCreateWithColorComponents (myColorspace,
                                                              components,
                                                              locations,
                                                              num_locations);
            
            CGContextRef myContext = UIGraphicsGetCurrentContext();
            CGPoint myStartPoint, myEndPoint;
            myStartPoint.x = 0.0;
            myStartPoint.y = 0.0;
            myEndPoint.x = size.width;
            myEndPoint.y = size.height;
            CGContextDrawLinearGradient (myContext, myGradient, myStartPoint, myEndPoint, 0);
            CFRelease(myColorspace);
            CFRelease(myGradient);
        }
    }
    
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}


@end
