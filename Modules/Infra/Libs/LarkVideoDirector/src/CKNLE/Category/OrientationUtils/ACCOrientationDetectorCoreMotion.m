//
//  ACCOrientationDetectorCoreMotion.m
//  AWEStudio-Pods-DouYin
//
//  Created by Howie He on 2020/8/10.
//

#import "ACCOrientationDetectorCoreMotion.h"
#import "ACCDeviceMotion.h"

@interface ACCOrientationDetectorCoreMotion ()

@property (nonatomic) UIDeviceOrientation orientation;
@property (nonatomic) ACCDeviceMotion *deviceMotion;

@end

@implementation ACCOrientationDetectorCoreMotion

- (instancetype)init
{
    self = [super init];
    if (self) {
        _deviceMotion = [[ACCDeviceMotion alloc] init];
        __weak typeof(self) wself = self;
        _deviceMotion.updateBlock = ^(ACCDeviceMotion * _Nonnull motion) {
            __strong typeof(wself) sself = wself;
            switch (motion.deviceOrientation) {
                case UIDeviceOrientationPortrait:
                case UIDeviceOrientationPortraitUpsideDown:
                case UIDeviceOrientationLandscapeLeft:
                case UIDeviceOrientationLandscapeRight:
                    sself.orientation = motion.deviceOrientation;
                    break;
                default:
                    break;
            }
        };
    }
    return self;
}

- (void)startDetect
{
    [self.deviceMotion start];
}

- (void)stopDetect
{
    [self.deviceMotion stop];
}

@end
