//
//  ACCEditBingoManager.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/14.
//

#import "ACCEditBingoManager.h"
#import "ACCEditVideoDataDowngrading.h"
#import "ACCConfigKeyDefines.h"
#import "NLETrack_OC+Extension.h"
#import "NLEEditor_OC+Extension.h"
#import "ACCEditVideoDataFactory.h"
#import "NLETrackSlot_OC+Extension.h"

#import <NLEPlatform/NLETrackAlgorithm+iOS.h>
#import <NLEPlatform/NLEBingoManager.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

@interface ACCEditBingoManager()

@property (nonatomic, strong) IESMMBingoManager *veManager;
@property (nonatomic, strong) NLEBingoManager *nleManager;
@property (nonatomic, copy) NSString *draftFolder;

@end
@implementation ACCEditBingoManager

- (instancetype)initWithDraftFolder:(NSString *)draftFolder
{
    self = [super init];
    if (self) {
        _draftFolder = [draftFolder copy];
        if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
            _nleManager = [[NLEBingoManager alloc] init];
        } else {
            _veManager = [[IESMMBingoManager alloc] init];
        }
    }
    return self;
}

- (void)setMusic:(NSString *)musicPath
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        [self.nleManager setMusic:musicPath];
    } else {
        [self.veManager setMusic:musicPath];
    }
}

- (void)changeMusic:(NSTimeInterval)startTime duration:(NSTimeInterval)duration completion:(void (^)(int))completion
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        [self.nleManager changeMusic:startTime duration:duration completion:completion];
    } else {
        [self.veManager changeMusic:startTime duration:duration completion:completion];
    }
}

- (void)setStoredBeats:(IESMMBingoBeats *)beats completion:(void (^)(int))completion
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        [self.nleManager setStoredBeats:beats completion:completion];
    } else {
        [self.veManager setStoredBeats:beats completion:completion];
    }
}

- (void)insertPic:(NSString *)picPath picDuration:(float)picDuration pos:(int)pos completion:(void (^)(NSString * _Nonnull))completion
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        [self.nleManager insertPic:picPath picDuration:picDuration pos:pos completion:completion];
    } else {
        [self.veManager insertPic:picPath picDuration:picDuration pos:pos completion:completion];
    }
}

- (void)insertVideo:(NSString *)videoPath pos:(int)pos completion:(void (^)(NSString * _Nonnull))completion
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        [self.nleManager insertVideo:videoPath pos:pos completion:completion];
    } else {
        [self.veManager insertVideo:videoPath pos:pos completion:completion];
    }
}

- (void)deleteVideoWithPos:(NSInteger)pos completion:(void (^)(bool))completion
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        [self.nleManager deleteVideoWithPos:pos completion:completion];
    } else {
        [self.veManager deleteVideoWithPos:pos completion:completion];
    }
}

- (void)moveVideoInPos:(NSInteger)oldPos toPos:(NSInteger)newPos completion:(void (^)(bool))completion
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        [self.nleManager moveVideoInPos:oldPos toPos:newPos completion:completion];
    } else {
        [self.veManager moveVideoInPos:oldPos toPos:newPos completion:completion];
    }
}

- (void)generateVideo:(NSString *)key range:(CMTimeRange)range interval:(NSTimeInterval)interval progress:(void (^)(float))progress completion:(IESMMBingoGenertorBlock)completion
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        [self.nleManager generateVideo:key range:range interval:interval progress:progress completion:completion];
    } else {
        [self.veManager generateVideo:key range:range interval:interval progress:progress completion:completion];
    }
}

- (void)cancleGenerateVideo:(NSString *)key
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        [self.nleManager cancleGenerateVideo:key];
    } else {
        [self.veManager cancleGenerateVideo:key];
    }
}

- (void)getRandomReslove:(void (^)(ACCEditVideoData *))completion
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        [self.nleManager getRandomReslove:^(NLEClipBeatResult * _Nonnull beatsResult) {
            ACCNLEEditVideoData *videoData = [ACCEditBingoManager nleVideoDataWithBingoResult:beatsResult
                                                                                  draftFolder:self.draftFolder];
            [videoData.nle.editor setModel:videoData.nleModel];
            [videoData.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
                !completion ?: completion(videoData);
            }];
        }];
    } else {
        [self.veManager getRandomReslove:^(HTSVideoData * _Nonnull videoData) {
            !completion ?: completion([ACCVEVideoData videoDataWithVideoData:videoData
                                                                 draftFolder:self.draftFolder]);
        }];
    }
}

