//
//  ACCRepoStickerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/21.
//

#import <Foundation/Foundation.h>

#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <Mantle/Mantle.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <TTVideoEditor/IESMMBaseDefine.h>

@class AWEInfoStickerInfo;

NS_ASSUME_NONNULL_BEGIN

// notification key for AWEVideoPublishViewModel's infoStickerArray change
FOUNDATION_EXTERN NSNotificationName const ACCVideoChallengeChangeKey;

@class AWEInteractionStickerModel, ACCPublishInteractionModel, IESMMVideoDataClipRange, AVAsset;

@interface ACCRepoStickerModel : NSObject <NSCopying, ACCRepositoryContextProtocol, ACCRepositoryTrackContextProtocol>

//interaction sticker
@property (nonatomic, strong, nullable) NSArray<AWEInteractionStickerModel *> *interactionStickers;

//interaction sticker model
@property (nonatomic, strong) ACCPublishInteractionModel *interactionModel;

@property (nonatomic, strong, nullable) NSString *imageText;
@property (nonatomic, copy) NSString *imageTextFonts;
@property (nonatomic, copy) NSString *imageTextFontEffectIds;
@property (nonatomic, strong, nullable) UIImage *pollImage;

// should send notification ACCVideoChallengeChangeKey to notify infoStickerArray changement for title hash tags when support edit page publish
@property (nonatomic, strong) NSMutableArray<AWEInfoStickerInfo *> *infoStickerArray;
@property (nonatomic, assign) BOOL hasTextAdded; // ignore ctrl characters.
@property (nonatomic, strong) NSMutableDictionary<NSString *, AVAsset *> *textReadingAssets;
@property (nonatomic, strong) NSMutableDictionary<NSString *, IESMMVideoDataClipRange *> *textReadingRanges;
@property (nonatomic, copy) NSString *stickerID;
// sticker invalid gesture area
@property (nonatomic, copy) NSValue *gestureInvalidFrameValue;   // CGRectValue

- (NSDictionary *)textStickerTrackInfo;
- (NSArray<AVAsset *> *)allAudioAssetsInVideoData;
- (nullable AVAsset *)audioAssetInVideoDataWithKey:(NSString *)key;
- (NSDictionary *)customStickersInfos;
- (BOOL)supportMusicLyricSticker;
- (void)removeTextReadingInCurrentVideo;

@end

@interface AWEVideoPublishViewModel (RepoSticker) <ACCRepositoryElementRegisterCategoryProtocol>

@property (nonatomic, strong, readonly) ACCRepoStickerModel *repoSticker;

@end

NS_ASSUME_NONNULL_END
