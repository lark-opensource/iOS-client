//
// Created by chenzhendong.ok@bytedance.com on 2021/8/14.
//

#import <Foundation/Foundation.h>
#import "BDCTFaceVerificationFlow.h"


@interface BDCTFaceVerificationFlow (Tracker)

@property (nonatomic, assign, readonly) NSInteger beginAt;
@property (nonatomic, assign, readonly) NSInteger sdkInitEndAt;
@property (nonatomic, assign, readonly) NSInteger liveDetectEndAt;
@property (nonatomic, assign, readonly) NSInteger faceDetectBeginAt;

- (void)trackFlowBegin;

- (void)trackSDKInitRequestComplete;
- (void)trackLiveDetectRequestComplete;
- (void)trackFaceDetectBegin;

- (void)trackFlowFinishWithError:(BytedCertError *)error;

@end
