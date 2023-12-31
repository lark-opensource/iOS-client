//
//  CJPayAliChannel.m
//  AFgzipRequestSerializer
//
//  Created by jiangzhongping on 2018/8/29.
//

#import "CJPayAliChannel.h"
#import "CJPayUIMacro.h"
#import <AlipaySDK/AlipaySDK.h>
#import "CJPayChannelManager.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"

static NSString * const CJAlipaySchemeKey = @"alipayShare";

@interface CJPayAliChannel()
@property (nonatomic, assign) BOOL wakingApp;
@property (nonatomic, assign) BOOL startTime;

@end

@implementation CJPayAliChannel

CJPAY_REGISTER_PLUGIN({
    [[CJPayChannelManager sharedInstance] registerChannelClass:self channelType:CJPayChannelTypeTbPay];
})

- (instancetype)init {
    self = [super init];
    if (self) {
        self.channelType = CJPayChannelTypeTbPay;
        self.startTime = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidInForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidInBackground)
        name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)channelScheme {

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

//检查是否可用
+ (BOOL)isAvailableUse {
    return YES;
}

- (BOOL)isInstalled {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"alipay://"]];
}

- (NSString *)getAliPayVersion {
    return [[AlipaySDK defaultService] currentVersion];
}

- (BOOL)canProcessWithURL:(NSURL *)URL {
    
    NSString *scheme = [URL scheme];
    NSString *host = [[URL host] lowercaseString];
    
    BOOL canProcess = [scheme isEqualToString:[self channelScheme]] && [host isEqualToString:@"safepay"];
    if (canProcess) {
        @CJWeakify(self)
        [[AlipaySDK defaultService] processOrderWithPaymentResult:URL standbyCallback:^(NSDictionary *resultDic) {
            @CJStrongify(self)
            [self handleAliPayResponse:resultDic];
        }];
    }
    
    return canProcess;
}


- (void)payActionWithDataDict:(NSDictionary *)dataDict completionBlock:(CJPayCompletion) completionBlock {
    
    [super payActionWithDataDict:dataDict completionBlock:completionBlock];
    
    NSString *selfScheme = [self channelScheme];
    if (selfScheme == nil || selfScheme.length == 0) {
        // scheme is nil or scheme length is zero...
        return;
    }
    
    NSString *payOrder = dataDict[@"url"];
    if (payOrder == nil || payOrder.length == 0) {
        // payOrder is nil or payOrder length is zero...
        return;
    }
    @CJWeakify(self);
    self.wakingApp = YES;
    self.startTime = CFAbsoluteTimeGetCurrent();
    [[AlipaySDK defaultService] payOrder:payOrder fromScheme:selfScheme callback:^(NSDictionary *resultDic) {
        [weak_self handleAliPayResponse:resultDic];
    }];
}

#pragma mark - private method
//9000    订单支付成功
//8000    正在处理中，支付结果未知（有可能已经支付成功），请查询商户订单列表中订单的支付状态
//4000    订单支付失败
//5000    重复请求
//6001    用户中途取消
//6002    网络连接出错
//6004    支付结果未知（有可能已经支付成功），请查询商户订单列表中订单的支付状态
//其它    其它支付错误
- (void)handleAliPayResponse:(NSDictionary *)payResponse {
    NSInteger errCode = [payResponse[@"resultStatus"] intValue];
    CJPayResultType resType = CJPayResultTypeFail;
    NSString *errorMessage = @"";
    if (errCode == 9000) {//成功
        resType = CJPayResultTypeSuccess;
        errorMessage = @"订单支付成功";
    } else if (errCode == 6001) {//取消
        resType = CJPayResultTypeCancel;
        errorMessage = @"用户中途取消";
    } else if (errCode == 8000 || errCode == 6004) {
        resType = CJPayResultTypeProcessing;
        errorMessage = @"正在处理中，请查询商户订单列表中订单的支付状态";
    }else {//失败
        resType = CJPayResultTypeFail;
        errorMessage = @"订单支付失败";
    }
    NSMutableDictionary *trackDic = [NSMutableDictionary new];
    [trackDic addEntriesFromDictionary:@{
        @"method" : @"alipay",
        @"error_code" : [NSString stringWithFormat:@"%ld", errCode],
        @"error_message" : CJString(errorMessage),
        @"wake_by_alipay": @"1",
        @"is_install" : [self isInstalled] ? @"1" : @"0",
        @"other_sdk_version" : CJString([self getAliPayVersion]),
        @"first_callback": @(self.wakingApp),
    }];
    [self trackWithEvent:@"wallet_pay_callback" trackParam:trackDic];
    NSString* rawErrorCode = [NSString stringWithFormat:@"%ld",(long)errCode];
    [self exeCompletionBlock:self.channelType resultType:resType rawErrorCode:rawErrorCode];
    self.trackParam = nil;
    self.dataDict = nil;
}

- (void)exeCompletionBlock:(CJPayChannelType)type resultType:(CJPayResultType) resultType rawErrorCode:(NSString*) rawErrorCode{
    _wakingApp = NO;
    CJ_CALL_BLOCK(self.completionBlock, type, resultType, rawErrorCode);
}

- (void)appDidInForeground {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.wakingApp) {
            NSMutableDictionary *trackDic = [NSMutableDictionary new];
            [trackDic addEntriesFromDictionary:@{
                @"method" : @"alipay",
                @"wake_by_alipay": @"0",
                @"is_install" : [self isInstalled] ? @"1" : @"0",
                @"other_sdk_version" : CJString([self getAliPayVersion]),
                @"first_callback": @(self.wakingApp),
            }];
            [self trackWithEvent:@"wallet_pay_callback" trackParam:trackDic];
            [self exeCompletionBlock:self.channelType resultType:CJPayResultTypeBackToForeground rawErrorCode:@""];
        }
    });
}

- (void)appDidInBackground {
    if (_startTime != 0) {
        NSMutableDictionary *trackDic = [NSMutableDictionary new];
        [trackDic addEntriesFromDictionary:@{
            @"method" : @"alipay",
            @"status" : @"1",
            @"spend_time" : @((CFAbsoluteTimeGetCurrent() - _startTime) / 1000),
            @"is_install" : [self isInstalled] ? @"1" : @"0",
            @"other_sdk_version" : CJString([self getAliPayVersion])
        }];
        [self trackWithEvent:@"wallet_pay_by_sdk" trackParam:trackDic];
        _startTime = 0;
    }
}

@end

