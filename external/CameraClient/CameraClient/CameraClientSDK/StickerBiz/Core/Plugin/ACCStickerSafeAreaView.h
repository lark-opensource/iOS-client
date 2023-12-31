//
//  ACCStickerSafeAreaView.h
//  CameraClient
//
//  Created by guocheng on 2020/5/26.
//

#import <CreativeKitSticker/ACCStickerContainerPluginProtocol.h>

FOUNDATION_EXTERN CGFloat const ACCStickerContainerSafeAreaLineWidth;

@interface ACCStickerSafeAreaView : UIView <ACCStickerGestureResponsiblePluginProtocol, ACCStickerCoordinatesModifiabilityProtocol>

@property (nonatomic, strong, nullable, readonly) UIView *leftGuideLine;
@property (nonatomic, strong, nullable, readonly) UIView *rightGuideLine;
@property (nonatomic, strong, nullable, readonly) UIView *bottomGuideLine;
@property (nonatomic, strong, nullable, readonly) UIView *topGuideLine;

- (CGPoint)fixStickerView:(nonnull UIView *)stickerView withWillChangeLocationWithCenter:(CGPoint)newCenter;

@end
