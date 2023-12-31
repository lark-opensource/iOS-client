//
//  CJPayBridgeAuthManager.m
//  CJPay
//
//  Created by 王新华 on 2022/7/2.
//

#import "CJPayBridgeAuthManager.h"
#import <BDJSBridgeAuthManager/IESBridgeAuthManager.h>
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import <IESJSBridgeCore/WKWebView+IESBridgeExecutor.h>
#import <IESJSBridgeCore/IESBridgeMessage.h>
#import "CJPayUIMacro.h"
#import <TTBridgeUnify/TTBridgePlugin.h>
#import <TTBridgeUnify/BDUnifiedWebViewBridgeEngine.h>
#import <WebKit/WKWebView.h>
#import <TTBridgeUnify/NSObject+IESAuthManager.h>
#import <TTBridgeUnify/TTBridgeAuthManager.h>

@interface CJPayBridgeAuthManager()<IESBridgeAuthManagerDelegate, TTBridgeInterceptor, IESBridgeEngineInterceptor>

@property (nonatomic, strong) IESBridgeAuthManager *authManager;

@end

@implementation CJPayBridgeAuthManager

+ (CJPayBridgeAuthManager *)shared {
    static CJPayBridgeAuthManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CJPayBridgeAuthManager new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_loadDomainWhiteListIfNeeded) name:CJPayFetchSettingsSuccessNotification object:nil];
    }
    return self;
}

- (IESBridgeAuthManager *)authManager {
    if (!_authManager) {
        _authManager = [IESBridgeAuthManager sharedManagerWithNamesapce:@"ttcjpay"];
        _authManager.delegate = self;
    }
    return _authManager;
}

- (NSSet<NSString *> *)allowedDomainsForSDK
{
    NSMutableSet<NSString *> *whiteListSet = [NSMutableSet new];

    NSArray *secDomains = [CJPaySettingsManager shared].currentSettings.secDomains;
    if (Check_ValidArray(secDomains)) {
        CJPayLogInfo(@"Settings下发的授权域名 domains = %@", secDomains);
        [whiteListSet addObjectsFromArray:secDomains];
    }
    // settings数据和兜底数据做合并
    [whiteListSet addObjectsFromArray:@[@".snssdk.com", @".ulpay.com", @".fangxinjiefxj.com", @".baohuaxia.com", @".bytedance.net", @".toutiao.com", @".byted.org", @".bytedance.net", @".bytednsdoc.com", @".feishu.cn", @".doupay.com"]];

    return [whiteListSet copy];
}

- (void)installEngineOn:(WKWebView *)webview {
    [webview tt_installBridgeEngine:BDUnifiedWebViewBridgeEngine.new];
}

- (void)installIESAuthOn:(WKWebView *)webview {
    [IESBridgeEngine addInterceptor:self];
    if ([CJPaySettingsManager shared].currentSettings.webviewCommonConfigModel.useIESAuthManager) {
        webview.tt_engine.sourceObject.ies_authManager = self.authManager;
        [self.authManager addPrivateDomains:[[self allowedDomainsForSDK] allObjects]];
        CJPayLogInfo(@"使用了IESAuthManager来进行鉴权");
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self p_loadDomainWhiteListIfNeeded];
        [TTBridgeRegister addInterceptor:self];
    });
}

- (void)p_loadDomainWhiteListIfNeeded
{
    NSArray *oldList = [[NSArray alloc] init];
    
    TTBridgeAuthManager *manager = [TTBridgeAuthManager sharedManager];
    SEL whiteListGetter = @selector(innerDomains);
    if ([manager respondsToSelector:whiteListGetter]) {
        oldList = [manager performSelector:@selector(innerDomains)];
    }
    
    NSSet *SDKSet = [self allowedDomainsForSDK];
    NSMutableSet *resultSet = [NSMutableSet setWithArray:oldList];
    [resultSet unionSet:SDKSet];
    
    SEL whiteListSetter = @selector(setInnerDomains:);
    if ([manager respondsToSelector:whiteListSetter]) {
        [manager performSelector:@selector(setInnerDomains:) withObject:[resultSet allObjects]];
    }
    CJPayLogInfo(@"所有授权的域名 domains = %@", resultSet);
}

