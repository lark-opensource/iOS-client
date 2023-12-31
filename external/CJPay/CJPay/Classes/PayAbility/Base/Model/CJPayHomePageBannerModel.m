//
//  CJPayHomePageBannerModel.m
//  Pods
//
//  Created by wangxiaohong on 2021/4/12.
//

#import "CJPayHomePageBannerModel.h"

@implementation CJPayHomePageBannerModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"bannerText": @"banner_text",
        @"btnText": @"btn_text",
        @"btnAction": @"btn_action"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)buildShowConfig {
    CJPayDefaultChannelShowConfig *config = [CJPayDefaultChannelShowConfig new];
    config.title = self.bannerText;
    config.subTitle = self.btnText;
    config.iconUrl = @"";
    if ([self.btnAction isEqualToString:@"combine_pay"]) {
        config.type = CJPayChannelTypeBannerCombinePay;
    } else if ([self.btnAction isEqualToString:@"sub_pay_type_list"] || [self.btnAction isEqualToString:@"bindcard"]) {
        config.type = CJPayChannelTypeBannerVoucher;
    } else {
        config.type = CJPayChannelTypeNone;
    }
    return @[config];
}

@end
