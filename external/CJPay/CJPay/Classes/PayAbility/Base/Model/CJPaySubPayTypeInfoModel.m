//
//  CJPaySubPayTypeInfoModel.m
//  Pods
//
//  Created by wangxiaohong on 2021/4/12.
//

#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayCreditPayMethodModel.h"
#import "CJPayUIMacro.h"

@interface CJPaySubPayTypeInfoModel()<CJPayRequestParamsProtocol>

@end

@implementation CJPaySubPayTypeInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"index": @"index",
        @"code" : @"ptcode",
        @"subPayType": @"sub_pay_type",
        @"way": @"way",
        @"status": @"status",
        @"iconUrl": @"icon_url",
        @"title": @"title",
        @"subTitle": @"sub_title",
        @"descTitle": @"desc_title",
        @"msg": @"msg",
        @"isChoosed": @"choose",
        @"homePageShow": @"home_page_show",
        @"mark": @"mark",
        @"identityVerifyWay": @"identity_verify_way",
        @"payTypeData": @"pay_type_data",
        @"tradeConfirmButtonText": @"trade_confirm_button_label",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)buildShowConfig {
    CJPayDefaultChannelShowConfig *configModel = [CJPayDefaultChannelShowConfig new];
    configModel.index = self.index;
    configModel.iconUrl = self.iconUrl;
    configModel.title = self.title;
    configModel.subTitle = self.msg;
    configModel.descTitle = self.descTitle;
    configModel.subPayType = self.subPayType;
    configModel.payChannel = self;
    configModel.status = self.status;
    configModel.canUse = [self.status isEqualToString:@"1"];
    configModel.mobile = self.payTypeData.mobileMask;
    configModel.cjIdentify = [self p_identifyWithPayType:self.subPayType];
    configModel.reason = self.msg;
    configModel.type = [self p_channelTypeWithSubPayTypeStr:self.subPayType];
    configModel.cardLevel = [self.payTypeData.cardLevel integerValue];
    configModel.isSelected = self.isChoosed;
    if (self.channelType == BDPayChannelTypeCreditPay) {
        CJPayVoucherModel *voucherModel = [self.payTypeData.voucherInfo.vouchers cj_objectAtIndex:0];
        if (voucherModel && [voucherModel isKindOfClass:[CJPayVoucherModel class]]) {
            configModel.discountStr = voucherModel.label;
        }
        configModel.creditActivateUrl = self.payTypeData.creditActivateUrl;
        configModel.isCreditActivate = self.payTypeData.isCreditActivate;
        configModel.creditSignUrl = self.payTypeData.creditSignUrl;
        configModel.decisionId = self.payTypeData.decisionId;
    } else {
        if(self.payTypeData.voucherMsgList.count > 0) {
            configModel.discountStr = [self.payTypeData.voucherMsgList cj_objectAtIndex:0];
            if (self.payTypeData.voucherMsgList.count > 1) {
                configModel.cardBinVoucher = [self.payTypeData.voucherMsgList cj_objectAtIndex:1];
            }
        }
    }
    configModel.showCombinePay = self.payTypeData.showCombinePay;
    configModel.voucherInfo = self.payTypeData.voucherInfo;
    configModel.frontBankCode = self.payTypeData.bankCode;
    configModel.cardType = self.payTypeData.cardType;
    configModel.cardAddExt = self.payTypeData.cardAddExt;
    configModel.businessScene = [self businessSceneString];
    configModel.bankCardId = self.payTypeData.bankCardId;

    configModel.tradeConfirmButtonText = self.tradeConfirmButtonText;
    configModel.payAmount = self.payTypeData.standardShowAmount;
    configModel.payVoucherMsg = self.payTypeData.standardRecDesc;
    configModel.canUse = [self.status isEqualToString:@"1"];
    configModel.payTypeData = [self.payTypeData copy];
    return @[configModel];
}

- (NSString *)p_identifyWithPayType:(NSString *)subPayType {
    if ([subPayType isEqualToString:@"bank_card"]) {
        return self.payTypeData.bankCardId;
    }
    
    return CJString(subPayType);
}

- (CJPayChannelType)p_channelTypeWithSubPayTypeStr:(NSString *)subPayTypeStr {
    if ([subPayTypeStr isEqualToString:@"bank_card"]) {
        return BDPayChannelTypeBankCard;
    } else if ([subPayTypeStr isEqualToString:@"balance"]) {
        return BDPayChannelTypeBalance;
    } else if ([subPayTypeStr isEqualToString:@"new_bank_card"]) {
        return BDPayChannelTypeAddBankCard;
    } else if ([subPayTypeStr isEqualToString:@"income"]) {
        return BDPayChannelTypeIncomePay;
    } else if ([subPayTypeStr isEqualToString:@"credit_pay"]) {
        return BDPayChannelTypeCreditPay;
    } else if ([subPayTypeStr isEqualToString:@"combinepay"]) {
        return BDPayChannelTypeCombinePay;
    } else if ([subPayTypeStr isEqualToString:@"fund_pay"]) {
        return BDPayChannelTypeFundPay;
    } else if ([subPayTypeStr isEqualToString:@"transfer_pay"]) {
        return BDPayChannelTypeTransferPay;
    }
    return CJPayChannelTypeNone;
}

- (CJPayChannelType)channelType {
    return [self p_channelTypeWithSubPayTypeStr:self.subPayType];
}

- (BOOL)isCombinePay {
    return self.payTypeData.combineShowInfo.count != 0;
}

- (NSString *)businessSceneString {
    switch (self.channelType) {
        case BDPayChannelTypeAddBankCard:
            return @"Pre_Pay_NewCard";
            
        case BDPayChannelTypeBalance:
            return @"Pre_Pay_Balance";
            
        case BDPayChannelTypeBankCard:
            return @"Pre_Pay_BankCard";
        
        case BDPayChannelTypeCreditPay:
            return @"Pre_Pay_Credit";
            
        case BDPayChannelTypeIncomePay:
            return @"Pre_Pay_Income";
            
        case BDPayChannelTypeCombinePay:
            return @"Pre_Pay_Combine";
        case BDPayChannelTypeFundPay:
            return @"Pre_Pay_FundPay";
        default:
            break;
    }
    return @"";
}

#pragma mark - CJPayRequestParamsProtocol 支付参数生成协议
- (NSDictionary *)requestNeedParams {
    NSMutableDictionary *dic = [NSMutableDictionary new];
    [dic cj_setObject:self.payTypeData.bankCardId forKey:@"bank_card_id"];
    [dic cj_setObject:self.payTypeData.mobileMask forKey:@"mobile"];
    return @{@"card_item": dic};
}

@end
