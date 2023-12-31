//
//  HMDThreadQosCollector.hpp
//  Heimdallr-8bda3036
//
//  Created by xushuangqing on 2022/5/11.
//

#ifndef HMDThreadQosCollector_hpp
#define HMDThreadQosCollector_hpp

#import <Foundation/Foundation.h>
#import "HMDThreadQosWorkerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDThreadQosCollector : NSObject <HMDThreadQosWorkerProtocol>

- (id)init __attribute__((unavailable("Use +sharedInstance to retrieve the shared instance.")));
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END

#endif /* HMDThreadQosCollector_hpp */
