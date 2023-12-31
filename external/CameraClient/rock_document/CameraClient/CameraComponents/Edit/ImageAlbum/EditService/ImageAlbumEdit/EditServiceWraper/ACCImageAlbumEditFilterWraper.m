//
//  ACCImageAlbumEditFilterWraper.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/23.
//

#import "ACCImageAlbumEditFilterWraper.h"
#import "ACCImageAlbumEditorSession.h"
#import <CreationKitArch/IESEffectModel+ComposerFilter.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import "ACCImageAlbumEditorMacro.h"

@interface ACCImageAlbumEditFilterWraper () <ACCEditBuildListener>

@property (nonatomic, weak) id<ACCImageAlbumEditorSessionProtocol> player;

@end

@implementation ACCImageAlbumEditFilterWraper

#pragma mark - ACCEditBuildListenerfil
- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.imageEditSession;
}

#pragma mark - ACCEditFilterProtocol
- (void)applyFilterEffect:(nullable IESEffectModel *)effect intensity:(float)intensity
{
    if (effect.isComposerFilter) {
        [self.player updateComposerFilterWithFilterId:effect.effectIdentifier filePath:effect.filePath intensity:intensity];
    } else {
        if (!effect) {
            [self.player updateComposerFilterWithFilterId:nil filePath:nil intensity:0.f];
        } else {
            // 图集模式只支持Composer
            ACCImageEditModeAssertUnsupportFeature
        }
    }
}

- (float)filterEffectOriginIndensity:(nullable IESEffectModel *)effect
{
    if (effect.isComposerFilter) {
        return effect.filterConfigItem.defaultIntensity;
    } else {
        
        if (!effect.filePath.length) {
            return 0.f;
        }
        return 1.f;
    }
}

#pragma mark - unsupport
- (void)applyFilterEffect:(nullable IESEffectModel *)effect
{
    
    // Lightning相关，assert一下防止误调用
    ACCImageEditModeAssertUnsupportFeature;
    [self applyFilterEffect:effect intensity:[self filterEffectOriginIndensity:effect]];
}

- (void)startAudioFilters:(IESMMAudioFilter * _Nonnull)filter forVideoAssets:(NSArray<AVAsset *> * _Nonnull)assets
{
    ACCImageEditModeAssertUnsupportFeature;
}

- (void)stopFiltersforVideoAssets:(NSArray<AVAsset *> * _Nonnull)assets
{
    ACCImageEditModeAssertUnsupportFeature;
}

- (BOOL)switchColorLeftFilter:(nonnull IESEffectModel *)leftFilter rightFilter:(nonnull IESEffectModel *)rightFilter inPosition:(float)position
{
    ACCImageEditModeAssertUnsupportFeature;
    return NO;
}

- (BOOL)switchColorLeftFilter:(nonnull IESEffectModel *)leftFilter rightFilter:(nonnull IESEffectModel *)rightFilter inPosition:(float)position inLeftIntensity:(float)leftIntensity inRightIntensity:(float)rightIntensity
{
    ACCImageEditModeAssertUnsupportFeature;
    return NO;
}

- (void)updateAudioFilterInfos:(NSArray<IESMMAudioFilter *> * _Nonnull)infos forAudioAssets:(NSArray<AVAsset *> * _Nonnull)assets
{
    ACCImageEditModeAssertUnsupportFeature;
}

- (void)updateAudioFilterInfos:(NSArray<IESMMAudioFilter *> * _Nonnull)infos forVideoAssets:(NSArray<AVAsset *> * _Nonnull)assets
{
    ACCImageEditModeAssertUnsupportFeature;
}

@end
