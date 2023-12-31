//
//  IESCategoryEffectModel.m
//  EffectPlatformSDK
//
//  Created by Fengfanhua.byte on 2021/9/27.
//

#import "IESCategorySampleEffectModel.h"


@interface IESCategorySampleEffectModel ()

@property (nonatomic, copy, readwrite) NSString *version;
@property (nonatomic, copy, readwrite) NSString *categoryKey;
@property (nonatomic, copy, readwrite) IESEffectModel *effect;
@property (nonatomic, copy, readwrite) IESEffectSampleVideoModel *video;

@end

@implementation IESCategorySampleEffectModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"version": @"version",
             @"categoryKey": @"category_key",
             @"effect": @"effects",
             @"video" : @"video_info"
             };
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {
    if ([key isEqualToString:@"effect"]) {
        return [MTLJSONAdapter dictionaryTransformerWithModelClass:[IESEffectModel class]];
    } if ([key isEqualToString:@"video"]) {
        return [MTLJSONAdapter dictionaryTransformerWithModelClass:[IESEffectSampleVideoModel class]];
    }
    return nil;
}

@end
