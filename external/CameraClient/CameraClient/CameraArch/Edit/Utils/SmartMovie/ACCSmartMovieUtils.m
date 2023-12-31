//
//  ACCSmartMovieUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by LeonZou on 2021/8/2.
//

#import "ACCSmartMovieUtils.h"
#import "AWERepoContextModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

#import <CameraClient/AWEAssetModel.h>
#import <CameraClient/AWERepoMVModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/ACCNLEEditVideoData.h>
#import <CameraClient/NLETrack_OC+Extension.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/ACCSmartMovieABConfig.h>
#import <CameraClient/NLEEditor_OC+Extension.h>
#import <CameraClient/ACCRepoSmartMovieInfoModel.h>
#import <CameraClient/ACCEditVideoDataDowngrading.h>

#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCRepoCutSameModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreativeAlbumKit/CAKAlbumAssetModel.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#include <EffectSDK_iOS/bef_effect_api.h>

NSString *const kACCSmartMovieBubbleTipsHasShownKey = @"kACCSmartMovieBubbleTipsHasShownKey";

NS_INLINE BOOL acc_checkMigrateTracks(NLETrack_OC *_Nonnull track)
{
    if (track.smartMovieVideoMode != ACCSmartMovieSceneModeNone) {
        return NO;
    }
    
    if ((track.extraTrackType == NLETrackAUDIO) && track.isTextRead) {
        return YES;
    }
    
    return (track.extraTrackType == NLETrackImage  ||
            track.extraTrackType == NLETrackFILTER ||
            track.extraTrackType == NLETrackEFFECT ||
            track.extraTrackType == NLETrackSTICKER);
}

@implementation ACCSmartMovieUtils

+ (BOOL)isAllPhotoAsset:(NSArray *_Nonnull)assets
{
    if ([assets.firstObject isKindOfClass:CAKAlbumAssetModel.class]) {
        for (CAKAlbumAssetModel *asset in assets) {
            if (asset.mediaType != CAKAlbumAssetModelMediaTypePhoto) {
                return NO;
            }
        }
        return YES;
    } else if ([assets.firstObject isKindOfClass:AWEAssetModel.class]) {
        for (AWEAssetModel *asset in assets) {
            if (asset.mediaType != AWEAssetModelMediaTypePhoto) {
                return NO;
            }
        }
        return YES;
    }
    
    NSAssert(NO, @"SmartMovie: invalid asset model type!");
    return NO;
}

+ (NSArray *_Nullable)trimHomeDirForPaths:(NSArray<NSString *> *_Nonnull)assetPaths
{
    NSString *homeDir = NSHomeDirectory();
    NSArray<NSString *> *tmps = [assetPaths acc_map:^id _Nonnull(NSString * _Nonnull obj) {
        NSRange range = [obj rangeOfString:homeDir];
        if (range.location != NSNotFound) {
            return [obj substringFromIndex:NSMaxRange(range)];
        }
        return obj;
    }];
    return tmps;
}

+ (NSArray<NSString *> *_Nullable)thumbImagesForPaths:(NSArray<NSString *> *_Nonnull)assetPaths
{
    return [assetPaths acc_map:^id _Nonnull(NSString * _Nonnull obj) {
        NSRange range = [obj rangeOfString:@"_thumb.jpg"];
        if (range.location == NSNotFound) {
            return [[obj stringByDeletingPathExtension] stringByAppendingFormat:@"_thumb.jpg"];
        }
        return obj;
    }];
}

+ (NSArray<NSString *> *_Nullable)absolutePathsForAssets:(NSArray<NSString *> *_Nonnull)assetPaths
{
    NSString *homeDir = NSHomeDirectory();
    NSArray<NSString *> *results = [assetPaths acc_map:^id _Nonnull(NSString * _Nonnull obj) {
        return [NSString stringWithFormat:@"%@%@", homeDir, obj];
    }];
    
    return results;
}

