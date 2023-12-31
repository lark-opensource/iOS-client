//
//  HMDHTTPDetailRecord+Report.h
//  Heimdallr
//
//  Created by fengyadong on 2018/11/20.
//

#import "HMDHTTPDetailRecord.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDHTTPDetailRecord (Report)
+ (NSInteger)getHitRulesWithInAllowList:(BOOL)inAllowList;
+ (NSArray *)getHitRulesTagsArrayWithHitRulesTages:(NSArray <NSString *> *)originHitRulesTags;
+ (NSString *)getRequestLogWithRecord:(HMDHTTPDetailRecord *)record;
+ (NSArray <NSDictionary *>*)getTimingInfoV2WithTimingInfo:(NSDictionary *)timingInfo;
@end

NS_ASSUME_NONNULL_END
