//
//  ACCMVCategoryModel.m
//  CameraClient
//
//  Created by long.chen on 2020/3/12.
//

#import "ACCMVCategoryModel.h"

@implementation ACCMVCategoryModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"categoryID" : @"category_id",
        @"categoryName" : @"category_name",
        @"categoryType" : @"category_type",
    };
}

@end


@implementation ACCMVCategoryReponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{
        @"categories" : @"categorys",
    } acc_apiPropertyKey];
}
 
+ (NSValueTransformer *)categoriesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ACCMVCategoryModel.class];
}

@end
