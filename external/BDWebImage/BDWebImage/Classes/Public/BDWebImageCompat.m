//
//  BDWebImageCompat.m
//  BDWebImage
//
//  Created by fengyadong on 2017/12/10.
//

#import "BDWebImageCompat.h"
#import <objc/runtime.h>

#ifdef BDWebImageToB_POD_VERSION
static NSString *const kBDWebImagePodVersion = BDWebImageToB_POD_VERSION;
#else
static NSString *const kBDWebImagePodVersion = @"";
#endif

inline NSString *BDWebImageSDKVersion() {
    NSString *sdkVersion = kBDWebImagePodVersion;
    NSRange underLineRange = [sdkVersion rangeOfString:@"_"];
    if (underLineRange.location != NSNotFound) {
        sdkVersion = [sdkVersion substringFromIndex:underLineRange.location+1];
    }
    return sdkVersion;
}

inline void BDWebImageMethodSwizzle(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

static BOOL _default_screen_scale_image_ = NO;

FOUNDATION_EXPORT void BDSetWebImageUsingScreenScale(BOOL use)
{
  _default_screen_scale_image_ = use;
}

NS_INLINE NSArray<NSNumber *> *BDImageScaleFactors() {
    return @[@2, @3];
}

inline CGFloat BDScaledFactorForKey(NSString * key) {
    if (_default_screen_scale_image_) {
        return [UIScreen mainScreen].scale;
    }
    CGFloat scale = 1;
    if (key.length >= 8) {
        BOOL isURL = [key hasPrefix:@"http"];
        key = [key stringByDeletingPathExtension];
        for (NSNumber *scaleFactor in BDImageScaleFactors()) {
            NSString *fileScale = [NSString stringWithFormat:@"@%@x", scaleFactor];
            if ([key hasSuffix:fileScale]) {
                scale = scaleFactor.doubleValue;
                return scale;
            }else if (isURL) {
                NSString *urlScale = [NSString stringWithFormat:@"%%40%@x", scaleFactor];
                if ([key hasSuffix:urlScale]) {
                    scale = scaleFactor.doubleValue;
                    return scale;
                }
            }
        }
    }
    return scale;
}

