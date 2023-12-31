//
//  ACCEditStickerSelectTimeManager.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/1/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class ACCStickerContainerView, AWEVideoPublishViewModel;

@protocol ACCEditServiceProtocol,
ACCStickerPlayerApplying,
ACCEditTransitionServiceProtocol,
ACCStickerProtocol,
ACCStickerContainerProtocol;

// SelectTime 逻辑聚合
@interface ACCEditStickerSelectTimeManager : NSObject

@property (nonatomic, strong, readonly) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong, readonly) AWEVideoPublishViewModel *repository;
@property (nonatomic, strong, readonly) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, strong, readonly) id<ACCStickerPlayerApplying> player;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithEditService:(id<ACCEditServiceProtocol>)editService
                         repository:(AWEVideoPublishViewModel *)repository
                             player:(id<ACCStickerPlayerApplying>)player
                   stickerContainer:(ACCStickerContainerView *)stickerContainer
                  transitionService:(id<ACCEditTransitionServiceProtocol>)transitionService;

- (void)modernEditStickerDuration:(UIView<ACCStickerProtocol> *)stickerView;

- (void)recoveryInfoStickerChanges:(UIView<ACCStickerContainerProtocol> *)stickerContainer
                   originPinStatus:(NSDictionary<NSNumber *, NSNumber *> *)originPinStatus;

- (NSDictionary<NSNumber *, NSNumber *> *)backupStickerInfosPinStatus;

@end

NS_ASSUME_NONNULL_END
