//
//  AWERepoContextModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/20.
//

#import <CreationKitArch/ACCRepoContextModel.h>
#import <Photos/Photos.h>
@protocol ACCAwemeModelProtocol;

typedef NS_ENUM(NSInteger, ACCEditPageBottomButtonStyle) {
    ACCEditPageBottomButtonStyleDefault = 0,
    ACCEditPageBottomButtonStyleNoNext = 1,
    ACCEditPageBottomButtonStyleOnlyNext = 2
};

typedef NS_ENUM(NSInteger, ACCActivityVideoType) {
    ACCActivityVideoTypeNewYearWish = 29,
    ACCActivityVideoTypeHighLight = 30,
    ACCActivityVideoTypeNewYearStageOne = 31,
    ACCActivityVideoTypeNewYearStageTwo = 39,
    ACCActivityVideoTypeNewYearStageThree = 40,
    ACCActivityVideoTypeYearEndReport = 41,
};

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel, RACSignal;
@interface AWERepoContextModel : ACCRepoContextModel <ACCRepositoryContextProtocol>

@property (nonatomic, strong, nullable) AWEVideoPublishViewModel *sourceModel;
@property (nonatomic, strong) RACSignal *assetDataSignal;

/// 发布过程是否允许跳过上传阶段总开关，YES:允许跳过；NO:不允许跳过；默认为NO
@property (nonatomic, assign) BOOL allowSkipUpload;

/// 服务端生成的视频vid
@property (nonatomic, strong, nullable) NSString *remoteVideoResourceId;

@property (nonatomic, readonly) BOOL isKaraokeAudio;
@property (nonatomic, readonly) BOOL isKaraokeOfficialBGVideo;
@property (nonatomic, readonly) BOOL isWishOfficialBGVideo;
@property (nonatomic, assign) BOOL isImageAlbumOnly;    //是否只支持图集
@property (nonatomic, assign) BOOL isReedit; // 是否二次编辑
@property (nonatomic, strong, nullable) NSObject<ACCAwemeModelProtocol> *aweme; // 二次编辑传入的aweme
@property (nonatomic, strong, nullable) NSData *awemeData;
@property (nonatomic, assign) BOOL reeditUsingDraft; // 发布后编辑使用草稿
@property (nonatomic, assign) BOOL isPrivateDailyType; // 快速保存发私密

// 0=默认 1=无下一步 2=无发日常
@property (nonatomic, assign) ACCEditPageBottomButtonStyle editPageBottomButtonStyle;

@property (nonatomic, readonly) BOOL isLive;
/** 是否由音量键触发拍摄，此属性不存草稿 */
@property (nonatomic, assign) BOOL isTriggeredByVolumeButton;
@property (nonatomic, readonly) BOOL isQuickStoryPictureVideoType;

@property (nonatomic, readonly) BOOL isLivePhoto;

@property (nonatomic, readonly) BOOL isIMRecord;

@property (nonatomic, readonly) BOOL supportNewEditClip;

@property (nonatomic, readonly) BOOL newClipForMultiUploadVideos;

@property (nonatomic, assign) BOOL isStoryVideoRecordingMode;   // 是否是快拍模式拍摄
@property (nonatomic, assign) BOOL enterFromShoot;

@property (nonatomic, assign) BOOL appearedMoreThanOne;

@property (nonatomic, assign) BOOL needShowMusicOfflineAlert;
@property (nonatomic, assign) BOOL triggerChangeOfflineMusic;
@property (nonatomic, assign) BOOL isEditEffectInPlayerContainer;
@property (nonatomic, assign) BOOL isStickerEdited;

@property (nonatomic, readonly) BOOL isRecord;
@property (nonatomic, readonly) BOOL isPhoto; // video是否是单图
@property (nonatomic, readonly) BOOL hasPhoto; // video是否包含图片
@property (nonatomic, readonly) BOOL isAudioRecord; //video是否纯音频

@property (nonatomic, assign) BOOL isMeteorMode;
@property (nonatomic, assign) BOOL isCloseMP;
@property (nonatomic, assign) BOOL noLandingAfterPublish;//发布完成后只退出投稿链路的堆栈，不dismiss其他页面（H5)，不跳转到首页特定的tab，保持现状不懂

@property (nonatomic, assign) BOOL isFromCommentPanel; // 该flag用来判断是否是从评论面板进入的拍摄页（用来判断是否发布后不跳转tab）

@property (nonatomic, strong) PHAsset *shareImageAsset;

@property (nonatomic, assign) BOOL propTabLandingRedPacket;

@property (nonatomic, assign) BOOL quickSaveAlbum;

// camera auth and micro auth
@property (nonatomic, assign) BOOL NotNeedCameraAuth;
@property (nonatomic, assign) BOOL NotNeedMicroAuth;

// 静默合成，.e.g. feed下载图片合成视频
@property (nonatomic, assign) BOOL isSilentMergeMode;

@property (nonatomic, assign, readonly) BOOL enableTakePictureOpt;
@property (nonatomic, assign, readonly) BOOL enableTakePictureDelayFrameOpt;

#pragma mark - 活动
@property (nonatomic, strong) NSNumber *activityVideoType;
@property (nonatomic, strong) NSString *activityTaskToken;
@property (nonatomic, assign) AWEVideoType exclusiveVideoType;
@property (nonatomic, assign) BOOL liteActivityRedPacketType;
@property (nonatomic, copy) NSString *liteRedPacketTaskKey;

@property (nonatomic, assign) NSInteger effectMessageTaskId;

@property (nonatomic, assign) BOOL isLiteRedPacketPropCategory;
@property (nonatomic, assign) BOOL propPannelClicked;

@property (nonatomic, assign) BOOL flowerMode;
@property (nonatomic, copy) NSString* flowerItem;
@property (nonatomic, assign) NSInteger flowerBooking;

/// flower活动奖励enter from，对应编辑和发布两个链路，字段不存草稿
@property (nonatomic, copy) NSString *flowerEditActivityEnterFrom;
@property (nonatomic, copy) NSString *flowerPublishActivityEnterFrom;
/// 标记一下已经发布请求过，避免逻辑问题重复请求,字段不存草稿
@property (nonatomic, assign) BOOL didRequestFlowerPublishActivityAward;
@property (nonatomic, copy) NSArray<NSString *> *flowerActivityProps;
- (BOOL)enablePublishFlowerActivityAward;

- (BOOL)shouldSelectMusicAutomatically;
- (BOOL)shouldUseMVMusic;
- (BOOL)canChangeMusicInEditPage;
- (BOOL)isTC21RedPackageActivity;
- (BOOL)isLitePropEnterMethod;

@end

@interface AWEVideoPublishViewModel (AWERepoContext)
 
@property (nonatomic, strong, readonly) AWERepoContextModel *repoContext;
 
@end

NS_ASSUME_NONNULL_END