#pragma - mark auth Delegate
- (BOOL)authManager:(IESBridgeAuthManager *)authManager isAuthorizedMethod:(NSString *)method forURL:(NSURL *)url {
    __block BOOL permitted = NO;
    if (!url || !Check_ValidString(url.host)) {
        permitted = NO;
    } else {
        NSArray<NSString *> *innerDomains = [[self allowedDomainsForSDK] allObjects];
        [innerDomains enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (Check_ValidString(obj) && [url.host hasSuffix:obj]) {
                permitted = YES;
                *stop = YES;
            }
        }];
    }
    CJPayLogInfo(@"ttcjpay auth: method = %@, url = %@, permitted = %@", method, url, @(permitted));
    return permitted;
}

- (void)authManager:(IESBridgeAuthManager *)authManager isAuthorizedMethod:(NSString *)method success:(BOOL)success forURL:(NSURL *)url stage:(NSString *)stage list:(NSArray<NSString *> *)list {
    CJPayLogInfo(@"ttcjpay auth: method = %@, success = %d, url = %@, stage = %@, list = %@", method, success, [url absoluteString], stage, list);
}

- (BOOL)p_isSelfBridges:(TTBridgeCommand *)command {
    if ([command.bridgeName hasPrefix:@"ttcjpay."]) {
        return YES;
    }
    return NO;
}

- (void)bridgeEngine:(id<TTBridgeEngine>)engine willExecuteBridgeCommand:(TTBridgeCommand *)command {
    BOOL isWebView = [engine.sourceObject isKindOfClass:WKWebView.class];
    if ([self p_isSelfBridges:command]) {
        NSURL *url = engine.sourceURL;
        NSDictionary *category = @{
            @"host": CJString(url.host),
            @"path": CJString(url.path),
            @"url": CJString([url absoluteString]),
            @"is_web": isWebView ? @"1" : @"0",
            @"method": CJString(command.bridgeName)
        };
        [CJMonitor trackService:@"wallet_rd_jsb_invoke" category:category extra:@{}];
//        if ([command respondsToSelector:NSSelectorFromString(@"originMessage")]) {
//            CJPayLogInfo(@"willExecuteBridgeCommand: bridgeName: %@, params: %@, originMessage: %@", CJString(command.bridgeName), command.params, command.originMessage);
//        }
    }
}

- (void)bridgeEngine:(id<TTBridgeEngine>)engine willCallbackBridgeCommand:(TTBridgeCommand *)command {
    BOOL isWebView = [engine.sourceObject isKindOfClass:WKWebView.class];
    if ([self p_isSelfBridges:command]) {
        NSURL *url = engine.sourceURL;
        NSDictionary *metric = @{@"duration" : @([[NSDate date] timeIntervalSince1970] * 1000 - [command.startTime longLongValue])};
        NSDictionary *category = @{
            @"host": CJString(url.host),
            @"path": CJString(url.path),
            @"url": CJString([url absoluteString]),
            @"is_web": isWebView ? @"1" : @"0",
            @"method": CJString(command.bridgeName),
            @"result_code": CJString([@(command.bridgeMsg) stringValue])
        };
        [CJMonitor trackService:@"wallet_rd_jsb_callback" metric:metric category:category extra:@{}];
        NSDictionary *resultMessage = @{};
//        if ([command respondsToSelector:NSSelectorFromString(@"originMessage")] && [command.originMessage isKindOfClass:IESBridgeMessage.class]) {
//            IESBridgeMessage *msg = (IESBridgeMessage *)command.originMessage;
//            resultMessage = msg.params;
//        }
        CJPayLogInfo(@"willCallbackBridgeCommand: bridgeName: %@, params: %@, callback_data: %@", CJString(command.bridgeName), command.params, resultMessage);
    }
}

#pragma - mark IESBridgeEngineInterceptor
- (void)bridgeEngine:(IESBridgeEngine *)engine willFireEventWithMessage:(IESBridgeMessage *)bridgeMessage {
    if (Check_ValidString(bridgeMessage.eventID) && [bridgeMessage.eventID hasPrefix:@"ttcjpay"]) {
        CJPayLogInfo(@"willFireEventWithMessage, eventID: %@, params: %@", bridgeMessage.eventID, bridgeMessage.params);
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
