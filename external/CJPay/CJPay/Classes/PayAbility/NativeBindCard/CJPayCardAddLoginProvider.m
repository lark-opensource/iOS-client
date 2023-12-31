//
//  CJPayCardAddLoginProvider.m
//  Pods
//
//  Created by 王新华 on 2021/6/15.
//

#import "CJPayCardAddLoginProvider.h"
#import "CJPayBankCardAddRequest.h"
#import "CJPayLoadingManager.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@implementation CJPayCardAddLoginProvider {
    NSDictionary *_bizParams;
    CJPayUserInfo *_userInfo;
    BOOL _haveStopedLoading;
}

@synthesize referVC;
@synthesize continueProgressWhenLoginSuccess;

- (instancetype)initWithBizParams:(NSDictionary *)bizParams userInfo:(nonnull CJPayUserInfo *)userInfo{
    self = [super init];
    if (self) {
        _bizParams = bizParams;
        _userInfo = userInfo;
    }
    return self;
}

- (nonnull NSString *)getAppId {
    return [_bizParams cj_stringValueForKey:@"app_id"];
}

- (nonnull NSString *)getMerchantId {
    return [_bizParams cj_stringValueForKey:@"merchant_id"];
}

- (nonnull NSString *)getSourceName {
    return _sourceName;
}

- (void)loadData:(void (^ _Nullable)(CJPayUniversalLoginModel * _Nullable, BOOL))completion {
    @CJWeakify(self);
    CJPayUserInfo *tmpUserInfo = _userInfo;
    [CJPayBankCardAddRequest startRequestWithBizParams:_bizParams completion:^(NSError * _Nullable error, CJPayBankCardAddResponse * _Nonnull response) {
        @CJStrongify(self);
        self.cardAddResponse = response;
        CJPayUniversalLoginModel *loginModel = [CJPayUniversalLoginModel new];
        loginModel.userInfo = response.userInfo ?: tmpUserInfo;
        loginModel.passModel = response.passModel;
        loginModel.code = response.code;
        loginModel.error = error;
        completion(loginModel, [response.code hasPrefix:@"GW4009"]);
    }];
}

- (void)startLoading {
    CJ_CALL_BLOCK(self.eventBlock, 1);
    if (_haveStopedLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading vc:self.referVC];
    }
}

- (void)stopLoading {
    CJ_CALL_BLOCK(self.eventBlock, 0);
    if (_haveStopedLoading) {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
    _haveStopedLoading = YES;
}

@end


