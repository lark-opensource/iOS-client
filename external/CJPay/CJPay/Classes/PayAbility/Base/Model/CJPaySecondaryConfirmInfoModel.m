//
//  CJPaySecondaryConfirmInfoModel.m
//  Pods
//
//  Created by bytedance on 2021/11/15.
//

#import "CJPaySecondaryConfirmInfoModel.h"

@implementation CJPaySecondaryConfirmInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"subTitle" : @"sub_title",
        @"tipsCheckbox" : @"tips_checkbox",
        @"choicePwdCheckWay" : @"choice_pwd_check_way",
        @"nopwdConfirmHidePeriod" : @"no_pwd_confirm_hide_period",
        @"style" : @"style",
        @"buttonText" : @"button_text",
        @"checkboxSelectDefault" : @"checkbox_select_default"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