- (void)getReslove:(void (^)(ACCEditVideoData *))completion
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        [self.nleManager getReslove:^(NLEClipBeatResult * _Nonnull beatsResult) {
            ACCNLEEditVideoData *videoData = [ACCEditBingoManager nleVideoDataWithBingoResult:beatsResult
                                                                                  draftFolder:self.draftFolder];
            [videoData.nle.editor setModel:videoData.nleModel];
            [videoData.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
                !completion ?: completion(videoData);
            }];
        }];
    } else {
        [self.veManager getReslove:^(HTSVideoData * _Nonnull videoData) {
            !completion ?: completion([ACCVEVideoData videoDataWithVideoData:videoData
                                                                 draftFolder:self.draftFolder]);
        }];
    }
}

- (AVPlayerItem *)makeItemWithVideodata:(ACCEditVideoData *)videoData
{
    return acc_videodata_downgrading_ret(videoData, ^id(HTSVideoData *videoData) {
        return [self.veManager makeItemWithVideodata:videoData];
    }, ^id(ACCNLEEditVideoData *videoData) {
        return [self.nleManager makeItemWithVideodata:acc_videodata_make_hts(videoData)];
    });
}

- (int)saveInterimScoresToFile:(NSString *)filePath
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        return [self.nleManager saveInterimScoresToFile:filePath];
    } else {
        return [self.veManager saveInterimScoresToFile:filePath];
    }
}

- (int)checkScoreFile:(NSString *)filePath
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        return [self.nleManager checkScoreFile:filePath];
    } else {
        return [self.veManager checkScoreFile:filePath];
    }
}

+ (AVPlayerItem *)makeItemWithVideoData:(ACCEditVideoData *)videoData
{
    return acc_videodata_downgrading_ret(videoData, ^(HTSVideoData *videoData) {
        return [IESMMBingoManager makeItemWithVideoData:videoData];
    }, ^id(ACCNLEEditVideoData *videoData) {
        return [IESMMBingoManager makeItemWithVideoData:acc_videodata_make_hts(videoData)];
    });
}

+ (void)insertPic:(NSURL *)picUrl duration:(float)duration transform:(IESMMVideoTransformInfo *)transfomInfo toVideoData:(ACCEditVideoData *)videoData
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [IESMMBingoManager insertPic:picUrl duration:duration transform:transfomInfo toVideoData:videoData];
    }, ^(ACCNLEEditVideoData *videoData) {
        NLETrackSlot_OC *trackSlot = [videoData addPictureWithURL:picUrl duration:duration];
        trackSlot.videoTransform = transfomInfo;
        trackSlot.movieInputFillType = @(IESMediaOneInputFilter_Fit);
    });
}

+ (void)insertVideo:(AVAsset *)asset clipRange:(IESMMVideoDataClipRange *)clipRange toVideoData:(ACCEditVideoData *)videoData
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [IESMMBingoManager insertVideo:asset clipRange:clipRange toVideoData:videoData];
    }, ^(ACCNLEEditVideoData *videoData) {
        [videoData addVideoWithAsset:asset];
        [videoData updateVideoTimeClipInfoWithClipRange:clipRange asset:asset];
        [videoData updateMovieInputFillTypeWithType:@(IESMediaOneInputFilter_Fit) asset:asset];
    });
}


+ (void)setRate:(CGFloat)rate forAssetAtIndex:(NSUInteger)index videoData:(ACCEditVideoData *)videoData
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [IESMMBingoManager setRate:rate forAssetAtIndex:index videoData:videoData];
    }, ^(ACCNLEEditVideoData *videoData) {
        AVAsset *videoAsset = [videoData acc_videoAssetAtIndex:index];
        if (!videoAsset) {
            return;
        }
        [videoData updateVideoTimeScaleInfoWithScale:@(rate) asset:videoAsset];
    });
}

