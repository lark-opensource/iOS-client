//
//  ACCNLEUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/2/18.
//

#import "AWERepoVideoInfoModel.h"
#import "AWERepoCutSameModel.h"
#import "ACCNLEUtils.h"
#import "ACCNLEHeaders.h"
#import "ACCNLEEditVideoData.h"
#import "ACCEditVideoDataDowngrading.h"
#import "ACCEditSessionConfigBuilder.h"
#import "ACCVideoDataTranslator.h"
#import "AWERepoDraftModel.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCConfigKeyDefines.h"
#import "ACCStickerMigrateUtil.h"
#import "NLETrackSlot_OC+Extension.h"
#import <CreationKitArch/AWEDraftUtils.h>
#import "AWERepoVideoInfoModel.h"
#import "AWERepoMusicModel.h"
#import "ACCRepoLivePhotoModel.h"
#import "AWEVideoEffectPathBlockManager.h"
#import "AWERepoContextModel.h"
#import <CameraClient/AWERepoDuetModel.h>
#import <CameraClient/AWERepoContextModel.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <NLEPlatform/NLEConstDefinition.h>

@implementation ACCNLEUtils

+ (BOOL)useNLEWithRepository:(AWEVideoPublishViewModel *)repository
{
    return [self creativePolicyWithRepository:repository] == ACCCreativePolicyNLE;
}

+ (ACCCreativePolicy)creativePolicyWithRepository:(AWEVideoPublishViewModel *)repository {
    // 图集模式不支持 NLE
    if (repository.repoImageAlbumInfo.isImageAlbumEdit) {
        return ACCCreativePolicyNormal;
    }
    if (repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        return ACCCreativePolicyNormal;
    }
    // 动图先不兼容 NLE
    if (repository.repoLivePhoto.businessType != ACCLivePhotoTypeNone) {
        return ACCCreativePolicyNormal;
    }
    // 合拍上传只支持NLE
    if (repository.repoDuet.isDuet && repository.repoDuet.isDuetUpload) {
        repository.repoVideoInfo.nleVersion = kACCNLEVersion2;
        return ACCCreativePolicyNLE;
    }
    
    if ((repository.repoVideoInfo.nleVersion == kACCNLEVersionNone && [self p_repositoryHasNLEData:repository]) ||
        (repository.repoCutSame.isNewCutSameOrSmartFilming && repository.repoCutSame.cutSameNLEModel) ||
        ([repository.repoCutSame canTransferToCutSame] && ACCConfigInt(kConfigInt_smart_video_entrance) == ACCOneClickFlimingEntranceNoButton)) {
        // 智能成片已经对应的草稿逻辑
        // 1. 智能成片草稿，永远使用 kACCNLEVersionNone，只走 NLE 逻辑，不受 AB 控制
        // 2. 智能成片新建流程
        // 3. 智能成片 v3 实验，开启后导入场景使用 NLE
        repository.repoVideoInfo.nleVersion = kACCNLEVersionNone;
        return ACCCreativePolicyNLE;
    } else if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        repository.repoVideoInfo.nleVersion = kACCNLEVersion2;
        return ACCCreativePolicyNLE;
    } else {
        repository.repoVideoInfo.nleVersion = kACCNLEVersion2;
        return ACCCreativePolicyNormal;
    }
}

+ (NLEInterface_OC *)createNLEInterfaceIfNeededWithRepository:(AWEVideoPublishViewModel *)repository
{
    NLEInterface_OC *newNLE = [ACCNLEUtils nleInterfaceWithRepository:repository];
    if (acc_videodata_is_nle(repository.repoDraft.originalModel.repoVideoInfo.video)) {
        // 草稿返回拍摄再重新进入编辑页，查看 VE 配置是否变化，如果有变化则需要重新创建 NLE 实例
        NLEInterface_OC *draftNLE = acc_videodata_take_nle(repository.repoDraft.originalModel.repoVideoInfo.video).nle;
        if ((draftNLE.veEditor.config.mvModel == nil &&
             newNLE.veEditor.config.mvModel != nil) ||
            (draftNLE.veEditor.config.mvModel != nil &&
             newNLE.veEditor.config.mvModel == nil)) {
            return newNLE;
        } else {
            return draftNLE;
        }
    } else {
        return newNLE;
    }
}

