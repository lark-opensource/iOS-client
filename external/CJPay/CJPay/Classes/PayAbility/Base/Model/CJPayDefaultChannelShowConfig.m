//
//  CJPayDefaultChannelShowConfig.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/23.
//

#import "CJPaySubPayTypeData.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayUIMacro.h"
#import "CJPayChannelModel.h"
#import "CJPayCreditPayMethodModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayCombinePayInfoModel.h"
#import "CJPayTypeVoucherMsgV2Model.h"
#import "CJPayTypeInfo.h"

@implementation CJPayDefaultChannelShowConfig

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    CJPayDefaultChannelShowConfig *showConfig = [[self.class alloc] init];
    showConfig.iconUrl = [self.iconUrl copy];
    showConfig.title = [self.title copy];
    showConfig.subTitle = [self.subTitle copy];
    showConfig.subTitleColor = [self.subTitleColor copy];
    showConfig.descTitle = [self.descTitle copy];
    showConfig.subPayType = [self.subPayType copy];
    showConfig.payChannel = self.payChannel;
    showConfig.status = [self.status copy];
    showConfig.type = self.type;
    showConfig.isSelected = self.isSelected;
    showConfig.mobile = [self.mobile copy];
    showConfig.mark = [self.mark copy];
    showConfig.cjIdentify = [self.cjIdentify copy];
    showConfig.reason = [self.reason copy];
    showConfig.cardLevel = self.cardLevel;
    showConfig.cardTailNumStr = [self.cardTailNumStr copy];
    showConfig.account = [self.account copy];
    showConfig.accountUrl = [self.accountUrl copy];
    showConfig.inValidConfig = self.inValidConfig;
    showConfig.limitMsg = [self.limitMsg copy];
    showConfig.withdrawMsg = [self.withdrawMsg copy];
    showConfig.discountStr = [self.discountStr copy];
    showConfig.cardBinVoucher = [self.cardBinVoucher copy];
    showConfig.voucherMsg = [self.voucherMsg copy];
    showConfig.isShowRedDot = self.isShowRedDot;
    showConfig.showCombinePay = self.showCombinePay;
    showConfig.frontBankCode = [self.frontBankCode copy];
    showConfig.isLineBreak = self.isLineBreak;
    showConfig.voucherInfo = [self.voucherInfo copy];
    showConfig.comeFromSceneType = self.comeFromSceneType;
    showConfig.isCombinePay = self.isCombinePay;
    showConfig.creditSignUrl = self.creditSignUrl;
    showConfig.cardAddExt = self.cardAddExt;
    
    return showConfig;
}

- (BOOL)isNeedReSigning
{
    return (self.type == BDPayChannelTypeBankCard) && (self.cardLevel == 2);
}

- (BOOL)isDisplayCreditPayMetheds {
    if ([self.payChannel isKindOfClass:CJPaySubPayTypeInfoModel.class]) {
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)self.payChannel;
        return (self.type == BDPayChannelTypeCreditPay && payChannel.payTypeData.creditPayMethods.count > 0 && self.canUse);
    } else {
        return NO;
    }
}

- (BOOL)isEqual:(id)object {
    if(object == self) return YES;
    if([object isKindOfClass:CJPayDefaultChannelShowConfig.class]){
        CJPayDefaultChannelShowConfig *config = (CJPayDefaultChannelShowConfig *)object;
        return [config.title isEqual:self.title] && [self.cjIdentify isEqualToString:config.cjIdentify];
    }else{
        return [super isEqual:object];
    }
    return NO;
}

- (NSUInteger)hash
{
    return [self.title hash] ^ [self.subTitle hash] ^ [self.cjIdentify hash];
}

- (BOOL)isFromCombinePay {
    if ([self.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) {
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)self.payChannel;
        return (payChannel.payTypeData.combineShowInfo.count > 0);
    } else {
        return NO;
    }
}

- (BOOL)isUnionBindCard {
    return ([self.frontBankCode isEqualToString:@"UPYSFBANK"] && self.type == BDPayChannelTypeAddBankCard);
}

- (BOOL)hasSub {
    return self.type == BDPayChannelTypeCardCategory ? YES : NO;
}

- (BOOL)isNoActive {
    return (self.cardLevel == 2);
}

- (BOOL)enable {
    return [self.status isEqualToString:@"1"];
}

- (NSDictionary *)toActivityInfoTracker {
    CJPayVoucherModel *voucherModel = self.voucherInfo.vouchers.firstObject;
    if ([self.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]] && [self isFromCombinePay]) {
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)self.payChannel;
        voucherModel = payChannel.payTypeData.combinePayInfo.combinePayVoucherInfo.vouchers.firstObject;
    }
    if (!voucherModel) {
        return @{};
    }
    return @{
        @"id" : CJString(voucherModel.voucherNo),
        @"type": [voucherModel.voucherType isEqualToString:@"discount_voucher"] ? @"0" : @"1",
        @"front_bank_code": CJString(self.frontBankCode),
        @"reduce" : @(voucherModel.reduceAmount),
        @"label": CJString(voucherModel.label)
    };
}

- (NSDictionary *)toCombinePayActivityInfoTracker {
    CJPayVoucherModel *voucherModel = nil;
    if ([self.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) {
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)self.payChannel;
        voucherModel = payChannel.payTypeData.combinePayInfo.combinePayVoucherInfo.vouchers.firstObject;
    }
    if (!voucherModel) {
        return @{};
    }
    return @{
        @"id" : CJString(voucherModel.voucherNo),
        @"type": [voucherModel.voucherType isEqualToString:@"discount_voucher"] ? @"0" : @"1",
        @"front_bank_code": CJString(self.frontBankCode),
        @"reduce" : @(voucherModel.reduceAmount),
        @"label": CJString(voucherModel.label)
    };
}