+ (void)setClipRange:(IESMMVideoDataClipRange *)clipRange forAssetAtIndex:(NSUInteger)index videoData:(ACCEditVideoData *)videoData
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [IESMMBingoManager setClipRange:clipRange forAssetAtIndex:index videoData:videoData];
    }, ^(ACCNLEEditVideoData *videoData) {
        AVAsset *videoAsset = [videoData acc_videoAssetAtIndex:index];
        if (!videoAsset) {
            return;
        }
        [videoData updateVideoTimeClipInfoWithClipRange:clipRange asset:videoAsset];
    });
}

+ (void)setRotateType:(NSNumber *)rotateType forAssetAtIndex:(NSUInteger)index videoData:(ACCEditVideoData *)videoData
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [IESMMBingoManager setRotateType:rotateType forAssetAtIndex:index videoData:videoData];
    }, ^(ACCNLEEditVideoData *videoData) {
        AVAsset *videoAsset = [videoData acc_videoAssetAtIndex:index];
        if (!videoAsset) {
            return;
        }
        [videoData updateAssetRotationsInfoWithRotateType:rotateType asset:videoAsset];
    });
}

+ (void)deleteAsset:(AVAsset *)asset toVideeeoData:(ACCEditVideoData *)videoData
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [IESMMBingoManager deleteAsset:asset toVideeeoData:videoData];
    }, ^(ACCNLEEditVideoData *videoData) {
        [videoData removeVideoAsset:asset];
    });
}

+ (void)moveAssetFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex videoData:(ACCEditVideoData *)videoData
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [IESMMBingoManager moveAssetFromIndex:fromIndex toIndex:toIndex videoData:videoData];
    }, ^(ACCNLEEditVideoData *videoData) {
        [videoData moveVideoAssetFromIndex:fromIndex toIndex:toIndex];
    });
}

+ (void)setTransformInfo:(IESMMVideoTransformInfo *)transformInfo forAssetAtIndex:(NSUInteger)index videoData:(ACCEditVideoData *)videoData
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [IESMMBingoManager setTransformInfo:transformInfo forAssetAtIndex:index videoData:videoData];
    }, ^(ACCNLEEditVideoData *videoData) {
        AVAsset *videoAsset = [videoData acc_videoAssetAtIndex:index];
        if (!videoAsset) {
            return;
        }
        [videoData updateAssetTransformInfoWithTransformInfo:transformInfo asset:videoAsset];
    });
}

#pragma mark - Private

+ (ACCNLEEditVideoData *)nleVideoDataWithBingoResult:(NLEClipBeatResult *)result draftFolder:(NSString *)draftFolder
{
    ACCNLEEditVideoData *videoData = [ACCEditVideoDataFactory tempNLEVideoDataWithDraftFolder:draftFolder];
    videoData.audioAssets = result.audioAssets;
    videoData.audioTimeClipInfo = result.audioTimeClipInfo;
    
    videoData.photoAssetsInfo = result.photoAssetsInfo;
    videoData.photoMovieAssets = result.photoMovieAssets;
    videoData.videoAssets = result.videoAssets;
    
    videoData.movieInputFillType = result.movieInputFillType;
    videoData.movieAnimationType = result.movieAnimationType;
    videoData.assetTransformInfo = result.assetTransformInfo;
    videoData.bingoVideoKeys = result.bingoVideoKeys;
    videoData.volumnInfo = result.volumnInfo;
    videoData.videoTimeScaleInfo = result.videoTimeScaleInfo;
    videoData.videoTimeClipInfo = result.videoTimeClipInfo;
    
    NLETrack_OC *mainTrack = [[videoData.nleModel getTracks] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isMainTrack;
    }];
    
    [videoData.nleModel removeTrack:mainTrack];
    
    // 替换为算法轨，兼容 Android
    NLETrackAlgorithm_OC *algorihtmTrack = [[NLETrackAlgorithm_OC alloc] init];
    algorihtmTrack.layer = 0;
    algorihtmTrack.mainTrack = YES;
    [mainTrack.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        [algorihtmTrack addSlot:obj];
    }];
    
    [videoData.nleModel addTrack:algorihtmTrack];
    
    return videoData;
}

@end
