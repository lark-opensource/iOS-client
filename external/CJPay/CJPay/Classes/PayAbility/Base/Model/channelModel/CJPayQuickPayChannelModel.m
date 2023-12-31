//
//  CJPayQuickPayChannelModel.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/23.
//

#import "CJPayQuickPayChannelModel.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayCreditPayMethodModel.h"

@implementation CJPayQuickPayCardModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"status": @"status",
                @"msg" : @"msg",
                @"bankCardID" : @"bank_card_id",
                @"cardNoMask" : @"card_no_mask",
                @"cardType" : @"card_type",
                @"cardTypeName" : @"card_type_name",
                @"frontBankCode" : @"front_bank_code",
                @"iconUrl" : @"icon_url",
                @"trueNameMask" : @"true_name_mask",
                @"frontBankCodeName" : @"front_bank_code_name",
                @"mobileMask" : @"mobile_mask",
                @"certificateCodeMask" : @"certificate_code_mask",
                @"certificateType" : @"certificate_type",
                @"needRepaire" : @"need_repaire",
//                @"displayItems" : @"display_items",
                @"userAgreements" : @"user_agreement",
                @"cardLevel" : @"card_level",
                @"perDayLimit" : @"perday_limit",
                @"perPayLimit" : @"perpay_limit",
                @"withdrawMsg": @"withdraw_msg",
                @"identityVerifyWay": @"identity_verify_way"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

#pragma mark CJPayDefaultChannelShowConfigBuildProtocol 内部统一model协议
- (NSArray<CJPayDefaultChannelShowConfig *> *)buildShowConfig {
    CJPayDefaultChannelShowConfig *configModel = [CJPayDefaultChannelShowConfig new];
    configModel.iconUrl = self.iconUrl;
    NSString *titleStr = self.frontBankCodeName;
    titleStr = [NSString stringWithFormat:@"%@%@", CJString(titleStr), CJString(self.cardTypeName)];
    
    configModel.title = titleStr;
    configModel.subTitle = self.bankCardID;
    configModel.payChannel = self;
    configModel.status = self.status;
    configModel.mobile = self.mobileMask;
    configModel.cjIdentify = self.bankCardID;
    configModel.reason = self.msg;
    configModel.type = BDPayChannelTypeBankCard;
    configModel.cardLevel = self.cardLevel;
    configModel.comeFromSceneType = self.comeFromSceneType;
    configModel.bankCardId = self.bankCardID;
    if (Check_ValidString(self.withdrawMsg) && (self.comeFromSceneType == CJPayComeFromSceneTypeBalanceWithdraw)) {
        configModel.withdrawMsg = self.withdrawMsg;
    }else{
        if ([CJPayLocalizedUtil getCurrentLanguage] == CJPayLocalizationLanguageZhhans){//英文暂不显示每笔限额
            if (Check_ValidString(self.perPayLimit)) {
                configModel.limitMsg = [NSString stringWithFormat:CJPayLocalizedStr(@"限%@元/笔"), self.perPayLimit];
            }
            if (Check_ValidString(self.perPayLimit) && Check_ValidString(self.perDayLimit)) {
                configModel.limitMsg = [NSString stringWithFormat:@"%@，", configModel.limitMsg];
            }
        }
        if (Check_ValidString(self.perDayLimit)) {
            NSString *preLimitMsg = configModel.limitMsg;
            configModel.limitMsg = [NSString stringWithFormat:CJPayLocalizedStr(@"%@%@元/日"), Check_ValidString(preLimitMsg) ? preLimitMsg : @"", self.perDayLimit];
        }
    }
   
    if (self.cardNoMask.length >= 4) {
        configModel.cardTailNumStr = [self.cardNoMask substringFromIndex:self.cardNoMask.length - 4];
    }
    
    configModel.voucherInfo = [self.voucherInfo copy];
    
    return @[configModel];
}

#pragma mark CJPayRequestParamsProtocol 支付参数生成协议
- (NSDictionary *)requestNeedParams{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    [dic cj_setObject:self.bankCardID forKey:@"bank_card_id"];
    [dic cj_setObject:self.trueNameMask forKey:@"true_name"];
    [dic cj_setObject:self.certificateCodeMask forKey:@"certificate_num"];
    [dic cj_setObject:self.certificateType forKey:@"certificate_type"];
    [dic cj_setObject:self.mobileMask forKey:@"mobile"];
    [dic cj_setObject:@"" forKey:@"cvv2"];
    [dic cj_setObject:@"" forKey:@"valid_date"];
    return @{@"card_item": dic};
}

@end

@implementation CJPayQuickPayChannelModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"mark": @"mark",
                @"msg": @"msg",
                @"status": @"status",
                @"cards": @"cards",
                @"discountBanks": @"discount_banks",
                @"enableBindCard": @"enable_bind_card",
                @"enableBindCardMsg": @"enable_bind_card_msg",
                @"discountBindCardMsg": @"discount_bind_card_msg",
                @"title": @"title",
                @"ttSubTitle": @"tt_sub_title",
                @"iconUrl": @"icon_url",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)buildShowConfig{
    NSMutableArray *cardShowConfigs = [NSMutableArray array];
    for (CJPayQuickPayCardModel *cardModel in _cards) {
        NSArray<CJPayDefaultChannelShowConfig *> * cardShowConfig = [cardModel buildShowConfig];
        if (cardShowConfig != nil && cardShowConfig.count > 0) {
            [cardShowConfigs addObjectsFromArray:cardShowConfig];
        }
    }
    return cardShowConfigs;
}

- (BOOL)hasValidBankCard {
    __block BOOL hasValidCard = NO;
    [self.cards enumerateObjectsUsingBlock:^(CJPayQuickPayCardModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj && Check_ValidString(obj.bankCardID)) {
            hasValidCard = YES;
        }
    }];
    return hasValidCard;
}

@end
