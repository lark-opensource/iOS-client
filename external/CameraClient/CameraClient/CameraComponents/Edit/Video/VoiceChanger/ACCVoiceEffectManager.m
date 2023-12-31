//
//  ACCVoiceEffectManager.m
//  Pods
//
//  Created by Shen Chen on 2020/8/10.
//

#import "AWERepoVoiceChangerModel.h"
#import "ACCVoiceEffectManager.h"
#import "ACCCameraClient.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CameraClient/AWEEffectPlatformManager.h>
#import "ACCVoiceEffectEditSession.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/ACCRepoDraftModel.h>

static NSString * const kACCVoiceChangerEffectPanelName = @"voicechanger";
static NSString * const kACCVoiceChangerEffectCategoryKey = @"all";

@interface ACCVoiceEffectManager()
@property (nonatomic, strong) NSString *panelName;
@property (nonatomic, strong) NSString *categoryKey;
@property (nonatomic, strong) ACCVoiceEffectEditSession *editSession;
@property (nonatomic, assign) BOOL toastHasDisplayed;
@property (nonatomic, assign) BOOL voiceHadRecovered;
@end

@implementation ACCVoiceEffectManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _panelName = kACCVoiceChangerEffectPanelName;
        _categoryKey = kACCVoiceChangerEffectCategoryKey;
        _logTag = AWELogToolTagEdit;
    }
    return self;
}

- (void)loadEffectsByEffectIDs:(NSArray<NSString *> *)effectIDs completion:(void (^)(NSError * _Nullable error, NSDictionary<NSString *, IESEffectModel *> *_Nullable effectMap))completion
{
    NSMutableDictionary<NSString *, IESEffectModel *> *map = [NSMutableDictionary dictionary];
    if (effectIDs.count == 0) {
        ACCBLOCK_INVOKE(completion, nil, map);
        return;
    }
    
    // find from cache + local
    
    NSMutableArray *localEffects = [([AWEEffectPlatformManager sharedManager].localVoiceEffectList ?: @[]) mutableCopy];
    IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:self.panelName category:self.categoryKey];
    [localEffects addObjectsFromArray:cachedResponse.categoryEffects.effects];
    NSMutableSet *effectIDSet = [[NSMutableSet alloc] initWithArray:effectIDs];
    [localEffects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([effectIDSet containsObject:obj.effectIdentifier]) {
            map[obj.effectIdentifier] = obj;
            [effectIDSet removeObject:obj.effectIdentifier];
            *stop = effectIDSet.count == 0;
        }
    }];
    if (effectIDSet.count == 0) {
        ACCBLOCK_INVOKE(completion, nil, map);
        return;
    }
    
    // fetch effect models with ids
    [EffectPlatform downloadEffectListWithEffectIDS:effectIDSet.allObjects completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects) {
        if (!error) {
            [effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                map[obj.effectIdentifier] = obj;
            }];
        } else {
            AWELogToolError2(@"voice_effect", self.logTag, @"download effect list failed: %@, effects: %@", error, effectIDSet.allObjects);
        }
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(completion, error, map);
        });
    }];
}

