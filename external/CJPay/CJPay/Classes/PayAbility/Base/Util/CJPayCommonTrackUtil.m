//
//  CJPayCommonTrackUtil.m
//  Pods
//
//  Created by 王新华 on 2020/11/8.
//

#import "CJPayCommonTrackUtil.h"
#import "CJPayCreateOrderResponse.h"
#import "CJPayUserInfo.h"
#import "CJPaySDKMacro.h"
#import "CJPayKVContext.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayOutDisplayInfoModel.h"

@implementation CJPayCommonTrackUtil

+ (NSDictionary *)getCashDeskCommonParamsWithResponse:(CJPayCreateOrderResponse *)response
                                    defaultPayChannel:(NSString *)defaultPayChannel {
    NSString *methodListString = [response.payInfo.sortedPayChannels componentsJoinedByString:@","];
    
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"method" : CJString(response.payInfo.defaultPayChannel),
        @"method_list" : CJString(methodListString),
    }];
    [mutableDic addEntriesFromDictionary:[self p_commonBytePayParamsWithResponse:response]];
    return [mutableDic copy];
}

+ (NSDictionary *)getBDPayCommonParamsWithResponse:(CJPayBDCreateOrderResponse *)response showConfig:(CJPayDefaultChannelShowConfig *)showConfig {
    NSString *methodListString;
    if (response.payTypeInfo.allPayChannels.count) {
        __block NSMutableArray *array = [NSMutableArray new];
        [response.payTypeInfo.allPayChannels enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj && obj.title.length) {
                [array addObject:obj.title];
            }
        }];
        methodListString = [array componentsJoinedByString:@","]; // 电商场景不需要关注该字段
    } else {
        methodListString = [response.payTypeInfo.payChannels componentsJoinedByString:@","]; // 电商场景不需要关注该字段
    }

    // 是否已开通抖分期
    NSArray<CJPayDefaultChannelShowConfig *> *showConfigs = [response.payTypeInfo allSumInfoPayChannels];
    __block CJPayDefaultChannelShowConfig *creditPayChannelShowConfig = nil;
    [showConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type == BDPayChannelTypeCreditPay) {
            creditPayChannelShowConfig = obj;
            *stop = YES;
        }
    }];
    BOOL isCreditActivate = NO;
    if (creditPayChannelShowConfig && creditPayChannelShowConfig.isCreditActivate) {
        isCreditActivate = YES;
    }
    
    return @{
        @"app_id" : CJString(response.merchant.appId),
        @"merchant_id" : CJString(response.merchant.merchantId),
        @"is_chaselight" : @"1", // 是否为追光埋点
        @"identity_type" : CJString(response.userInfo.authStatus),
        @"trade_no" : CJString(response.tradeInfo.tradeNo),
        @"is_new_user" : (response.userInfo.isNewUser) ? @"1" : @"0",
        @"method" : CJString([CJPayBDTypeInfo getTrackerMethodByChannelConfig:showConfig]),
        @"this_method" : CJString([CJPayBDTypeInfo getTrackerMethodByChannelConfig:showConfig]),
        @"method_list" : CJString(methodListString),
        @"is_bankcard" : CJString(response.preTradeInfoWrapper.trackInfo.bankCardStatus),
        @"amount": @(response.tradeInfo.tradeAmount).stringValue,
        @"is_bankfold" : @"0",
        @"user_open_fxh_flag" : isCreditActivate ? @"1" : @"0",
        @"is_balavailable" : CJString(response.preTradeInfoWrapper.trackInfo.balanceStatus),
        @"user_open_fxh_flag" : CJString(response.preTradeInfoWrapper.trackInfo.creditStatus),
        @"fxh_method_list" : @"",
        @"fxh_method" : CJString(response.preTradeInfoWrapper.trackInfo.creditStatus),
        @"is_have_balance" : CJString(response.preTradeInfoWrapper.trackInfo.balanceStatus), // 余额支付是否展示
        @"PayAndSignCashierStyle": CJString(response.payTypeInfo.outDisplayInfo.payAndSignCashierStyle), // 「前置签约模式」的状态
        @"cashier_style" : response.payTypeInfo.outDisplayInfo ? @"1" : @"0",
    };
}

