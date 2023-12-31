//
// Created by 易培淮 on 2020/10/15.
//

#import "CJPayQRCodeModel.h"


@implementation CJPayShareImageModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"payeeName":@"share_image.payee_name",
        @"userNameDesc":@"share_image.username_desc",
        @"validityDesc":@"share_image.validity_desc"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end



@implementation CJPayQRCodeModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"imageUrl":@"image_url",
        @"logo":@"logo",
        @"themeColor":@"theme_color",
        @"shareImageSwitch":@"share_image_switch",
        @"shareDesc":@"share_desc",
        @"bgColor":@"share_image.bg_color",
        @"payDeskTitle":@"payDeskTitle",
        @"shareImage":@"share_image"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