+ (void)createNLEVideoData:(AWEVideoPublishViewModel *)repository
                    editor:(NLEEditor_OC *)editor
                completion:(nullable void(^)(void))completion
{
    ACCNLEEditVideoData *videoData =
    [self p_nleVideoDataWithRepository:repository
                                editor:editor
                                config:nil];
    [self p_initalNLEWithRepository:repository
                          videoData:videoData
                       moveResource:NO
                         needCommit:YES
                         completion:completion];
}

+ (void)createNLEVideoData:(AWEVideoPublishViewModel *)repository
                    config:(nullable VEEditorSessionConfig *)config
              moveResource:(BOOL)moveResource
                needCommit:(BOOL)needCommit
                completion:(nullable void(^)(void))completion
{
    ACCNLEEditVideoData *videoData =
    [self p_nleVideoDataWithRepository:repository
                                editor:nil
                                config:config];
    
    [self p_initalNLEWithRepository:repository
                          videoData:videoData
                       moveResource:moveResource
                         needCommit:needCommit
                         completion:completion];
}

// 创建 ACCNLEEditVideoData
+ (ACCNLEEditVideoData *)p_nleVideoDataWithRepository:(AWEVideoPublishViewModel *)repository
                                               editor:(nullable NLEEditor_OC *)editor
                                               config:(nullable VEEditorSessionConfig *)config
{
    ACCNLEEditVideoData *videoData;
    if (acc_videodata_is_nle(repository.repoVideoInfo.video) &&
        !acc_videodata_take_nle(repository.repoVideoInfo.video).isTempVideoData) {
        // 如果外部已经创建了 NLEInterface，不需要重复创建
        videoData = acc_videodata_take_nle(repository.repoVideoInfo.video);
    } else if (editor) {
        // 显式传 NLEEditor 是草稿恢复的场景，直接通过 editor 创建 NLE 实例
        NLEInterface_OC *nle = [self nleInterfaceWithRepository:repository editor:editor config:config];
        videoData = [[ACCNLEEditVideoData alloc] initWithNLEModel:editor.model nle:nle];
        // 由于贴纸的 userInfo 是通过“草稿迁移”完成的，这一步会丢失不少关键信息，
        // 在跨端迁移的时候，这些关键信息会通过资源下载重新填充，但是由于目前 NLE
        // 的资源下载依赖 VE 的 userInfo，从而导致 NLE 的 userInfo 信息不能得到填充，
        // 此方法就是将 VE 完整的 userInfo 数据同步回 NLE
        [repository.repoVideoInfo.video.infoStickers acc_forEach:^(IESInfoSticker * _Nonnull obj) {
            [videoData.nle setStickerUserInfo:obj.userinfo];
        }];
    } else if (repository.repoCutSame.isNewCutSameOrSmartFilming && repository.repoCutSame.cutSameNLEModel) {
        NLEInterface_OC *nle = [self nleInterfaceWithRepository:repository editor:nil config:config];
        videoData = [[ACCNLEEditVideoData alloc] initWithNLEModel:repository.repoCutSame.cutSameNLEModel nle:nle];
    } else {
        NLEInterface_OC *nle = [self createNLEInterfaceIfNeededWithRepository:repository];
        videoData = acc_videodata_make_nle(repository.repoVideoInfo.video, nle);
        videoData.draftFolder = repository.repoDraft.draftFolder;
        videoData.nle = nle;
    }
    return videoData;
}

// 根据 videoData 初始化 repository
+ (void)p_initalNLEWithRepository:(AWEVideoPublishViewModel *)repository
                        videoData:(ACCNLEEditVideoData *)videoData
                     moveResource:(BOOL)moveResource
                       needCommit:(BOOL)needCommit
                       completion:(nullable void(^)(void))completion
{
    // bgm 状态恢复
    if (repository.repoMusic.bgmAsset != nil) {
        [[videoData.nleModel tracksWithType:NLETrackAUDIO] acc_forEach:^(NLETrack_OC * _Nonnull obj) {
            if ([obj.slots.firstObject isRelatedWithAudioAsset:repository.repoMusic.bgmAsset]) {
                obj.isBGMTrack = YES;
            }
        }];
    }
    
    // 需要移动资源
    if (moveResource) {
        [videoData moveResourceToDraftFolder:repository.repoDraft.draftFolder];
    }
    
    videoData.isTempVideoData = NO;
    [repository.repoVideoInfo updateVideoData:videoData];
    [videoData.nle.editor setModel:videoData.nleModel];
    
    // 提交修改
    NLETrack_OC *mainTrack = [[videoData.nleModel getTracks] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isMainTrack;
    }];
    if (needCommit && (mainTrack.slots.count > 0 || videoData.imageMovieInfo.imageArray.count > 0)) {
        [videoData.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
            !completion ?: completion();
        }];
    } else {
        // 无主轨
        !completion ?: completion();
    }
}


