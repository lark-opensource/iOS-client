//
//  ACCStickerProtocol.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/8.
//

#import "ACCStickerConfig.h"
#import "ACCStickerContentProtocol.h"
#import "ACCStickerContainerProtocol.h"
#import "ACCPlaybackResponsibleProtocol.h"
#import "ACCStickerSelectTimeRangeProtocol.h"
#import "ACCStickerTimeRangeModel.h"
#import "ACCStickerGeometryModel.h"

NS_ASSUME_NONNULL_BEGIN

// this will a business protocol combined with ACCStickerProtocol in the future
@protocol ACCSelectTimeRangeStickerProtocol <ACCPlaybackResponsibleProtocol, ACCStickerSelectTimeRangeProtocol>

@property (nonatomic, strong, readonly) ACCStickerTimeRangeModel *stickerTimeRange;
- (void)recoverWithTimeRangeModel:(ACCStickerTimeRangeModel *)timeRangeModel;

@end

///

@class ACCStickerGroupView;
@protocol ACCStickerProtocol <ACCSelectTimeRangeStickerProtocol>

@property (nonatomic, weak) id <ACCStickerContainerProtocol> stickerContainer;
@property (nonatomic, strong, readonly) NSNumber *groupId;
@property (nonatomic, strong, readonly) UIView *selectedHintView;

- (UIView<ACCStickerContentProtocol> *)contentView;
- (__kindof ACCStickerConfig *)config;

- (instancetype)initWithContentView:(UIView <ACCStickerContentProtocol> *)contentView config:(__kindof ACCStickerConfig *)config;

#pragma mark - Geometry
@property (nonatomic, strong, readonly) ACCStickerGeometryModel *stickerGeometry;
- (void)recoverWithGeometryModel:(ACCStickerGeometryModel *)geometryModel;
- (nullable ACCStickerGeometryModel *)interactiveStickerGeometryWithCenterInPlayer:(CGPoint)center interactiveBoundsSize:(CGSize)size;

@end

///

typedef NS_OPTIONS(NSInteger, ACCStickerGestureState) {
    ACCStickerGestureStateNone = 0,
    ACCStickerGestureStateTap = 1 << 0,
    ACCStickerGestureStatePan = 1 << 1,
    ACCStickerGestureStatePinch = 1 << 2,
    ACCStickerGestureStateRotate = 1 << 3
};

@protocol ACCGestureResponsibleStickerProtocol <ACCStickerProtocol>

@property (nonatomic, assign) CGFloat currentScale;
@property (nonatomic, assign) ACCStickerGestureState gestureActiveState;

- (BOOL)willGestureStart:(UIGestureRecognizer *)gesture;

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture;
- (CGPoint)panGestureLocatedPoint:(UIPanGestureRecognizer *)gesture;
- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture withNewCenter:(CGPoint)point;
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gesture;
- (void)handleRotationGesture:(UIRotationGestureRecognizer *)gesture;

- (void)endGesture:(UIGestureRecognizer *)gesture;

- (BOOL)supportGesture:(UIGestureRecognizer *)gesture;

@end

NS_ASSUME_NONNULL_END
