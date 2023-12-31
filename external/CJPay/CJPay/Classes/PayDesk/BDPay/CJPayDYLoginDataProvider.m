//
//  CJPayDYLoginDataProvider.m
//  CJPay
//
//  Created by 徐波 on 2020/4/9.
//

#import "CJPayDYLoginDataProvider.h"
#import "CJPayLoadingManager.h"
#import "CJPayToast.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@interface CJPayDYLoginDataProvider()

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;

@end

@implementation CJPayDYLoginDataProvider

- (instancetype)initWithBizContentParams:(NSDictionary *)bizContentParams
                         appId:(NSString *)appId
                    merhcantId:(NSString *)merchantId{
    self = [super init];
    if (self) {
        _bizContentParams = bizContentParams;
        _appId = appId;
        _merchantId = merchantId;
    }
    return self;
}

- (void)loadData:(void (^)(CJPayUniversalLoginModel * _Nullable, BOOL))completion {
    [CJPayBDCreateOrderRequest startWithAppId:self.appId merchantId:self.merchantId bizParams:self.bizContentParams completion:^(NSError * _Nonnull error, CJPayBDCreateOrderResponse * _Nonnull response) {
        self.response = response;
        if (![response isSuccess] && ![response isNeedThrottle] && Check_ValidString(response.msg) && ![response.code isEqualToString:@"GW400009"]) {
            [CJToast toastText:CJString(response.msg) inWindow:self.referVC.cj_window];
        }
        CJPayUniversalLoginModel *loginModel = [[CJPayUniversalLoginModel alloc] init];
        loginModel.passModel = response.passModel;
        loginModel.userInfo = response.userInfo;
        loginModel.code = response.code;
    
        CJ_CALL_BLOCK(completion, loginModel, NO);// 三方收银台的限流统一走收银台处理
    }];
}

- (NSString *)getAppId {
    return self.appId;
}

- (NSString *)getMerchantId {
    return self.merchantId;
}

- (NSString *)getSourceName {
    return @"支付";
}


- (void)startLoading {
    if (!self.disableLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:self.referVC];
    }
}

- (void)stopLoading {
    if (!self.disableLoading) {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

@synthesize referVC;
@synthesize continueProgressWhenLoginSuccess;

@end
