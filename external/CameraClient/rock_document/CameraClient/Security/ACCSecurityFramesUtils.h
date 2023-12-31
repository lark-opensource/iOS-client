//
//  ACCSecurityFramesUtils.h
//  AWEStudioService-Pods-Aweme
//
//  Created by lixingdong on 2021/4/13.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const ACCSecurityFramesErrorDomain;

NS_ERROR_ENUM(ACCSecurityFramesErrorDomain)
{
    ACCSecurityFramesErrorUnknown                       = -10000,
    ACCSecurityFramesErrorEmptySecurityFrames           = -10001,
    ACCSecurityFramesErrorEmptyFragmentInfo             = -10002,
    ACCSecurityFramesErrorInvalidAVASSetURL             = -10003,
    ACCSecurityFramesErrorInvalidAVASSet                = -10004,
    ACCSecurityFramesErrorInvalidImageAssetURL          = -10005,
    ACCSecurityFramesErrorInvalidImageAsset             = -10006,
    ACCSecurityFramesErrorInvalidFragment               = -10007,
};

typedef NS_ENUM(NSUInteger, ACCSecurityFrameType) {
    ACCSecurityFrameTypeUpload,     // 上传类视频帧
    ACCSecurityFrameTypeRecord,     // 录制类视频帧
    ACCSecurityFrameTypeTemplate,   // 模板类视频帧
    ACCSecurityFrameTypeProps,      // 录制页特殊道具、合拍带的资源帧
    ACCSecurityFrameTypeCustomSticker,  // 自定义贴纸帧
    ACCSecurityFrameTypeImageAlbum,     // 图集
    ACCSecurityFrameTypeAIRecommond,    // AI抽帧
};

@interface ACCSecurityExportModel : NSObject

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, assign) ACCSecurityFrameType frameType;
@property (nonatomic, assign) UIEdgeInsets insets;
@property (nonatomic, assign) CMTimeRange range;
@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, assign) UIImageOrientation orientation;

@end

@interface ACCSecurityFramesUtils : NSObject

+ (NSError *)errorWithErrorCode:(NSInteger)errorCode;

+ (void)showACCMonitorAlertWithErrorCode:(NSInteger)errorCode;

+ (NSTimeInterval)recordFramesInterval;
+ (NSTimeInterval)uploadFramesInterval;
+ (CGSize)framesResolution;
+ (CGSize)framesResolutionWithType:(ACCSecurityFrameType)type;
+ (CGSize)highHramesResolution;
+ (CGFloat)framesCompressionRatio;

@end

NS_ASSUME_NONNULL_END
