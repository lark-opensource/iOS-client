//
//  CJPayRetainUtilModel.m
//  Pods
//
//  Created by youerwei on 2022/4/11.
//

#import "CJPayRetainUtilModel.h"
#import "CJPayBDRetainInfoModel.h"
#import "CJPaySDKMacro.h"

@implementation CJPayRetainUtilModel

- (CJPayRetainType)retainType {
    BOOL isTextValid = NO;
    BOOL isBonusValid = NO;
    
    if (self.retainInfo.voucherType == CJPayRetainVoucherTypeV2 || self.retainInfo.voucherType == CJPayRetainVoucherTypeV3) {
        isTextValid = Check_ValidArray(self.retainInfo.retainMsgTextList);
        isBonusValid = Check_ValidArray(self.retainInfo.retainMsgBonusList);
    } else {
        isTextValid = Check_ValidString(self.retainInfo.retainMsgText);
        isBonusValid = Check_ValidString(self.retainInfo.retainMsgBonusStr);
    }
    
    if (!self.isBonusPath) {
        return isTextValid ? CJPayRetainTypeText : CJPayRetainTypeDefault;
    }
    
    // isBonusPath
    if (isBonusValid) {
        return CJPayRetainTypeBonus;
    }
    
    return isTextValid ? CJPayRetainTypeText : CJPayRetainTypeDefault;
}

- (NSString *)eventNameForPopUpClick {
    if (!_eventNameForPopUpClick) {
        return @"wallet_password_keep_pop_click";
    }
    return _eventNameForPopUpClick;
}

- (NSString *)eventNameForPopUpShow {
    if (!_eventNameForPopUpShow) {
        return @"wallet_password_keep_pop_show";
    }
    return _eventNameForPopUpShow;
}

- (NSDictionary *)extraParamForConfirm {
    NSMutableDictionary *dic = [@{@"button_name": @"1"} mutableCopy];
    [dic addEntriesFromDictionary:_extraParamForConfirm];
    return dic;
}

- (NSDictionary *)extraParamForOtherVerify {
    NSMutableDictionary *dic = [@{@"button_name": @"2"} mutableCopy];
    [dic addEntriesFromDictionary:_extraParamForOtherVerify];
    return dic;
}

- (NSDictionary *)extraParamForClose {
    NSMutableDictionary *dic = [@{@"button_name": @"0"} mutableCopy];
    [dic addEntriesFromDictionary:_extraParamForClose];
    return dic;
}

- (void)buildTrackEventNormalSetting {
    if (!self.retainInfo) {
        return;
    }
    NSString *topButtonTitle;
    NSString *bottomButtonTitle;
    topButtonTitle = CJString(self.retainInfo.retainButtonText);
    bottomButtonTitle = CJString(self.retainInfo.choicePwdCheckWayTitle);
    NSDictionary *dict = @{
        @"main_verify": topButtonTitle,
        @"other_verify" : bottomButtonTitle
    };
    NSMutableDictionary *confirmParam = [@{
        @"button_verify": topButtonTitle
    } mutableCopy];
    NSMutableDictionary *otherVerifyParam = [@{
        @"button_verify": bottomButtonTitle
    } mutableCopy];
    [confirmParam addEntriesFromDictionary:dict];
    [otherVerifyParam addEntriesFromDictionary:dict];
    
    self.extraParamForPopUpShow = dict;
    self.extraParamForConfirm = confirmParam;
    self.extraParamForOtherVerify = otherVerifyParam;
}

- (CJPayLynxRetainEventType)obtainEventType:(NSString *)eventName {
    if (!Check_ValidString(eventName)) {
        return CJPayLynxRetainEventTypeOnCancel;
    }
    if ([eventName isEqualToString:@"on_cancel"]) {
        return CJPayLynxRetainEventTypeOnCancel;
    }
    if ([eventName isEqualToString:@"on_confirm"]) {
        return CJPayLynxRetainEventTypeOnConfirm;
    }
    if ([eventName isEqualToString:@"on_cancel_and_leave"]) {
        return CJPayLynxRetainEventTypeOnCancelAndLeave;
    }
    if ([eventName isEqualToString:@"on_change_pay_method"]) {
        return CJPayLynxRetainEventTypeOnChangePayType;
    }
    if ([eventName isEqualToString:@"on_other_verify"]) {
        return CJPayLynxRetainEventTypeOnOtherVerify;
    }
    if ([eventName isEqualToString:@"on_reinput_pwd"]) {
        return CJPayLynxRetainEventTypeOnReinputPwd;
    }
    if ([eventName isEqualToString:@"on_pay"]) {
        return CJPayLynxRetainEventTypeOnPay;
    }
    if ([eventName isEqualToString:@"on_select_pay"]) {
        return CJPayLynxRetainEventTypeOnSelectPay;
    }
    return CJPayLynxRetainEventTypeOnCancel;
}

- (CJPayChannelType)recommendChannelType:(NSString *)payTypeStr {
    if ([payTypeStr isEqualToString:@"credit_pay"]) {
        return BDPayChannelTypeCreditPay;
    } else if ([payTypeStr isEqualToString:@"bank_card"]) {
        return BDPayChannelTypeBankCard;
    }
    return CJPayChannelTypeNone;
}
@end
