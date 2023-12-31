//
//  BDCTEventTracker+ReflectionLiveness.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/16.
//

#import "BDCTEventTracker+ReflectionLiveness.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>


@implementation BDCTEventTracker (ReflectionLiveness)

- (void)trackReflectionLivenessDetectionColorQualityResult:(BOOL)success promptInfo:(NSArray *)promptInfo {
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionary];
    [trackParams setValue:[promptInfo btd_jsonStringEncoded] forKey:@"color_prompt_info"];
    [trackParams setValue:(success ? @"success" : @"fail") forKey:@"color_prompt_result"];
    [self trackWithEvent:@"face_detection_color_quality" params:trackParams.copy];
}

- (void)trackReflectionLivenessDetectionResult:(BOOL)success colorPromptInfo:(NSArray *)colorPromptInfo colorList:(NSArray *)colorList interruptTimes:(int)interruptTimes errorCode:(int)errorCode {
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionary];
    [trackParams setValue:[colorPromptInfo btd_jsonStringEncoded] forKey:@"prompt_info"];
    [trackParams setValue:[colorList btd_jsonStringEncoded] forKey:@"require_list"];
    [trackParams setValue:@(interruptTimes) forKey:@"interrupt_times"];
    [trackParams setValue:@(errorCode) forKey:@"error_code"];
    [trackParams setValue:(success ? @"success" : @"fail") forKey:@"color_detection_result"];
    [self trackWithEvent:@"face_detection_live_result" params:trackParams.copy];
}

@end