+ (NSDictionary *)getBytePayDeskCommonTrackerWithResponse:(CJPayCreateOrderResponse *)response {
    NSMutableDictionary *mutableDic = [NSMutableDictionary new];
    
    NSString *trackParams_defaultMethod;
    if (response.payInfo.bdPay != nil){ //默认支付方式优先追光
        trackParams_defaultMethod = response.payInfo.bdPay.defaultPayChannel;
    } else {
        trackParams_defaultMethod = [(CJPayChannelModel*)[response.payInfo.payChannels cj_objectAtIndex:0] code];
    }
    
    NSMutableString *trackParams_methodList = [NSMutableString new];
    
    for (id item in response.payInfo.payChannels) {
        if(![item isKindOfClass:[CJPayChannelModel class]]) {
            continue;
        }
        if(![trackParams_methodList isEqualToString:@""]) {
            [trackParams_methodList appendString:@","];
        }
        CJPayChannelModel *model = item;
        if([model.code isEqualToString:@"bytepay"]) {
            [trackParams_methodList appendString:CJString([response.payInfo.bdPay.payChannels componentsJoinedByString:@","])];
        } else {
            [trackParams_methodList appendString:CJString(model.code)];
        }
    }
    NSString *scene = @([[response.tradeInfo.statInfo cj_toDic] cj_integerValueForKey:@"scene"]).stringValue;
    [mutableDic addEntriesFromDictionary:@{
        @"method" : CJString(trackParams_defaultMethod),
        @"method_list" : CJString(trackParams_methodList),
        @"amount" : @(response.tradeInfo.amount),
        @"dy_charge_scene": CJString(scene),
    }];
    [mutableDic addEntriesFromDictionary:[self p_commonBytePayParamsWithResponse:response]];
    [mutableDic addEntriesFromDictionary:response.feMetrics];

    NSString *bdPayProcessID = [[[response.payInfo bdPay] promotionProcessInfo] cj_stringValueForKey:@"process_id"] ?: @"";
    [mutableDic addEntriesFromDictionary:@{@"process_id": bdPayProcessID}];
    
    if ([response.deskConfig currentDeskType] == CJPayDeskTypeBytePay) {
        [response.payInfo.payChannels enumerateObjectsUsingBlock:^(CJPayChannelModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.code isEqualToString:@"bytepay"]) {
                [mutableDic addEntriesFromDictionary:@{@"tips_msg" : CJString(obj.tipsMsg)}];
                *stop = YES;
            }
        }];
        
        CJPaySubPayTypeSumInfoModel *sumInfoModel = response.payInfo.bdPay.subPayTypeSumInfo;
        CJPaySubPayTypeInfoModel *firstInfoModel = sumInfoModel.subPayTypeInfoList.firstObject;
        BOOL isHaveBalance = [firstInfoModel.subPayType isEqualToString:@"balance"];
        trackParams_methodList = [NSMutableString string];
        for (CJPayChannelModel *item in response.payInfo.payChannels) {
            [trackParams_methodList appendFormat:@"%@,", CJString(item.code)];
        }
        NSArray<NSString *> *defaultCardMsg = [self p_bytePayMethodGetDefaultCardMsg:sumInfoModel];
        [mutableDic addEntriesFromDictionary:@{
            @"first_method_list": CJString([response.payInfo.sortedPayChannels componentsJoinedByString:@","]),
            @"is_comavailable" : sumInfoModel.balanceTypeData.showCombinePay ? @"1" : @"0",
            @"is_balavailable" : sumInfoModel.balanceTypeData.balanceAmount > 0 ? @"1" : @"0",
            @"is_have_balance" : isHaveBalance ? @"1" : @"0",
            @"is_bankcard": sumInfoModel.isBindedCard ? @"1" : @"0",
            @"method_list": CJString(trackParams_methodList),
            @"method": [self p_bytePayMethodTrackerWithResponse:response model:firstInfoModel],
            @"is_recommend": sumInfoModel.homePageBanner ? @"1" : @"0",  //是否有强推区
            @"recommend_title": CJString(sumInfoModel.homePageBanner.bannerText),    //强推区文案
            @"recommend_type":CJString([self p_bytePayMethodGetRecommendType:sumInfoModel]),   //强推区类型
            @"default_first_card_msg":CJString([defaultCardMsg cj_objectAtIndex:0]),
            @"default_second_card_msg":CJString([defaultCardMsg cj_objectAtIndex:1]),
            @"expanding_open_pay_type": CJString([CJPayCommonTrackUtil p_bytePayMethodGetExpandingOpenPayType:response sumInfoModel:sumInfoModel]),//支付方式的扩展区样式
            @"tag_title": CJString([CJPayCommonTrackUtil p_bytePayMethodGetTagTitle:response sumInfoModel:sumInfoModel]),
        }];
    }
    return [mutableDic copy];
}

