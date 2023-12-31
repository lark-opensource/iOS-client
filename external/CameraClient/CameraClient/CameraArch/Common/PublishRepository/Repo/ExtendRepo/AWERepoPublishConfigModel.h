//
//  AWERepoPublishConfigModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/21.
//

#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>

// https://bytedance.feishu.cn/docs/doccn9oXk9dTlwdz1bOKcqHdedc
// publish中extra字段category_da对应投稿类型
typedef NS_ENUM(NSUInteger, ACCFeedTypeExtraCategoryDa) {
    ACCFeedTypeExtraCategoryDaUnknown = 0,
    ACCFeedTypeExtraCategoryDaAvatarStory = 1,
    ACCFeedTypeExtraCategoryDaTextMode = 2,
    ACCFeedTypeExtraCategoryDaBirthday = 3,
    ACCFeedTypeExtraCategoryDaMiniGameVideo = 4,
    ACCFeedTypeExtraCategoryDaChangeBackground = 6, //已下线，保留一段时间兼容可能意外存在的草稿
    ACCFeedTypeExtraCategoryDaIntroduction = 7,
    ACCFeedTypeExtraCategoryDaNewcomers = 8,
    ACCFeedTypeExtraCategoryDaRePost = 9,
    ACCFeedTypeExtraCategoryDaShareAsStory = 10,
    ACCFeedTypeExtraCategoryDaMusicStory = 11,
    ACCFeedTypeExtraCategoryDaNewCity = 12,
    ACCFeedTypeExtraCategoryJoinCircle = 13,
    ACCFeedTypeExtraCategoryLivePhoto = 14,
    ACCFeedTypeExtraCategoryDaShareCommentToStory = 15,
    ACCFeedTypeExtraCategoryDaSinglePhoto = 16 ///<  普通的单图画布，canvasType == SinglePhoto
};

NS_ASSUME_NONNULL_BEGIN

@interface AWERepoPublishConfigModel : ACCRepoPublishConfigModel

@property (nonatomic, weak) id<ACCRepoPublishConfigModelTitleObserver> titleObserver;

@property (nonatomic, nullable) NSNumber *recommendedAICoverIndex;
@property (nonatomic, nullable) NSNumber *recommendedAICoverTime;

@property (nonatomic, nullable) NSString *coverTitleSelectedFrom;
@property (nonatomic, nullable) NSString *coverTitleSelectedId;

@property (nonatomic, assign) CGPoint coverCropOffset; //裁剪的偏移量，百分比
@property (nonatomic, strong, nullable) UIImage  *cropedCoverImage; // 经过裁剪的封面, Deprecated
@property (nonatomic, strong, nullable) UIImage *meteorModeCover; // 高斯模糊处理的封面
@property (nonatomic, strong, nullable) UIImage *backupCover;

@property (nonatomic, copy) NSString *tosCropCoverURI;

@property (nonatomic, assign) BOOL shouldHideInMyPosts; // [want to show in my posts by default] and [BOOL's default value is NO], so using "hide" in the name

// activity
@property (nonatomic, copy) NSString *activityHashtagID;

//是否是首次投稿
@property (nonatomic, assign) BOOL isFirstPost;

//是否强转SDR
@property (nonatomic, assign) BOOL shouldForceSDR;

///  保存本地的素材为图片(例如图集 / 单图画布等),  将执行图片存储
///  不会存草稿，因为是否存为图片需要根据最终发布时候才能决定
@property (nonatomic, assign) BOOL isSaveToAlbumSourceImage;

/// 是否为单图发布为图集的flag， 一般用于埋点的track
/// 任务开始前实时判断 不会存草稿, 发布前实时更新
/// 以最终的task是否为imageTask决定是否发为图集，而非此字段
@property (nonatomic, assign) BOOL isPublishCanvasAsImageAlbum;

/// BOOL 用于发布页动态创建task的同步的flag，不存草稿，创建task流程实时更新
@property (nonatomic, strong) NSNumber *dynamicyPrepareCanvasPublishAsImageFlagValue;

/// 发布后编辑是否用户手动修改过封面
@property (nonatomic, assign) BOOL isUserSelectedCover;

@property (nonatomic, assign) BOOL isParameterizedCreation; //是否是参数化配置投稿，仅端监控短期使用，不存草稿。
@property (nonatomic, assign) BOOL isSilentPublish; //是否是静默发布(不经编辑页直接发布)，不存草稿。参数化配置投稿有效

@property (nonatomic, assign) BOOL publishPhaseIsAfterSynthesis; // 是否完成合成

/// 记录拍摄照片所用的主镜头
@property (nonatomic, copy, nullable) NSString *lensName;

#pragma mark - only for draft

// resource path
@property (nonatomic, copy) NSString *coverImagePath;
@property (nonatomic, copy) NSString *coverTextPath;
@property (nonatomic, copy) NSString *firstFramePath;
@property (nonatomic, copy) NSString *cropedCoverImagePath;
@property (nonatomic, copy) NSString *backupCoverPath;

@property (nonatomic, copy) NSString *coverImagePathRelative;
@property (nonatomic, copy) NSString *coverTextPathRelative;
@property (nonatomic, copy) NSString *firstFramePathRelative;
@property (nonatomic, copy) NSString *cropedCoverImagePathRelative;

/*
 工具业务对外接口接收的发布参数，这些参数仅透传，在创作链路内部不再做修改
 */
@property (nonatomic, strong) NSDictionary *unmodifiablePublishParams;

@property (nonatomic, assign) ACCFeedTypeExtraCategoryDa categoryDA;

@property (nonatomic, strong, nullable) NSData *titleExtraInfoData;

- (NSDictionary *)recommendedAICoverTrackInfo;
- (NSDictionary *)recommendedAICoverTrackInfoWithCoverStartTime:(CGFloat)coverStartTime;
- (UIImage *)composedCoverImage;

- (BOOL)isTitleModified;
- (BOOL)isSelectCoverModified;
- (BOOL)isCoverTextModified;

@end

@interface AWEVideoPublishViewModel (AWERepoPublishConfig)
 
@property (nonatomic, strong, readonly) AWERepoPublishConfigModel *repoPublishConfig;
 
@end

NS_ASSUME_NONNULL_END
