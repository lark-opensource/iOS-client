//
//  ACCVideoEditMusicViewModel+ACCSelectMusic.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/7/29.
//

#import "ACCVideoEditMusicViewModel+ACCSelectMusic.h"
#import <objc/message.h>
#import "AWERepoContextModel.h"
#import "AWEMVTemplateModel.h"
#import "AWEMusicSelectItem.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import "ACCVideoMusicProtocol.h"
#import "AWERepoDraftModel.h"
#import "AWERepoUploadInfomationModel.h"
#import "AWERepoGameModel.h"
#import "ACCCommerceServiceProtocol.h"

#import <CreationKitInfra/ACCToastProtocol.h>


@interface ACCVideoEditMusicViewModel ()

@property (nonatomic, strong) NSNumber *isRequestingMusicForQuickPicture;
@property (nonatomic, assign) BOOL shouldForbidWeakBindMusic;
@property (nonatomic, assign) BOOL didSignMusicSelectedFrom;

@end

@implementation ACCVideoEditMusicViewModel (ACCSelectMusic)

#pragma mark - public

- (void)fetchPhotoToVideoMusicSilently { //  静默预下载进入编辑页的热门推荐歌曲，只针对 文字/单图/多图/照片快拍做热门推荐
    if ([self.repository.repoContext shouldSelectMusicAutomatically]) {
        BOOL isEcomCommentPage = [IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.repository];
        [[AWEMVTemplateModel sharedManager] fetchPhotoToVideoMusicWithRetryBlock:nil isCommercialScene:isEcomCommentPage completionBlock:nil];
    }
}

- (void)fetchPhotoToVideoMusicWithCompletion:(void (^)(BOOL))completion {
    if ([self shouldSelectMusicAutomatically]) {
        self.isRequestingMusicForQuickPicture = @YES;
        
        BOOL precondition = [self.repository.repoContext shouldSelectMusicAutomatically];
        BOOL shouldRecordAutomaticSelectMusic = [self shouldRecordAutomaticSelectMusic];
        BOOL shouldImportAutomaticSelectMusic = [self shouldImportAutomaticSelectMusic];
        BOOL importAutoSelectMusic = precondition || shouldRecordAutomaticSelectMusic || shouldImportAutomaticSelectMusic;
        if (importAutoSelectMusic) {
            // 单段导入视频资源，优先使用缓存的推荐音乐
            id<ACCMusicModelProtocol> musicModel = [AWEMVTemplateModel sharedManager].musicModel;
            id<ACCMusicModelProtocol> presentedMusicModel = [AWEMVTemplateModel sharedManager].presentedMusicModel;
            if (musicModel && ![presentedMusicModel isEqual:musicModel]) {
                [AWEMVTemplateModel sharedManager].presentedMusicModel = musicModel;
                self.isRequestingMusicForQuickPicture = @NO;
                ACCBLOCK_INVOKE(completion, YES);
                return;
            }
        }
        @weakify(self);
        BOOL isEcomCommentPage = [IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.repository];
        [[AWEMVTemplateModel sharedManager] fetchPhotoToVideoMusicWithRetryBlock:nil isCommercialScene:isEcomCommentPage completionBlock:^(BOOL success) {
            @strongify(self);
            self.isRequestingMusicForQuickPicture = @NO;
            if (success && importAutoSelectMusic) {
                // 记录已经展现过的自动配乐
                [AWEMVTemplateModel sharedManager].presentedMusicModel = [AWEMVTemplateModel sharedManager].musicModel;
            }
            ACCBLOCK_INVOKE(completion, success);
        }];
    } else {
        ACCBLOCK_INVOKE(completion, NO);
    }
}

- (void)configForbidWeakBindMusicWithBlock:(void (^)(void))weakBindMusicSuccessBlock {
    self.shouldForbidWeakBindMusic = NO;
    if (self.repository.repoMusic.music) { // 录制使用道具，自动配置过音乐，在编辑页则不使用自动配乐
        BOOL autoUseEffectRecommendMusic = ACCConfigBool(kConfigBool_recorder_auto_use_effect_recommend_music);
        if (self.repository.repoMusic.musicSelectFrom == AWERecordMusicSelectSourceRecommendAutoApply && autoUseEffectRecommendMusic) {
            self.shouldForbidWeakBindMusic = YES;
        }
    } else {
        // 没有选择音乐的时判断是否有道具弱绑定音乐
        if ([self shouldAutoApplyWeakBind]) {
            self.shouldForbidWeakBindMusic = YES;
            [self applyWeakBindMusic:self.repository.repoMusic.weakBindMusic completion:^{
                self.repository.repoMusic.musicSelectedFrom = @"prop_music_recommended";
                ACCBLOCK_INVOKE(weakBindMusicSuccessBlock);
            }];
        }
    }
}

- (void)selectFirstMusicAutomatically { // 自动应用上热门推荐歌曲
    if (!self.repository.repoMusic.music && [self shouldSelectMusicAutomatically] && !self.shouldForbidWeakBindMusic) {
        [self updateMusicList];
        [self selectFirstMusic];
    }
}

- (BOOL)shouldSelectMusicAutomatically {  // 是否需要支持自动选音乐
    return [self.repository.repoContext shouldSelectMusicAutomatically] || [self shouldRecordAutomaticSelectMusic] || [self shouldImportAutomaticSelectMusic];
}

- (BOOL)shouldAutoApplyWeakBind { // 没有手动选择音乐的时候判断是否有道具弱绑定音乐，且开启道具后置绑定音乐实验
    return self.repository.repoMusic.weakBindMusic && ACCConfigBool(kConfigBool_edit_auto_use_effect_recommend_music);
}

