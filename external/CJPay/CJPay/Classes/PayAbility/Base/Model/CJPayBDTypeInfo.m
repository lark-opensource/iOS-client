//
//  CJPayBDTypeInfo.m
//  CJPay
//
//  Created by wangxiaohong on 2020/3/11.
//

#import "CJPayBDTypeInfo.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayBalanceModel.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayOutDisplayInfoModel.h"

@implementation CJPayBDTypeInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"payChannels" : @"pay_channels",
                @"defaultPayChannel" : @"default_pay_channel",
                @"creditPayModel":@"credit_pay",
                @"quickPay": @"quick_pay",
                @"balance": @"balance",
                @"payBrand": @"pay_brand",
                @"homePagePictureUrl" : @"home_page_picture_url",
                @"subPayTypeSumInfo": @"sub_pay_type_sum_info",
                @"subPayTypeGroupInfoList" : @"sub_pay_type_group_info_list",
                @"outDisplayInfo" : @"out_display_info",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

// 根据channel名称获取指定的model
- (id<CJPayDefaultChannelShowConfigBuildProtocol>)p_obtainChannelModelBy:(NSString *)channelName{
    NSDictionary *cjPayChannelModelMap = @{
                                           @"balance": self.balance ?: [CJPayBalanceModel new],
                                           @"quickpay": self.quickPay ?: [CJPayQuickPayChannelModel new]
                                           };
    return  (id<CJPayDefaultChannelShowConfigBuildProtocol>)[cjPayChannelModelMap cj_objectForKey:channelName];
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)allPayChannels {
    if (_allPayChannels == nil || _allPayChannels.count < 1) {
        NSMutableArray<CJPayDefaultChannelShowConfig *> *channels = [NSMutableArray new];
        for (NSString *channel in self.payChannels) {
            id<CJPayDefaultChannelShowConfigBuildProtocol> channelModel = [self p_obtainChannelModelBy:channel];
            NSArray *currentChannels = [channelModel buildShowConfig];
            CJPayChannelType curType = [CJPayBDTypeInfo getChannelTypeBy:channel];
            for (CJPayDefaultChannelShowConfig *channelConfig in currentChannels) {
                channelConfig.type = curType;
            }
            if (currentChannels.count > 0) {
                [channels addObjectsFromArray:currentChannels];
            }
            // 选中状态初始化为服务端返回的结果
            if ([channel isEqualToString:self.defaultPayChannel]) {
                ((CJPayDefaultChannelShowConfig *)currentChannels.firstObject).isSelected = YES;
            }
        }
        _allPayChannels = channels;
    }
    return _allPayChannels;
}

// 通过subPayTypeSumInfo来获取所有支付方式
- (NSArray<CJPayDefaultChannelShowConfig *> *)allSumInfoPayChannels {
    if (_allPayChannels == nil || _allPayChannels.count < 1) {
        NSMutableArray<CJPayDefaultChannelShowConfig *> *allShowConfigs = [NSMutableArray new];
        __block NSInteger count = 0;
        [self.subPayTypeSumInfo.subPayTypeInfoList enumerateObjectsUsingBlock:^(CJPaySubPayTypeInfoModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ((Check_ValidString(obj.payTypeData.voucherInfo.vouchersLabel) || obj.payTypeData.voucherInfo.vouchers.count)
                && [obj.status isEqualToString:@"1"]) {
                count = count + 1;
            }
            [allShowConfigs addObjectsFromArray:[obj buildShowConfig]];
        }];
        
        if (count > 1) {
            for (CJPayDefaultChannelShowConfig *showConfig in allShowConfigs) {
                showConfig.isLineBreak = YES;
            }
        }
        _allPayChannels = [allShowConfigs copy];
    }
    return _allPayChannels;
}

