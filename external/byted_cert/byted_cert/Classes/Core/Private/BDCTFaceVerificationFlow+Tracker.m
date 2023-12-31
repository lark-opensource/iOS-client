//
// Created by chenzhendong.ok@bytedance.com on 2021/8/14.
//

#import "BDCTFaceVerificationFlow+Tracker.h"
#import "BDCTEventTracker+FaceVerificationFlow.h"

#import <objc/runtime.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

#define BDCTTrackMillisecondSince1970 @(NSDate.date.timeIntervalSince1970 * 1000)


@implementation BDCTFaceVerificationFlow (Tracker)

- (NSMutableDictionary *)flowTrackParams {
    NSMutableDictionary *flowTrackParams = objc_getAssociatedObject(self, _cmd);
    if (!flowTrackParams) {
        flowTrackParams = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, flowTrackParams, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return flowTrackParams;
}

- (NSInteger)beginAt {
    return [[self flowTrackParams] btd_integerValueForKey:NSStringFromSelector(_cmd)];
}

- (NSInteger)sdkInitEndAt {
    return [[self flowTrackParams] btd_integerValueForKey:NSStringFromSelector(_cmd)];
}

- (NSInteger)liveDetectEndAt {
    return [[self flowTrackParams] btd_integerValueForKey:NSStringFromSelector(_cmd)];
}

- (NSInteger)faceDetectBeginAt {
    return [[self flowTrackParams] btd_integerValueForKey:NSStringFromSelector(_cmd)];
}

- (void)trackFlowBegin {
    [[self flowTrackParams] setValue:BDCTTrackMillisecondSince1970 forKey:NSStringFromSelector(@selector(beginAt))];
}

- (void)trackSDKInitRequestComplete {
    [[self flowTrackParams] setValue:BDCTTrackMillisecondSince1970 forKey:NSStringFromSelector(@selector(sdkInitEndAt))];
}

- (void)trackLiveDetectRequestComplete {
    [[self flowTrackParams] setValue:BDCTTrackMillisecondSince1970 forKey:NSStringFromSelector(@selector(liveDetectEndAt))];
}

- (void)trackFaceDetectBegin {
    [[self flowTrackParams] setValue:BDCTTrackMillisecondSince1970 forKey:NSStringFromSelector(@selector(faceDetectBeginAt))];
    [self.eventTracker trackFaceDetectionStart];
}

- (void)trackFlowFinishWithError:(BytedCertError *)error {
    // 全流程结束
    [self.eventTracker trackLivenessDetectionFlowComplete:self error:error];
    [[self flowTrackParams] removeAllObjects];
}

@end
