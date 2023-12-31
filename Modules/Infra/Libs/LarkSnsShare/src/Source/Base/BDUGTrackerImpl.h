//
//  BDUGTrackerImpl.h
//  BDUGPushDemo
//
//  Created by bytedance on 2019/6/19.
//  Copyright © 2019年 bytedance. All rights reserved.
//

#if LarkSnsShare_InternalSnsShareDependency
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDUGTrackerImpl : NSObject

- (void)event:(NSString *)event params:(NSDictionary * _Nullable)params;

- (void)trackService:(NSString *)serviceName attributes:(NSDictionary *)attributes;

@end

NS_ASSUME_NONNULL_END
#endif
