//
//  CJPayWXChannel.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/29.
//

#import "CJPayWXChannel.h"
#import <WechatSDK/WXApiObject.h>
#import <WechatSDK/WXApi.h>
#import "CJPayChannelManager.h"
#import "CJPaySDKMacro.h"

static NSString * const kCJWechatSchemeKey = @"weixin";

@interface CJPayWXChannel() <WXApiDelegate>
@property (nonatomic, assign) BOOL wakingApp;
@property (nonatomic, assign) BOOL canHandleUserActivity;
@end

@implementation CJPayWXChannel

CJPAY_REGISTER_PLUGIN({
    [[CJPayChannelManager sharedInstance] registerChannelClass:self channelType:CJPayChannelTypeWX];
})

- (instancetype)init {
    self = [super init];
    if (self) {
        self.channelType = CJPayChannelTypeWX;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidInForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)channelScheme {
    NSString *wechatScheme = @"";
    NSArray *URLTypeArray = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
    NSString *universalLink = [CJPayChannelManager sharedInstance].wxUniversalLink;
    CJPayLogAssert(universalLink, @"使用微信支付，必须要配置universalLink");
    for (NSDictionary *anURLType in URLTypeArray) {
        if ([kCJWechatSchemeKey isEqualToString:[anURLType objectForKey:@"CFBundleURLName"]]) {
            wechatScheme = [[anURLType objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                BOOL success = NO;
                if (Check_ValidString(wechatScheme) && Check_ValidString(universalLink)) {
                    success = [WXApi registerApp:wechatScheme universalLink:universalLink];
                }
                NSMutableDictionary *trackDic = [NSMutableDictionary new];
                [trackDic addEntriesFromDictionary:@{
                    @"status" : success ? @"1" : @"0",
                    @"is_install" : [self isInstalled] ? @"1" : @"0",
                    @"other_sdk_version" : CJString([self getWEBayVersion]),
                    @"method" : @"weBay"
                }];
                [self trackWithEvent:@"wallet_register_sdk" trackParam:trackDic];
            });
            break;
        }
    }
    return wechatScheme;
}

//检查是否可用
+ (BOOL)isAvailableUse {
    //    return [WXApi isWXAppInstalled] && [WXApi isWXAppSupportApi];
    return YES;
}

- (BOOL)isInstalled {
    return [WXApi isWXAppInstalled];
}

- (NSString *)getWEBayVersion {
    return [WXApi getApiVersion];
}

- (BOOL)canProcessWithURL:(NSURL *)URL {
    
    NSString *scheme = [URL scheme];
    NSString *host = [[URL host] lowercaseString];
    BOOL canProcess = [scheme isEqualToString:[self channelScheme]] && [host isEqualToString:@"pay"];
    if (canProcess) {
        [WXApi handleOpenURL:URL delegate:self];
    }
    return canProcess;
}

- (BOOL)canProcessUserActivity:(NSUserActivity *)activity {
    self.canHandleUserActivity = NO;
    [WXApi handleOpenUniversalLink:activity delegate:self];
    return self.canHandleUserActivity;
}

- (void)payActionWithDataDict:(NSDictionary *)dataDict
              completionBlock:(CJPayCompletion) completionBlock {
    
    [super payActionWithDataDict:dataDict completionBlock:completionBlock];
    [self channelScheme];
    
    if (![self isInstalled]) {
        
        CJ_CALL_BLOCK(self.completionBlock, CJPayChannelTypeWX, CJPayResultTypeUnInstall, @"");
        self.completionBlock = nil;
        self.trackParam = nil;
        self.dataDict = nil;
        return;
    }
    self.wakingApp = YES;
    NSDictionary *payParam = dataDict;
    
    PayReq * weBay = [[PayReq alloc] init];
    weBay.nonceStr = payParam[@"nonce_str"] ? payParam[@"nonce_str"] : payParam[@"noncestr"];
    weBay.partnerId = payParam[@"partner_id"] ? payParam[@"partner_id"] : payParam[@"partnerid"];
    weBay.prepayId = payParam[@"prepay_id"] ? payParam[@"prepay_id"] : payParam[@"prepayid"];
    weBay.openID = payParam[@"app_id"] ? payParam[@"app_id"] : payParam[@"appid"];
    weBay.package = payParam[@"package"];
    weBay.timeStamp = [payParam[@"timestamp"] intValue];
    weBay.sign = payParam[@"sign"];
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    [WXApi sendReq:weBay completion:^(BOOL success) {
        NSMutableDictionary *trackDic = [NSMutableDictionary new];
        [trackDic addEntriesFromDictionary:@{
            @"method" : @"weBay",
            @"status" : success ? @"1" : @"0",
            @"spend_time" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
            @"is_install" : [self isInstalled] ? @"1" : @"0",
            @"other_sdk_version" : CJString([self getWEBayVersion]),
        }];
        [self trackWithEvent:@"wallet_pay_by_sdk" trackParam:trackDic];
    }];
}

#pragma mark - WXApiDelegate
- (void)onResp:(BaseResp *)resp {
    if ([resp isKindOfClass:[PayResp class]]) {
        self.canHandleUserActivity = YES;
        [self handleWEBayResponse:(PayResp *)resp];
    }
}

#pragma mark - private method
// 处理回调
//        WXSuccess           = 0,    /**< 成功    */
//        WXErrCodeCommon     = -1,   /**< 普通错误类型    */
//        WXErrCodeUserCancel = -2,   /**< 用户点击取消并返回    */
//        WXErrCodeSentFail   = -3,   /**< 发送失败    */
//        WXErrCodeAuthDeny   = -4,   /**< 授权失败    */
//        WXErrCodeUnsupport  = -5,   /**< 微信不支持    */

- (void)handleWEBayResponse:(PayResp *) payResponse {
    CJPayResultType resType = CJPayResultTypeFail;
    if (payResponse.errCode == WXSuccess) {//成功
        resType = CJPayResultTypeSuccess;
    } else if (payResponse.errCode == WXErrCodeUserCancel) { //取消
        resType = CJPayResultTypeCancel;
    } else { //失败
        resType = CJPayResultTypeFail;
    }
    NSMutableDictionary *trackDic = [NSMutableDictionary new];
    [trackDic addEntriesFromDictionary:@{
        @"method" : @"weBay",
        @"error_code" : [NSString stringWithFormat:@"%d", payResponse.errCode],
        @"error_message" : CJString(payResponse.errStr),
        @"is_install" : [self isInstalled] ? @"1" : @"0",
        @"other_sdk_version" : CJString([self getWEBayVersion]),
        @"first_callback": @(self.wakingApp),
    }];
    [self trackWithEvent:@"wallet_pay_callback" trackParam:trackDic];
    NSString *rawErrorCode = [NSString stringWithFormat:@"%d",payResponse.errCode];
    [self exeCompletionBlock:self.channelType resultType:resType errCode:rawErrorCode];
    self.trackParam = nil;
    self.dataDict = nil;
}

- (void)exeCompletionBlock:(CJPayChannelType)type resultType:(CJPayResultType) resultType errCode:(NSString*) errCode {
    self.wakingApp = NO;
    CJ_CALL_BLOCK(self.completionBlock, type, resultType, errCode);
}

- (void)appDidInForeground {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.wakingApp) {
            NSMutableDictionary *trackDic = [NSMutableDictionary new];
            [trackDic addEntriesFromDictionary:@{
                @"method" : @"wxpay",
                @"wake_by_alipay": @"0",
                @"is_install" : [self isInstalled] ? @"1" : @"0",
                @"other_sdk_version" : CJString([self getWEBayVersion]),
                @"first_callback": @(self.wakingApp)
            }];
            [self trackWithEvent:@"wallet_pay_callback" trackParam:trackDic];
            [self exeCompletionBlock:self.channelType resultType:CJPayResultTypeBackToForeground errCode:@""];
        }
    });
}

@end
