//
//  ACCStickerContainerPluginProtocol.h
//  CameraClient
//
//  Created by guocheng on 2020/5/28.
//

#import "ACCStickerProtocol.h"
#import "ACCBaseStickerView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerContainerProtocol, ACCStickerEventFlowProtocol;

@protocol ACCStickerCoordinatesModifiabilityProtocol <NSObject>

- (CGPoint)fixOperatingStickerView:(ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)stickerView withWillChangeLocationWithCenter:(CGPoint)newCenter;

@end

@protocol ACCStickerContainerPluginProtocol <NSObject>

- (BOOL)featureSupportSticker:(id<ACCStickerProtocol>)sticker;

+ (instancetype)createPlugin;
- (void)loadPlugin;

@property (nonatomic, weak) UIView<ACCStickerContainerProtocol, ACCStickerEventFlowProtocol> *stickerContainer;
- (void)playerFrameChange:(CGRect)playerFrame;

@optional
- (UIView *)pluginView;

@end

@protocol ACCStickerGestureResponsiblePluginProtocol <ACCStickerContainerPluginProtocol>

// all methods callback within a gesture's life cycle
- (void)didChangeLocationWithOperationStickerView:(ACCBaseStickerView *)stickerView;
- (void)sticker:(ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)stickerView willHandleGesture:(UIGestureRecognizer *)gesture;
- (void)sticker:(ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)stickerView didHandleGesture:(UIGestureRecognizer *)gesture;
- (void)sticker:(ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)stickerView didEndGesture:(UIGestureRecognizer *)gesture;

@end

/// Before Gesture Enters Sticker Field
@protocol ACCStickerOverAheadGesturePluginProtocol <ACCStickerContainerPluginProtocol>

- (void)stickerContainer:(UIView<ACCStickerContainerProtocol> *)container beforeRecognizerGesture:(UIGestureRecognizer *)gesture;

@end

NS_ASSUME_NONNULL_END
