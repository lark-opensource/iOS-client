//
//  BDCTEventTracker+LivenessDetectionFlow.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/18.
//

#import "BDCTEventTracker+FaceVerificationFlow.h"
#import "BDCTFaceVerificationFlow+Tracker.h"
#import "BytedCertError.h"
#import <AVFoundation/AVCaptureDevice.h>


@implementation BDCTEventTracker (FaceVerificationFlow)

- (void)trackLivenessDetectionFlowComplete:(BDCTFaceVerificationFlow *)flow error:(BytedCertError *)error {
    NSString *eventName = !flow.superFlow ? @"cert_start_face_live" : @"cert_start_face_live_internal";
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@(error ? 0 : 1) forKey:@"result"];
    [params setValue:@(error.detailErrorCode ?: error.errorCode ?:
                                                                  0)
              forKey:@"error_code"];
    [params setValue:(error.detailErrorMessage ?: error.errorMessage ?:
                                                                       @"")
              forKey:@"error_msg"];
    NSInteger nowTime = NSDate.date.timeIntervalSince1970 * 1000;
    [params setValue:@(nowTime - flow.beginAt) forKey:@"during"];
    [params setValue:@(flow.liveDetectEndAt ? (flow.liveDetectEndAt - flow.beginAt) : 0) forKey:@"during_query_live"];
    [params setValue:@(flow.faceDetectBeginAt ? (flow.faceDetectBeginAt - flow.beginAt) : 0) forKey:@"during_start_activity"];
    if (flow.sdkInitEndAt) {
        [params setValue:@(flow.sdkInitEndAt - flow.beginAt) forKey:@"during_query_init"];
    }
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (AVAuthorizationStatusRestricted == authStatus || AVAuthorizationStatusDenied == authStatus) {
        [params setValue:@"0" forKey:@"already_has_permission"];
    } else {
        [params setValue:@"1" forKey:@"already_has_permission"];
    }

    [self trackWithEvent:eventName params:params.copy];
}

@end
