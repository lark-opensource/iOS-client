//
//  BDCTEventTracker+VideoLiveness.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/16.
//

#import "BDCTEventTracker+VideoLiveness.h"
#import "BDCTStringConst.h"
#import "BytedCertError.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>


@implementation BDCTEventTracker (VideoLiveness)

- (void)trackVideoLivenessDetectionFaceQualityResult:(BOOL)success promptInfo:(NSArray *)promptInfo {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:promptInfo forKey:@"video_prompt_info"];
    [params setValue:(success ? @"success" : @"fail") forKey:@"video_prompt_result"];
    [self trackWithEvent:@"face_detection_video_quality" params:params.copy];
}

- (void)trackVideoLivenessDetectionResultWithReadNumber:(NSString *)readNumber interuptTimes:(int)interuptTimes error:(BytedCertError *)error {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    mutableParams[@"result"] = error ? @(0) : @(1);
    mutableParams[@"fail_reason"] = [BytedCertError trackErrorMsgForError:error];
    mutableParams[@"error_code"] = [BytedCertError trackErrorCodeForError:error];
    mutableParams[@"interrupt_times"] = @(interuptTimes);
    mutableParams[@"require_list"] = readNumber;
    [self trackWithEvent:@"face_detection_live_result" params:mutableParams.copy];
}

@end
