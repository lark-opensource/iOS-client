//
//  CJPayTypeInfo+Util.m
//  Pods
//
//  Created by wangxinhua on 2020/9/10.
//

#import "CJPayTypeInfo+Util.h"
#import "CJPayUIMacro.h"
#import "CJPayAddCardChannelModel.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayHomePageBannerModel.h"
#import "CJPayCreditPayMethodModel.h"
#import "CJPayCreditPayChannelModel.h"

@implementation CJPayTypeInfo(Util)

- (NSArray<CJPayDefaultChannelShowConfig *> *)showConfigForHomePageWithId:(NSString *)identify {
    return [self p_bytePayShowConfigForHomePageWithId:identify];
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)showConfigForCardList {
    return [self.bdPay buildConfigsWithIdentify:@""];
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)showConfigForUniteSign {
    NSMutableArray *allChannelsConfig = [NSMutableArray new];

    if (!Check_ValidArray(self.sortedPayChannels)) {
        self.sortedPayChannels = self.bdPay.payChannels;
    }
    
    [self.sortedPayChannels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        CJPayChannelModel *model;
        for (CJPayChannelModel *singleModel in self.payChannels) {
            if ([singleModel.code isEqualToString:obj]) {
                model = singleModel;
            }
        }
        CJPayDefaultChannelShowConfig *config = [model buildShowConfig].firstObject;
        config.type = [self.class getChannelTypeBy:model.code];
        if (config) {
            [allChannelsConfig addObject:config];
        }
    }];
    
    return allChannelsConfig;
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)p_bytePayShowConfigForHomePageWithId:(NSString *)identify {
    NSMutableArray *allChannelsConfig = [NSMutableArray new];

    if (!Check_ValidArray(self.sortedPayChannels)) {
        self.sortedPayChannels = self.bdPay.payChannels;
    }
    
    [self.sortedPayChannels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        CJPayChannelModel *model;
        for (CJPayChannelModel *singleModel in self.payChannels) {
            if ([singleModel.code isEqualToString:obj]) {
                model = singleModel;
            }
        }
        CJPayDefaultChannelShowConfig *config = [model buildShowConfig].firstObject;
        config.type = [self.class getChannelTypeBy:model.code];
        if (config.type == BDPayChannelTypeCreditPay) {
            CJPayDefaultChannelShowConfig *creditConfig = [self.creditPay buildShowConfig].firstObject;
            [allChannelsConfig btd_addObject:creditConfig];
        } else if (config) {
            [allChannelsConfig btd_addObject:config];
        }
        if ([obj isEqualToString:@"bytepay"]) {
            config.homePageShowStyle = self.bdPay.subPayTypeSumInfo.homePageShowStyle;
            config.useSubPayListVoucherMsg = self.bdPay.subPayTypeSumInfo.useSubPayListVoucherMsg;
            
            NSArray *showConfigs = [self.bdPay buildConfigsWithIdentify:identify];
            if ([self.bdPay.subPayTypeSumInfo.homePageShowStyle isEqualToString:@"card"]) {
                CJPayDefaultChannelShowConfig *subPayConfig = [[CJPayDefaultChannelShowConfig alloc] init];
                subPayConfig.type = BDPayChannelTypeAddBankCardNewCustomer;
                NSMutableArray<CJPaySubPayTypeInfoModel*> *array = [[NSMutableArray alloc] init];
                for (NSNumber *index in self.bdPay.subPayTypeSumInfo.cardStyleIndexList) {
                    for (CJPaySubPayTypeInfoModel *model in self.bdPay.subPayTypeSumInfo.subPayTypeInfoList) {
                        if ([index integerValue] == model.index) {
                            [array btd_addObject:model];
                        }
                    }
                }
                config.subPayTypeData = [array copy];
                subPayConfig.subPayTypeData = [array copy];
                
                [allChannelsConfig btd_addObject:subPayConfig];
            } else {
                if (Check_ValidString(identify)) {
                    [showConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj.cjIdentify isEqualToString:identify]) {
                            obj.voucherMsg = self.bdPay.subPayTypeSumInfo.homePageGuideText;
                            obj.isShowRedDot = self.bdPay.subPayTypeSumInfo.homePageRedDot;
                            //根据选中二级支付方式的营销文案来设置一级支付“抖音支付”后的营销文案
                            CJPayDefaultChannelShowConfig *bytepayConfig = [self setHomePageBytepayVoucherMsg:[allChannelsConfig lastObject] bySubPayObj:obj];
                            //提单页的卡片营销从voucher_msg_list 换到 subpay_voucher_msg_list
                            if (obj.useSubPayListVoucherMsg) {
                                obj.discountStr = [obj.payTypeData.subPayVoucherMsgList cj_objectAtIndex:0];
                            }
                            [allChannelsConfig removeLastObject];
                            [allChannelsConfig btd_addObject:bytepayConfig];
                            
                            [allChannelsConfig btd_addObject:obj];
                            *stop = YES;
                        }
                    }];
                } else {
                    [showConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (obj.isSelected) {
                            obj.voucherMsg = self.bdPay.subPayTypeSumInfo.homePageGuideText;
                            obj.isShowRedDot = self.bdPay.subPayTypeSumInfo.homePageRedDot;
                            //根据默认二级支付方式的营销文案来设置一级支付“抖音支付”后的营销文案
                            CJPayDefaultChannelShowConfig *bytepayConfig = [self setHomePageBytepayVoucherMsg:[allChannelsConfig lastObject] bySubPayObj:obj];
                            //提单页的卡片营销从voucher_msg_list 换到 subpay_voucher_msg_list
                            if (obj.useSubPayListVoucherMsg) {
                                obj.discountStr = [obj.payTypeData.subPayVoucherMsgList cj_objectAtIndex:0];
                            }
                            [allChannelsConfig removeLastObject];
                            [allChannelsConfig btd_addObject:bytepayConfig];
                            
                            [allChannelsConfig btd_addObject:obj];
                            *stop = YES;
                        }
                    }];
                }
            }
            
            if (self.bdPay.subPayTypeSumInfo.homePageBanner) {
                [allChannelsConfig addObjectsFromArray:[self.bdPay.subPayTypeSumInfo.homePageBanner buildShowConfig]];
            }
        }
    }];
    
    return allChannelsConfig;
}

