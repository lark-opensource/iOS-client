//
//  CJPayDyChannel.m
//  AFgzipRequestSerializer
//
//  Created by jiangzhongping on 2018/8/29.
//

#import "CJPayDyChannel.h"
#import "CJPayUIMacro.h"
#import "CJPayUIMacro.h"
//#import "CJPayAPI.h"
#import <DypaySDK/DypayAPI.h>
#import "CJPayChannelManager.h"
#import "UIViewController+CJPay.h"
#import "CJPayRequestParam.h"

static NSString * const CJDypaySchemeKey = @"dypayResult";

@interface CJPayDyChannel()
@property (nonatomic, assign) BOOL wakingApp;
@property (nonatomic, assign) BOOL startTime;

@end

@implementation CJPayDyChannel

CJPAY_REGISTER_PLUGIN({
    [[CJPayChannelManager sharedInstance] registerChannelClass:self channelType:CJPayChannelTypeDyPay];
})

- (instancetype)init {
    self = [super init];
    if (self) {
        self.channelType = CJPayChannelTypeDyPay;
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

    NSString *dypayScheme = @"";
    NSArray *URLTypeArray = [[[NSBundle mainBundle] infoDictionary] cj_arrayValueForKey:@"CFBundleURLTypes"];
    for (NSDictionary *anURLType in URLTypeArray) {
        if ([CJDypaySchemeKey isEqualToString:[anURLType cj_stringValueForKey:@"CFBundleURLName"]]) {
            dypayScheme = [[anURLType objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
            break;
        }
    }
    return dypayScheme;
}

//检查是否可用
+ (BOOL)isAvailableUse {
    return YES;
}

- (NSString *)getDyPayVersion {
    return [DypayAPI getAPIVersion];
}

- (BOOL)canProcessWithURL:(NSURL *)URL {
    
    NSString *scheme = [[URL scheme] lowercaseString];
    NSString *host = [[URL host] lowercaseString];
    
    BOOL canProcess = [scheme isEqualToString:[[self channelScheme] lowercaseString]] && [host isEqualToString:@"dypay"];
    if (canProcess) {
        [DypayAPI processDypayResultWithURL:URL callback:^(NSDictionary * _Nonnull resultDic) {
            [self handleDyPayResponse:resultDic];
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
    
    if (dataDict.count == 0) {
        return;
    }
    
    @CJWeakify(self);
    self.startTime = CFAbsoluteTimeGetCurrent();
    [DypayAPI registerWithAppID:[CJPayRequestParam gAppInfoConfig].appId callbackScheme:[NSString stringWithFormat:@"%@://dypay", [self channelScheme]]];
    [DypayAPI sharedDypayAPI].trackEventBlock = ^(NSString * _Nonnull event, NSDictionary * _Nonnull params) {
        @CJStrongify(self);
        [self trackWithEvent:event trackParam:params];
    };
    [DypayAPI openDypayWithInfo:dataDict
             fromViewController:[UIViewController cj_topViewController]
                       callback:^(BOOL isOpenedSuccessed, NSString *errMsg) {
        @CJStrongify(self);
        if (!isOpenedSuccessed) {
            [self exeCompletionBlock:self.channelType resultType:CJPayResultTypeCancel rawErrorCode:@"40"];
        } else {
            // 拉起成功
            self.wakingApp = YES;
        }
    }];
}

#pragma mark - private method
//-1   未知
//0    订单支付成功
//10   用户中途取消
//20   正在处理中
//30   版本过低
//40   失败
//50   超时

- (void)handleDyPayResponse:(NSDictionary *)payResponse {
    NSString *resultStatusStr = [payResponse btd_stringValueForKey:@"resultStatus"];
    NSInteger errCode = -1;
    if ([resultStatusStr isKindOfClass:[NSString class]]) {
        errCode = [resultStatusStr intValue];
    }
    
    CJPayResultType resType = CJPayResultTypeFail;
    NSString *errorMessage = @"";
    if (errCode == 0) {//成功
        resType = CJPayResultTypeSuccess;
        errorMessage = @"订单支付成功";
    } else if (errCode == 10) {//取消
        resType = CJPayResultTypeCancel;
        errorMessage = @"用户中途取消";
    } else if (errCode == 20) {
        resType = CJPayResultTypeProcessing;
        errorMessage = @"正在处理中，请查询商户订单列表中订单的支付状态";
    } else if (errCode == 30) {
        resType = CJPayResultTypeFail;
        errorMessage = @"抖音版本过低";
    } else if (errCode == 40) {//失败
        resType = CJPayResultTypeFail;
        errorMessage = @"订单支付失败";
    } else if (errCode == 50) {//失败
        resType = CJPayResultTypeFail;
        errorMessage = @"订单超时";
    } else {
        resType = CJPayResultTypeFail;
        errorMessage = @"订单未知错误";
    }
    
    NSMutableDictionary *trackDic = [NSMutableDictionary new];
    [trackDic addEntriesFromDictionary:@{
        @"method" : @"dypay",
        @"error_code" : [NSString stringWithFormat:@"%ld", errCode],
        @"error_message" : CJString(errorMessage),
        @"wake_by_dypay": @"1",
        @"other_sdk_version" : CJString([self getDyPayVersion])
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
                @"method" : @"dypay",
                @"wake_by_dypay": @"0",
                @"other_sdk_version" : CJString([self getDyPayVersion])
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
            @"method" : @"dypay",
            @"status" : @"1",
            @"spend_time" : @((CFAbsoluteTimeGetCurrent() - _startTime) * 1000),
            @"other_sdk_version" : CJString([self getDyPayVersion])
        }];
        [self trackWithEvent:@"wallet_pay_by_sdk" trackParam:trackDic];
        _startTime = 0;
    }
}

@end

