//
//  TTVideoEngineVRModel.m
//  TTVideoEngine
//
//  Created by shen chen on 2022/7/27.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineVRModel.h"

int const kTTVideoEngineVideoProcessingProcessorActionInitEffect = 0;
int const kTTVideoEngineVideoProcessingProcessorActionUseEffect = 2;
int const kTTVideoEngineVideoProcessingProcessorActionVRConfiguration = 11;
int const kTTVideoEngineVideoProcessingProcessorActionVRRecenter = 12;

int const kTTVideoEngineVideoProcessingProcessorEffectTypeVR = 7;

NSString * const kTTVideoEngineVideoProcessingProcessorAction = @"kProcessorAction";
NSString * const kTTVideoEngineVideoProcessingProcessorVROutputTextureWidth = @"kProcessorVROutputTextureWidth";
NSString * const kTTVideoEngineVideoProcessingProcessorVROutputTextureHeight = @"kProcessorVROutputTextureHeight";
NSString * const kTTVideoEngineVideoProcessingProcessorVRHeadTrackingEnabled = @"kProcessorVRHeadTrackingEnabled";
NSString * const kTTVideoEngineVideoProcessingProcessorVRScopicType = @"kProcessorVRScopicType";
NSString * const kTTVideoEngineVideoProcessingProcessorVRRotationPitch = @"kProcessorVRRotationPitch";
NSString * const kTTVideoEngineVideoProcessingProcessorVRRotationYaw = @"kProcessorVRRotationYaw";
NSString * const kTTVideoEngineVideoProcessingProcessorVRRotationRoll = @"kProcessorVRRotationRoll";
NSString * const kTTVideoEngineVideoProcessingProcessorVRZoom = @"kProcessorVRZoom";
NSString * const kTTVideoEngineVideoProcessingProcessorEffectType = @"kProcessorEffectType";
NSString * const kTTVideoEngineVideoProcessingProcessorUseEffect = @"kProcessorUseEffect";
NSString * const kTTVideoEngineVideoProcessingProcessorIntValue = @"kProcessorIntValue";
NSString * const kTTVideoEngineEnableVRMode = @"kProcessEnableVRMode";
NSString * const kTTVideoEngineVideoProcessingProcessorVRContentType = @"ContentType";
NSString * const kTTVideoEngineVideoProcessingProcessorVRFOVType = @"FOV";

NSString * const kTTVideoEngineVideoProcessingProcessorHeadPoseDidUpdateNotification = @"VideoProcessorVRHeadPoseDidUpdateNotification";
NSString * const kTTVideoEngineVideoProcessingProcessorHeadPoseOrientationQuaternionX = @"VideoProcessorVRHeadPoseOrientationQuaternionX";
NSString * const kTTVideoEngineVideoProcessingProcessorHeadPoseOrientationQuaternionY = @"VideoProcessorVRHeadPoseOrientationQuaternionY";
NSString * const kTTVideoEngineVideoProcessingProcessorHeadPoseOrientationQuaternionZ = @"VideoProcessorVRHeadPoseOrientationQuaternionZ";
NSString * const kTTVideoEngineVideoProcessingProcessorHeadPoseOrientationQuaternionW = @"VideoProcessorVRHeadPoseOrientationQuaternionW";
NSString * const kTTVideoEngineVideoProcessingProcessorHeadPosePositionX = @"VideoProcessorVRHeadPosePositionX";
NSString * const kTTVideoEngineVideoProcessingProcessorHeadPosePositionY = @"VideoProcessorVRHeadPosePositionY";
NSString * const kTTVideoEngineVideoProcessingProcessorHeadPosePositionZ = @"VideoProcessorVRHeadPosePositionZ";

NSString * const kTTVideoEngineVideoProcessingProcessorVREnableVsyncHelper = @"kTTVideoEngineVideoProcessingProcessorVREnableVsyncHelper";
NSString * const kTTVideoEngineVideoProcessingProcessorVRCustomizedVideoRenderingFrameRate = @"kTTVideoEngineVideoProcessingProcessorVRCustomizedVideoRenderingFrameRate";


