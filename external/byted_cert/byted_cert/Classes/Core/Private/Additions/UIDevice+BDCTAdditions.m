//
//  UIDevice+BDCTAdditions.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/31.
//

#import "UIDevice+BDCTAdditions.h"


@implementation UIDevice (BDCTAdditions)

+ (ScreenOrient)bdct_deviceOrientation {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            return kClockwiseRotate_0;
        case UIDeviceOrientationPortraitUpsideDown:
            return kClockwiseRotate_180;
        case UIDeviceOrientationLandscapeLeft:
            return kClockwiseRotate_270;
        case UIDeviceOrientationLandscapeRight:
            return kClockwiseRotate_90;
        default:
            return kClockwiseRotate_Unknown;
    }
    return kClockwiseRotate_Unknown;
}
@end
