//
//  CJPayRouteServiceImp.m
//  Pods
//
//  Created by 王新华 on 2020/11/15.
//

#import "CJPayRouteServiceImp.h"
#import "CJPayRouter.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPaySDKMacro.h"
#import "CJPayCardManageModule.h"
#import "CJPayUserCenterModule.h"
#import "CJPayProtocolManager.h"

#define CJPayRouterPattern(Path) [NSString stringWithFormat:@"sslocal://cjpay/%@", Path]

#define CJPayWakeBySchemeImpObject(ProtocolName) id<CJPayWakeBySchemeProtocol> routeImp; \
    id object = CJ_OBJECT_WITH_PROTOCOL(ProtocolName);  \
    if (object && [object conformsToProtocol:@protocol(ProtocolName)]) {  \
        if ([object respondsToSelector:(@selector(openPath:withParams:))]) {     \
            routeImp = object;                                    \
        }                                                                 \
    }

@implementation CJPayRouteServiceImp

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassToPtocol(self, CJPayRouterService)
})

+ (void)p_registerRouters {
    [CJPayRouter registerURLPattern:CJPayRouterPattern(@"webview") toHandler:^(NSDictionary * _Nonnull routerParameters) {
        CJPayWakeBySchemeImpObject(CJPayWebViewService);
        [routeImp openPath:@"webview" withParams:routerParameters];
    }];
    
    [CJPayRouter registerURLPattern:CJPayRouterPattern(@"lynxview") toHandler:^(NSDictionary * _Nonnull routerParameters) {
        
        CJPayWakeBySchemeImpObject(CJPayWebViewService);
        [routeImp openPath:@"lynxview" withParams:routerParameters];
    }];
    
    [CJPayRouter registerURLPattern:CJPayRouterPattern(@"bankcardlist") toHandler:^(NSDictionary * _Nonnull routerParameters) {
        
        CJPayWakeBySchemeImpObject(CJPayCardManageModule);
        [routeImp openPath:@"bankcardlist" withParams:routerParameters];
    }];
    
    [CJPayRouter registerURLPattern:CJPayRouterPattern(@"quickbindsign") toHandler:^(NSDictionary * _Nonnull routerParameters) {

        CJPayWakeBySchemeImpObject(CJPayCardManageModule);
        [routeImp openPath:@"quickbindsign" withParams:routerParameters];
    }];
    
    [CJPayRouter registerURLPattern:CJPayRouterPattern(@"bindcardpage") toHandler:^(NSDictionary * _Nonnull routerParameters) {
        
        CJPayWakeBySchemeImpObject(CJPayCardManageModule);
        [routeImp openPath:@"bindcardpage" withParams:routerParameters];
    }];
    
    [CJPayRouter registerURLPattern:CJPayRouterPattern(@"bdtopupdesk") toHandler:^(NSDictionary * _Nonnull routerParameters) {

        CJPayWakeBySchemeImpObject(CJPayUserCenterModule);
        [routeImp openPath:@"bdtopupdesk" withParams:routerParameters];
    }];
    
    [CJPayRouter registerURLPattern:CJPayRouterPattern(@"bdwithdrawaldesk") toHandler:^(NSDictionary * _Nonnull routerParameters) {

        CJPayWakeBySchemeImpObject(CJPayUserCenterModule);
        [routeImp openPath:@"bdwithdrawaldesk" withParams:routerParameters];
    }];
}

- (BOOL)i_openScheme:(NSString *)scheme withDelegate:(id<CJPayAPIDelegate> _Nullable)delegate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ //懒注册
        [CJPayRouteServiceImp p_registerRouters];
    });
    
    [CJTracker event: @"wallet_router_open_scheme" params: @{@"scheme": CJString(scheme)}];
    
    // 兼容老的sslocal://cjpay? 和 http的形式
    if ([self p_canOpenScheme:scheme]) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayWebViewService) i_openScheme:scheme withDelegate:delegate];
        return YES;
    }
    if ([CJPayRouter canOpenURL:scheme]) {
        if (delegate && [delegate respondsToSelector:@selector(callState:fromScene:)]) {
            [delegate callState:YES fromScene:CJPaySceneWeb];
        }
        [CJPayRouter openURL:scheme completion:^(id  _Nonnull result) {
            if (delegate) {
                [delegate onResponse:result];
            }
        }];
        return YES;
    } else {
        CJPayAPIBaseResponse *response = [CJPayAPIBaseResponse new];
        response.scene = CJPaySceneWeb;
        response.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeFail userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"打开H5失败", nil)}];
        if (delegate) {
            [delegate onResponse:response];
        }
        [CJMonitor trackService:@"wallet_rd_router_url_no_handler" category:@{@"url": CJString(scheme)} extra:@{}];
        return NO;
    }
    return NO;
}

- (BOOL)i_openScheme:(NSString *)scheme callBack:(void (^)(CJPayAPIBaseResponse *))callback {
    return [self i_openScheme:scheme withDelegate:[[CJPayAPICallBack alloc] initWithCallBack:callback]];
}

- (BOOL)p_canOpenScheme:(NSString *)scheme {
    return [scheme hasPrefix:@"http"] || [scheme hasPrefix:@"sslocal://cjpay?"] || [scheme hasPrefix:@"aweme://cjpay?"] || [scheme hasPrefix:@"sslocal://cjpay/webview?"];
}

@end
