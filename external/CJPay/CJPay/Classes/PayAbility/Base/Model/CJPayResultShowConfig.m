//
//  CJPayResultShowConfig.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/27.
//

#import "CJPayResultShowConfig.h"
#import "CJPaySDKMacro.h"

@implementation CJPayResultShowConfigGuideInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"text": @"text",
        @"color": @"color",
        @"type":@"type"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (BOOL)isShowText {
    return ([self.type isEqualToString:@"text"] && Check_ValidString(self.text));
}

@end

@implementation CJPayResultShowConfig

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
            @"remainTime": @"remain_time",
            @"successDesc": @"success_desc",
            @"resultDesc": @"result_desc",
            @"successUrl": @"success_url",
            @"successBtnDesc": @"success_btn_desc",
            @"queryResultTimes": @"query_result_times",
            @"middleBannerType": @"middle_banner.banner_type",
            @"middleBanners": @"middle_banner.discount_banner",
            @"bottomBannerType": @"banner_type",
            @"bottomBanners": @"discount_banner",
            @"showStyle": @"show_style",
            @"bottomGuideInfo": @"bottom_guide_info",
            @"withdrawResultPageDesc":@"withdraw_result_page_desc",
            @"hiddenResultPage" : @"no_show_result_page",
            @"successBtnPosition" : @"success_btn_position",
            @"bgImageURL" : @"bg_image",
            @"iconUrl" : @"tip_image"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (int)queryResultTime {
    if (_queryResultTimes < 1) {
        return 5;
    }
    return _queryResultTimes;
}

@end