// 使用默认/选中二级支付方式的营销文案来设置一级支付方式“抖音支付”后的营销文案
// （新客标准收银台改动：通过use_sub_pay_voucher_msg_list来判断是否使用原有字段更改「抖音支付」营销）
- (CJPayDefaultChannelShowConfig *)setHomePageBytepayVoucherMsg:(CJPayDefaultChannelShowConfig *)bytepayChannelConfig
                                                    bySubPayObj:(CJPayDefaultChannelShowConfig *)subPayObj {
    CJPayDefaultChannelShowConfig *bytepayShowConfig = [bytepayChannelConfig copy];
    if ([subPayObj.payChannel isKindOfClass:CJPaySubPayTypeInfoModel.class]) {
        //取选中二级支付方式的索引
        NSMutableArray *homePageBytepayVoucherMsg = [[NSMutableArray alloc] init];
        if (subPayObj.useSubPayListVoucherMsg) {
            CJPaySubPayTypeInfoModel *subPayMethod = (CJPaySubPayTypeInfoModel *)subPayObj.payChannel;
            //取索引对应的二级支付方式营销文案
            for (NSDictionary *voucher in subPayMethod.payTypeData.bytepayVoucherMsgList) {
                [homePageBytepayVoucherMsg btd_addObject:[voucher cj_objectForKey:@"label"]];
            }
        } else {
            NSString *subPayMethodIndex = [NSString stringWithFormat:@"%ld",(long)((CJPaySubPayTypeInfoModel *)subPayObj.payChannel).index];
            if([self.bdPay.subPayTypeSumInfo.bytepayVoucherMsgMap cj_objectForKey:subPayMethodIndex]) {
                //取索引对应的二级支付方式营销文案
                homePageBytepayVoucherMsg = [[self.bdPay.subPayTypeSumInfo.bytepayVoucherMsgMap cj_arrayValueForKey:subPayMethodIndex] mutableCopy];
            }
        }
        if(homePageBytepayVoucherMsg && homePageBytepayVoucherMsg.count > 0) {
            bytepayShowConfig.marks = [homePageBytepayVoucherMsg copy];
        } else {
            bytepayShowConfig.marks = @[];
        }
    }
    return bytepayShowConfig;
}

@end

@implementation CJPayIntegratedChannelModel(CJPay)

- (NSArray <CJPayDefaultChannelShowConfig *> *)buildConfigsWithIdentify:(NSString *)identify {
    return [self p_buildBytePayDeskConfigWithIdentify:identify];
}