- (NSArray *)toActivityInfoTrackerForCreditPay:(NSString *)installment {
    NSMutableArray *activityInfo = [NSMutableArray new];
    if (self.type == BDPayChannelTypeCreditPay && Check_ValidString(installment)) {
        if ([installment isEqualToString:@"1"]) {
            [activityInfo btd_addObject:[self p_buildActivityInfoForCreditPay:nil]];
        }
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)self.payChannel;
        [payChannel.payTypeData.creditPayMethods enumerateObjectsUsingBlock:^(CJPayCreditPayMethodModel*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.installment isEqualToString:installment]) {
                [activityInfo btd_addObject:[self p_buildActivityInfoForCreditPay:obj]];
            }
        }];
    }
    return [activityInfo copy];
}

- (NSArray *)toActivityInfoTrackerForCreditPay {
    NSMutableArray *activityInfo = [NSMutableArray new];
    if (self.type == BDPayChannelTypeCreditPay) {
        [activityInfo btd_addObject:[self p_buildActivityInfoForCreditPay:nil]];
        if ([self.payChannel isKindOfClass:CJPaySubPayTypeInfoModel.class]) {
            CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)self.payChannel;
            [payChannel.payTypeData.creditPayMethods enumerateObjectsUsingBlock:^(CJPayCreditPayMethodModel*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [activityInfo btd_addObject:[self p_buildActivityInfoForCreditPay:obj]];
            }];
        }
    }
    return [activityInfo copy];
}

- (NSDictionary *)p_buildActivityInfoForCreditPay:(CJPayCreditPayMethodModel*)model {
    CJPayVoucherModel *voucherModel = self.voucherInfo.vouchers.firstObject;
    if (voucherModel) {
        return @{
            @"id" : CJString(voucherModel.voucherNo),
            @"type": [voucherModel.voucherType isEqualToString:@"discount_voucher"] ? @"0" : @"1",
            @"front_bank_code": @"1",
            @"reduce" : @(voucherModel.reduceAmount),
            @"label": CJString(voucherModel.label)
        };
    }
    if (!model) {
        return nil;
    }
    voucherModel = (CJPayVoucherModel *)model.voucherInfo.vouchers.firstObject;
    if (Check_ValidString(voucherModel.voucherNo)) {
        return @{
            @"id" : CJString(voucherModel.voucherNo),
            @"type": [voucherModel.voucherType isEqualToString:@"discount_voucher"] ? @"0" : @"1",
            @"front_bank_code": CJString(model.installment),
            @"reduce" : @(voucherModel.reduceAmount),
            @"label": CJString(voucherModel.label)
        };
    }
    return nil;
}

- (NSDictionary *)toMethodInfoTracker {
    return @{
        @"info": CJString(self.title),
        @"status": self.status ? @"1" : @"0",
        @"reason": CJString(self.subTitle)
    };
}

- (NSDictionary *)toSubPayMethodInfoTrackerDic {
    NSString *payTypeStr = [CJPayTypeInfo getChannelStrByChannelType:self.type];
    return @{
        @"show_name": CJString(self.title),
        @"support": @([self.status isEqualToString:@"1"]),
        @"unsupported_reason": CJString(self.subTitle),
        @"pay_type": CJString(payTypeStr)
    };
}

- (CJPayChannelModel *)payChannel {
    if ([_payChannel isKindOfClass:CJPaySubPayTypeInfoModel.class]) {
        ((CJPaySubPayTypeInfoModel *)_payChannel).currentShowConfig = self;
    }
    return _payChannel;
}

- (NSDictionary *)getStandardAmountAndVoucher {
    NSString *payAmount = @"";
    NSString *payVoucherMsg = @"";

    if (self.type == BDPayChannelTypeCreditPay) {
        // 抖分期，特殊处理,需要从里面取出分期数以及支付金额和营销信息
        __block CJPayBytePayCreditPayMethodModel *selectedCreditPayMethodModel = nil;
        if ([self.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) {
            CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)self.payChannel;
            [payChannel.payTypeData.creditPayMethods enumerateObjectsUsingBlock:^(CJPayBytePayCreditPayMethodModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.choose) {
                    selectedCreditPayMethodModel = obj;
                    *stop = YES;
                }
            }];
            if (selectedCreditPayMethodModel) {
                payAmount = selectedCreditPayMethodModel.standardShowAmount;
                payVoucherMsg = selectedCreditPayMethodModel.standardRecDesc;
            } else {
                payAmount = payChannel.payTypeData.standardShowAmount;
                payVoucherMsg = payChannel.payTypeData.standardRecDesc;
            }
        } else {
            CJPayLogAssert(YES, @"下发抖分期数据错误");
        }
    } else {
        payAmount = self.payAmount;
        payVoucherMsg = self.payVoucherMsg;
    }
    return @{@"pay_amount": CJString(payAmount),
             @"pay_voucher": CJString(payVoucherMsg)
    };
}

- (NSString *)bindCardBusinessScene {
    if (self.isCombinePay) {
        return @"Pre_Pay_Combine";
    } else {    
        return CJString(self.businessScene);
    }
}

@end
