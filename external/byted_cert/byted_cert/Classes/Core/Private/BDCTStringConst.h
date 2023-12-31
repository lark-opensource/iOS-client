//
//  BytedCertDisplayStringHelper.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const BytedCertPopupAlertActionRetry;
FOUNDATION_EXPORT NSString *const BytedCertPopupAlertActionQuit;

FOUNDATION_EXPORT NSArray<NSString *> *bdct_status_strs(void);
FOUNDATION_EXPORT NSArray<NSString *> *bdct_circle_strs(void);
FOUNDATION_EXPORT NSArray<NSString *> *bdct_action_strs(void);
FOUNDATION_EXPORT NSArray<NSString *> *bdct_reflection_status_strs(void);
FOUNDATION_EXPORT NSArray<NSString *> *bdct_reflection_result_strs(void);
FOUNDATION_EXPORT NSArray<NSString *> *bdct_video_status_strs(void);

FOUNDATION_EXPORT NSArray<NSString *> *bdct_log_event_action_strs_en(void);

FOUNDATION_EXPORT NSDictionary<NSNumber *, NSString *> *bdct_error_code_to_message(void);
FOUNDATION_EXPORT NSArray<NSString *> *bdct_log_event_action_liveness_fail_reasons(void);
FOUNDATION_EXPORT NSDictionary<NSNumber *, NSString *> *bdct_log_event_video_liveness_fail_reasons(void);
FOUNDATION_EXPORT NSArray<NSString *> *bdct_offline_model_pre(void);
FOUNDATION_EXPORT NSArray<NSString *> *bdct_reflection_model_pre(void);
FOUNDATION_EXPORT NSArray<NSString *> *bdct_audio_resource_pre(void);


@interface BDCTStringConst : NSObject

@end

NS_ASSUME_NONNULL_END
