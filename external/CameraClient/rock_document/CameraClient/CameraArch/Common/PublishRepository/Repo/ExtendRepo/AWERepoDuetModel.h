//
//  AWERepoDuetModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/23.
//

#import <CreationKitArch/ACCRepoDuetModel.h>

extern const int kAWEModernVideoEditDuetEnlargeMetric;

typedef NS_ENUM(NSUInteger, ACCDuetMicrophoneOptimizeABType) {
    ACCDuetMicrophoneOptimizeABTypeNone             = 0, ///< 保持线上(关闭,无提示)
    ACCDuetMicrophoneOptimizeABTypeCloseAndReminder = 1, ///< 默认关闭 有提示
    ACCDuetMicrophoneOptimizeABTypeOpenAndReminder  = 2, ///< 默认开启 有提示
};

typedef NS_ENUM(NSInteger, ACCDuetUploadType) {
    ACCDuetUploadTypeNone   = 0, ///< 默认
    ACCDuetUploadTypePic   = 1,  ///< 图片
    ACCDuetUploadTypeVideo   = 2  ///< 视频
};

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const kACCDuetLayoutGreenScreen;

@interface AWERepoDuetModel : ACCRepoDuetModel <NSCopying, ACCRepositoryTrackContextProtocol, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

@property (nonatomic, strong) NSString *sourceAwemeID;

// only for draft
@property (nonatomic, strong, nullable) NSData *duetSourceAwemeJSON;
@property (nonatomic, strong, nullable) NSString *duetSourceVideoFilename;

@property (nonatomic, assign) BOOL hasSticker;
@property (nonatomic, assign) BOOL hasChallenge;
@property (nonatomic, assign) BOOL shouldShowDuetGreenScreenAlert;
@property (nonatomic, copy) NSString *duetOriginID;
@property (nonatomic, assign) BOOL shouldEnableMicrophoneOnStart;
@property (nonatomic, assign) BOOL showingDuetMicrophoneStateToast;
@property (nonatomic, assign) BOOL isDuetSing;
@property (nonatomic, assign) BOOL isFromDuetSingTab;
@property (nonatomic, assign) BOOL isFromDuetSingMode;
@property (nonatomic, readonly, nonnull) NSString *duetIdentifierText; // Duet 创作链路上相关文案的关键字，取值为【合拍】or【合唱】

// 合唱埋点 & 调音参数
@property (nonatomic, copy) NSString *chorusMethod; // 合唱来源
@property (nonatomic, assign) BOOL useRecommendVolume;
@property (nonatomic, assign) CGFloat bgmVolume;
@property (nonatomic, assign) CGFloat vocalVolume;
@property (nonatomic, assign) CGFloat vocalAlign;
@property (nonatomic, copy) NSString *soundEffectID;
@property (nonatomic, copy) NSString *duetSingTuningJSON;

@property (nonatomic, copy, nullable) NSString *duetLayoutMessage; // 合拍布局变更相关信息
@property (nonatomic, assign) BOOL isDuetUpload; // 是否是合拍上传
@property (nonatomic, assign) ACCDuetUploadType duetUploadType; // 上传资源类型 1图片 2视频

- (BOOL)isOldDuet;

@end

@interface AWEVideoPublishViewModel (AWERepoDuet)
 
@property (nonatomic, strong, readonly) AWERepoDuetModel *repoDuet;
 
@end

NS_ASSUME_NONNULL_END