//获取默认卡片第1、2张卡片的营销
+ (NSArray<NSString *> *)p_bytePayMethodGetDefaultCardMsg:(CJPaySubPayTypeSumInfoModel *)sumInfoModel {
    NSMutableArray *cardMsg = [[NSMutableArray alloc] init];
    
    if (sumInfoModel.subPayTypeInfoList.count > 1) {
        NSInteger firstSubIndex = [[sumInfoModel.cardStyleIndexList cj_objectAtIndex:0] integerValue];
        NSInteger secondSubIndex = [[sumInfoModel.cardStyleIndexList cj_objectAtIndex:1] integerValue];
        
        for (CJPaySubPayTypeInfoModel *subModel in sumInfoModel.subPayTypeInfoList) {
            if (subModel.index == firstSubIndex) {
                [cardMsg btd_addObject:[subModel.payTypeData.subPayVoucherMsgList cj_objectAtIndex:0]];
            } else if (cardMsg.count > 0 && subModel.index == secondSubIndex) {
                [cardMsg btd_addObject:[subModel.payTypeData.subPayVoucherMsgList cj_objectAtIndex:0]];
                break;
            }
        }
    } else if (sumInfoModel.subPayTypeInfoList.count == 1) {
        NSInteger firstSubIndex = [[sumInfoModel.cardStyleIndexList cj_objectAtIndex:0] integerValue];
        
        for (CJPaySubPayTypeInfoModel *subModel in sumInfoModel.subPayTypeInfoList) {
            if (subModel.index == firstSubIndex) {
                [cardMsg btd_addObject:[subModel.payTypeData.subPayVoucherMsgList cj_objectAtIndex:0]];
                break;
            }
        }
        [cardMsg btd_addObject:@""];
    } else {
        [cardMsg addObjectsFromArray:@[@"",@""]];
    }
    return [cardMsg copy];
}

//获取强推区类型
+ (NSString *)p_bytePayMethodGetRecommendType:(CJPaySubPayTypeSumInfoModel *)sumInfoModel {
    if (!Check_ValidString(sumInfoModel.homePageBanner.btnAction)) {
        return @"";
    }
    if ([sumInfoModel.homePageBanner.btnAction isEqualToString:@"bindcard"]) {
        return @"wxcard";
    } else if ([sumInfoModel.homePageBanner.btnAction isEqualToString:@"combine_pay"]) {
        return @"combine";
    } else {
        return @"";
    }
}

//获取下发的tag
+ (NSString *)p_bytePayMethodGetTagTitle:(CJPayCreateOrderResponse *)response sumInfoModel:(CJPaySubPayTypeSumInfoModel *)sumInfoModel {
    NSInteger firstIndex = -1;
    NSInteger secondIndex = -1;
    if (sumInfoModel.cardStyleIndexList.count > 1) {
        firstIndex = [[sumInfoModel.cardStyleIndexList cj_objectAtIndex:0] integerValue];
        secondIndex = [[sumInfoModel.cardStyleIndexList cj_objectAtIndex:1] integerValue];
    } else if (sumInfoModel.cardStyleIndexList > 0) {
        firstIndex = [[sumInfoModel.cardStyleIndexList cj_objectAtIndex:0] integerValue];
    }
    NSMutableString *tagTitleTracker = [[NSMutableString alloc] init];
    if ([sumInfoModel.homePageShowStyle isEqualToString:@"card"]) {
        [sumInfoModel.subPayTypeInfoList enumerateObjectsUsingBlock:^(CJPaySubPayTypeInfoModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.index == firstIndex) {
                NSString *tag1 = [[obj.payTypeData.bytepayVoucherMsgList cj_objectAtIndex:0] cj_stringValueForKey:@"label"];
                NSString *tag2 = [[obj.payTypeData.bytepayVoucherMsgList cj_objectAtIndex:1] cj_stringValueForKey:@"label"];
                NSString *tag3 = [obj.payTypeData.subPayVoucherMsgList cj_objectAtIndex:0];
                [tagTitleTracker appendFormat:@"10-1:%@、10-2:%@、10-3:%@、10-4:",tag1,tag2,tag3];
            } else if (tagTitleTracker && obj.index == secondIndex) {
                NSString *tag4 = [obj.payTypeData.subPayVoucherMsgList cj_objectAtIndex:0];
                [tagTitleTracker appendFormat:@"、10-5:%@、10-6:",tag4];
            }
        }];
    } else {
        CJPaySubPayTypeInfoModel *firstSubPayModel = [sumInfoModel.subPayTypeInfoList cj_objectAtIndex:0];
        NSString *tag1 = [[firstSubPayModel.payTypeData.bytepayVoucherMsgList cj_objectAtIndex:0] cj_stringValueForKey:@"label"];
        NSString *tag2 = [[firstSubPayModel.payTypeData.bytepayVoucherMsgList cj_objectAtIndex:1] cj_stringValueForKey:@"label"];
        NSString *tag3 = [firstSubPayModel.payTypeData.subPayVoucherMsgList cj_objectAtIndex:0];
        [tagTitleTracker appendFormat:@"10-1:%@、10-2:%@、10-3:%@、10-4:",tag1,tag2,tag3];
    }
    return [tagTitleTracker copy];
}

