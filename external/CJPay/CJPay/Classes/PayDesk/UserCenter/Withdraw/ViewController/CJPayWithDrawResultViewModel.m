//
//  CJWithdrawResultViewModel.m
//  CJPay
//
//  Created by liyu on 2019/10/12.
//

#import "CJPayWithDrawResultViewModel.h"

#import "CJPayUIMacro.h"
#import <BDWebImage/BDWebImage.h>

#import "CJPayBDOrderResultResponse.h"
#import "CJPayBannerResponse.h"
#import "CJPayWithDrawResultArrivingView.h"
#import "CJPayWithDrawResultHeaderView.h"
#import "CJPayBDTypeInfo.h"
#import "CJPayLoopView.h"
#import "CJPayWebViewUtil.h"
#import "CJPayTracker.h"
#import "CJPayUIMacro.h"
#import "CJPayDiscountBanner.h"
#import "CJPayCommonUtil.h"
#import "CJPayBindCardManager.h"

@interface CJPayWithDrawResultViewModel ()

@property (nonatomic, strong) CJPayBDOrderResultResponse *response;
@property (nonatomic, strong) CJPayBannerResponse *bannerResponse;
@property (nonatomic, copy, readonly) NSString *arrivingMethod;
@property (nonatomic, copy, readonly, nullable) NSString *timeText;
@property (nonatomic, copy, readonly) NSString *dateFormaterString;

@property (nonatomic, assign) int orderNum;

@end


@implementation CJPayWithDrawResultViewModel

- (NSString *)arrivingMethod {
    NSString *bankName = self.response.tradeInfo.bankName;
    NSString *bankCodeMask = CJString(self.response.tradeInfo.bankCodeMask);
    if (bankCodeMask.length >= 4) {
        bankCodeMask = [bankCodeMask substringFromIndex:(bankCodeMask.length-4)];
    }
    return [NSString stringWithFormat:@"%@(%@)",CJString(bankName), CJString(bankCodeMask)];
}

- (NSString *)timeText {
    switch ([CJPayBDTradeInfo statusFromString:self.response.tradeInfo.tradeStatusString]) {
        case CJBDPayWithdrawTradeStatusSuccess:
            return [CJPayCommonUtil dateStringFromTimeStamp:[self.response.tradeInfo.finishTime integerValue] dateFormat:self.dateFormaterString];
        default: {
            return [CJPayCommonUtil dateStringFromTimeStamp:[self.response.tradeInfo.createTime integerValue] dateFormat:self.dateFormaterString];
        }
    }
}

- (NSString *)dateFormaterString {
    return CJPayLocalizedStr(@"yyyy年MM月dd日 HH:mm");
}

- (void)updateWithResponse:(CJPayBDOrderResultResponse *)response {
    self.response = response;

    if (self.response.tradeInfo.isFailed && Check_ValidString(self.response.tradeInfo.failMsg)) {
        [self p_trackerWithEventName:@"wallet_tixian_progress_reason_imp" params:@{@"reason_type": CJString(self.response.tradeInfo.failMsg)}];
        [self.headerView updateWithErrorMsg:self.response.tradeInfo.failMsg];
    }
    
    if (self.response.tradeInfo.isFailed) {
        self.headerView.style = kCJWithdrawResultHeaderViewFailed;
    } else if (self.response.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) {
        self.headerView.style = kCJWithdrawResultHeaderViewSuccess;
    } else if (self.response.tradeInfo.tradeStatus == CJPayOrderStatusProcess){
        self.headerView.style = kCJWithdrawResultHeaderViewProcessing;
    }

    [self.headerView updateWithAmountText:[CJPayCommonUtil getMoneyFormatStringFromDouble:((double) self.response.tradeInfo.tradeAmount / 100) formatString:nil]];
    
    [self.bootomView updateWithAccountText:self.arrivingMethod
                            accountIconUrl:self.response.tradeInfo.iconUrl
                                    status:self.response.tradeInfo.tradeStatus
                                  timeText:self.timeText];
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSDictionary *bindCardTrackerBaseParams = [[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams];
    NSMutableDictionary *baseParams = [@{
        @"app_id": CJString(self.appID),
        @"merchant_id": CJString(self.merchantID),
        @"is_chaselight": @"1",
        @"twoelements_verify_status": @"0",
        @"type": @"可变金额",
        @"balance_amount": CJString(self.response.userInfo.balanceAmount),
        @"tixian_amount": @(self.response.tradeInfo.tradeAmount).stringValue,
        @"account_type": @"银行卡",
        @"version": @"普通",
        @"is_bankcard": CJString([self.preOrderTrackInfo cj_stringValueForKey:@"is_bankcard"]),
        @"needidentify" : CJString([bindCardTrackerBaseParams cj_stringValueForKey:@"needidentify"]),
        @"haspass" : CJString([bindCardTrackerBaseParams cj_stringValueForKey:@"haspass"])
    } mutableCopy];
    
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

@end
