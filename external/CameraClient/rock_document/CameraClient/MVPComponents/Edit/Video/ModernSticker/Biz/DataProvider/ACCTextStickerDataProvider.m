//
//  ACCTextStickerDataProvider.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/7/1.
//

#import "ACCTextStickerDataProvider.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitRTProtocol/ACCEditAudioEffectProtocol.h>
#import "AWERepoDraftModel.h"
#import "AWERepoStickerModel.h"
#import "ACCRepoTextModeModel.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCEditTransitionServiceProtocol.h"
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCVideoEditStickerContainerConfig.h"
#import "ACCTextReaderSoundEffectsSelectionViewController.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKitSticker/ACCStickerContainerView+ACCStickerCopying.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>

@interface ACCTextStickerDataProvider ()

@property (nonatomic, weak) id<ACCEditAudioEffectProtocol> audioEffectService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;

@end

@implementation ACCTextStickerDataProvider
IESAutoInject(self.serviceProvider, audioEffectService, ACCEditAudioEffectProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

#pragma mark - ACCTextStickerDataProvider

- (NSString *)textStickerFolderForDraft {
    return [AWEDraftUtils generateDraftFolderFromTaskId:self.repository.repoDraft.taskID];
}

- (NSString *)textStickerImagePathForDraftWithIndex:(NSInteger)index {
    // fix AME-84121, if edit from draft, should not cover original path
    return [AWEDraftUtils generateTextImagePathFromTaskId:self.repository.repoDraft.taskID withDraftTag:[self.repository.repoDraft tagForDraftFromBackEdit] index:index];
}

- (void)storeTextInfoForAuditWith:(NSString *)imageText imageTextFonts:(NSString *)imageTextFonts imageTextFontEffectIds:(NSString *)imageTextFontEffectIds {
    // 添加文字信息，供审核
    self.repository.repoSticker.imageText = imageText;
    self.repository.repoSticker.imageTextFonts = imageTextFonts;
    self.repository.repoSticker.imageTextFontEffectIds = imageTextFontEffectIds;
}

- (void)addTextReadForKey:(NSString *)key asset:(AVAsset *)audioAsset range:(IESMMVideoDataClipRange *)audioRange
{
    self.repository.repoSticker.textReadingAssets[key] = audioAsset;
    self.repository.repoSticker.textReadingRanges[key] = audioRange;
    [[self audioEffectService] hotAppendAudioAsset:audioAsset withRange:audioRange];
    [[self audioEffectService] setVolume:4.f forAudioAssets:@[audioAsset]];
    [[self audioEffectService] refreshAudioPlayer];
}

- (void)removeTextReadForKey:(NSString *)key
{
    AVAsset *toRemove = [self.repository.repoSticker audioAssetInVideoDataWithKey:key];
    [self.repository.repoSticker.textReadingAssets removeObjectForKey:key];
    [self.repository.repoSticker.textReadingRanges removeObjectForKey:key];
    if (toRemove) {
        [[self audioEffectService] hotRemoveAudioAssests:@[toRemove]];
    }
}

- (BOOL)supportTextReading
{
    if ([self isImageAlbumEdit]) {
        return NO;
    }
    let userService = IESAutoInline(self.serviceProvider, ACCUserServiceProtocol);
    return ACCConfigBool(kConfigBool_enable_edit_text_reading) && ![userService isChildMode] && [userService isLogin];
}

- (BOOL)isImageAlbumEdit
{
    return self.repository.repoImageAlbumInfo.isImageAlbumEdit;
}

- (void)clearTextMode
{
    self.repository.repoTextMode.textModel = nil;
}

- (void)showTextReaderSoundEffectsSelectionViewController
{

}

@end
