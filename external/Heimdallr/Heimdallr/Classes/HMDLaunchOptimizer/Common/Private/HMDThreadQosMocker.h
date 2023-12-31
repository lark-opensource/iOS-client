//
//  HMDThreadQosMocker.h
//  Heimdallr-8bda3036
//
//  Created by xushuangqing on 2022/5/11.
//

#import <Foundation/Foundation.h>
#import "HMDThreadQosWorkerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDThreadQosMocker : NSObject<HMDThreadQosWorkerProtocol>

- (id)init __attribute__((unavailable("Use +sharedInstance to retrieve the shared instance.")));
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