+ (NLEInterface_OC *)nleInterfaceWithRepository:(AWEVideoPublishViewModel *)repository
{
    return [self nleInterfaceWithRepository:repository editor:nil config:nil];
}

+ (NLEInterface_OC *)nleInterfaceWithRepository:(AWEVideoPublishViewModel *)repository
                                         editor:(nullable NLEEditor_OC *)editor
                                         config:(nullable VEEditorSessionConfig *)config
{
    // 创建一个空的 NLEInterface
    NLEInterface_OC *nle = [[NLEInterface_OC alloc] init];
    
    // 构造 config
    if (config == nil) {
        config = [ACCEditSessionConfigBuilder editorSessionConfigWithPublishModel:repository];
    }
    
    NLEEditorConfiguration *editorConfig = [[NLEEditorConfiguration alloc] init];
    editorConfig.veConfig = config;
    editorConfig.notSupportCrossplat = repository.repoVideoInfo.video.notSupportCrossplat;
    editorConfig.crossplatInput = repository.repoVideoInfo.video.crossplatInput;
    editorConfig.crossplatCompile = repository.repoVideoInfo.video.crossplatCompile;
    editorConfig.isRecordFromCamera = repository.repoVideoInfo.video.isRecordFromCamera;
    editorConfig.imageMovieInfo = repository.repoVideoInfo.video.imageMovieInfo;
    [nle CreateNLEEditorWithConfiguration:editorConfig];
    
    // 替换 editor
    if (editor) {
        nle.editor = editor;
    }
    
    // 轨道填充模式
    if (repository.repoCutSame.isNewCutSameOrSmartFilming) {
        [nle configVideoDurationMode:NLEVideoDurationModeFillToMaxEnd];
    } else {
        [nle configVideoDurationMode:NLEVideoDurationModeFitToMainTrack];
    }
    
    // 业务数据的配置
    [nle setDraftFolder:repository.repoDraft.draftFolder];
    [nle setDisableAutoUpdateCanvasSize:YES];
    nle.effectPathBlock = [AWEVideoEffectPathBlockManager pathConvertBlock:repository];
    
    // sticker userInfo 数据
    [self p_updateUserInfoBlockForNLE:nle repository:repository];
    
    return nle;
}

+ (void)p_updateUserInfoBlockForNLE:(NLEInterface_OC *)nle
                         repository:(AWEVideoPublishViewModel *)repository
{
    @weakify(repository);
    [nle setNleConvertUserInfoBlock:^(NSDictionary *__autoreleasing *userInfo, NLETrackSlot_OC *slot) {
        @strongify(repository);
        NSString *extraStr = [slot.segment getExtraForKey:kNLEExtraKey];
        if (extraStr == nil) {
            return;
        }
        NSData *extraData = [extraStr dataUsingEncoding:NSUTF8StringEncoding];
        if (extraData == nil) {
            return;
        }
        NSError *error = nil;
        NSDictionary *extraDict = [NSJSONSerialization JSONObjectWithData:extraData options:kNilOptions error:&error];
        if (error) {
            AWELogToolError2(@"ACCNLEEditorBuilder", AWELogToolTagEdit, @"JSON serialize error: %@", error);
        }
    
        if (extraDict == nil || extraDict.count == 0) {
            return;
        }
        slot.sticker.stickerType = (ACCCrossPlatformStickerType)[extraDict acc_unsignedIntegerValueForKey:kStickerTypeKey];
        slot.sticker.extraDict = [extraDict mutableCopy];
        
        [ACCStickerMigrateUtil updateUserInfo:userInfo repoModel:(id<ACCPublishRepository>)repository byCrossPlatformSlot:slot];
    }];
}

