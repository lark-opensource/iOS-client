//
//  ACCRecordFrameSamplingServiceProtocol.h
//  AAWELaunchOptimization
//
//  Created by limeng on 2020/5/11.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/VERecorder.h>
#import <pthread/pthread.h>
#import <CreationKitRTProtocol/ACCCameraService.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;
@class IESEffectModel;
@protocol ACCRecordFrameSamplingServiceProtocol;
@protocol ACCRecordFrameSamplingHandlerProtocol;

typedef void(^ACCRecordFrameSamplingCompletionObserver)(id<ACCRecordFrameSamplingServiceProtocol> service, id<ACCRecordFrameSamplingHandlerProtocol> handler, NSArray<NSString *> *samplingFrames);

/// 抽帧服务
@protocol ACCRecordFrameSamplingServiceProtocol <NSObject>

/// 发布数据模型
@property (nonatomic, weak, readonly, nullable) AWEVideoPublishViewModel *publishModel;

/// 当前应用的道具
@property (nonatomic, weak, readonly, nullable) IESEffectModel *currentSticker;

/// 绿幕道具背景照片（单图）
@property (nonatomic, strong, nullable) UIImage *bgPhoto;

/// 绿幕道具背景照片（多图）
@property (nonatomic, copy, nullable) NSArray<UIImage *> *bgPhotos;

/// selected images for multi-assets pixaloop prop
@property (nonatomic, copy, nullable) NSArray<UIImage *> *multiAssetsPixaloopSelectedImages;

/// 当前抽帧间隔
@property (nonatomic, assign, readonly) NSTimeInterval timeInterval;

/// 配置cameraService、samplingContext
- (void)configCameraService:(id<ACCCameraService>)cameraService;

/// 抽帧开启
/// @param timeInterval 抽帧间隔
- (void)startWithCameraService:(id<ACCCameraService>)cameraService timeInterval:(NSTimeInterval)timeInterval;

/// 手动添加抽帧，若未先start则忽略调用
/// @note 一般情况下start/stop即可，此方法仅用于特定情况下需要手动补帧的场景
- (void)sampleFrame;

/// 停止抽帧服务
- (void)stop;

/// 清空抽帧数据
- (void)removeAllFrames;

- (void)addCompletionObserver:(ACCRecordFrameSamplingCompletionObserver)observer;

- (void)removeCompletionObserver:(ACCRecordFrameSamplingCompletionObserver)observer;

- (void)removeAllCompletionObservers;

- (void)updatePublishModel:(AWEVideoPublishViewModel * __nullable)publishModel;

- (void)updateCurrentSticker:(IESEffectModel * __nullable)currentSticker;

- (void)saveBgPhotosForTakePicture;

@end

@protocol ACCRecordFrameSamplingHandlerDelegate <NSObject>

@optional
- (void)samplingCompleted:(id<ACCRecordFrameSamplingHandlerProtocol>)handler samplingFrames:(NSArray<NSString *> *)samplingFrames;

@end

/// 具体抽帧逻辑处理协议
@protocol ACCRecordFrameSamplingHandlerProtocol <NSObject>

/// 抽帧服务上下文
@property (nonatomic, weak, readonly) id<ACCRecordFrameSamplingServiceProtocol> frameSamplingContext;

/// 当前使用的相机
@property (nonatomic, weak, readonly) id<ACCCameraService> cameraService;

/// 当前抽帧间隔
@property (nonatomic, assign, readonly) NSTimeInterval timeInterval;

/// 是否正在抽帧
@property (nonatomic, assign, readonly, getter=isRunning) BOOL running;

/// 代理
@property (nonatomic, weak) id<ACCRecordFrameSamplingHandlerDelegate> delegate;

/// 是否处理当前相机的视频流
/// @param samplingContext 抽帧服务上下文
- (BOOL)shouldHandle:(id<ACCRecordFrameSamplingServiceProtocol>)samplingContext;

/// 配置cameraService、samplingContext
- (void)configCameraService:(id<ACCCameraService>)cameraService samplingContext:(id<ACCRecordFrameSamplingServiceProtocol>)samplingContext;

/// 抽帧开启
/// @param timeInterval 抽帧间隔
- (void)startWithCameraService:(id<ACCCameraService>)cameraService timeInterval:(NSTimeInterval)timeInterval;

/// 手动添加抽帧，若未先start则忽略调用
/// @note 一般情况下start/stop即可，此方法仅用于特定情况下需要手动补帧的场景
- (void)sampleFrame;

/// 停止抽帧处理
- (void)stop;

/// 清空抽帧数据
- (void)removeAllFrames;

/// 达到阈值就清理一半抽帧数据
- (void)reduceSamplingFramesByThreshold:(NSUInteger)threshold;

/// 抽帧数据集合
- (NSMutableArray<NSString *> *)mutableSamplingFrames;

/// 抽帧数据集合
- (NSArray<NSString *> *)immutableSamplingFrames;

/// 为拍照保存背景图片帧（拍照会导致prepareToSampleFrame保存的bgPhotos失效）
- (void)saveBgPhotosForTakePicture;

@end

NS_ASSUME_NONNULL_END
