//
//  CJPayTypeInfo.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import "CJPayTypeInfo.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayDeskConfig.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayCreditPayChannelModel.h"

@interface CJPayTypeInfo()

@property (nonatomic, strong) CJPayIntegratedChannelModel *bdPayModel;
@property (nonatomic, strong) CJPayCreditPayChannelModel *creditPayModel;

@end

@implementation CJPayTypeInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"deskConfig": @"cashdesk_show_conf",
        @"payChannels" : @"paytype_items",
        @"defaultPayChannel" : @"default_ptcode",
        @"sortedPayChannels" : @"sorted_ptcodes",
        @"paySource" : @"pay_source",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (nullable CJPayIntegratedChannelModel *)bdPay {
    if (!_bdPayModel) {
        [self.payChannels enumerateObjectsUsingBlock:^(CJPayChannelModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.code isEqualToString:@"bytepay"]) {
                _bdPayModel = [[CJPayIntegratedChannelModel alloc] initWithDictionary:[obj.payTypeItemInfo cj_toDic] error:nil];
                _bdPayModel.retainInfoV2 = obj.retainInfoV2;
                *stop = YES;
            }
        }];
    }
    return _bdPayModel;
}
- (nullable CJPayCreditPayChannelModel *)creditPay {
    if (!_creditPayModel) {
        [self.payChannels enumerateObjectsUsingBlock:^(CJPayChannelModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.code isEqualToString:@"creditpay"]) {
                _creditPayModel = [[CJPayCreditPayChannelModel alloc] initWithDictionary:[obj.payTypeItemInfo cj_toDic] error:nil];
                _creditPayModel.retainInfoV2 = obj.retainInfoV2;
                *stop = YES;
            }
        }];
    }
    return _creditPayModel;
}

- (BOOL)isDefaultBytePay {
    return [_defaultPayChannel isEqualToString:@"bytepay"];
}

- (NSString *)defaultPayChannel {
    if ([_defaultPayChannel isEqualToString:@"bytepay"]) {
        NSArray *typeInfoList = self.bdPay.subPayTypeSumInfo.subPayTypeInfoList;
        if (typeInfoList.count > 0 && [typeInfoList.firstObject isKindOfClass:CJPaySubPayTypeInfoModel.class]) {
            return ((CJPaySubPayTypeInfoModel *)typeInfoList.firstObject).subPayType;
        }
        return self.bdPay.defaultPayChannel; // 普通收银台，如果是bytepay的话，就返回bytepay里面的默认支付方式
    }
    return _defaultPayChannel;
}

+ (CJPayChannelType)getChannelTypeBy:(NSString *)channelStr {
    if ([channelStr isEqualToString:@"dypay"]) {
        return CJPayChannelTypeDyPay;
    }
    if ([channelStr isEqualToString:EN_zfb]) {
        return CJPayChannelTypeTbPay;
    }
    if ([channelStr isEqualToString:@"wx"]) {
        return CJPayChannelTypeWX;
    }
    if ([channelStr isEqualToString:@"qrcode"]) {
        return CJPayChannelTypeQRCodePay;
    }
    if ([channelStr isEqualToString:@"bdpay"]) {
        return CJPayChannelTypeBDPay;
    }
    if ([channelStr isEqualToString:@"bytepay"]) {
        return BDPayChannelTypeCardCategory;
    }
    if ([channelStr isEqualToString:@"balance"]) {
        return BDPayChannelTypeBalance;
    }
    if ([channelStr isEqualToString:@"income"]) {
        return BDPayChannelTypeIncomePay;
    }
    if ([channelStr isEqualToString:@"credit_pay"] || [channelStr isEqualToString:@"creditpay"]) {
        return BDPayChannelTypeCreditPay;
    }
    
    if ([channelStr isEqualToString:@"transfer_pay"]) {
        return BDPayChannelTypeTransferPay;
    }
    
    if ([channelStr isEqualToString:@"quickpay"] ||
        [channelStr isEqualToString:@"bank_card"] ||
        [channelStr isEqualToString:@"new_bank_card"]) {
        return BDPayChannelTypeBankCard;
    }
    
    return CJPayChannelTypeNone;
}

