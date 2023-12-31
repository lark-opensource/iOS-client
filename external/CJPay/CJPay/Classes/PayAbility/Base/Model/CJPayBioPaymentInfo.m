//
//  CJPayBioPaymentInfo.m
//  CJPay
//
//  Created by 王新华 on 2019/3/31.
//

#import "CJPayBioPaymentInfo.h"

@implementation CJPayBioPaymentSubGuideModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"iconUrl": @"icon_url",
                @"iconDesc": @"desc"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

@implementation CJPayBioPaymentInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"cancelBtnDesc": @"cancel_btn_desc",
                @"showGuide": @"show_guide",
                @"guideDesc": @"guide_desc",
                @"bioType": @"bio_type",
                @"openBioDesc": @"confirm_btn_desc",
                @"successDesc": @"after_open_desc",
                @"showType": @"show_type",
                @"subGuide": @"sub_guide_desc"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
