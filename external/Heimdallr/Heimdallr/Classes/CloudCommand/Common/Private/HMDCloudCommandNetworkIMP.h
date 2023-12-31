//
//  HMDCloudCommandNetworkDelegateIMP.h
//  Pods-Heimdallr_Example
//
//  Created by zhangxiao on 2019/9/16.
//

#import <Foundation/Foundation.h>
#import <AWECloudCommand/AWECloudCommandNetworkHandler.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDCloudCommandNetworkIMP : NSObject <AWECloudCommandNetworkDelegate>

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
