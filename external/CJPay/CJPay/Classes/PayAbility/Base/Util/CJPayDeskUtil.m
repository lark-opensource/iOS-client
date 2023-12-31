//
//  CJPayDeskUtil.m
//  CJPay
//
//  Created by wangxiaohong on 2022/12/27.
//

#import "CJPayDeskUtil.h"

#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"
#import "CJPayUniversalPayDeskService.h"
#import "CJPaySaasSceneUtil.h"
#import "CJPayRequestParam.h"

@implementation CJPayDeskUtil

+ (void)openLynxPageBySchema:(NSString *)schema
             completionBlock:(void (^)(CJPayAPIBaseResponse * _Nullable))completion
{
    [self openLynxPageBySchema:schema routeDelegate:nil completionBlock:completion];
}

+ (void)openLynxPageBySchema:(NSString *)schema
               routeDelegate:(id<CJPayDeskRouteDelegate>)routeDelegate
             completionBlock:(void (^)(CJPayAPIBaseResponse * _Nullable))completion
{

    NSMutableDictionary *sdkInfoDic = [NSMutableDictionary new];
    // 适配SaaS场景：需在schema后拼上is_caijing_saas=1
    if ([CJPayRequestParam isSaasEnv]) {
        NSMutableDictionary *extraParam = [NSMutableDictionary new];
        if (![schema containsString:CJPaySaasKey]) {
            [extraParam cj_setObject:@"1" forKey:CJPaySaasKey];
        }
        if (Check_ValidString([CJPaySaasSceneUtil getCurrentSaasSceneValue]) && ![schema containsString:@"saas_scene"]) {
            [extraParam cj_setObject:CJString([CJPaySaasSceneUtil getCurrentSaasSceneValue]) forKey:@"saas_scene"];
        }
        if (Check_ValidDictionary(extraParam)) {
            schema = [CJPayCommonUtil appendParamsToUrl:schema params:extraParam];
        }
    }
    [sdkInfoDic cj_setObject:CJString(schema) forKey:@"schema"]; // schema

    NSMutableDictionary *paramDic = [NSMutableDictionary new];
    [paramDic cj_setObject:@(98) forKey:@"service"];
    [paramDic cj_setObject:sdkInfoDic forKey:@"sdk_info"];

    CJ_DECLARE_ID_PROTOCOL(CJPayUniversalPayDeskService);
    if (objectWithCJPayUniversalPayDeskService) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [objectWithCJPayUniversalPayDeskService i_openUniversalPayDeskWithParams:paramDic
                                                                       routeDelegate:routeDelegate
                                                                        withDelegate:[[CJPayAPICallBack alloc] initWithCallBack:^(CJPayAPIBaseResponse * _Nonnull response) {
                CJ_CALL_BLOCK(completion, response);
            }]];
        });
    } else {
        CJ_CALL_BLOCK(completion, nil);
    }
}

@end
