//
//  AWECloudCommandNetDiagnoseDownSpeed.m
//  AWELive
//
//  Created by songxiangwu on 2018/4/16.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWECloudCommandNetDiagnoseDownSpeed.h"
#import "AWECloudCommandNetworkUtility.h"

@implementation AWECloudCommandNetDiagnoseDownSpeed

- (void)startDownSpeedTestWithUrl:(NSString *)url completion:(AWECloudCommandNetDiagnoseDownSpeedCompletion)completion
{
    NSTimeInterval st = [[NSDate date] timeIntervalSince1970];
    
    [AWECloudCommandNetworkUtility requestWithUrl:url
                                    requestMethod:AWECloudCommandRequestMethodGet
                                           params:nil
                                   requestHeaders:nil
                           needDecodeResponseData:NO
                                          success:^(id responseObject, NSData *data, NSString *ran) {
                                              NSTimeInterval duration = [[NSDate date] timeIntervalSince1970] - st;
                                              CGFloat speed = data.length * 1.0 / duration / 1024.f;
                                              if (completion) {
                                                  completion(speed, nil);
                                              }
                                          }
                                          failure:^(NSError *error) {
                                              if (completion) {
                                                  completion(0, error);
                                              }
                                          }];
}

@end
