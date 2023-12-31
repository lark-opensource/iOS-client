//
//  AWECloudCommandNetDiagnoseUpSpeed.h
//  AWELive
//
//  Created by songxiangwu on 2018/4/16.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AWECloudCommandNetDiagnoseUpSpeedCompletion)(CGFloat speed, NSError * _Nullable error, NSString * _Nullable url); //k/s

@interface AWECloudCommandNetDiagnoseUpSpeed : NSObject

- (void)startUpSpeedTestWithCompletion:(AWECloudCommandNetDiagnoseUpSpeedCompletion)completion;

@end

NS_ASSUME_NONNULL_END
