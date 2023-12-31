//
//  ACCDeviceMotion.m
//  CameraClient
//
//  Created by ZhangYuanming on 2019/12/30.
//

#import "ACCDeviceMotion.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

@interface ACCDeviceMotion ()

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) UIDeviceOrientation deviceOrientation;
@property (nonatomic, strong) NSOperationQueue *motionQueue;
@property (nonatomic) CGFloat lastXYRotate;

@end

@implementation ACCDeviceMotion

- (instancetype)init {
    if (self = [super init]) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.accelerometerUpdateInterval = 0.4;

        _motionQueue = [[NSOperationQueue alloc] init];
        _motionQueue.maxConcurrentOperationCount = 1;
    }

    return self;
}

- (void)setDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    if (_deviceOrientation != deviceOrientation) {
        _deviceOrientation = deviceOrientation;

        @weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if (self.updateBlock) {
                self.updateBlock(self);
            }
        });
    }
}

- (void)start {
    if (_motionManager.deviceMotionAvailable) {
        @weakify(self);
        [LVDMotionManager startDeviceMotionUpdatesWithManager:_motionManager queue: _motionQueue handler: ^(CMDeviceMotion *motion, NSError *error){
            @strongify(self);
            if (error || !motion) {
                AWELogToolError(AWELogToolTagRecord, @"motion start with error: %@", error);
                return;
            }

            [self performSelectorOnMainThread:@selector(calculateOrientation:) withObject:motion waitUntilDone:YES];

        }];
    }
}

- (void)stop {
    if (self.motionManager) {
        [self.motionManager stopDeviceMotionUpdates];
        [self.motionManager stopAccelerometerUpdates];
    }
}

- (void)calculateOrientation:(CMDeviceMotion *)motion {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self calculateOrientationInPad: motion];
    } else {
        [self calculateOrientationInPhone: motion];
    }
}

// iPad 直接跟随当前状态栏方向
- (void)calculateOrientationInPad:(CMDeviceMotion *)motion {
    UIInterfaceOrientation currentInterfaceOrientation = UIInterfaceOrientationUnknown;
    if (@available(iOS 13.0, *)) {
        currentInterfaceOrientation = [UIApplication acc_currentWindow].windowScene.interfaceOrientation;
    } else {
        currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    }
    switch (currentInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            self.deviceOrientation = UIDeviceOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            self.deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            self.deviceOrientation = UIDeviceOrientationLandscapeRight;
            break;
        case UIInterfaceOrientationLandscapeRight:
            self.deviceOrientation = UIDeviceOrientationLandscapeLeft;
            break;
        default:
            self.deviceOrientation = UIDeviceOrientationPortrait;
            break;
    }
}

- (void)calculateOrientationInPhone:(CMDeviceMotion *)motion {
    double x = motion.gravity.x;
    double y = motion.gravity.y;
    double z = motion.gravity.z;
    double xyTheta = atan2(x, y) / M_PI * 180.0;
    if (fabs(z) > 0.99) { //水平位置使用重力
        CMAttitude *attitude = motion.attitude;
        float yaw            = attitude.yaw;
        if (yaw < M_PI * 0.25 && yaw >= -M_PI * 0.25) {
            self.deviceOrientation = UIDeviceOrientationPortrait;
        } else if (yaw < M_PI * 0.75 && yaw >= M_PI * 0.25) {
            self.deviceOrientation = UIDeviceOrientationLandscapeLeft;
        } else if ((yaw < M_PI && yaw >= M_PI * 0.75) || (yaw < -M_PI * 0.75 && yaw >= -M_PI)) {
            self.deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
        } else if (yaw < -M_PI * 0.25 && yaw >= -M_PI * 0.75) {
            self.deviceOrientation = UIDeviceOrientationLandscapeRight;
        } else {
            self.deviceOrientation = UIDeviceOrientationPortrait;
        }
    } else {
        if (fabs(y) >= fabs(x)) {
            if (y >= 0) {
                self.deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
            } else {
                self.deviceOrientation = UIDeviceOrientationPortrait;
            }
        } else {
            if (x >= 0) {
                self.deviceOrientation = UIDeviceOrientationLandscapeRight;
            } else {
                self.deviceOrientation = UIDeviceOrientationLandscapeLeft;
            }
        }
    }
}

@end
