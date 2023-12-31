//
//  TTVideoEngineVRModel.h
//  TTVideoEngine
//
//  Created by shen chen on 2022/7/26.
//

#ifndef ttvideoengine_model_h
#define ttvideoengine_model_h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern int const kTTVideoEngineVideoProcessingProcessorActionInitEffect;
extern int const kTTVideoEngineVideoProcessingProcessorActionUseEffect;
extern int const kTTVideoEngineVideoProcessingProcessorActionVRConfiguration;
extern int const kTTVideoEngineVideoProcessingProcessorActionVRRecenter;

extern int const kTTVideoEngineVideoProcessingProcessorEffectTypeVR;

extern NSString * const kTTVideoEngineVideoProcessingProcessorAction;
extern NSString * const kTTVideoEngineVideoProcessingProcessorVROutputTextureWidth;
extern NSString * const kTTVideoEngineVideoProcessingProcessorVROutputTextureHeight;
extern NSString * const kTTVideoEngineVideoProcessingProcessorVRHeadTrackingEnabled;
extern NSString * const kTTVideoEngineVideoProcessingProcessorVRScopicType;
extern NSString * const kTTVideoEngineVideoProcessingProcessorVRRotationPitch;
extern NSString * const kTTVideoEngineVideoProcessingProcessorVRRotationYaw;
extern NSString * const kTTVideoEngineVideoProcessingProcessorVRRotationRoll;
extern NSString * const kTTVideoEngineVideoProcessingProcessorVRZoom;
extern NSString * const kTTVideoEngineVideoProcessingProcessorEffectType;
extern NSString * const kTTVideoEngineVideoProcessingProcessorUseEffect;
extern NSString * const kTTVideoEngineVideoProcessingProcessorIntValue;
extern NSString * const kTTVideoEngineEnableVRMode;
extern NSString * const kTTVideoEngineVideoProcessingProcessorVRContentType;
extern NSString * const kTTVideoEngineVideoProcessingProcessorVRFOVType;

extern NSString * const kTTVideoEngineVideoProcessingProcessorHeadPoseDidUpdateNotification;
extern NSString * const kTTVideoEngineVideoProcessingProcessorHeadPoseOrientationQuaternionX;
extern NSString * const kTTVideoEngineVideoProcessingProcessorHeadPoseOrientationQuaternionY;
extern NSString * const kTTVideoEngineVideoProcessingProcessorHeadPoseOrientationQuaternionZ;
extern NSString * const kTTVideoEngineVideoProcessingProcessorHeadPoseOrientationQuaternionW;
extern NSString * const kTTVideoEngineVideoProcessingProcessorHeadPosePositionX;
extern NSString * const kTTVideoEngineVideoProcessingProcessorHeadPosePositionY;
extern NSString * const kTTVideoEngineVideoProcessingProcessorHeadPosePositionZ;

extern NSString * const kTTVideoEngineVideoProcessingProcessorVREnableVsyncHelper;
extern NSString * const kTTVideoEngineVideoProcessingProcessorVRCustomizedVideoRenderingFrameRate;


typedef NS_ENUM(NSInteger, TTVideoEngineVRScopicType) {
    TTVideoEngineVRScopicTypeUnknow = -1,
    TTVideoEngineVRScopicTypeMono   = 0,
    TTVideoEngineVRScopicTypeStereo = 1,
};

typedef NS_ENUM(NSInteger, TTVideoEngineVROption) {
    TTVideoEnginePlayerOptionEnableVsyncHelper = 0,
    TTVideoEnginePlayerOptionCustomizedVideoRenderingFrameRate = 1,
};

typedef NS_ENUM(NSInteger, TTVideoEngineVRContentType) {
    TTVideoEngineVRContentTypePano_2D,
    TTVideoEngineVRContentTypeSideBySide_3D,   // for 180 degrees video mostly
    TTVideoEngineVRContentTypeTopAndBottom_3D, // for 360 degrees video mostly
};

typedef NS_ENUM(NSInteger, TTVideoEngineVRFOV) {
    TTVideoEngineVRFOV_180,
    TTVideoEngineVRFOV_360,
};

NS_ASSUME_NONNULL_END
#endif

