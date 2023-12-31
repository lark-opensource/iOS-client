//
//  ACCBeautyBuildInDataSourceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2020/10/12.
//

#import "ACCBeautyBuildInDataSourceImpl.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSString+CameraClientResource.h>

NSString *const ACCBeautyBuildInSmoothKey       = @"100";
NSString *const ACCBeautyBuildInFaceLiftKey     = @"101";
NSString *const ACCBeautyBuildInBigEyeKey       = @"102";

@interface ACCBeautyBuildInDataSourceImpl()

@property (nonatomic, copy)NSArray<AWEComposerBeautyEffectCategoryWrapper *> *categories;

@end

@implementation ACCBeautyBuildInDataSourceImpl

- (NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)buildInCategories {
    if (!_categories) {
        NSString *bundlePath = [NSString acc_bundlePathWithName:@"FilterEffect"];
        if (!bundlePath) {
            return @[];
        }
        AWEComposerBeautyEffectCategoryWrapper *categoryWrapper = [[AWEComposerBeautyEffectCategoryWrapper alloc]init];
        categoryWrapper.gender = AWEComposerBeautyGenderBoth;
        categoryWrapper.isLocalEffect = YES;
        
        NSDictionary *categoryDic = @{
            @"categoryIdentifier": @"1"
        };
        NSArray *itemDic = @[
            @{
                @"isDoubleDirection": @(NO),
                @"minPercent": @(0),
                @"maxPercent": @(100),
                @"defaultPercent": @(60),
                @"tag": @"Smooth_ALL",
                @"name": @"smooth"
            },
            @{
                @"isDoubleDirection": @(NO),
                @"minPercent": @(0),
                @"maxPercent": @(100),
                @"defaultPercent": @(40),
                @"tag": @"Face_ALL",
                @"name": @"face"
            },
            @{
                @"isDoubleDirection": @(NO),
                @"minPercent": @(0),
                @"maxPercent": @(100),
                @"defaultPercent": @(30),
                @"tag": @"Eye_ALL",
                @"name": @"bigeye"
            }
        ];
        NSArray *effectDic = @[
            @{@"effectName":ACCLocalizedCurrentString(@"av_beauty_smooth_skin"),
              @"effectIdentifier":@"100",
              @"resourceId": @"100",
              @"builtinIcon":@"icUlikeSmooth",
              @"builtinResource":[bundlePath stringByAppendingPathComponent:@"smooth_composer_V6"],
              @"types":@[],
              @"tags":@[],
              @"isBuildin": @(YES)
              },
            @{@"effectName":ACCLocalizedCurrentString(@"av_beauty_reshape"),
              @"effectIdentifier":@"101",
              @"resourceId": @"101",
              @"builtinIcon":@"icUlikeFaceLift",
              @"builtinResource":[bundlePath stringByAppendingPathComponent:@"reshape_composer_V4"],
              @"types":@[],
              @"tags":@[],
              @"isBuildin": @(YES)
              },
            @{@"effectName":ACCLocalizedCurrentString(@"com_mig_eye"),
              @"effectIdentifier":@"102",
              @"resourceId": @"102",
              @"builtinIcon":@"icUlikeBigEye",
              @"builtinResource":[bundlePath stringByAppendingPathComponent:@"reshape_composer_V4"],
              @"types":@[],
              @"tags":@[],
              @"isBuildin": @(YES)
              },
        ];
        
        NSMutableArray *effects = [NSMutableArray array];
        for (int i = 0; i < itemDic.count; i++) {
            AWEComposerBeautyEffectWrapper *wrapper = [[AWEComposerBeautyEffectWrapper alloc]init];
            wrapper.isLocalEffect = YES;
            wrapper.available = YES;
            wrapper.makeupType = @(AWELiveBeautyMakeupTypeNonExclusive);
            NSError *error = nil;
            IESEffectModel *effectModel = [[IESEffectModel alloc]initWithDictionary:effectDic[i] error:&error];
            if (error) {
                AWELogToolError(AWELogToolTagRecord, @"%s %@", __PRETTY_FUNCTION__, error);
            }
            NSError *error_item = nil;
            AWEComposerBeautyEffectItem *item = [[AWEComposerBeautyEffectItem alloc]initWithDictionary:itemDic[i] error:&error_item];
            if (error_item) {
                AWELogToolError(AWELogToolTagRecord, @"%s %@", __PRETTY_FUNCTION__, error_item);
            }
            wrapper.items = @[item];
            wrapper.effect = effectModel;
            
            [effects addObject:wrapper];
        }

        NSError *error = nil;
        IESCategoryModel *category = [[IESCategoryModel alloc] initWithDictionary:categoryDic error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagRecord, @"%s %@", __PRETTY_FUNCTION__, error);
        }
        categoryWrapper.category = category;
        categoryWrapper.effects = effects;
        _categories = @[categoryWrapper];
    }
    
    return _categories;

}

- (UIImage *)iconForItem:(AWEComposerBeautyEffectWrapper *)item {
    UIImage *image = ACCResourceImage(item.effect.builtinIcon);
    return image;
}

@end
