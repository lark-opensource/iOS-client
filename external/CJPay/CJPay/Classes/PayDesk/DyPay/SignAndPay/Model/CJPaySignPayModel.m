//
//  CJPaySignPayModel.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/6/29.
//

#import "CJPaySignPayModel.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayMemAgreementModel.h"
#import "CJPaySignPageInfoModel.h"

#import "CJPayUIMacro.h"

@implementation CJPaySignPayModel

#pragma mark - public func

- (instancetype)initWithResponse:(CJPayBDCreateOrderResponse *)response {
    self = [super init];
    if (self) {
        CJPaySignPageInfoModel *signPageInfo = response.signPageInfo;
        self.title = signPageInfo.serviceName;
        self.subTitle = signPageInfo.merchantName;
        self.logoImageURL = [NSURL cj_URLWithString:signPageInfo.icon];
        self.signPaySwitch = signPageInfo.paySignSwitch;
        
        [self p_handleMarketInfoStr:signPageInfo];
        
        self.switchDesc = signPageInfo.paySignSwitchInfo;
        
        self.serviceDesc = signPageInfo.serviceDesc;
        self.nextDeductDate = signPageInfo.nextDeductDate;
        
        [self p_handleDeductMethodInfo:response.payTypeInfo];
        self.deductMethodSubDesc = signPageInfo.deductMethodSubDesc;
        
        self.buttonAction = signPageInfo.buttonAction;
        self.buttonDesc = signPageInfo.buttonDesc;
        
        self.protocolGroupNames = signPageInfo.protocolGroupNames;
        self.protocolInfo = signPageInfo.protocolInfo;
    }
    return self;
}

#pragma mark - private func
// 用来修改金额展示
- (void)p_handleMarketInfoStr:(CJPaySignPageInfoModel *)signPageInfo {
    NSDecimalNumber *tradeNumber = [NSDecimalNumber decimalNumberWithString:signPageInfo.tradeAmount];
    CGFloat tradeFloat;
    NSString *tradeAmount;
     if ([tradeNumber compare:[NSDecimalNumber zero]] == NSOrderedSame || [[NSDecimalNumber notANumber] isEqualToNumber:tradeNumber]) {
         tradeAmount = @"--";
         CJPayLogInfo(@"折前金额错误 signPageInfo.tradeAmount");
     } else {
         tradeFloat = [[tradeNumber decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] floatValue] ;
         tradeAmount = [NSString stringWithFormat:@"%.2f",tradeFloat];
     }
    
    NSDecimalNumber *realTradeNumber = [NSDecimalNumber decimalNumberWithString:signPageInfo.realTradeAmount];
    CGFloat realTradeFloat;
    NSString *realTradeAmount;
     if ([realTradeNumber compare:[NSDecimalNumber zero]] == NSOrderedSame || [[NSDecimalNumber notANumber] isEqualToNumber:realTradeNumber]) {
         realTradeAmount = @"--";
         CJPayLogInfo(@"真实金额错误 signPageInfo.realTradeAmount");
     } else {
         realTradeFloat = [[realTradeNumber decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] floatValue] ;
         realTradeAmount = [NSString stringWithFormat:@"%.2f",realTradeFloat];
     }
    
    
    NSString *promotionDesc = signPageInfo.promotionDesc;
    
    self.closePayAmount = tradeAmount;
    self.openPayAmount = realTradeAmount;
    
    // 只有在开通并支付的状态下才有营销
    self.voucherMsg = promotionDesc;
}

// 用来修改支付并签约详情页的支付方式的展示内容
- (void)p_handleDeductMethodInfo:(CJPayBDTypeInfo *)payTypeInfo {
    CJPayDefaultChannelShowConfig *defaultConfig = [payTypeInfo getDefaultDyPayConfig];
    self.deductIconImageURL = [NSURL cj_URLWithString:defaultConfig.iconUrl];
    self.deductMethodDesc = defaultConfig.title;
}

@end
