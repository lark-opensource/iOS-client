//
//  IESGurdPollingRequest.h
//  BDAssert
//
//  Created by 陈煜钏 on 2020/8/31.
//

#import "IESGurdMultiAccessKeysRequest.h"

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdPollingRequest : IESGurdMultiAccessKeysRequest

@property (nonatomic, readonly, assign) IESGurdPollingPriority priority;

+ (instancetype)requestWithPriority:(IESGurdPollingPriority)priority;

@end

NS_ASSUME_NONNULL_END