+ (NSString *)getChannelStrByChannelType:(CJPayChannelType)channleType {
    switch (channleType) {
        case CJPayChannelTypeDyPay:
            return @"dypay";
        case CJPayChannelTypeTbPay:
            return EN_zfb;
        case CJPayChannelTypeWX:
            return @"wx";
        case CJPayChannelTypeBDPay:
            return @"bdpay";
        case CJPayChannelTypeQRCodePay:
            return @"qrcode";
        case BDPayChannelTypeBankCard:
            return @"quickpay";
        case BDPayChannelTypeBalance:
            return @"balance";
        case BDPayChannelTypeAddBankCard:
            return @"addcard";
        case BDPayChannelTypeCreditPay:
            return @"creditpay";
        case BDPayChannelTypeIncomePay:
            return @"income";
        default:
            break;
    }
    return @"";
}

+ (NSString *)getTrackerMethodByChannelConfig:(CJPayDefaultChannelShowConfig *)channelConfig {
    if (channelConfig == nil) {
        return @"";
    }
    BOOL isCombinePay = channelConfig.isCombinePay;
    
    switch (channelConfig.type) {
        case CJPayChannelTypeDyPay:
            return @"dypay";
        case CJPayChannelTypeTbPay:
            return EN_zfb;
        case CJPayChannelTypeWX:
            return @"wx";
        case CJPayChannelTypeBDPay:
            return @"bdpay";
        case CJPayChannelTypeQRCodePay:
            return @"qrcode";
        case BDPayChannelTypeBankCard:
            return isCombinePay ? @"balance_quickpay" : @"quickpay";
        case BDPayChannelTypeBalance:
            return @"balance";
        case BDPayChannelTypeAddBankCard:
            return isCombinePay ? @"balance_addcard" : @"addcard";
        case BDPayChannelTypeCreditPay:
            return @"creditpay";
        case BDPayChannelTypeIncomePay:
            return @"income";
        default:
            break;
    }
    return @"";
}

- (NSString *)isCreditPayAvailable {
    if (self.deskConfig.currentDeskType == CJPayDeskTypeBytePayHybrid) {
        return CJString(self.creditPay.status);
    }
    return [self p_isAvailableWithMethod:@"credit_pay"];
}

- (BOOL)isBalanceAvailable {
    if ([[self p_isAvailableWithMethod:@"balance"] isEqualToString:@"1"]){
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)creditPayStageListStr {
    __block NSString * result = @"";
    if (![[self isCreditPayAvailable] isEqualToString:@"1"]) {
        return result;
    } else {
        if (self.deskConfig.currentDeskType == CJPayDeskTypeBytePayHybrid) {
            [self.creditPay.payTypeData.creditPayMethods enumerateObjectsUsingBlock:^(CJPayBytePayCreditPayMethodModel*  _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
                result = [NSString stringWithFormat:@"%@%@,", result, CJString(item.installment)];
            }];
        } else {
            [self.bdPay.subPayTypeSumInfo.subPayTypeInfoList enumerateObjectsUsingBlock:^(CJPaySubPayTypeInfoModel*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.subPayType isEqualToString:@"credit_pay"]){
                    *stop = YES;
                    [obj.payTypeData.creditPayMethods enumerateObjectsUsingBlock:^(CJPayBytePayCreditPayMethodModel*  _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
                        result = [NSString stringWithFormat:@"%@%@,", result, CJString(item.installment)];
                    }];
                }
            }];
        }
        if (Check_ValidString(result)) {
            return [result substringWithRange:NSMakeRange(0, [result length] - 1)];
        } else {
            return @"1";
        }
    }
}

- (NSString *)p_isAvailableWithMethod:(NSString *)subPayTypeStr {
    __block NSString *result = @"";
    [self.bdPay.subPayTypeSumInfo.subPayTypeInfoList enumerateObjectsUsingBlock:^(CJPaySubPayTypeInfoModel*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.subPayType isEqualToString:subPayTypeStr]){
            *stop = YES;
            result = CJString(obj.status);
        }
    }];
    return result;
}

@end
