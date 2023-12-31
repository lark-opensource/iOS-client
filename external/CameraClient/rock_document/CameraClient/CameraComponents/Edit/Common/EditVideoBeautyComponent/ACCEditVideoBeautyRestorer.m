//
//  ACCEditVideoBeautyRestorer.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/23.
//

#import "ACCEditVideoBeautyRestorer.h"
#import <CreationKitArch/ACCRepoBeautyModel.h>
#import <CreationKitBeauty/AWEComposerBeautyViewModel.h>
#import <CreationKitComponents/ACCBeautyDataHandler.h>
#import <CreativeKit/ACCMacros.h>

@implementation ACCEditVideoBeautyRestorer

+ (NSArray<NSString *> *)effectIdsToDownloadForResume:(nonnull AWEVideoPublishViewModel *)publishModel
{
    NSArray *effects = [self effectsToApplyForResume:publishModel];
    NSMutableArray *effectIds = [NSMutableArray array];
    
    for (AWEComposerBeautyEffectWrapper *effectWrapper in effects) {
        if (!effectWrapper.downloaded) {
            [effectIds addObject:effectWrapper.effect.effectIdentifier];
        }
    }
    
    return ACC_isEmptyArray(effects) ? publishModel.repoBeauty.appliedEffectIds : effectIds;
}


+ (NSArray<AWEComposerBeautyEffectWrapper *> *)effectsToApplyForResume:(nonnull AWEVideoPublishViewModel *)publishModel
{
    NSDictionary *beautyValueDic = publishModel.repoBeauty.beautyValueDic;
    if (beautyValueDic.allKeys.count == 0) {
        return @[];
    }
    
    ACCBeautyDataHandler *dataHandler = [[ACCBeautyDataHandler alloc]init];
    AWEComposerBeautyEffectViewModel *effectViewModel = [[AWEComposerBeautyEffectViewModel alloc] initWithCacheViewModel:nil
                                                                              panelName:nil
                                                                       migrationHandler:nil
                                                                            dataHandler:dataHandler];
    [effectViewModel updateWithGender:publishModel.repoBeauty.gender cameraPosition:AWEComposerBeautyCameraPositionFront];
    NSArray<AWEComposerBeautyEffectCategoryWrapper *> *categories = [effectViewModel localCachedBeautyData];
    NSArray<AWEComposerBeautyEffectWrapper *> *result = [self effectsToApplyForResume:publishModel
                                                                        forCategories:categories];
    
    return result;
}

+ (NSArray<AWEComposerBeautyEffectWrapper *> *)effectsToApplyForResume:(nonnull AWEVideoPublishViewModel *)publishModel
                                                         forCategories:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories
{
    NSDictionary *beautyValueDic = publishModel.repoBeauty.beautyValueDic;

    NSMutableArray<AWEComposerBeautyEffectWrapper *> *result = [NSMutableArray array];
    
    void (^applyEffectIfNeed)(AWEComposerBeautyEffectWrapper *) = ^(AWEComposerBeautyEffectWrapper *effectWrapper){

        // 恢复二级小项的选中项
        if (effectWrapper.parentEffect.isEffectSet) {
            effectWrapper.parentEffect.appliedChildEffect = effectWrapper;
        }
        // 恢复互斥分类的选中项
        if (effectWrapper.categoryWrapper.exclusive) {
            effectWrapper.categoryWrapper.selectedEffect = effectWrapper;
            effectWrapper.categoryWrapper.userSelectedEffect = effectWrapper;
        }
        
        NSNumber *sliderNum = ACCDynamicCast(beautyValueDic[effectWrapper.effect.resourceId], NSNumber);
        // 记录有滑竿值的effectId，有则说明是需要恢复的
        if (sliderNum) {
            [result addObject:effectWrapper];
        }
    };
    
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in categories) {
        NSString *lastSelectedEffectId = publishModel.repoBeauty.selectedBeautyDic[categoryWrapper.category.categoryIdentifier];
        AWEComposerBeautyEffectWrapper *noneEffect = nil;
        AWEComposerBeautyEffectWrapper *defaultEffect = nil;
        for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
            
            NSNumber *sliderNum = ACCDynamicCast(beautyValueDic[effectWrapper.effect.resourceId], NSNumber);
            CGFloat sliderValue = [sliderNum floatValue];
            [effectWrapper updateRatioWithSliderValue:sliderValue];
            
            if (effectWrapper.isNone) {
                noneEffect = effectWrapper;
            }
            if (effectWrapper.isDefault) {
                defaultEffect = effectWrapper;
            }
            
            // 如果是小项互斥的分类，同时草稿中又没有选中这个小项，则跳过循环
            if (categoryWrapper.exclusive && ![lastSelectedEffectId isEqualToString:effectWrapper.effect.effectIdentifier]) {
                continue;
            }
            if ([effectWrapper isEffectSet]) {
                NSString *lastSelectedChildId = publishModel.repoBeauty.selectedAlbumDic[effectWrapper.effect.resourceId];
                AWEComposerBeautyEffectWrapper *defaultChildEffect = nil;
                for (int i = 0; i < effectWrapper.childEffects.count; i++) {
                    AWEComposerBeautyEffectWrapper *childEffect = effectWrapper.childEffects[i];
                    NSString *resourceId = ACCDynamicCast(childEffect.effect.resourceId, NSString);
                    NSNumber *sliderNum = ACCDynamicCast(beautyValueDic[childEffect.effect.resourceId], NSNumber);
                    CGFloat sliderValue = [sliderNum floatValue];
                    [childEffect updateRatioWithSliderValue:sliderValue];
                    
                    if (childEffect.isDefault) {
                        defaultChildEffect = childEffect;
                    }
                    // 如果是二级小项，则判断是否是上一次选中的二级小项id
                    if (resourceId && [lastSelectedChildId isEqualToString:resourceId]) {
                        applyEffectIfNeed(effectWrapper.childEffects[i]);
                    }
                }
                
                // 如果二级小项没有历史选中，则恢复到默认
                if (!lastSelectedChildId) {
                    effectWrapper.appliedChildEffect = defaultChildEffect;
                }
            } else {
                applyEffectIfNeed(effectWrapper);
            }
        }
        
        // 如果互斥分类没有历史选中，则恢复到默认effect或者“无”选项
        if (categoryWrapper.exclusive && !lastSelectedEffectId) {
            categoryWrapper.selectedEffect = defaultEffect ?: noneEffect;
            categoryWrapper.userSelectedEffect = defaultEffect ?: noneEffect;
        }
    }
    return result;
}

+ (void)reapplyBeautyEffectFrom:(AWEVideoPublishViewModel *)publishViewModel
                withEditService:(id<ACCEditServiceProtocol>)editService
{
    NSArray *effects = [self effectsToApplyForResume:publishViewModel];
    
//    for (AWEComposerBeautyEffectWrapper *effectWrapper in effects) {
//        if (effectWrapper.downloaded) {
//            NSArray *nodes = [effectWrapper nodes];
//            [editService.beauty appendComposerNodesWithTags:nodes];
//
//            for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
//                float value = [item effectValueForRatio:effectWrapper.currentRatio];
//                [editService.beauty updateComposerNode:effectWrapper.effect.resourcePath key:item.tag value:value];
//            }
//        }
//    }
    
    
    [editService.beauty appendComposerBeautys:effects];
}


@end