- (BOOL)shouldRecordAutomaticSelectMusic {
    BOOL recordAutomaticSelectMusic = ACCConfigBool(kConfigBool_studio_record_automatic_select_music);
    BOOL musicWhenEnterEditPage = self.musicWhenEnterEditPage != nil;
    BOOL normalRecord = (self.repository.repoContext.videoType == AWEVideoTypeNormal && self.repository.repoContext.videoSource == AWEVideoSourceCapture);
    if (normalRecord && !musicWhenEnterEditPage && recordAutomaticSelectMusic && [self commonAutomaticSelectMusicCondition]) {
        if (!self.didSignMusicSelectedFrom) {
            self.didSignMusicSelectedFrom = YES;
            self.publishModel.repoMusic.musicSelectedFrom = @"edit_page_recommend";
        }
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)shouldImportAutomaticSelectMusic {
    BOOL uploadAutomaticSelectMusic = ACCConfigBool(kConfigBool_studio_upload_automatic_select_music);
    BOOL musicWhenEnterEditPage = self.musicWhenEnterEditPage != nil;
    BOOL singleVideoImport = self.repository.repoContext.videoType == AWEVideoTypeNormal &&
    self.repository.repoUploadInfo.originUploadVideoClipCount.integerValue == 1 &&
    self.repository.repoUploadInfo.originUploadPhotoCount.integerValue == 0 &&
    self.repository.repoContext.videoSource == AWEVideoSourceAlbum;
    if (singleVideoImport && !musicWhenEnterEditPage && uploadAutomaticSelectMusic && [self commonAutomaticSelectMusicCondition]) {
        if (!self.didSignMusicSelectedFrom) {
            self.didSignMusicSelectedFrom = YES;
            [self importAutoSelectMusicTrack];
        }
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - private

- (void)importAutoSelectMusicTrack {
    id<ACCMusicModelProtocol> musicModel = [AWEMVTemplateModel sharedManager].musicModel;
    id<ACCMusicModelProtocol> presentedMusicModel = [AWEMVTemplateModel sharedManager].presentedMusicModel;
    if (musicModel && ![presentedMusicModel isEqual:musicModel]) { // 单段上传视频，在进入编辑页前完成配乐
        self.publishModel.repoMusic.musicSelectedFrom = @"video_rec";
    } else {
        self.publishModel.repoMusic.musicSelectedFrom = @"edit_page_recommend";
    }
}

- (BOOL)commonAutomaticSelectMusicCondition {
    BOOL isGame = self.repository.repoGame.gameType != ACCGameTypeNone;
    BOOL isFromIM = self.repository.repoContext.isIMRecord;
    BOOL fromeThirdPary = [self.repository.repoMusic.musicSelectedFrom isEqualToString:@"lv_sync"];
    BOOL isDraft = (self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp);
    if (isGame || isFromIM || fromeThirdPary || isDraft) {
        return NO;
    }
    return YES;
}

- (void)applyWeakBindMusic:(id<ACCMusicModelProtocol>)music completion:(nonnull dispatch_block_t)completion {
    self.isRequestingMusicForQuickPicture = @YES;
    [ACCVideoMusic() fetchLocalURLForMusic:music withProgress:nil completion:^(NSURL * _Nonnull localURL, NSError * _Nonnull error) {
        [self handleSelectMusic:music error:error removeMusicSticker:YES];
        self.isRequestingMusicForQuickPicture = @NO;
        ACCBLOCK_INVOKE(completion);
    }];
}

- (void)selectFirstMusic {
    if (self.musicList.firstObject.musicModel) {
        id<ACCMusicModelProtocol> music = self.musicList.firstObject.musicModel;
        if (!music.loaclAssetUrl) {
            @weakify(self);
            [ACCVideoMusic() fetchLocalURLForMusic:music lyricURL:music.lyricUrl withProgress:nil completion:^(NSURL * _Nonnull localMusicURL, NSURL * _Nonnull localLyricURL, NSError * _Nonnull error) {
                @strongify(self);
                if (error) {
                    [ACCToast() show:@"load_failed"];
                } else {
                    music.loaclAssetUrl = localMusicURL;
                    [self handleSelectMusic:music error:nil removeMusicSticker:YES];
                }
            }];
        } else {
            [self handleSelectMusic:music error:nil removeMusicSticker:YES];
        }
    }
}

#pragma mark - getter & setter

- (BOOL)shouldForbidWeakBindMusic {
    NSNumber *value = objc_getAssociatedObject(self, _cmd);
    return value.boolValue;
}

- (void)setShouldForbidWeakBindMusic:(BOOL)shouldForbidWeakBindMusic {
    NSNumber *value = [NSNumber numberWithBool:shouldForbidWeakBindMusic];
    objc_setAssociatedObject(self, @selector(shouldForbidWeakBindMusic), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)isRequestingMusicForQuickPicture {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setIsRequestingMusicForQuickPicture:(NSNumber *)isRequestingMusicForQuickPicture {
    objc_setAssociatedObject(self, @selector(isRequestingMusicForQuickPicture), isRequestingMusicForQuickPicture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)didSignMusicSelectedFrom {
    NSNumber *value = objc_getAssociatedObject(self, _cmd);
    return value.boolValue;
}

- (void)setDidSignMusicSelectedFrom:(BOOL)didSignMusicSelectedFrom {
    NSNumber *value = [NSNumber numberWithBool:didSignMusicSelectedFrom];
    objc_setAssociatedObject(self, @selector(didSignMusicSelectedFrom), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
