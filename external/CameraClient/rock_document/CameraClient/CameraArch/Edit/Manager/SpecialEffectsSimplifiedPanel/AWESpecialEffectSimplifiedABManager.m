//
//  AWESpecialEffectSimplifiedABManager.m
//  Indexer
//
//  Created by Daniel on 2021/11/11.
//

#import "AWESpecialEffectSimplifiedABManager.h"

#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>

@implementation AWESpecialEffectSimplifiedABManager

#pragma mark - Public Methods

+ (BOOL)shouldUseNewBarItemIcon
{
    return ACCConfigBool(kConfigDict_special_effects_simplified_panel_new_icon);
}

+ (BOOL)shouldUseSimplifiedPanel:(AWEVideoPublishViewModel *)publishModel
{
    if ([self getSimplifiedPanelType] == AWESpecialEffectSimplifiedPanelAll) {
        return YES;
    }
    
    BOOL isPhoto = publishModel.repoContext.isPhoto && !publishModel.repoQuickStory.isAvatarQuickStory;
    if ([self getSimplifiedPanelType] == AWESpecialEffectSimplifiedPanelImageOnly && isPhoto) {
        return YES;
    }
    
    return NO;
}

+ (AWESpecialEffectSimplifiedPanelType)getSimplifiedPanelType
{
    NSUInteger scenarioInt = ACCConfigInt(kConfigDict_special_effects_simplified_panel_scenario);
    if (scenarioInt == 1) {
        return AWESpecialEffectSimplifiedPanelImageOnly;
    } else if (scenarioInt == 2) {
        return AWESpecialEffectSimplifiedPanelAll;
    } else {
        return AWESpecialEffectSimplifiedPanelNone;
    }
}

@end
