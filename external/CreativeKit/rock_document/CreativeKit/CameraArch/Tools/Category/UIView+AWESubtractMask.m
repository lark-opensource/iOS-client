//
//  UIView+AWESubtractMask.m
//  Pods
//
//  Created by chengfei xiao on 2019/3/3.
//

#define ROUND_UP(N, S) ((((N) + (S) - 1) / (S)) * (S))

#import "UIView+AWESubtractMask.h"

@implementation UIView (MFSubtractMask)

- (void)awe_setSubtractMaskView:(UIView *)view {

    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(),view.frame.origin.x,view.frame.origin.y);
    // CGContextSetRGBFillColor(UIGraphicsGetCurrentContext(), 1.0, 1.0, 1.0, 0);
    // CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 1.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Get the opposite mask image
    image = [self p_subtractMaskImageWithImage:image];
    // Set the reversed mask image as a boarding image
    UIView *maskView = [[UIView alloc] init];
    maskView.frame = self.bounds;
    maskView.layer.contents = (__bridge id)(image.CGImage);
    maskView.alpha = 1.f;
    
//    CALayer * layer1 = [CALayer layer];
//    layer1.frame = maskView.frame;
//    layer1.backgroundColor = [UIColor clearColor].CGColor;
//    layer1.contents = (__bridge id)(image.CGImage);
//    [maskView.layer addSublayer:layer1];
//
//    CALayer *layer = [CALayer layer];
//    layer.frame = maskView.frame;
//    layer.backgroundColor = [UIColor yellowColor].CGColor;
//    layer.opacity = 0.5f;
//    [maskView.layer addSublayer:layer];
    
    self.maskView = maskView;
}

- (UIView *)awe_subtractMaskView {
    return self.maskView;
}

#pragma mark - private methods

- (UIImage *)p_subtractMaskImageWithImage:(UIImage *)image {
    // NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    CGImageRef originalMaskImage = [image CGImage];
    float width = CGImageGetWidth(originalMaskImage);
    float height = CGImageGetHeight(originalMaskImage);
    
    int strideLength = ROUND_UP(width * 1, 4);
    unsigned char * alphaData = calloc(strideLength * height, sizeof(unsigned char));
    CGContextRef alphaOnlyContext = CGBitmapContextCreate(alphaData,
                                                          width,
                                                          height,
                                                          8,
                                                          strideLength,
                                                          NULL,
                                                          kCGImageAlphaOnly);
    
    CGContextDrawImage(alphaOnlyContext, CGRectMake(0, 0, width, height), originalMaskImage);
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            unsigned char val = alphaData[y*strideLength + x];
            val = 255 - val;
            alphaData[y*strideLength + x] = val;
        }
    }
    
    CGImageRef alphaMaskImage = CGBitmapContextCreateImage(alphaOnlyContext);
    UIImage *result = [UIImage imageWithCGImage:alphaMaskImage];
    
    CGImageRelease(alphaMaskImage);
    CGContextRelease(alphaOnlyContext);
    free(alphaData);
    return result;
}

@end