- (NSArray <CJPayDefaultChannelShowConfig *> *)p_buildBytePayDeskConfigWithIdentify:(NSString *)identify {
    NSMutableArray<CJPayDefaultChannelShowConfig *> *allShowConfigs = [NSMutableArray new];
//    if (![self.subPayTypeSumInfo.homePageShowStyle isEqualToString:@"single"]) {
//        return @[];
//    }
    __block NSInteger count = 0;
    [self.subPayTypeSumInfo.subPayTypeInfoList enumerateObjectsUsingBlock:^(CJPaySubPayTypeInfoModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ((Check_ValidString(obj.payTypeData.voucherInfo.vouchersLabel) || obj.payTypeData.voucherInfo.vouchers.count)
            && [obj.status isEqualToString:@"1"]) {
            count = count + 1;
        }
        obj.extParamStr = self.extParamStr;
        NSArray<CJPayDefaultChannelShowConfig *> *configArray = [obj buildShowConfig];
        [configArray enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.retainInfoV2 = self.retainInfoV2;
        }];
        [allShowConfigs addObjectsFromArray:configArray];
    }];
    
    if (count > 1) {
        for (CJPayDefaultChannelShowConfig *showConfig in allShowConfigs) {
            showConfig.isLineBreak = YES;
        }
    }
    
    return [allShowConfigs copy];
}

@end

@implementation CJPayChannelModel(CJPayRequestParamProtocol)

- (NSDictionary *)buildParams {
    return @{@"ptcode": CJString(self.code)};
}

@end

@interface CJPayCreditPayChannelModel(CJPayRequestParamProtocol)
@end
@implementation CJPayCreditPayChannelModel(CJPayRequestParamProtocol)

- (NSDictionary *)buildParams {
    NSDictionary *superParams = [super buildParams];
    NSMutableDictionary *selfPrams = [NSMutableDictionary new];
    [selfPrams addEntriesFromDictionary:superParams];
    NSDictionary *ptcodeInfo = @{
        @"business_scene": @"Pre_Pay_Credit",
        @"ext_param" : CJString(self.extParamStr)
    };
    [selfPrams cj_setObject:@"creditpay" forKey:@"ptcode"];
    [selfPrams cj_setObject:[CJPayCommonUtil dictionaryToJson:ptcodeInfo] forKey:@"ptcode_info"];
    return [selfPrams copy];
}

@end

@interface CJPaySubPayTypeInfoModel (CJPayRequestParamProtocol)
@end
@implementation CJPaySubPayTypeInfoModel (CJPayRequestParamProtocol)

- (NSDictionary *)buildParams {
    NSMutableDictionary *selfPrams = [NSMutableDictionary dictionaryWithDictionary:[super buildParams]];
    NSString *business_scene = @"";
    NSString *combineType = @"";
    
    if (self.currentShowConfig.isCombinePay) {
        business_scene = @"Pre_Pay_Combine";
        if (self.currentShowConfig.combineType == BDPayChannelTypeBalance) {
            combineType = @"3";
        } else if (self.currentShowConfig.combineType == BDPayChannelTypeIncomePay) {
            combineType = @"129";
        }
    } else {
        switch (self.channelType) {
            case BDPayChannelTypeBankCard:
                business_scene = @"Pre_Pay_BankCard";
                break;
            case BDPayChannelTypeAddBankCard:
                business_scene = @"Pre_Pay_NewCard";
                break;
            case BDPayChannelTypeBalance:
                business_scene = @"Pre_Pay_Balance";
                break;
            case BDPayChannelTypeCreditPay:
                business_scene = @"Pre_Pay_Credit";
                break;
            case BDPayChannelTypeIncomePay:
                business_scene = @"Pre_Pay_Income";
                break;
            case BDPayChannelTypeTransferPay:
                business_scene = @"Pre_Pay_Transfer";
                break;
            default:
                break;
        }
    }
    NSMutableDictionary *ptcodeInfo = [@{@"business_scene": CJString(business_scene),
                                         @"bank_card_id": CJString(self.payTypeData.bankCardId)
                                       } mutableCopy];
    
    if (Check_ValidString(combineType) && self.currentShowConfig.isCombinePay) {
        [ptcodeInfo cj_setObject:combineType forKey:@"combine_type"];
        [ptcodeInfo cj_setObject:self.subPayType forKey:@"primary_pay_type"];
    }
    if (self.channelType == BDPayChannelTypeCreditPay) {
        NSString *installment = self.payTypeData.creditPayInstallment;
        if (!Check_ValidString(self.payTypeData.creditPayInstallment)) {
            installment = self.payTypeData.curSelectCredit.installment;
        }
        [ptcodeInfo cj_setObject:installment forKey:@"credit_pay_installment"];
    }
    
    [selfPrams cj_setObject:[CJPayCommonUtil dictionaryToJson:[ptcodeInfo copy]] forKey:@"ptcode_info"];
    [selfPrams cj_setObject:@"bytepay" forKey:@"ptcode"];
    return [selfPrams copy];
}

@end
