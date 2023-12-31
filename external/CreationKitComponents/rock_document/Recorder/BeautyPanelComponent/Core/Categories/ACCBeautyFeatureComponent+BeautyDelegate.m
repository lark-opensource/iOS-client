//
//  ACCBeautyFeatureComponent+BeautyDelegate.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/13.
//

#import "ACCBeautyFeatureComponent+BeautyDelegate.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogHelper.h>

#import "ACCBeautyService.h"
#import "ACCBeautyFeatureComponent+Private.h"

@implementation ACCBeautyFeatureComponent (BeautyDelegate)

#pragma mark - AWEComposerBeautyDelegate

// update applied effect ratio
- (void)applyComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                            ratio:(float)ratio
{
    [self.beautyService addAlgorithmCallbackForBeauty:effectWrapper];
    [self msg_applyComposerBeautyEffect:effectWrapper ratio:ratio];
}


// actually use effect, the old effect might be nil.
- (void)selectComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                             ratio:(float)ratio
                         oldEffect:(AWEComposerBeautyEffectWrapper *)oldEffectWrapper
{
    [self.beautyService addAlgorithmCallbackForBeauty:effectWrapper];
    [self msg_selectComposerBeautyEffect:effectWrapper ratio:ratio oldEffect:oldEffectWrapper];
    // For non mutually exclusive categories, click none to reapply category
    if (effectWrapper.isNone && !effectWrapper.categoryWrapper.exclusive) {
        [self.beautyService clearComposerBeautyEffects:effectWrapper.categoryWrapper.effects];
    }
}

- (void)deselectComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    [self msg_deselectComposerBeautyEffect:effectWrapper];
}

- (void)selectCategory:(AWEComposerBeautyEffectCategoryWrapper *)category
{
    [self.componentView.beautyPanel.composerVM setCurrentCategory:category];
    [self.beautyService.effectViewModel.cacheObj cacheSelectedCategory:self.componentView.beautyPanel.composerVM.currentCategory.category.categoryIdentifier];
}

#pragma mark - private method

- (void)msg_applyComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                                ratio:(float)ratio
{
    [self updateRatio:ratio forEffect:effectWrapper];
}

- (void)msg_selectComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                                 ratio:(float)ratio
                             oldEffect:(AWEComposerBeautyEffectWrapper *)oldEffectWrapper
{
    // use `replace` method for change effect, otherwise use `add` method
    if (oldEffectWrapper && oldEffectWrapper != effectWrapper) {
        NSArray *oldNodes = [oldEffectWrapper nodesWithIntensity:NO];
        NSArray *nodes = [effectWrapper nodes];
        [self.camera.beauty replaceComposerNodesWithNewTag:nodes old:oldNodes];
    } else {
        NSArray *nodes = [effectWrapper nodes];
        [self.camera.beauty appendComposerNodesWithTags:nodes];
    }
    [self updateRatio:ratio forEffect:effectWrapper];
}

- (void)msg_deselectComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if (effectWrapper) {
        NSArray *nodes = [effectWrapper nodesWithIntensity:NO];
        [self.camera.beauty removeComposerNodesWithTags:nodes];
    }
}

- (void)updateRatio:(float)ratio forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    AWELogToolInfo2(@"beauty", AWELogToolTagRecord, @"effectIdentifier = %@", effectWrapper.effect.effectIdentifier);
    for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
        float value = [item effectValueForRatio:ratio];
        [self.camera.beauty updateComposerNode:effectWrapper.effect.resourcePath key:item.tag value:value];
        AWELogToolInfo2(@"beauty", AWELogToolTagRecord, @"item.tag = %@, ratio = %f", item.tag, ratio);
    }
}


#pragma mark - private methods

- (id<ACCCameraService>)camera
{
    let camera = IESAutoInline(self.serviceProvider, ACCCameraService);
    return camera;
}

@end
