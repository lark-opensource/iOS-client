//
//  CJPayGeneralParamsManager.m
//  Aweme
//
//  Created by ByteDance on 2023/3/23.
//

#import "CJPayGeneralParamsManager.h"
#import "CJPayGeneralParamsService.h"
#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"
#import "CJPayRequestParam.h"
#import "CJPayBioPaymentPlugin.h"

@interface CJPayGeneralParamsManager() <CJPayGeneralParamsService>

@end

@implementation CJPayGeneralParamsManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayGeneralParamsService)
})

+ (instancetype)defaultService {
    static CJPayGeneralParamsManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CJPayGeneralParamsManager new];
    });
    return instance;
}

- (void)i_getGeneralParamsWithQuery:(NSDictionary *)query delegate:(id<CJPayAPIDelegate>)delegate {
    [self p_getLatestParams:query delegate:delegate];
}

- (void)p_getLatestParams:(NSDictionary *)query delegate:(id<CJPayAPIDelegate>)delegate{
    NSDictionary *devInfo = [CJPayRequestParam commonDeviceInfoDic];
    NSDictionary *riskInfo = [CJPayRequestParam riskInfoDict];
    NSDictionary *deviceInfo = [CJPayRequestParam riskInfoDict];
    NSDictionary *bioInfo;
    
    if (!Check_ValidString([query cj_stringValueForKey:@"uid"])) { // 这里是与安卓逻辑对齐，安卓获取bio_info需要前端下发uid
        bioInfo = [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) getPreTradeCreateBioParamDic];
    }
    
    NSDictionary *result = @{
        @"dev_info": devInfo ?: @{},
        @"risk_info": riskInfo ?: @{},
        @"device_info": deviceInfo ?: @{},
        @"bio_info":bioInfo?: @{}
    };
    
    CJPayAPIBaseResponse *baseResponse = [[CJPayAPIBaseResponse alloc] init];
    baseResponse.scene = CJPaySceneGeneralAbilityService;
    baseResponse.data = @{
        @"code": @"",
        @"msg": @"",
        @"data": result ?: @{}
    };
    [delegate onResponse:baseResponse];
}

@end
