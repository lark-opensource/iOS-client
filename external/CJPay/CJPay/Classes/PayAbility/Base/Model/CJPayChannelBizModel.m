//
//  CJPayChannelBizModel.m
//  CJPay
//
//  Created by 王新华 on 2019/4/18.
//

#import "CJPayChannelBizModel.h"
#import "CJPayChannelModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayUIMacro.h"

@implementation CJPayChannelBizModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hasConfirmBtnWhenUnConfirm = YES;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:CJPayChannelBizModel.class]) {
        CJPayChannelBizModel *bizModel = object;
        return bizModel.type == self.type &&
                [bizModel.title isEqual:self.title] &&
        [bizModel.channelConfig.cjIdentify isEqual:self.channelConfig.cjIdentify];
    }
    return NO;
}

- (BOOL)isDisplayCreditPayMetheds {
    if ([self.channelConfig.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) {
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)self.channelConfig.payChannel;
        return (self.type == BDPayChannelTypeCreditPay && payChannel.payTypeData.creditPayMethods.count > 0 && self.enable);
    } else {
        return NO;
    }
}

- (NSDictionary *)toMethodInfoTracker {
    return @{
        @"info": CJString(self.title),
        @"status": self.enable ? @"1" : @"0",
        @"reason": CJString(self.subTitle)
    };
}

- (BOOL)isUnionBindCard {
    return ([self.channelConfig.frontBankCode isEqualToString:@"UPYSFBANK"] && self.type == BDPayChannelTypeAddBankCard);
}

@end

@implementation CJPayDefaultChannelShowConfig(CJPayToBizModel)

- (CJPayChannelBizModel *)toBizModel {
    CJPayChannelBizModel *model = [CJPayChannelBizModel new];
    model.index = self.index;
    model.type = self.type;
    model.title = self.title;
    model.subTitle = self.subTitle;
    model.subTitleColorStr = self.subTitleColor;
    model.iconUrl = self.iconUrl;
    model.enable = [self.status isEqualToString:@"1"];
    model.isConfirmed = self.isSelected;
    model.reasonStr = self.reason;
    model.channelConfig = self;
    model.isNoActive = (self.cardLevel == 2);
    model.WithDrawMsgStr = self.withdrawMsg;
    model.limitMsgStr = self.limitMsg;
    model.discountStr = self.discountStr;
    model.showCombinePay = self.showCombinePay;
    model.isLineBreak = self.isLineBreak;
    model.isCombinePay = self.isCombinePay;
    model.combineType = self.combineType;
    if (model.type == BDPayChannelTypeCardCategory) {
        model.hasSub = YES;
    }
    model.comeFromSceneType = self.comeFromSceneType;
    model.code = self.payChannel.code;
    model.tipsMsg = self.payChannel.tipsMsg;
    model.homePageShowStyle = self.homePageShowStyle;
    model.subPayTypeData = self.subPayTypeData;
    model.primaryCombinePayAmount = self.primaryCombinePayAmount;
    model.useSubPayListVoucherMsg = self.useSubPayListVoucherMsg;
    model.selectPageGuideText = self.payTypeData.selectPageGuideText;
    model.voucherMsgV2Model = self.payTypeData.voucherMsgV2Model;
    model.voucherMsgV2Type = self.voucherMsgV2Type;
    return model;
}

@end
