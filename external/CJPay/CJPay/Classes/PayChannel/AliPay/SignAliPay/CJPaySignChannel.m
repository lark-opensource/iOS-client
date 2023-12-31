//
//  CJPaySignChannel.m
//  arkcrypto-minigame-iOS
//
//  Created by mengxin on 2021/3/10.
//

#import "CJPaySignChannel.h"
#import "CJPaySDKMacro.h"
#import <AlipaySDK/AlipaySDK.h>
#import "CJPayChannelManager.h"
#import "CJPayPrivacyMethodUtil.h"

static NSString * const CJAlipaySchemeKey = @"alipayShare";

@interface CJPaySignChannel()

@property (nonatomic, copy) NSString *signAliPayScheme;
@property (nonatomic, copy) CompletionBlock signAliPayCompletionBlock;
@property (nonatomic, assign) BOOL wakingApp;

@end

@implementation CJPaySignChannel

CJPAY_REGISTER_PLUGIN({
    [[CJPayChannelManager sharedInstance] registerChannelClass:self channelType:CJPayChannelTypeSignTbPay];
})

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedInstance), CJPaySignAliPayModule)
})

- (instancetype)init {
    self = [super init];
    if (self) {
        self.channelType = CJPayChannelTypeSignTbPay;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidInForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance {
    static CJPaySignChannel *channel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        channel = [[CJPaySignChannel alloc] init];
    });
    return channel;
}

- (NSString *)signAliPayScheme {
    NSString *alipayScheme = @"";
    NSArray *URLTypeArray = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
    for (NSDictionary *anURLType in URLTypeArray) {
        if ([CJAlipaySchemeKey isEqualToString:[anURLType objectForKey:@"CFBundleURLName"]]) {
            alipayScheme = [[anURLType objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
            break;
        }
    }
    return alipayScheme;
}

- (BOOL)canProcessWithURL:(NSURL *)URL {
    
    NSString *scheme = [[URL scheme] lowercaseString];
    NSString *host = [[URL host] lowercaseString];
    
    BOOL canProcess = [scheme isEqualToString:[self signAliPayScheme]] && [host isEqualToString:@"apmqpdispatch"];
    if (canProcess) {
        [AFServiceCenter handleResponseURL:URL withCompletion:^(AFServiceResponse *response) {
            [self handleSignAliPayResponseWith:response];
        }];
    }
    return canProcess;
}


- (void)appDidInForeground {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.wakingApp) {
            self.completionBlock(CJPayChannelTypeSignTbPay, CJPayResultTypeBackToForeground, @"");
            self.wakingApp = NO;
        }
    });
}

- (void)payActionWithDataDict:(NSDictionary *)dataDict completionBlock:(CJPayCompletion)completionBlock {
    [super payActionWithDataDict:dataDict completionBlock:completionBlock];
    NSString *url = [dataDict cj_stringValueForKey:@"url"];
    NSURL *signURL = [NSURL URLWithString:url];
    if (!signURL) {
        CJ_CALL_BLOCK(self.completionBlock, self.channelType, CJPayResultTypeFail, @"");
        return;
    }
    if (![CJPaySignChannel isAvailableUse]) {
        CJ_CALL_BLOCK(self.completionBlock, self.channelType, CJPayResultTypeUnInstall, @"");
        return;
    }
    [[UIApplication sharedApplication] openURL:signURL options:@{} completionHandler:^(BOOL success) {
        CJPayLogInfo(@"支付宝签约App唤起状态：%d", success);
        if (!success) {
            CJ_CALL_BLOCK(self.completionBlock, self.channelType, CJPayResultTypeFail, @"");
        }
        self.wakingApp = YES;
    }];
}

+ (BOOL)isAvailableUse {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"alipay://"]];
}

@end


@implementation CJPaySignChannel(AliPaySDKSign)