+ (CJPayChannelType)getChannelTypeBy:(NSString *)channelStr {
    if ([channelStr isEqualToString:@"quickpay"] || [channelStr isEqualToString:@"Pre_Pay_BankCard"]) {
        return BDPayChannelTypeBankCard;
    }
    if ([channelStr isEqualToString:@"balance"] || [channelStr isEqualToString:@"Pre_Pay_Balance"]) {
        return BDPayChannelTypeBalance;
    }
    if ([channelStr isEqualToString:@"credit_pay"] || [channelStr isEqualToString:@"Pre_Pay_Credit"]) {
        return BDPayChannelTypeCreditPay;
    }
    
    if ([channelStr isEqualToString:@"Pre_Pay_NewCard"]) {
        return BDPayChannelTypeAddBankCard;
    }
    
    if ([channelStr isEqualToString:@"Pre_Pay_PayAfterUse"]) {
        return BDPayChannelTypeAfterUsePay;
    }
    
    if ([channelStr isEqualToString:@"income"] || [channelStr isEqualToString:@"Pre_Pay_Income"]) {
        return BDPayChannelTypeIncomePay;
    }
    
    if ([channelStr isEqualToString:@"Pre_Pay_Combine"]) {
        return  BDPayChannelTypeCombinePay;
    }
    
    if ([channelStr isEqualToString:@"Pre_Pay_FundPay"]) {
        return BDPayChannelTypeFundPay;
    }
    
    return CJPayChannelTypeNone;
}

+ (NSString *)getChannelStrByChannelType:(CJPayChannelType)channleType
                            isCombinePay:(BOOL)isCombinePay {
    if (isCombinePay) {
        return @"combinepay";
    } else {
        return [self p_getChannelStrByChannelType:channleType];
    }
}

+ (NSString *)p_getChannelStrByChannelType:(CJPayChannelType)channleType {
    switch (channleType) {
        case BDPayChannelTypeBankCard:
            return @"quickpay";
        case BDPayChannelTypeBalance:
            return @"balance";
        case BDPayChannelTypeIncomePay:
            return @"income";
        case BDPayChannelTypeCreditPay:
            return @"creditpay";
        case BDPayChannelTypeAfterUsePay:
            return @"pay_after_use";
        case BDPayChannelTypeCombinePay:
            return @"combinepay";
        case BDPayChannelTypeFundPay:
            return @"fundpay";
        default:
            break;
    }
    return @"";
}

- (nullable CJPayDefaultChannelShowConfig *)obtainDefaultConfig {
    CJPayDefaultChannelShowConfig *defaultConfig;
    CJPayChannelType type = [CJPayBDTypeInfo getChannelTypeBy:self.defaultPayChannel];
    switch (type) {
        case BDPayChannelTypeBalance:
            defaultConfig = [self.balance buildShowConfig].firstObject;
            break;
        case BDPayChannelTypeBankCard: {
            defaultConfig = [self.quickPay.cards.firstObject buildShowConfig].firstObject;
            break;
        }
        default:
            defaultConfig = nil;
            break;
    }
    return defaultConfig;
}

- (nullable CJPayDefaultChannelShowConfig *)getDefaultDyPayConfig {
    NSArray<CJPayDefaultChannelShowConfig *> *showConfigs = [self allSumInfoPayChannels];
    __block CJPayDefaultChannelShowConfig *defaultConfig;
    [showConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isSelected) {
            defaultConfig = obj;
            *stop = YES;
        }
    }];
    return defaultConfig;
}

- (nullable CJPayDefaultChannelShowConfig *)getDefaultBankCardPayConfig {
    NSArray<CJPayDefaultChannelShowConfig *> *showConfigs = [self allSumInfoPayChannels];
    __block CJPayDefaultChannelShowConfig *defaultConfig;
    [showConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type == BDPayChannelTypeBankCard || obj.type == BDPayChannelTypeAddBankCard) {
            defaultConfig = obj;
            *stop = YES;
        }
    }];
    return defaultConfig;
}

+ (NSString *)getTrackerMethodByChannelConfig:(CJPayDefaultChannelShowConfig *)channelConfig {
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
        case BDPayChannelTypeCombinePay:
            return @"combinepay";
        default:
            break;
    }
    return @"";
}

@end
