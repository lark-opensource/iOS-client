//
//  AWERepoStickerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by 马超 on 2021/4/11.
//

#import <CreationKitArch/ACCRepoStickerModel.h>
#import "ACCShootSameStickerModel.h"

@class IESEffectModel;
@class ACCEditorStickerConfigAssembler;
@class AWEVideoShareInfoModel;
@class ACCTextStickerLibItem, ACCTextStickerRecommendItem;
@class ACCVideoReplyModel;
@class ACCVideoReplyCommentModel;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const ACCStickerDeleteableKey;
FOUNDATION_EXTERN NSString *const ACCStickerEditableKey;

@interface AWERepoStickerModel : ACCRepoStickerModel

@property (nonatomic, strong, nullable) NSString *dateTextStickerContent;

@property (nonatomic, strong, nullable) UIImage *textImage;           //文字、POI贴纸图片

@property (nonatomic, strong, nullable) NSString *lastSelectedSpeakerID; // indicate the lastly selected speaker ID

@property (nonatomic,   copy) NSString *currentLyricStickerID;//用于歌词贴纸按钮点击埋点

@property (nonatomic, assign) BOOL showInRecord;

@property (nonatomic, copy, nullable) NSArray<IESEffectModel *> *stickerEffectModel;  // EffectPlatform下载贴纸

@property (nonatomic, strong, nullable) IESEffectModel *stickerShootSameEffectModel; // sticker shoot same effect model, only used for shoot page, reset when added on edit page

@property (nonatomic, strong, nullable) NSString *signatureStickerContent;

// for draft only
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSURL *> *textReadingURLs;

@property (nonatomic, copy, nullable) NSString *interactionStickersString;//array json string
@property (nonatomic, copy, nullable) NSString *interactionImgPath;
@property (nonatomic, copy, nullable) NSString *interactionProps;//json string
@property (nonatomic, copy, nullable) NSString *pollImgPath;
@property (nonatomic, strong, nullable) NSData *infoStickersJson;

// no need save draft
@property (nonatomic, strong, nullable) ACCEditorStickerConfigAssembler *stickerConfigAssembler;
// Shoot Same Sticker Models
@property (nonatomic, strong) NSMutableArray<ACCShootSameStickerModel *> *shootSameStickerModels;
@property (nonatomic, strong, nullable) NSDate *assetCreationDate;

// groot info
@property (nonatomic, copy, nullable) NSString *grootModelResult;
@property (nonatomic, copy, nullable) NSString *recorderGrootModelResult;

@property (nonatomic, assign) BOOL adjustTo9V16EditFrame;

@property (nonatomic, strong) AWEVideoShareInfoModel *videoShareInfo;

@property (nonatomic, strong, nullable) ACCVideoReplyModel *videoReplyModel;

@property (nonatomic, strong, nullable) ACCVideoReplyCommentModel *videoReplyCommentModel;

@property (nonatomic, assign) BOOL appliedAutoSocialStickerInAlbumMode;

@property (nonatomic, copy) NSArray<ACCTextStickerRecommendItem *> *directTitles;// 直接推荐
@property (nonatomic, copy) NSArray<ACCTextStickerLibItem *> *textLibItems;

// Recorder Sync
@property (nonatomic, assign) BOOL shouldRecoverRecordStickers;// 是否需要恢复拍摄页的贴纸
@property (nonatomic, assign) CGRect recordStickerPlayerFrame;
@property (nonatomic, strong, nullable) NSArray<AWEInteractionStickerModel *> *recorderInteractionStickers;

- (NSDictionary *)videoCommentStickerTrackInfo; // Video Comment Sticker
- (NSDictionary *)textStickerTrackInfo;
- (NSArray *)infoStickerChallengeNames;
- (NSArray *)infoStickerChallengeIDs;
- (NSDictionary *)socialStickerTrackInfoDic;
- (void)syncWishDirectTitles;

- (BOOL)containsStickerType:(AWEInteractionStickerType)stickerType; // is there an added sticker conforming to a specific sticker type
@end

@interface AWEVideoPublishViewModel (AWERepoSticker) <ACCRepositoryElementRegisterCategoryProtocol>

@property (nonatomic, strong, readonly) AWERepoStickerModel *repoSticker;

@end

NS_ASSUME_NONNULL_END
