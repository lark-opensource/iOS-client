//
//  CJPayBDRetainInfoModel.m
//  Pods
//
//  Created by 王新华 on 2021/8/10.
//

#import "CJPayBDRetainInfoModel.h"

@implementation CJPayBDRetainInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"title" : @"title",
        @"retainMsgBonusStr" : @"retain_msg_bonus",
        @"retainMsgText" : @"retain_msg_text",
        @"retainType" : @"retain_type",
        @"showRetainWindow" : @"show_retain_window",
        @"retainPlan" : @"retain_plan",
        @"retainButtonText" : @"retain_button_text",
        @"choicePwdCheckWay" : @"choice_pwd_check_way",
        @"choicePwdCheckWayTitle" : @"choice_pwd_check_way_title",
        @"showChoicePwdCheckWay" : @"show_choice_pwd_check_way",
        @"forgetPwdVerfyType" : @"forget_pwd_verfy_type",
        @"retainMsgTextList": @"retain_msg_text_list",
        @"retainMsgBonusList": @"retain_msg_bonus_list",
        @"needVerifyRetain": @"need_verify_retain",
        @"type": @"type",
        @"recommendInfoModel": @"recommend_face_verify_info"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (CJPayRetainVoucherType)voucherType {
    if ([self.style isEqualToString:@"2.0"]) {
        return CJPayRetainVoucherTypeV2;
    } else if ([self.style isEqualToString:@"3.0"]) {
        return CJPayRetainVoucherTypeV3;
    }
    return CJPayRetainVoucherTypeV1;
}

- (BOOL)isfeatureRetain {
    return [self.type isEqualToString:@"feature_voucher"];
}

@end
