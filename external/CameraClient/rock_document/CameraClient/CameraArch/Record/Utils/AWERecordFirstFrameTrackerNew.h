//
//  AWERecordFirstFrameTrackerNew.h
//  CameraClient-Pods-Aweme
//
//  Created by Liyingpeng on 2021/7/19.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCToolPerformanceTrakcer.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const kAWERecordEventFirstFrame;
FOUNDATION_EXTERN NSString * const kAWERecordEventUserInteractiveEnableDuration;
FOUNDATION_EXTERN NSString * const kAWERecordEventPreControlerInit;
FOUNDATION_EXTERN NSString * const kAWERecordEventControlerInit;
FOUNDATION_EXTERN NSString * const kAWERecordEventViewLoad;
FOUNDATION_EXTERN NSString * const kAWERecordEventViewDidLoad;
FOUNDATION_EXTERN NSString * const kAWERecordEventViewWillAppear;
FOUNDATION_EXTERN NSString * const kAWERecordEventViewAppear;
FOUNDATION_EXTERN NSString * const kAWERecordEventCameraCreate;
FOUNDATION_EXTERN NSString * const kAWERecordEventPostCameraCreate;
FOUNDATION_EXTERN NSString * const kAWERecordEventEffectFirstFrame;
FOUNDATION_EXTERN NSString * const kAWERecordEventCameraCaptureFirstFrame;
FOUNDATION_EXTERN NSString * const kAWERecordEventStartCameraCapture;

typedef NS_ENUM(NSUInteger, AWERecordFirstFrameTrackError) {
    AWERecordFirstFrameTrackErrorNone = 0,
    AWERecordFirstFrameTrackErrorClickBack, // 首帧没出来就点击返回
    AWERecordFirstFrameTrackErrorEnterBackground, // 首帧没出来就退后台
    AWERecordFirstFrameTrackErrorDisappear, // 首帧没出来就跳转页面
    AWERecordFirstFrameTrackErrorDuplicated, // 首帧没出来就收到了新的重复首帧
    AWERecordFirstFrameTrackErrorExit // 首帧没出来就异常退出了 OOM、Crash、杀进程
};

@interface AWERecordFirstFrameTrackerNew : ACCToolPerformanceTrakcer

@property (nonatomic, assign) BOOL forceLoadComponent;  //是否强制加载了组件

+ (instancetype)sharedTracker;
- (void)finishTrackWithInputData:(ACCRecordViewControllerInputData *)inputData;
- (void)finishTrackWithInputData:(ACCRecordViewControllerInputData *)inputData errorCode:(AWERecordFirstFrameTrackError)errorCode;

@end

NS_ASSUME_NONNULL_END
