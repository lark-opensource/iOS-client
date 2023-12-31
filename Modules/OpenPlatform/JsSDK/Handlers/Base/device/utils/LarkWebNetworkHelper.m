//
//  LarkWebNetworkHelper.m
//  LarkWeb
//
//  Created by 李论 on 2019/12/12.
//

#import "LarkWebNetworkHelper.h"
#import <arpa/inet.h>
#import "LarkWebRouterInfo.h"

@implementation GatewayIPInfoData

- (instancetype)init
{
    if(self = [super init]) {
        _errMsg = @"";
        _routerIP = @"0.0.0.0";
    }
    return self;
}

@end


@implementation LarkWebNetworkHelper

+ (GatewayIPInfoData *)gatewayInfo
{
    GatewayIPInfoData *ipInfo = [[GatewayIPInfoData alloc] init];
    struct in_addr gatewayaddr = {0};
    ipInfo.code = getdefaultgateway((in_addr_t *)(&gatewayaddr));
    if(ipInfo.code >= 0) {
        ipInfo.routerIP = [NSString stringWithFormat: @"%s",inet_ntoa(gatewayaddr)];
    } else {
        ipInfo.errMsg = [NSString stringWithFormat:@"error code: %@", @(ipInfo.code)];
    }
    return ipInfo;
}

@end
