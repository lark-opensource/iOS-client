//
//  IESBridgeAuthManager+CN.m
//  BDJSBridgeAuthManager
//
//  Created by Lizhen Hu on 2020/6/21.
//

#import "IESBridgeAuthManager.h"

static NSString * const IWKDefaultAuthDomain = @"jsb.snssdk.com";

@implementation IESBridgeAuthManager (CN)

+ (void)configureWithAccessKey:(NSString *)accessKey commonParams:(IESBridgeAuthCommonParamsBlock)commonParams
{
    [self configureWithAuthDomain:IWKDefaultAuthDomain accessKey:accessKey afterDelay:0 commonParams:commonParams];
}

+ (NSArray<NSString *> *)defaultPrivateDomains
{
    return @[@"snssdk.com", @"toutiao.com", @"chengzijianzhan.com"];
}

@end