+ (void)replaceSandboxForResourceWithNLEEditor:(NLEEditor_OC * _Nonnull)editor
                                    repository:(AWEVideoPublishViewModel *)repository {
    [[[editor getModel] acc_allResouces] acc_forEach:^(NLEResourceNode_OC * _Nonnull obj) {
        [obj acc_fixSandboxDirWithDraftFolder:repository.repoDraft.draftFolder];
    }];
}

+ (void)repositoryFallbackVEIfNeeded:(AWEVideoPublishViewModel *)repository
{
    // 进编辑先修改为 VE，防止多 NLE 实例出现导致编辑页卡顿
    if (acc_videodata_is_nle(repository.repoVideoInfo.video)) {
        ACCEditVideoData *videoData = acc_videodata_make_ve(repository.repoVideoInfo.video);
        [repository.repoVideoInfo updateVideoData:videoData];
    }
}

+ (void)saveNLEEditor:(NLEEditor_OC *)editor
           repository:(AWEVideoPublishViewModel *)repository
         businessJSON:(NSString *)businessJSON
           completion:(void (^)(void))completion
{
    if (!acc_videodata_is_nle(repository.repoVideoInfo.video)) {
        ACCBLOCK_INVOKE(completion);
        return;
    }
    
    // 保存草稿有可能保存的是 originalModel，所以需要同步 userInfo 数据
    NLEInterface_OC *nle = acc_videodata_take_nle(repository.repoVideoInfo.video).nle;
    [self p_updateUserInfoBlockForNLE:nle repository:repository];
    
    // 更新 NLE 数据
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(repository.repoVideoInfo.video);
    [nleVideoData beginEdit];
    [editor acc_commitAndRender:^(NSError * _Nullable error) {
        [self syncNLEEditor:editor repository:repository];
        if (businessJSON) {
            [editor setGlobalExtra:kNLEExtraKey extra:businessJSON];
            [editor done];
        }
        [self p_saveNLEEditor:editor repository:repository];
        ACCBLOCK_INVOKE(completion);
    }];
}

+ (void)syncNLEEditor:(NLEEditor_OC *)editor
           repository:(AWEVideoPublishViewModel *)repository
{
    if (editor == nil) {
        return;
    }
    
    ACCEditVideoData *videoData = repository.repoVideoInfo.video;
    NSArray<IESInfoSticker *> *infoStickers = [videoData infoStickers];
    NSArray<NLETrackSlot_OC *> *slots = [[editor getModel] slotsWithType:NLETrackSTICKER];
    for (IESInfoSticker *sticker in infoStickers) {
        NSString *slotName = [sticker.userinfo acc_stringValueForKey:NLEStickerUserInfoSlotName];
        if (!slotName) {
            continue;
        }
        
        NLETrackSlot_OC *slot = [slots acc_match:^BOOL(NLETrackSlot_OC * _Nonnull item) {
            return [[item getName] isEqualToString:slotName];
        }];
        NSCAssert(slot, @"not found sticker, id:%zd", sticker.stickerId);
        if (!slot || slot.captionSticker) {
            // ignore caption sticker
            continue;
        }
        NLESegment_OC *segment = slot.segment;
        if (!segment || ![segment isKindOfClass:NLESegmentSticker_OC.class]) {
            continue;
        }
        NLESegmentSticker_OC *nleSticker = (NLESegmentSticker_OC *)segment;
        [self p_setNleExtraWith:repository nleSticker:nleSticker sticker:sticker];
    }
    [editor commit];
}

