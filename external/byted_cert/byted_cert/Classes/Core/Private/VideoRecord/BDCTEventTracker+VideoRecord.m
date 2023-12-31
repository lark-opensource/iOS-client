//
//  BDCTEventTracker+VideoRecord.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/30.
//

#import "BDCTEventTracker+VideoRecord.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>


@implementation BDCTEventTracker (VideoRecord)

- (void)trackAuthVideoCheckingStart {
    [self trackWithEvent:@"auth_video_checking_start" params:nil];
}

- (void)trackAuthVideoCheckingResultWithError:(BytedCertError *)error params:(nonnull NSDictionary *)params {
    NSMutableDictionary *mutableParams = [params mutableCopy] ?: [NSMutableDictionary dictionary];
    mutableParams[@"result"] = error ? @"fail" : @"success";
    mutableParams[@"error_code"] = @(error == nil ? 0 : error.errorCode);
    if (error) {
        mutableParams[@"fail_reason"] = [@{@(BytedCertErrorClickCancel) : @"cancel",
                                           @(BytedCertErrorVideoUploadFailrure) : @"upload_fail",
                                           @(BytedCertErrorFaceQualityOverTime) : @"face_detect_fail"} btd_stringValueForKey:@(error.errorCode)];
    }
    [self trackWithEvent:@"auth_video_checking_result" params:mutableParams.copy];
}

@end