+ (BOOL)isPhotoAssets:(NSArray<AWEAssetModel *> *_Nonnull)assets
{
    for (AWEAssetModel *ast in assets) {
        if (![ast isKindOfClass:AWEAssetModel.class]) {
            return NO;
        }
        if (ast.mediaType != AWEAssetModelMediaTypePhoto) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)isPhotoResources:(NSArray<IESMMMVResource *> *_Nonnull)resources
{
    for (IESMMMVResource *ast in resources) {
        if (![ast isKindOfClass:IESMMMVResource.class]) {
            return NO;
        }
        if (ast.resourceType != IESMMMVResourcesType_img) {
            return NO;
        }
    }
    return YES;
}

+ (UIImage *_Nullable)compressImage:(UIImage *_Nonnull)originImg toSize:(CGFloat)maxLength
{
    CGSize originSize = originImg.size;
    CGFloat scale = 1.f;
    CGSize targetSize = CGSizeZero;
    
    if (originSize.width > maxLength && originSize.height > maxLength) {
        if (originSize.width > originSize.height) {
            scale = originSize.height / originSize.width;
            targetSize.width = maxLength;
            targetSize.height = maxLength * scale;
        } else {
            scale = originSize.width / originSize.height;
            targetSize.height = maxLength;
            targetSize.width = maxLength * scale;
        }
    } else if (originSize.width > maxLength) {
        scale = originSize.height / originSize.width;
        targetSize.width = maxLength;
        targetSize.height = maxLength * scale;
    } else if (originSize.height > maxLength) {
        scale = originSize.width / originSize.height;
        targetSize.height = maxLength;
        targetSize.width = maxLength * scale;
    }
    
    if (!CGSizeEqualToSize(targetSize, CGSizeZero)) {
        UIGraphicsBeginImageContext(targetSize);
        [originImg drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
        UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return resultImg;
    }
    
    return originImg;
}

#pragma mark - Config Methods

+ (NSString *)effectSDKVersion
{
    char version[10] = {0};
#if !TARGET_IPHONE_SIMULATOR
    bef_effect_get_sdk_version(version,sizeof(version));
#endif
    NSString *effectSDKVersion = [[NSString alloc] initWithUTF8String:version];
    return effectSDKVersion;
}

#pragma mark - NLE Methods

+ (void)mergeModeTracks:(ACCSmartMovieSceneMode)mode to:(AWEVideoPublishViewModel *_Nonnull)to
{
    id<ACCEditVideoDataProtocol> videoData = nil;
    if (mode == ACCSmartMovieSceneModeSmartMovie) {
        videoData = to.repoSmartMovie.videoForSmartMovie;
    } else if (mode == ACCSmartMovieSceneModeMVVideo) {
        videoData = to.repoSmartMovie.videoForMV;
    }
    
    if (videoData) {
        ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(videoData);
        [self mergeVideoData:nleVideoData to:to];
    }
}

+ (void)removeModeTracks:(ACCSmartMovieSceneMode)mode from:(AWEVideoPublishViewModel *_Nonnull)from
{
    id<ACCEditVideoDataProtocol> videoData = nil;
    if (mode == ACCSmartMovieSceneModeSmartMovie) {
        videoData = from.repoSmartMovie.videoForSmartMovie;
    } else if (mode == ACCSmartMovieSceneModeMVVideo) {
        videoData = from.repoSmartMovie.videoForMV;
    }
    if (!videoData) { return; }
    
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(videoData);
    if (!nleVideoData) { return; }
    
    NLEInterface_OC *nle = nleVideoData.nle;
    NSMutableArray<NLETrack_OC *> *curTracks = [NSMutableArray array];
    for (NLETrack_OC *track in [[nle.editor getModel] getTracks]) {
        if (acc_checkMigrateTracks(track)) {
            [curTracks btd_addObject:track];
        }
    }
    
    for (NLETrack_OC *track in curTracks) {
        [[nle.editor getModel] removeTrack:track];
    }
}

+ (void)syncMVTracks:(AWEVideoPublishViewModel *_Nonnull)to
{
    [self mergeModeTracks:ACCSmartMovieSceneModeMVVideo to:to];
    [self removeModeTracks:ACCSmartMovieSceneModeMVVideo from:to];
}

+ (void)syncSmartMovieTracks:(AWEVideoPublishViewModel *_Nonnull)to
{
    [self mergeModeTracks:ACCSmartMovieSceneModeSmartMovie to:to];
    [self removeModeTracks:ACCSmartMovieSceneModeSmartMovie from:to];
}

+ (void)markTracksAsMVForSmartMovie:(id<ACCEditVideoDataProtocol>_Nonnull)videoData
{
    if (!videoData || ![videoData isKindOfClass:[ACCNLEEditVideoData class]]) {
        return;
    }
    ACCNLEEditVideoData *nleVideoData = (ACCNLEEditVideoData *)videoData;
    for (NLETrack_OC *track in [nleVideoData.nleModel getTracks]) {
        track.smartMovieVideoMode = ACCSmartMovieSceneModeMVVideo;
    }
}


#pragma mark - Private Methods

+ (void)mergeVideoData:(ACCNLEEditVideoData *_Nullable)videoData to:(AWEVideoPublishViewModel *_Nonnull)to
{
    if (!to || !videoData || !to.repoVideoInfo.video) { return; }
    ACCNLEEditVideoData *toVideoData = acc_videodata_take_nle(to.repoVideoInfo.video);
    if (!toVideoData) { return; }
    
    // 获取当前已经存在的二次编辑数据
    NLEInterface_OC *toNle = toVideoData.nle;
    NSMutableArray<NLETrack_OC *> *totalTracks = [NSMutableArray array];
    for (NLETrack_OC *track in [[toNle.editor getModel] getTracks]) {
        if (track.smartMovieVideoMode == ACCSmartMovieSceneModeNone) {
            [totalTracks btd_addObject:track];
        }
    }
    BOOL (^canMigrate)(NLETrack_OC *) = ^(NLETrack_OC *track) {
        if (!acc_checkMigrateTracks(track)) {
            return NO;
        }
        BOOL notExsited = YES;
        for (NLETrack_OC *it in totalTracks) {
            if ([track.UUID isEqual:it.UUID]) {
                notExsited = NO;
                break;
            }
        }
        return notExsited;
    };
    
    // 检索需要迁移的数据
    NLEInterface_OC *nle = videoData.nle;
    
    NSMutableArray<NLETrack_OC *> *curTracks = [NSMutableArray array];
    for (NLETrack_OC *track in [[nle.editor getModel] getTracks]) {
        if (canMigrate(track)) {
            [curTracks btd_addObject:track];
        }
    }
    
    if (curTracks.count == 0) {
        return;
    }
    
    for (NLETrack_OC *track in curTracks) {
        [[toNle.editor getModel] addTrack:track];
    }
}
@end

FOUNDATION_EXTERN BOOL acc_isOpenSmartMovieCapabilities(AWEVideoPublishViewModel *_Nonnull publishModel)
{
    if (![ACCSmartMovieABConfig isOn]) {
        return NO;
    }
    
    // 剪同款
    BOOL isCutSameMode = (publishModel.repoCutSame.templateModel != nil) && (publishModel.repoCutSame.accTemplateType == ACCMVTemplateTypeCutSame);
    if (isCutSameMode) {
        return NO;
    }
    
    // 一键成片
    BOOL isOneClickFilming = publishModel.repoContext.videoType == AWEVideoTypeOneClickFilming && publishModel.repoCutSame.accTemplateType == ACCMVTemplateTypeCutSame;
    if (isOneClickFilming) {
        return NO;
    }
    
    BOOL isBackUpFromDraft = (publishModel.repoDraft.isDraft || publishModel.repoDraft.isBackUp);

    // 草稿恢复（旧版本草稿不支持）
    BOOL isUnkownMode = (publishModel.repoSmartMovie.videoMode == ACCSmartMovieSceneModeNone);
    if (isBackUpFromDraft && isUnkownMode) {
        return NO;
    }
    
    NSArray<AWEAssetModel *> *assets = publishModel.repoUploadInfo.selectedUploadAssets;
    return (assets.count > 1) && [ACCSmartMovieUtils isPhotoAssets:assets];
}