// 支付宝独立签约
- (void)signActionWithDataDict:(NSDictionary *)dataDict completionBlock:(void(^)(NSDictionary *resultDic))completionBlock {
    self.signAliPayCompletionBlock = completionBlock;
    NSString *signParamStr = [dataDict cj_stringValueForKey:@"sign_params"];
    if (!Check_ValidString(signParamStr)) {// 缺少该参数之后，走降级逻辑
        CJ_CALL_BLOCK(self.signAliPayCompletionBlock, @{@"code": @(9), @"msg": @"参数错误"});
        return;
    }
    [self p_signByAliPaySDK:signParamStr];
}

- (void)p_signByAliPaySDK:(NSString *)signParamStr{
    NSDictionary *params = @{
        kAFServiceOptionBizParams: @{
                @"sign_params": signParamStr
        },
        kAFServiceOptionCallbackScheme: self.signAliPayScheme,
    };
    if (![CJPaySignChannel isAvailableUse]) {
        CJ_CALL_BLOCK(self.signAliPayCompletionBlock, @{@"code": @(3), @"msg": @"未安装支付宝"});
        return;
    }
    [CJPayPrivacyMethodUtil injectCert:@"bpea-cjpaysignchannel_ap_signaction"];
    [AFServiceCenter callService:AFServiceDeduct withParams:params andCompletion:^(AFServiceResponse *response) {
        [self handleSignAliPayResponseWith:response];
    }];
    [CJPayPrivacyMethodUtil clearCert];
}

- (void)handleSignAliPayResponseWith:(AFServiceResponse *)response {
    NSDictionary *dic = [response.result cj_objectForKey:@"alipay_user_agreement_page_sign_response"];
    NSInteger code = [dic cj_integerValueForKey:@"code"];
    NSString *msg = [dic cj_stringValueForKey:@"msg"];
    NSString *res = @"0";
    switch (response.responseCode) {
        case AFResSuccess:
            if (code == 10000) {
                res = @"1";
                CJ_CALL_BLOCK(self.signAliPayCompletionBlock, @{@"code": @(0), @"msg": msg});
            } else if(code == 60001) {
                CJ_CALL_BLOCK(self.signAliPayCompletionBlock, @{@"code": @(9), @"msg": @"签约取消"});
            } else {
                CJ_CALL_BLOCK(self.signAliPayCompletionBlock, @{@"code": @(9), @"msg": @"开通失败"});
            }
            break;
        case AFResRepeatCall:
            CJ_CALL_BLOCK(self.signAliPayCompletionBlock, @{@"code": @(1), @"msg": @"业务重复调用"});
            break;
        default:
            CJ_CALL_BLOCK(self.signAliPayCompletionBlock, @{@"code": @(9), @"msg": @"开通失败"});
            break;
    }
}

#pragma mark CJPaySignAliPayModule

- (BOOL)wakeByUniversalPayDesk:(NSDictionary *)dictionary withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self i_signActionWithDataDict:dictionary completionBlock:^(NSDictionary *resultDic) {
        CJPayErrorCode errorCode = CJPayErrorCodeFail;
        NSInteger code = [resultDic cj_integerValueForKey:@"code"];
        switch (code) {
            case 0:
                errorCode = CJPayErrorCodeSuccess;
                break;
            default:
                break;
        }
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.scene = CJPaySceneSign;
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(CJString([resultDic cj_stringValueForKey:@"msg"]), nil)}];
        apiResponse.data = @{
            @"sdk_code": @([resultDic cj_integerValueForKey:@"code"]),
            @"sdk_msg": [resultDic cj_stringValueForKey:@"msg"]
        };
        if ([delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:apiResponse];
        }
    }];
    return YES;
}

- (void)i_signActionWithDataDict:(NSDictionary *)dataDict completionBlock:(void(^)(NSDictionary *resultDic))completionBlock {
    [self signActionWithDataDict:dataDict completionBlock:completionBlock];
}

@end
