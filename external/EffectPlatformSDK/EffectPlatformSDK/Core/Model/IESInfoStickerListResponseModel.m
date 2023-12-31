//
//  IESInfoStickerListResponseModel.m
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/2/22.
//

#import "IESInfoStickerListResponseModel.h"

@interface IESInfoStickerListResponseModel ()

@property (nonatomic, strong, readwrite) NSArray<IESInfoStickerModel *> *stickerList;
@property (nonatomic, strong, readwrite) NSArray<IESInfoStickerModel *> *collectionStickerList;
@property (nonatomic, strong, readwrite) NSArray<IESInfoStickerCategoryModel *> *categoryList;

@end

@implementation IESInfoStickerListResponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"version":@"version",
        @"panelName":@"panel",
        @"stickerList":@"effects",
        @"collectionStickerList":@"collection",
        @"categoryList":@"category",
        @"frontInfoStickerID":@"front_effect_id",
        @"rearInfoStickerID":@"rear_effect_id",
        @"urlPrefix":@"url_prefix"
    };
}

- (void)preProcessEffects
{
    NSArray<NSString *> *urlPrefix = self.urlPrefix;
    [self.stickerList enumerateObjectsUsingBlock:^(IESInfoStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setURLPrefix:urlPrefix];
    }];
    [self.collectionStickerList enumerateObjectsUsingBlock:^(IESInfoStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setURLPrefix:urlPrefix];
    }];
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {
    if ([key isEqualToString:@"stickerList"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESInfoStickerModel class]];
    } else if ([key isEqualToString:@"categoryList"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESInfoStickerCategoryModel class]];
    } else if ([key isEqualToString:@"collectionStickerList"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESInfoStickerModel class]];
    }
    return nil;
}

@end