//获取扩展区样式埋点值
+ (NSString *)p_bytePayMethodGetExpandingOpenPayType:(CJPayCreateOrderResponse *)response sumInfoModel:(CJPaySubPayTypeSumInfoModel *)sumInfoModel {
    NSMutableArray *payTypeArray = [[NSMutableArray alloc] init];
    
    if ([sumInfoModel.homePageShowStyle isEqualToString:@"card"]) {
        [response.payInfo.payChannels enumerateObjectsUsingBlock:^(CJPayChannelModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMutableDictionary *payTypeDic = [[NSMutableDictionary alloc] init];
            [payTypeDic addEntriesFromDictionary:@{
                @"type": obj.title,
                @"style": [obj.code isEqualToString:@"bytepay"] ? @"card" : @"single"
            }];
            [payTypeArray btd_addObject:[payTypeDic copy]];
        }];
    } else {
        [response.payInfo.payChannels enumerateObjectsUsingBlock:^(CJPayChannelModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMutableDictionary *payTypeDic = [[NSMutableDictionary alloc] init];
            [payTypeDic addEntriesFromDictionary:@{
                @"type": obj.title,
                @"style": @"single"
            }];
            [payTypeArray btd_addObject:[payTypeDic copy]];
        }];
    }
    return [payTypeArray btd_jsonStringEncoded];
}

+ (NSString *)p_bytePayMethodTrackerWithResponse:(CJPayCreateOrderResponse *)response model:(CJPaySubPayTypeInfoModel *)model {
    if ([model.subPayType isEqualToString:@"bank_card"]) {
        return @"quickpay";
    }
    if ([model.subPayType isEqualToString:@"new_bank_card"]) {
        return @"addcard";
    }
    return CJString(response.payInfo.defaultPayChannel);
}

+ (NSMutableDictionary *)p_commonBytePayParamsWithResponse:(CJPayCreateOrderResponse *)response {

    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict addEntriesFromDictionary:@{
        @"app_id" : CJString(response.merchantInfo.appId),
        @"merchant_id" : CJString(response.merchantInfo.merchantId),
        @"is_chaselight" : @"1", // 是否为追光埋点
        @"identity_type" : CJString(response.userInfo.authStatus),
        @"trade_no" : CJString(response.tradeInfo.tradeNo),
        @"is_new_user" : response.userInfo.isNewUser ? @"1" : @"0",
        @"is_bankcard" : @"0",
        @"is_bankfold" : @"0",
        @"is_balavailable" : response.payInfo.isBalanceAvailable ? @"1" : @"0",
        @"user_open_fxh_flag" : CJString(response.payInfo.isCreditPayAvailable),
        @"fxh_method_list" : CJString(response.payInfo.creditPayStageListStr),
        @"fxh_method" : CJString([CJPayKVContext kv_stringForKey:CJPayTrackerCommonParamsCreditStage]),
        @"is_have_balance" : @"0" // 余额支付是否展示
    }];
    return mutableDict;
}

@end
