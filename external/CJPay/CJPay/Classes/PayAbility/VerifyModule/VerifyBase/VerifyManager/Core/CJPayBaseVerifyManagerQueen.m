//
//  CJPayBaseVerifyManagerQueen.m
//  Pods
//
//  Created by wangxiaohong on 2021/11/15.
//

#import "CJPayBaseVerifyManagerQueen.h"

#import "CJPayBaseVerifyManager.h"
#import "CJPayUIMacro.h"
#import "CJPayTracker.h"
#import "CJPayVerifyItemSignCard.h"
#import "CJPayCommonTrackUtil.h"

@interface CJPayBaseVerifyManagerQueen()

@property (nonatomic, weak) CJPayBaseVerifyManager *verifyManager;

@end

@implementation CJPayBaseVerifyManagerQueen

- (void)bindManager:(CJPayBaseVerifyManager *)verifyManager {
    self.verifyManager = verifyManager;
}

- (NSDictionary *)cashierExtraTrackerParams {
    //默认为空，子类可覆写增加埋点参数
    return @{};
}

#pragma mark - Tracker
- (void)trackCashierWithEventName:(NSString *)eventName params:(nullable NSDictionary *)params {
    NSMutableDictionary *mutableDic = [[CJPayCommonTrackUtil getBDPayCommonParamsWithResponse:self.verifyManager.response
                                                                                   showConfig:self.verifyManager.homePageVC.curSelectConfig] mutableCopy];
    [mutableDic addEntriesFromDictionary:params];
    [self p_trackWithEventName:eventName params:mutableDic];
}

- (void)trackVerifyWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSString *bank_type = [NSString new];
    if ([self.verifyManager.defaultConfig.payChannel isKindOfClass:CJPayQuickPayCardModel.class]) {
        bank_type = [(CJPayQuickPayCardModel *)self.verifyManager.defaultConfig.payChannel cardTypeName];
    }
    
    NSString *outerId = [self.verifyManager.bizParams cj_stringValueForKey:@"app_id" defaultValue:@""];
    if (!Check_ValidString(outerId)) {
        outerId = [self.verifyManager.bizParams cj_stringValueForKey:@"merchant_app_id" defaultValue:@""];
    }
    
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"bank_type" : CJString(bank_type),
        @"identity_type" : CJString(self.verifyManager.response.userInfo.authStatus),
        @"activity_label" : CJString(self.verifyManager.response.payInfo.voucherMsg),
        @"result" : self.verifyManager.response.tradeInfo.tradeStatus == CJPayOrderStatusSuccess ? @"1" : @"0",
        @"outer_aid" : CJString(outerId),
    }];
    [mutableDic addEntriesFromDictionary:params];
    
    [self trackCashierWithEventName:eventName params:[mutableDic copy]];
}

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] init];
    NSDictionary *extraDic = [self cashierExtraTrackerParams];
    [mutableDic addEntriesFromDictionary:params];
    if (extraDic) {
        [mutableDic addEntriesFromDictionary:extraDic];
    }
    [CJTracker event:eventName params:mutableDic];
}

- (void)beforeConfirmRequest {}

- (void)afterConfirmRequestWithResponse:(CJPayOrderConfirmResponse *)orderResponse {}

- (void)beforQueryResult {}

- (void)afterLastQueryResultWithResultResponse:(CJPayBDOrderResultResponse *)response {}

- (void)retainUsers {}

#pragma mark - CJPayTrackerProtocol

- (void)event:(NSString *)event params:(NSDictionary *)params {
    [self trackVerifyWithEventName:event params:params];
}

@end

