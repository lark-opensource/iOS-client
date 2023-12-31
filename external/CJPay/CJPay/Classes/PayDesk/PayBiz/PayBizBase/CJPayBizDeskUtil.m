//
//  CJPayBizDeskUtil.m
//  Aweme
//
//  Created by shanghuaijun on 2023/2/25.
//

#import "CJPayBizDeskUtil.h"
#import "CJPayChannelBizModel.h"
#import "CJPayZoneSplitInfoModel.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBizDeskUtil

+ (NSArray<CJPayChannelBizModel *> *)reorderDisableCardsWithMethodArray:(NSArray<CJPayChannelBizModel *> *)array
                                                     zoneSplitInfoModel:(CJPayZoneSplitInfoModel *)zoneSplitInfoModel {
    NSMutableArray *allMethodsArray = [array mutableCopy];
    
    __block NSInteger firstUnbindNewCardIndex = -1;
    [allMethodsArray enumerateObjectsUsingBlock:^(CJPayChannelBizModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self isCertainChannelUnbindNewCard:obj]) {
            firstUnbindNewCardIndex = idx;
            *stop = YES;
        }
    }];
    
    // 获取特定渠道新卡列表的分隔条信息，选择合适位置插入
    if (zoneSplitInfoModel && zoneSplitInfoModel.zoneIndex > 0) {
        if (firstUnbindNewCardIndex >= 0 && firstUnbindNewCardIndex < allMethodsArray.count) {
            CJPayChannelBizModel *zoneChannelModel = [CJPayChannelBizModel new];
            zoneChannelModel.type = CJPayChannelTypeUnBindBankCardZone;
            zoneChannelModel.isChooseMethodSubPage = YES;
            zoneChannelModel.title = zoneSplitInfoModel.isShowCombineTitle ? zoneSplitInfoModel.combineZoneTitle : zoneSplitInfoModel.zoneTitle ;
            [allMethodsArray btd_insertObject:zoneChannelModel atIndex:firstUnbindNewCardIndex];
        }
    }
    
    NSMutableArray<CJPayChannelBizModel *> *enableArray = [NSMutableArray new];
    NSMutableArray<CJPayChannelBizModel *> *disableArray = [NSMutableArray new];
    for (CJPayChannelBizModel *bizModel in allMethodsArray) {
        if (bizModel.enable || bizModel.type == CJPayChannelTypeUnBindBankCardZone) {
            [enableArray btd_addObject:bizModel];
        } else {
            [disableArray btd_addObject:bizModel];
        }
    }
    
    if (disableArray.count > 0) {
        CJPayChannelBizModel *separateChannelModel = [CJPayChannelBizModel new];
        separateChannelModel.type = CJPayChannelTypeSeparateLine;
        separateChannelModel.isChooseMethodSubPage = YES;
        [enableArray btd_addObject:separateChannelModel];
    }
    [enableArray addObjectsFromArray:disableArray];
    
    return  [enableArray copy];
}

+ (BOOL)isCertainChannelUnbindNewCard:(CJPayChannelBizModel *)channelModel {
    return  channelModel.type == BDPayChannelTypeAddBankCard && Check_ValidString(channelModel.channelConfig.frontBankCode);
}


@end
