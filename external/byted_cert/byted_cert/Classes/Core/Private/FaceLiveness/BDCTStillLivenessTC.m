//
//  BDCTStillLivenessTC.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/5/6.
//

#import "BDCTStillLivenessTC.h"
#import "FaceLiveViewController+Layout.h"
#import "FaceLiveUtils.h"
#import "FaceLiveModule.h"
#import "BDCTAdditions.h"
#import "BDCTStringConst.h"
#import "BytedCertManager+Private.h"
#import <AVFoundation/AVFoundation.h>
#import <ByteDanceKit/ByteDanceKit.h>


@interface BDCTStillLivenessTC ()
{
    BOOL _isDetecting;
    long _detectStartTime;
    long _firstBestTime;
    BOOL _hasSuccess;
}

@property (nonatomic, strong) FaceLiveModule *faceliveInstance;

@property (nonatomic, weak) FaceLiveViewController *faceLiveViewController;

@end


@implementation BDCTStillLivenessTC

- (instancetype)initWithVC:(FaceLiveViewController *)vc {
    if (self = [super init]) {
        _faceLiveViewController = vc;
        _faceliveInstance = [FaceLiveModule new];
        int angleLimit = vc.bdct_flow.context.parameter.faceAngleLimit;
        if (angleLimit > 0 && angleLimit < 45) {
            [self setParamsGeneral:BDCT_ACTION_LIVENESS_FACE_ANGLE value:angleLimit];
        }
        [self start];
    }
    return self;
}

- (int)setInitParams:(NSDictionary *)params {
    return 0;
}

- (int)setParamsGeneral:(int)type value:(float)value {
    return [self.faceliveInstance setParamsGeneral:type value:value];
}


- (void)start {
    @synchronized(self) {
        _isDetecting = YES;
        _detectStartTime = [[NSDate date] timeIntervalSince1970];
    }
}

- (BOOL)stop {
    return [self stop:NO];
}

- (BOOL)stop:(BOOL)success {
    @synchronized(self) {
        if (!_isDetecting) {
            return NO;
        }
        _isDetecting = NO;
        _detectStartTime = 0;
        return YES;
    }
}

- (CGImageRef)doFaceLive:(CVPixelBufferRef)pixels orient:(ScreenOrient)orient {
    if (!_isDetecting) {
        _firstBestTime = 0;
        [self updateProgress:(_hasSuccess ? 1 : 0) prompt:@"" animated:NO];
        return nil;
    }
    FaceQualityInfo info;
    [self.faceliveInstance doFaceQuality:pixels orient:[UIDevice bdct_deviceOrientation] ret:&info];
    // 延迟2秒再检测
    if (info.prompt == 6) {
        if (_firstBestTime == 0) {
            _firstBestTime = [[NSDate date] timeIntervalSince1970];
        }
        double maxKeepTime = 2;
        int keepTime = [[NSDate date] timeIntervalSince1970] - _firstBestTime;
        if (keepTime < maxKeepTime) {
            CGFloat progress = (keepTime + 1) / maxKeepTime;
            [self updateProgress:progress prompt:@"请保持不动" animated:YES];
            return nil;
        }

        // 无法结束 说明已经提前结束了 无法成功
        if (![self stop:YES]) {
            return nil;
        }
        _hasSuccess = YES;

        NSData *faceData;
        CVImageBufferRef imageBuffer = pixels;
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        void *baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        faceData = [FaceLiveUtils convertRawBufferToImage:baseAddress imageName:@"env.jpg" cols:(int)width rows:(int)height bgra2rgba:false saveImage:false];
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *b64FaceWithEnv = [faceData base64EncodedStringWithOptions:0];

            NSDictionary *data = ({
                NSMutableDictionary *dicm = [NSMutableDictionary dictionary];
                dicm[@"image_env"] = b64FaceWithEnv;
                [dicm copy];
            });

            NSDictionary *packedData = ({
                NSMutableDictionary *dicm = [NSMutableDictionary dictionary];
                dicm[@"sdk_data"] = [FaceLiveUtils buildFaceCompareSDKDataWithParams:data];
                dicm[@"image_env"] = b64FaceWithEnv;
                dicm[@"image_env_data"] = faceData;
                [dicm copy];
            });
            [self.faceLiveViewController liveDetectSuccessWithPackedParams:packedData faceData:faceData resultCode:0];
        });
    } else {
        _firstBestTime = 0;
        NSString *faceDetectPrompt = [bdct_video_status_strs() btd_objectAtIndex:info.prompt];
        [self updateProgress:0 prompt:faceDetectPrompt animated:NO];
        if ([[NSDate date] timeIntervalSince1970] - self->_detectStartTime > 10 && [self stop]) {
            [BytedCertManager showAlertOnViewController:self.faceLiveViewController title:@"操作超时" message:@"正对手机，更容易成功" actions:@[
                [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeDefault title:@"再试一次" handler:^{
                    [self start];
                }]
            ]];
        }
    }

    return nil;
}

- (void)updateProgress:(float)progress prompt:(NSString *)prompt animated:(BOOL)animated {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.faceLiveViewController.actionTipLabel.text = prompt;
        [CATransaction begin];
        [CATransaction setAnimationDuration:(animated ? 1 : 0.1)];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        self.faceLiveViewController.circleProgressTrackLayer.strokeEnd = MIN(1, progress);
        [CATransaction commit];
    });
}

- (void)setMaskRadiusRatio:(float)maskRadiusRadio offsetToCenterRatio:(float)offsetToCenterRatio {
    [_faceliveInstance setMaskRadiusRatio:maskRadiusRadio offsetToCenterRatio:offsetToCenterRatio];
}

- (void)reStart:(int)type {
    [self stop];
    [self start];
    [self.faceliveInstance reStart];
}

- (void)trackCancel {
}

- (void)viewDismiss {
}

- (int)getAlgoErrorCode {
    return 0;
}

- (NSString *)getLivenessErrorTitle:(int)code {
    return nil;
}

@end