- (void)recoverVoiceEffectsToEditService:(id<ACCEditServiceProtocol>)editService withPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel completion:(void (^_Nullable)(BOOL recovered, NSError *error))completion
{
    if ((!publishViewModel.repoDraft.isDraft && !publishViewModel.repoDraft.isBackUp) || editService.audioEffect.hadRecoveredVoiceEffect || editService.audioEffect.isEffectPreprocessing) {
        ACCBLOCK_INVOKE(completion,NO,nil);
        return;
    }
    ACCVoiceEffectType voiceEffectType = [publishViewModel.repoVoiceChanger voiceEffectType];
    if (voiceEffectType == ACCVoiceEffectTypeNone) {
        ACCBLOCK_INVOKE(completion,NO,nil);
        return;
    }
    if (voiceEffectType == ACCVoiceEffectTypeWhole) {
        editService.audioEffect.isEffectPreprocessing = YES;
        //cached effect
        IESEffectModel *voiceEffect = [[AWEEffectPlatformManager sharedManager] cachedVoiceEffectWithID:publishViewModel.repoVoiceChanger.voiceChangerID];
        
        //local effect
        if (!voiceEffect || !voiceEffect.downloaded) {
            voiceEffect = [[AWEEffectPlatformManager sharedManager] localVoiceEffectWithID:publishViewModel.repoVoiceChanger.voiceChangerID];
        }
        
        //recover effect logic
        if (!voiceEffect || !voiceEffect.downloaded || ![voiceEffect.filePath length]) {
            @weakify(self);
            [[AWEEffectPlatformManager sharedManager] loadEffectWithID:publishViewModel.repoVoiceChanger.voiceChangerID completion:^(IESEffectModel *effect) {
                @strongify(self);
                [self recoverVoiceEffect:effect toEditService:editService withPublishViewModel:publishViewModel recoverCompletion:completion];
            }];
        } else {
            [self recoverVoiceEffect:voiceEffect toEditService:editService withPublishViewModel:publishViewModel recoverCompletion:completion];
        }
    } else if (voiceEffectType == ACCVoiceEffectTypeMultiSegment) {
        NSMutableArray *effectIds = [NSMutableArray arrayWithCapacity:publishViewModel.repoVoiceChanger.voiceEffectSegments.count];
        [publishViewModel.repoVoiceChanger.voiceEffectSegments enumerateObjectsUsingBlock:^(ACCVoiceEffectSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.effect == nil && obj.effectId.length > 0) {
                [effectIds addObject:obj.effectId];
            }
        }];
        if (effectIds.count == 0) {
            self.voiceHadRecovered = YES;
            ACCBLOCK_INVOKE(completion,NO,nil);
        }
        @weakify(self);
        [self loadEffectsByEffectIDs:effectIds completion:^(NSError * _Nullable error, NSDictionary<NSString *,IESEffectModel *> * _Nullable effectMap) {
            @strongify(self);
            if (error) {
                AWELogToolError(AWELogToolTagEdit, @"loadEffectsError: %@", error);
            }
            if (effectMap.count > 0) {
                NSMutableArray<IESEffectModel *> *undownloadedEffects = [NSMutableArray array];
                [publishViewModel.repoVoiceChanger.voiceEffectSegments enumerateObjectsUsingBlock:^(ACCVoiceEffectSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.effect == nil && effectMap[obj.effectId] != nil) {
                        obj.effect = effectMap[obj.effectId];
                    }
                }];
                [effectMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESEffectModel * _Nonnull effect, BOOL * _Nonnull stop) {
                    if (![undownloadedEffects containsObject:effect] && [[AWEEffectPlatformManager sharedManager] downloadStatusForEffect: effect] != AWEEffectDownloadStatusDownloading) {
                        [undownloadedEffects addObject:effect];
                    }
                }];
                [self downloadEffects:undownloadedEffects completion:^(BOOL success) {
                    @strongify(self);
                    AWELogToolInfo2(@"voice_effect", self.logTag, @"download all effects completed: %@", @(success));
                    if (!self) {
                        return;
                    }
                    self.voiceHadRecovered = YES;
                    ACCVoiceEffectEditSession *editSession = [[ACCVoiceEffectEditSession alloc] initWithEditService:editService publishViewModel:publishViewModel];
                    [editSession loadSegments:publishViewModel.repoVoiceChanger.voiceEffectSegments];
                    [editSession updateVoiceEffectsWithCompletion:^{
                        ACCBLOCK_INVOKE(completion,YES,nil);
                    }];
                    self.editSession = editSession;
                }];
            } else {
                ACCBLOCK_INVOKE(completion,NO,nil);
            }
        }];
    }
}

- (void)downloadEffects:(NSArray<IESEffectModel *> *)effects completion:(void(^_Nullable)(BOOL success))completion {
    // batch download
    dispatch_group_t group = dispatch_group_create();
    __block BOOL success = YES;
    @weakify(self);
    for (IESEffectModel *effect in effects) {
        if ([[AWEEffectPlatformManager sharedManager] downloadStatusForEffect:effect] == AWEEffectDownloadStatusDownloaded) {
            continue;
        }
        dispatch_group_enter(group);
        [EffectPlatform downloadEffect:effect progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
            @strongify(self);
            if (error) {
                success = NO;
                AWELogToolError2(@"voice_effect", self.logTag, @"download effect failed: %@, effect_id: %@", error, effect.effectIdentifier);
            }
            dispatch_group_leave(group);
        }];
    }
    
    // all downloads completion
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) {
            completion(success);
        }
    });
}

