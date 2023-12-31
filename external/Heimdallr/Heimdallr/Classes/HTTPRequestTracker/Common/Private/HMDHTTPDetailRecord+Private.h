//
//  HMDHTTPDetailRecord+Private.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/7/19.
//

#import "HMDHTTPDetailRecord.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDHTTPDetailRecord (Private)

// 采样前置校验
@property (nonatomic, assign) BOOL isHitSDKURLAllowedListBefore;

- (void)addCustomExtraValueWithKey:(NSString *_Nonnull)key value:(id _Nonnull )value;

@end

NS_ASSUME_NONNULL_END
