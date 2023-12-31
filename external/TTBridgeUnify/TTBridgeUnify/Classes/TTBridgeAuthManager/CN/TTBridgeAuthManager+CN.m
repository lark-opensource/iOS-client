//
//  TTBridgeAuthManager+CN.m
//  TTBridgeUnify
//
//  Created by Lizhen Hu on 2020/6/24.
//

#import "TTBridgeAuthManager.h"
#import <BDJSBridgeAuthManager/IESBridgeAuthManager.h>

static NSString * const IWKDefaultAuthDomain = @"jsb.snssdk.com";
static NSString * const TTBoeHostSuffix = @".boe-gateway.byted.org";

@implementation TTBridgeAuthManager (CN)

+ (void)configureWithAccessKey:(NSString *)accessKey commonParams:(TTBridgeAuthCommonParamsBlock)commonParams {
    [TTBridgeAuthManager configureWithAuthDomain:IWKDefaultAuthDomain accessKey:accessKey boeHostSuffix:TTBoeHostSuffix afterDelay:0 commonParams:commonParams];
}

- (NSString *)defaultAuthRequesthHost{
     return @"https://i.snssdk.com";
}

- (NSDictionary *)defaultInnerDomains{
    return @[@".toutiao.com",
             @".toutiaoapi.com",
             @".toutiaopage.com",
             @".snssdk.com",
             @".neihanshequ.com",
             @".youdianyisi.com",
             @".huoshanzhibo.com",
             @".huoshan.com",
             @".wukong.com",
             @".chengzijianzhan.com",
             @".zjurl.cn"];
}
@end
