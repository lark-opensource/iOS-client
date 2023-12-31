//
//  ACCEditPropComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/2/26.
//

#import "AWERepoPropModel.h"
#import "ACCEditPropComponent.h"
#import "ACCEditEffectProtocolD.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCEditPreviewProtocolD.h"
#import <CreativeKit/ACCProtocolContainer.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCProtocolContainer.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <EffectPlatformSDK/EffectPlatform+Additions.h>

// Except multi seg prop, normal prop should not have logic in edit page

@interface ACCEditPropComponent()<ACCEditSessionLifeCircleEvent>

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;

@end

@implementation ACCEditPropComponent


IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.editService addSubscriber:self];
}

#pragma mark - ACCDraftResourceRecoverProtocol

+ (nullable NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(nonnull AWEVideoPublishViewModel *)publishModel {
    if (publishModel.repoProp.isMultiSegPropApplied && publishModel.repoVideoInfo.fragmentInfo.firstObject.stickerId) {
        return @[publishModel.repoVideoInfo.fragmentInfo.firstObject.stickerId];
    }
    return @[];
}

+ (void)updateWithDownloadedEffects:(NSArray<IESEffectModel *> *)effects
                   publishViewModel:(AWEVideoPublishViewModel *)publishModel
                         completion:(ACCDraftRecoverCompletion)completion
{
    if (effects.count == 0) {
        ACCBLOCK_INVOKE(completion, nil, NO);
        return;
    }
    
    if (publishModel.repoProp.isMultiSegPropApplied && publishModel.repoVideoInfo.fragmentInfo.firstObject.stickerId) {
        [effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull effect, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([effect.effectIdentifier isEqualToString:publishModel.repoVideoInfo.fragmentInfo.firstObject.stickerId] ||
                [effect.originalEffectID isEqualToString:publishModel.repoVideoInfo.fragmentInfo.firstObject.stickerId]) {
                [[EffectPlatform sharedInstance] saveCacheWithEffect:effect];
            }
        }];
    }
    
    ACCBLOCK_INVOKE(completion, nil, NO);
}

#pragma mark - ACCEditSessionLifeCircleEvent

- (void)onCreateEditSessionCompletedWithEditService:(id<ACCEditServiceProtocol>)editService
{
    if (!self.repository.repoProp.isMultiSegPropApplied) {
        return;
    }
    
    if (self.repository.repoVideoInfo.fragmentInfo.firstObject.stickerId) {
        IESEffectModel *propEffect = [[EffectPlatform sharedInstance] cachedEffectOfEffectId:self.repository.repoVideoInfo.fragmentInfo.firstObject.stickerId];
        
        BOOL hasAppliedTrans = NO;
        if (propEffect.downloaded && [[NSFileManager defaultManager] fileExistsAtPath:propEffect.filePath]) {
            hasAppliedTrans = YES;
            [self applyTransComposerInfoWithEffect:propEffect];
        }
        
        @weakify(self);
        [EffectPlatform downloadEffectListWithEffectIDS:@[self.repository.repoVideoInfo.fragmentInfo.firstObject.stickerId] completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects) {
            if (effects.count > 0) {
                [EffectPlatform downloadEffect:effects.firstObject progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                    @strongify(self);
                    if (!error && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                        if (!hasAppliedTrans) {
                            [self applyTransComposerInfoWithEffect:effects.firstObject];
                        }
                        [[EffectPlatform sharedInstance] saveCacheWithEffect:effects.firstObject];
                    }
                }];
            }
        }];
    }
    
    // add transition and speed change effect if need
    [self.repository.repoProp.multiSegPropClipsArray enumerateObjectsUsingBlock:^(ACCStickerMultiSegPropClipModel * _Nonnull clipModel, NSUInteger index, BOOL * _Nonnull stop) {
        [ACCGetProtocol(self.editService.effect, ACCEditEffectProtocolD) changeSpeedWithVideoData:self.repository.repoVideoInfo.video xPoints:clipModel.xPoints yPoints:clipModel.yPoints assetIndex:index];
    }];

    @weakify(self);
    [ACCGetProtocol(self.editService.preview, ACCEditPreviewProtocolD) updateVideoData:self.repository.repoVideoInfo.video updateType:VEVideoDataUpdateAll completeBlock:^(NSError * _Nonnull error) {
        @strongify(self);
        [[self editService].preview play];
    }];
}

- (void)applyTransComposerInfoWithEffect:(IESEffectModel *)effect {
    if (!effect.isMultiSegProp) {
        return;
    }
    
    VEComposerInfo *node = [[VEComposerInfo alloc] init];
    node.node = [NSString stringWithFormat:@"%@;%@;%d", effect.filePath, @"multi_segments", 1];
    node.tag = @"";
    [ACCGetProtocol(self.editService.effect, ACCEditEffectProtocolD) appendComposerNodes:@[node] videoData:self.repository.repoVideoInfo.video];
}

@end
