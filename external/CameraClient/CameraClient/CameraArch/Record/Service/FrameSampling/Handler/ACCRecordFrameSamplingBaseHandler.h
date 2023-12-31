//
//  ACCRecordFrameSamplingBaseHandler.h
//  AAWELaunchOptimization
//
//  Created by limeng on 2020/5/11.
//

#import <Foundation/Foundation.h>
#import "ACCRecordFrameSamplingServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 具体抽帧逻辑处理的抽象基类
@interface ACCRecordFrameSamplingBaseHandler : NSObject <ACCRecordFrameSamplingHandlerProtocol, ACCEffectEvent>

/// 发布数据模型
@property (nonatomic, weak, readonly, nullable) AWEVideoPublishViewModel *publishModel;

/// 当前应用的道具
@property (nonatomic, weak, readonly, nullable) IESEffectModel *currentSticker;

/// 当前封面
@property (nonatomic, weak, readonly, nullable) UIImage *faceImage;

// 抽帧前的准备工作
- (void)prepareToSampleFrame NS_REQUIRES_SUPER;

/// 第一次抽取帧画面，在定时抽帧之前
- (void)firstSampling;

/// 开启定时抽帧
- (void)timedSampling;

/// 抽帧完成。
/// @note 有需要时，子类重写定制
- (void)samplingCompleted;

/// 具体抽帧的方法
- (void)sampleFrame NS_REQUIRES_SUPER;

/// pixloop拍摄抽帧的方法
- (void)sampleFrameForPixloop NS_REQUIRES_SUPER;

/// 预处理抽取的帧图像
/// @param rawImage 未处理帧
- (UIImage  * _Nullable )preprocessFrame:(UIImage * __nullable)rawImage;

/// 保存抽帧图片
/// @param processedImage 抽帧的图片
- (void)addFrameIfNeed:(UIImage * __nullable)processedImage;

/// 是否需要处理后的图片
/// @note ⚠️ 这里的处理指camera内部对图片的处理，不是抽帧时的图片处理任务
- (BOOL)needAfterProcess;

/// 是否处理当前相机的视频流
/// @param samplingContext 抽帧服务上下文
- (BOOL)shouldHandle:(id<ACCRecordFrameSamplingServiceProtocol>)samplingContext NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
