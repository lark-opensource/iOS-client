//
//  BDAutoTrackUtilities.m
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 6/28/22.
//

#import "BDAutoTrackUtilities.h"

@implementation BDAutoTrackUtilities


+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (void)ignoreAutoTrack:(UIButton *)btn {
    SEL ignoreSEL = NSSelectorFromString(@"setBdAutoTrackIgnoreClick:");
    if (![btn respondsToSelector:ignoreSEL]) {
        return;
    }
    
    IMP ignoreIMP = [btn methodForSelector:ignoreSEL];
    if (ignoreIMP) {
        id (*setBdAutoTrackIgnoreClick)(id, SEL, BOOL) = (void *)ignoreIMP;
        setBdAutoTrackIgnoreClick(btn, ignoreSEL, YES);
    }
}

@end
