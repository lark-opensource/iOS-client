//
//  AWERepoVideoInfoModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/20.
//

#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import "ACCEditVideoData.h"
#import <CameraClientModel/ACCVideoCanvasType.h>

@class NLEInterface_OC, NLEEditor_OC;

typedef NS_ENUM(NSUInteger, ACCMicrophoneBarState) {
    ACCMicrophoneBarStateHidden = 0,
    ACCMicrophoneBarStateSetOff,
    ACCMicrophoneBarStateSetOn,
};

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT const NSInteger kACCNLEVersionNone;
FOUNDATION_EXPORT const NSInteger kACCNLEVersion2;

@interface AWERepoVideoInfoModel : ACCRepoVideoInfoModel

// NLE 版本记录
@property (nonatomic, assign) NSInteger nleVersion;
@property (nonatomic, strong, readonly) ACCEditVideoData *video;
@property (nonatomic, assign) CGRect playerFrame; // 临时存储播放器大小

//是否是快速导入
@property (nonatomic, assign) BOOL isFastImportVideo;

@property (nonatomic, assign) ACCMicrophoneBarState microphoneBarState;//实际的麦克风开关 埋点与状态条件

@property (nonatomic, strong, nullable) NSData *fragmentInfoJson;

// new capture photo auto-save watermark image
@property (nonatomic, strong) UIImage *capturedPhotoWithWatermark;

@property (nonatomic, assign) NSInteger delay; // ms
@property (nonatomic, strong, readonly) IESMMVideoDataClipRange *delayRange; // used in edit page only;

@property (nonatomic, strong, nullable) NSNumber *hdVideoCount;

#pragma mark - only for draft
@property (nonatomic, copy) NSString *capturePhotoPath;
@property (nonatomic, copy) NSString *capturePhotoPathRelative;
@property (nonatomic, assign) ACCVideoCanvasType canvasType;
@property (nonatomic, strong) ACCVideoCanvasSource *canvasSource;
@property (nonatomic, assign) CGFloat canvasContentRatio; // canvas内容的高/宽的比值, 0表示非法值
/** 视频播放区域的四个顶点信息 */
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *videoTextureVertices;

@property (nonatomic, strong) NSNumber *enableCanvasGesture;
@property (nonatomic, assign) CGFloat videoFrameRatio;

#pragma mark - NLEEditor
@property (nonatomic, strong, readonly, nullable) NLEEditor_OC *nleEditor;

@property (nonatomic, assign) BOOL isDynamicRecorder;
// recorder lynx channel
@property (nonatomic, copy) NSString *lynxChannel;
@property (nonatomic, copy) NSString *dynamicActivityID;
@property (nonatomic, copy) NSDictionary *dynamicLynxData;
@property (nonatomic, copy) NSString *dynamicChallengeNames;
@property (nonatomic, copy) NSString *dynamicRecordSchema;
@property (nonatomic, assign) NSInteger dynamicAnimationEnable;
// 0 show publish end view, 1 not show
@property (nonatomic, assign) NSInteger dynamicPublishPageDisable;

- (BOOL)shouldAccommodateVideoDurationToMusicDuration;

- (NSString *)specializedCanvasPhotoExportSettings;

#pragma mark - Security

- (BOOL)isMultiVideoFastImport;

- (void)updateVideoData:(ACCEditVideoData *)videoData;

- (void)updateFragmentInfo;

- (void)updateFragmentInfoForce:(BOOL)force;

- (NSArray *)originalFrameNamesArray;

- (BOOL)hasStickers;

//==========================================================================================
// @description  Transform AVCaptureDevicePosition in each AWEVideoFragmentInfo into a
//               [@"front", @"back", @"front"]-like sequence
//               将 `ACCRecordInformationRepoModel` 中所有的 `AWEVideoFragmentInfo` 中的摄像头
//               位置信息转换为[@"front", @"back", @"front"]形式的字符串数组
//==========================================================================================
- (NSDictionary *)cameraDirectionInfoDic;

@end

@interface AWEVideoPublishViewModel (AWERepoVideoInfo)
 
@property (nonatomic, strong, readonly) AWERepoVideoInfoModel *repoVideoInfo;
 
@end

NS_ASSUME_NONNULL_END
