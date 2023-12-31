//
//  LKCExceptionNetworkInterfaceConfig.m
//  LarkMonitor
//
//  Created by sniperj on 2019/12/31.
//

#import "LKCExceptionNetworkInterfaceConfig.h"

LK_CEXC_CONFIG(LKCExceptionNetworkInterfaceConfig)

NSString *const LKCEXCNetwork = @"network";

@implementation LKCExceptionNetworkInterfaceConfig

+ (NSString *)configKey {
    return LKCEXCNetwork;
}

@end
