//
//  AWEVideoFragmentInfo.h
//  CameraClient
//
//  Created by haoyipeng on 2020/10/14.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <AVFoundation/AVFoundation.h>
#import <CreationKitArch/AWETimeRange.h>
#import <CreationKitArch/ACCStudioDefines.h>
#import <CreationKitArch/ACCVideoFragmentInfoProtocol.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>

@class IESEffectModel;

NS_ASSUME_NONNULL_BEGIN

@interface AWEVideoPublishChallengeInfo : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *challengeId;
@property (nonatomic, copy) NSString *challengeName;

@end

@interface ACCEffectTrackParams : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) BOOL needTrackInEdit;
@property (nonatomic, assign) BOOL needTrackInPublish;
@property (nonatomic, copy) NSDictionary *params;

@end

@interface AWEPictureToVideoInfo : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSString *propID;
@property (nonatomic, copy, nullable) NSArray<NSString *> *stickerTextArray;
@property (nonatomic, copy, nullable) NSArray<NSString *> *arTextArray;
@property (nonatomic, copy, nullable) NSArray<AWEVideoPublishChallengeInfo *> *challengeInfos;

#pragma mark - flower
@property (nonatomic) BOOL hasFlowerActivitySticker;
@property (nonatomic) BOOL hasSmartScanSticker;

// 编辑页按钮样式
@property (nonatomic, assign) NSInteger editPageButtonStyle;

//===============================================================
// @description: 超短视频/照片模式补充上报美颜信息
//===============================================================
@property (nonatomic, assign) BOOL beautifyUsed;
@property (nonatomic, assign) BOOL composerBeautifyUsed;
@property (nonatomic, copy) NSString *composerBeautifyInfo;
@property (nonatomic, copy) NSString *composerBeautifyEffectInfo;

@property (nonatomic, copy) NSString *colorFilterName;
@property (nonatomic, copy) NSString *colorFilterId;
@property (nonatomic, assign) BOOL hasDeselectionBeenMadeRecently;

@property (nonatomic, copy) NSString *cameraDirection;
//===============================================================

@property (nonatomic, copy) NSString *welfareActivityID;

@end

@interface ACCSecurityFrameInsetsModel : MTLModel<MTLJSONSerializing, NSCopying>

@property (nonatomic, assign) NSInteger top;
@property (nonatomic, assign) NSInteger left;
@property (nonatomic, assign) NSInteger bottom;
@property (nonatomic, assign) NSInteger right;

- (instancetype)initWithInsets:(UIEdgeInsets)insets;

@end

@class VEEffectPath;
@class VEClientPath;

typedef NS_ENUM(NSUInteger, AWEVideoFragmentSourceType) {
    AWEVideoFragmentSourceTypeRecord,       // 拍摄类资源
    AWEVideoFragmentSourceTypeUpload,       // 上传类资源
    AWEVideoFragmentSourceTypeTemplate,     // 模板类资源
    AWEVideoFragmentSourceTypeImageAlbum    // 图集类资源
};

@interface AWEVideoFragmentInfo : MTLModel<MTLJSONSerializing, ACCVideoFragmentInfoProtocol>

@property (nonatomic, assign) BOOL hasDeselectionBeenMadeRecently;
@property (nonatomic, assign) NSInteger selectedLiveDuetImageIndex;
@property (nonatomic, copy) NSArray<AWEVideoPublishChallengeInfo *> *challengeInfos; // challengeId&challengeName组合，支持多个
@property (nonatomic, assign) BOOL isCommerce;

@property (nonatomic, copy) NSString *stickerPoiId;
@property (nonatomic, assign) BOOL needSelectedStickerPoi;
@property (nonatomic, copy) NSString *mappedShortPoiId; // 记录与`stickerPoiId`对应的短PoiId
@property (nonatomic, copy) NSString *stickerName;
@property (nonatomic, assign) BOOL appliedUseOutputProp; // 该段使用了 audio graph 道具，且 use_output 字段为 YES

@property (nonatomic, strong, nullable) NSString *welfareActivityID;

@property (nonatomic, assign) NSInteger editPageButtonStyle;
@property (nonatomic, assign) BOOL needAddHashTagForStory;

//片段自动应用热门道具
@property (nonatomic, assign) BOOL hasAutoApplyHotProp;

//红包手势贴纸
@property (nonatomic, strong) NSArray<AWETimeRange *> *activityTimerange;//记录这一段中红包出现的时间段
@property (nonatomic, assign) NSInteger activityType;//记录是什么活动(目前双十一是1)

//whether stickers with uploading abilities is used in this fragment
@property (nonatomic, assign) BOOL uploadStickerUsed;

/// effect 埋点数据
@property (atomic, copy) NSArray<ACCEffectTrackParams *> *effectTrackParams;

/// 是否抽帧, 新能力灰度道具新增
@property (nonatomic, assign) BOOL isSupportExtractFrame;


#pragma mark - flower
@property (nonatomic) BOOL hasFlowerActivitySticker;
@property (nonatomic) BOOL hasSmartScanSticker;

#pragma mark - 红包通用
@property (nonatomic) BOOL hasRedpacketSticker;

/// Reshoot
@property (nonatomic, copy) NSString *reshootTaskId;

/// Security
@property (nonatomic, assign) AWEVideoFragmentSourceType sourceType;
@property (nonatomic, strong) AVAsset *avAsset;     // 视频资源
@property (nonatomic, strong) NSURL *avAssetURL;    // 视频资源对应的path
@property (nonatomic, strong) UIImage *imageAsset;  // 图片资源
@property (nonatomic, strong) NSURL *imageAssetURL; // 图片资源对应的path
@property (nonatomic, strong) NSValue *clipTimeRange;
@property (nonatomic, assign, readonly) UIEdgeInsets frameInset;
@property (nonatomic, strong) ACCSecurityFrameInsetsModel *frameInsetsModel;
@property (nonatomic, assign) UIImageOrientation assetOrientation;

@property (nonatomic, copy) NSArray<NSString *> *stickerImageAssetPaths;      // 拍摄用到的背景图片

@property (nonatomic, copy) NSString *stickerMatchId;

/// Orientation
@property (nonatomic, assign) UIDeviceOrientation captureOrientation;

- (void)convertToRelativePathWithTaskID:(NSString *)taskID;
- (void)convertToAbsolutePathWithTaskID:(NSString *)taskID;

+ (nullable NSString *)effectTrackStringWithFragmentInfos:(NSArray<AWEVideoFragmentInfo *> * _Nullable)fragmentInfos
                                                   filter:(BOOL(^ _Nullable)(ACCEffectTrackParams *param))filter;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithSourceType:(AWEVideoFragmentSourceType)sourceType;

@end

NS_ASSUME_NONNULL_END
