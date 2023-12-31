//
//  AWECloudCommandNetDiagnoseDownSpeed.h
//  AWELive
//
//  Created by songxiangwu on 2018/4/16.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AWECloudCommandNetDiagnoseDownSpeedCompletion)(CGFloat speed, NSError * _Nullable error); //k/s

@interface AWECloudCommandNetDiagnoseDownSpeed : NSObject

- (void)startDownSpeedTestWithUrl:(NSString *)url completion:(AWECloudCommandNetDiagnoseDownSpeedCompletion)completion;

@end

NS_ASSUME_NONNULL_END
