//
//  AWECloudCommandNetDiagnoseAddressInfo.h
//  AWELive
//
//  Created by songxiangwu on 2018/4/16.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWECloudCommandNetDiagnoseAddressInfo : NSObject

+ (NSString *)deviceIPAdress;
+ (NSString *)getGatewayIPAddress;
+ (NSArray *)getDNSsWithDormain:(NSString *)hostName;
+ (NSArray *)outPutDNSServers;

@end

NS_ASSUME_NONNULL_END
