//
//  ACCRecordFlowComponent.h
//  Pods
//
//  Created by songxiangwu on 2019/8/2.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCFeatureComponent.h>
#import "AWECaptureButtonAnimationView.h"
#import "ACCRecordFlowService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import "ACCRecordConfigService.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCGroupedPredicate;

@interface ACCRecordFlowComponent : ACCFeatureComponent <
AWECaptureButtonAnimationViewDelegate,
ACCRecordFlowServiceSubscriber,
ACCRecordSwitchModeServiceSubscriber,
ACCRecordConfigDurationHandler>

@property (nonatomic, strong, readonly) UIButton *recordButton;
@property (nonatomic, strong, readonly) UIView<ACCCaptureButtonAnimationProtocol> *captureButtonAnimationView;
@property (nonatomic, strong, readonly) ACCGroupedPredicate<id, id> *shouldShowCaptureAnimationView;

#pragma mark - Method to Override

- (void)updateStandardDurationIndicatorDisplay NS_REQUIRES_SUPER;
- (void)updateProgressAndMarksDisplay NS_REQUIRES_SUPER;
- (void)showRecordButtonIfShould:(BOOL)show animated:(BOOL)animated;

- (UIView<ACCCaptureButtonAnimationProtocol> *)buildCaptureButton;


/// 当前是否开启音量键拍摄功能
/// enable volume to shoot
@property (nonatomic, assign) BOOL enableVolumeToShoot;
/// 是否开启点击拍照
/// enable tap to take photo
@property (nonatomic, assign) BOOL enableTapToTakePhoto;
#pragma mark 开启音量键拍摄功能
- (void)openVolumnButtonTriggersTheShoot;
#pragma mark 关闭音量键拍摄功能

/// 当前模式支持音量键才关闭
- (void)closeVolumnButtonTriggersTheShoot;
/// 强制关闭
- (void)closeVolumnButtonTriggersTheShootForce;

@end

NS_ASSUME_NONNULL_END