- (void)toastFailure
{
    if (self.toastReferenceView != nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!self.toastHasDisplayed && self.toastReferenceView.window) {
                self.toastHasDisplayed = YES;
                [ACCToast() show: ACCLocalizedCurrentString(@"com_mig_this_voice_effect_isnt_available_now")];
            }
        });
    }
}

- (void)recoverVoiceEffect:(IESEffectModel *)voiceEffect toEditService:(id<ACCEditServiceProtocol>)editService withPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel  recoverCompletion:(void (^_Nullable)(BOOL recovered, NSError *error))completion
{
    if (!voiceEffect) {
        editService.audioEffect.isEffectPreprocessing = NO;
        [self toastFailure];
        ACCBLOCK_INVOKE(completion,NO,nil);
        return;
    }
    if (editService.audioEffect.hadRecoveredVoiceEffect) {//recover or use other effect
        ACCBLOCK_INVOKE(completion,NO,nil);
        return;
    }
    
    NSString *effectPath = nil;
    if ([voiceEffect.localUnCompressPath length]) {
        effectPath = voiceEffect.localUnCompressPath;
    } else if ([voiceEffect.filePath length]) {
        effectPath = voiceEffect.filePath;
    } else {
        effectPath = nil;
    }
    NSTimeInterval startApply = CFAbsoluteTimeGetCurrent();
    AWELogToolInfo(self.logTag, @"tool applyAudioEffectWithInfo startApply at:%f",startApply);
    editService.audioEffect.hadRecoveredVoiceEffect = YES;
    publishViewModel.repoVoiceChanger.voiceChangerID = voiceEffect.effectIdentifier;
    self.voiceHadRecovered = YES;
    @weakify(editService);
    @weakify(publishViewModel);
    [editService.audioEffect applyAudioEffectWithEffectPath:effectPath inPreProcessInfo:@"" inBlock:^(NSString * _Nonnull str, NSError * _Nonnull outErr) {
        @strongify(editService);
        @strongify(publishViewModel);
        AWELogToolInfo(self.logTag, @"tool applyAudioEffectWithInfo spendTime:%.2f voiceChangerID:%@ error:%@",(CFAbsoluteTimeGetCurrent() - startApply),
        publishViewModel.repoVoiceChanger.voiceChangerID?:@"", outErr.localizedDescription?:@"");
        editService.audioEffect.isEffectPreprocessing = NO;
        ACCBLOCK_INVOKE(completion,YES,nil);
    }];
}

+ (IESEffectModel *)voiceEffectForEffectID:(NSString *)effectID
{
    IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:kACCVoiceChangerEffectPanelName category:kACCVoiceChangerEffectCategoryKey];
    for (IESEffectModel *effect in cachedResponse.categoryEffects.effects) {
        if ([effect.effectIdentifier isEqualToString:effectID]) {
            return effect;
        }
    }
    return nil;
}

- (void)clearVoiceEffectToEditService:(id<ACCEditServiceProtocol>)editService withPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel completion:(void (^)(void))completion
{
    [publishViewModel.repoVoiceChanger clearVoiceEffect];
    self.voiceHadRecovered = NO;
    @weakify(editService);
    [editService.audioEffect applyAudioEffectWithEffectPath:nil inPreProcessInfo:@"" inBlock:^(NSString * _Nonnull str, NSError * _Nonnull outErr) {
        @strongify(editService);
        if (outErr) {
            AWELogToolInfo(self.logTag, @"tool applyAudioEffectWithInfo error:%@", outErr.localizedDescription?:@"");
        }
        editService.audioEffect.isEffectPreprocessing = NO;
        ACCBLOCK_INVOKE(completion);
    }];
}

@end