+ (void)p_saveNLEEditor:(NLEEditor_OC *)editor repository:(AWEVideoPublishViewModel *)repository
{
    NSString *nleJsonString = [editor store];
    NSData *NLEEditorData = [nleJsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *draftFolder = [[AWEDraftUtils generateDraftFolderFromTaskId:repository.repoDraft.taskID] stringByAppendingPathComponent:self.nleFileName];
    
    if (NLEEditorData.length == 0) {
        AWELogToolError2(@"save", AWELogToolTagDraft, @"save nle error, nle string is empty");
        return;
    }
    
    if (NLEEditorData.length > 0 && draftFolder) {
        [NLEEditorData acc_writeToFile:draftFolder atomically:YES];
    }
}

+ (NLEEditor_OC *)loadNLEEditorWithDraftID:(NSString *)draftID
                          publishViewModel:(AWEVideoPublishViewModel *)publishViewModel
                                     error:(NSError **)error
{
    NSError *lastError = nil;
    // restore NLEEditor
    NSString *nleFolder = [[AWEDraftUtils generateDraftFolderFromTaskId:draftID] stringByAppendingPathComponent:self.nleFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:nleFolder]) {
        NSData *nleEditorData = [NSData dataWithContentsOfFile:nleFolder];
        
        if (nleEditorData.length > 0) {
            NSString *nleEditorJson = [[NSString alloc] initWithData:nleEditorData encoding:NSUTF8StringEncoding];
            NLEEditor_OC *nleEditor = [[NLEEditor_OC alloc] init];
            NLEError nleError = [nleEditor restore:nleEditorJson];
            if (nleError != SUCCESS) {
                lastError = [NSError errorWithDomain:@"com.douyin.nle" code:-103 userInfo:@{@"NLERestoreCodeKey" : @(nleError)}];
            } else {
                [ACCNLEUtils replaceSandboxForResourceWithNLEEditor:nleEditor repository:publishViewModel];
        
                if (!ACCConfigBool(kConfigBool_tool_enable_edit_nle_draft)) {
                    lastError = [NSError errorWithDomain:@"com.douyin.nle" code:-102 userInfo:@{@"NLEForbidCodeKey" : @(ACCConfigBool(kConfigBool_tool_enable_edit_nle_draft))}];
                }
                
                return nleEditor;
            }
        } else {
            lastError = [NSError errorWithDomain:@"com.douyin.nle" code:-104 userInfo:@{
                NSLocalizedDescriptionKey : @"nle is empty"
            }];
        }
    }
    
    if (lastError && error) {
        *error = lastError;
    }
    
    return nil;
}

+ (void)removeNLEEditorWithDraftID:(NSString *)draftId
{
    NSString *nleFolder = [[AWEDraftUtils generateDraftFolderFromTaskId:draftId] stringByAppendingPathComponent:self.nleFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:nleFolder]) {
        [[NSFileManager defaultManager] removeItemAtPath:nleFolder error:nil];
    }
}

+ (BOOL)p_repositoryHasNLEData:(AWEVideoPublishViewModel *)publishViewModel
{
    NSString *nleFolder = [[AWEDraftUtils generateDraftFolderFromTaskId:publishViewModel.repoDraft.taskID] stringByAppendingPathComponent:self.nleFileName];
    return [[NSFileManager defaultManager] fileExistsAtPath:nleFolder];
}

+ (void)p_setNleExtraWith:(AWEVideoPublishViewModel *)model nleSticker:(NLESegmentSticker_OC *)nleSticker sticker:(IESInfoSticker *)sticker {
    NSDictionary *userInfo = sticker.userinfo;
    if (!userInfo) {
        // 抖音业务的贴纸都应该有userInfo
        return;
    }
    ACCStickerMigrateContext *context = [[ACCStickerMigrateContext alloc] init];
    context.stickerID = @(sticker.stickerId).stringValue;
    context.resourcePath = [nleSticker getResNode].resourceFile;
    context.isLyricSticker = sticker.isSrtInfoSticker;
    context.transformX = sticker.param.offsetX;
    context.transformY = sticker.param.offsetY;
    context.textParams = sticker.textParam;
    NLESegmentSticker_OC *temp_sticker;
    [ACCStickerMigrateUtil fillCrossPlatformStickerByUserInfo:userInfo repository:(id<ACCPublishRepository>)model context:context sticker:&temp_sticker];
    nleSticker.stickerType = temp_sticker.stickerType;
    nleSticker.extraDict = temp_sticker.extraDict.mutableCopy;
    if (nleSticker.extraDict == nil) {
        nleSticker.extraDict = [[NSMutableDictionary alloc] init];
    }
    nleSticker.extraDict[kStickerTypeKey] = @(nleSticker.stickerType);
    NSError *error = nil;
    NSData *extraJsonData = [NSJSONSerialization dataWithJSONObject:nleSticker.extraDict options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        AWELogToolError2(@"Convert", AWELogToolTagDraft, @"Sticker Extra Convert To Data Error: %@", error);
    }
    NSString *extraString = [[NSString alloc] initWithData:extraJsonData encoding:NSUTF8StringEncoding];
    [nleSticker setExtra:extraString forKey:kNLEExtraKey];
}

+ (NSString *)nleFileName
{
    return @"project.nle";
}

@end
