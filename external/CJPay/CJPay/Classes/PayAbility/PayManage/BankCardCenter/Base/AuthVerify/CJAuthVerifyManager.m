//
//  CJAuthVerifyManager.m
//  CJPay
//
//  Created by wangxiaohong on 2020/9/3.
//

#import "CJAuthVerifyManager.h"

#import "CJPayPrivateServiceHeader.h"
#import "CJPayAuthQueryRequest.h"
#import "CJPayLoadingManager.h"
#import "CJPayAuthQueryRequest.h"
#import "CJPayAuthQueryResponse.h"
#import "CJPayRealNameAuthToBizViewController.h"
#import "CJPayRealNameAuthToBizHalfViewController.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"
#import "CJPayAuthService.h"
#import "CJPayUIMacro.h"

@interface CJAuthVerifyManager() <CJPayAuthService>

@property (nonatomic, weak) id<CJPayAPIDelegate> apiDelegate;

@end

@implementation CJAuthVerifyManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayAuthService)
})

+ (instancetype)defaultService {
    static CJAuthVerifyManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJAuthVerifyManager alloc] init];
    });
    return manager;
}

- (void)i_authWith:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    [self openAuthDeskWithParams:params callBack:^(CJPayAuthDeskCallBackType callBackType) {
        CJPayAPIBaseResponse *resq = [CJPayAPIBaseResponse new];
        resq.scene = CJPaySceneAuth;
        NSError *error;
        switch (callBackType) {
            case CJPayAuthDeskCallBackTypeFail:
                error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeFail userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"授权失败", nil)}];
                break;
            case CJPayAuthDeskCallBackTypeCancel:
                error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeCancel userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"取消授权", nil)}];
                break;
            case CJPayAuthDeskCallBackTypeSuccess:
                error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeSuccess userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"授权成功", nil)}];
                break;
            case CJPayAuthDeskCallBackTypeUnnamed:
                error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeUnnamed userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"未实名", nil)}];
                break;
            case CJPayAuthDeskCallBackTypeLogout:
                error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeUnLogin userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"注销成功", nil)}];
                break;
            case CJPayAuthDeskCallBackTypeAuthorized:
                error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeAuthrized userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"已授权", nil)}];
                break;
            case CJPayAuthDeskCallBackTypeQueryError:
                error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeAuthQueryError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"查询授权信息出错", nil)}];
                break;
            default:
                break;
        }
        resq.error = error;
        [self p_reportMonitor:callBackType requestParams:params];
        if (delegate && [delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:resq];
        }
    }];
}


- (void)openAuthDeskWithParams:(NSDictionary *)params callBack:(void (^)(CJPayAuthDeskCallBackType))callBack
{
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:params.cjpay_referViewController];
    [CJPayAuthQueryRequest startWithBizParams:params completion:^(NSError * _Nonnull error, CJPayAuthQueryResponse * _Nonnull response) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if ([response isSuccess]) {
            if (response.isAuthorize) { //已授权
                if (callBack) {
                    callBack(CJPayAuthDeskCallBackTypeAuthorized);
                }
                return;
            }
            if (!response.isAuth) { //用户未实名，和下面的未实名不是同一种情况
                if (callBack) {
                    callBack(CJPayAuthDeskCallBackTypeUnnamed);
                }
                return;
            }
            NSDictionary *data = [params cj_dictionaryValueForKey:@"data"];
            NSString *theme = [data cj_stringValueForKey:@"theme"];
            UIViewController *authVC;
            if ([theme isEqualToString:@"pay"]) {
                authVC = [[CJPayRealNameAuthToBizHalfViewController alloc] initWithParams:params authQueryResponse:response authCallback:callBack];
            } else {
                authVC = [[CJPayRealNameAuthToBizViewController alloc] initWithParams:params authQueryResponse:response authCallback:callBack];
            }
            CJPayNavigationController *nav = [CJPayNavigationController instanceForRootVC:authVC];
            nav.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet :UIModalPresentationOverFullScreen;
            [[UIViewController cj_foundTopViewControllerFrom:params.cjpay_referViewController] presentViewController:nav animated:NO completion:nil];
            
        } else {
            if (response != nil && !response.isAuth) { //用户未实名，返回UM0401错误码
                if (callBack) {
                    callBack(CJPayAuthDeskCallBackTypeUnnamed);
                }
                return;
            }
            if (callBack) {//查询授权信息失败
                callBack(CJPayAuthDeskCallBackTypeQueryError);
            }
            return;
        }
    }];
}

- (void)p_reportMonitor:(CJPayAuthDeskCallBackType)type requestParams:(NSDictionary *)requestParams{
    NSMutableDictionary *categoryParams = [NSMutableDictionary new];
    switch (type) {
        case CJPayAuthDeskCallBackTypeFail:
            [categoryParams addEntriesFromDictionary:@{@"callback_fail":@YES}];
            break;
        case CJPayAuthDeskCallBackTypeQueryError:
            [categoryParams addEntriesFromDictionary:@{@"callback_query_error":@YES}];
            break;
        case CJPayAuthDeskCallBackTypeSuccess:
        case CJPayAuthDeskCallBackTypeUnnamed:
        case CJPayAuthDeskCallBackTypeLogout:
        case CJPayAuthDeskCallBackTypeAuthorized:
        default:
            return;
    }
    [CJMonitor trackService:@"wallet_rd_auth_verify_result" metric:@{} category:categoryParams extra:@{@"requestParams":requestParams}];
}

@end
