//
//  BDCTEventTracker+ActionLiveness.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/18.
//

#import "BDCTEventTracker+ActionLiveness.h"
#import "BDCTStringConst.h"
#import "BytedCertManager+Private.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>


@implementation BDCTEventTracker (ActionLiveness)

- (void)trackActionFaceDetectionLiveResult:(NSNumber *)errorCode motionList:(NSString *)motionList promptInfos:(NSArray *)promptInfos {
    NSMutableDictionary *mutableParams = [[NSMutableDictionary alloc] init];
    mutableParams[@"result"] = errorCode ? @(0) : @(1);
    if (errorCode) {
        mutableParams[@"error_code"] = errorCode;
        mutableParams[@"fail_reason"] = [bdct_log_event_action_liveness_fail_reasons() btd_objectAtIndex:errorCode.intValue];
    }
    mutableParams[@"interrupt_times"] = @(0);
    mutableParams[@"require_list"] = motionList;
    mutableParams[@"prompt_info"] = [promptInfos btd_jsonStringEncoded];
    [self trackWithEvent:@"face_detection_live_result" params:mutableParams.copy];
}

@end
