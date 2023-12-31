//
//  CJPayResultPageGuideInfoModel.m
//  Pods
//
//  Created by 利国卿 on 2021/12/8.
//

#import "CJPayResultPageGuideInfoModel.h"
#import "CJPaySDKMacro.h"

@implementation CJPayResultPageGuideInfoModel

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
        @"guideType" : @"guide_type",
        @"confirmBtnDesc" : @"confirm_btn_desc",
        @"cancelBtnDesc" : @"cancel_btn_desc",
        @"cancelBtnLocation" : @"cancel_btn_location",
        @"headerDesc" : @"header_desc",
        @"subTitle" : @"sub_title",
        @"subTitleColor" : @"sub_title_color",
        @"pictureUrl" : @"pic_url",
        @"subTitleIconUrl" : @"sub_title_icon_url",
        @"bioType" : @"bio_type",
        @"afterOpenDesc" : @"after_open_desc",
        @"quota": @"quota",
        @"voucherDisplayText" : @"voucher_display_text",
        @"guideShowStyle" : @"guide_show_style",
        @"bubbleText" : @"bubble_text",
        @"headerPicUrl" : @"header_pic_url"
    }];
    
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (BOOL)isNewGuideShowStyle {    
    return [self.guideShowStyle containsString:@"new_guide_test"] && ![self isNewGuideShowStyleForOldPeople];
}

- (BOOL)isNewGuideShowStyleForOldPeople {
    return [self.guideShowStyle isEqualToString:@"new_guide_test4_v4"];
}

@end
