//
//  ACCStickerConfig.h
//  CameraClient
//
//  Created by guocheng on 2020/6/2.
//

#import "ACCStickerDefines.h"
#import "ACCStickerBubbleConfig.h"
#import "ACCStickerGeometryModel.h"
#import "ACCStickerTimeRangeModel.h"
#import "ACCStickerBubbleProtocol.h"
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerProtocol, ACCGestureResponsibleStickerProtocol;
@class ACCBaseStickerView;

@interface ACCStickerConfig : MTLModel

@property (nonatomic, strong) id typeId;

@property (nonatomic, strong) id hierarchyId;

@property (nonatomic, strong) NSNumber *groupId; //fix me

/*
 * @brief If not set, sticker will support all gesture type.
 */
@property (nonatomic, copy, nullable) BOOL (^supportGesture)(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer);
/*
 * default is 0.5
 */
@property (nonatomic, assign) CGFloat minimumScale;

/*
* default is CGFloat_MAX
*/
@property (nonatomic, assign) CGFloat maximumScale;

@property (nonatomic, strong, class, readonly, nullable) Class <ACCStickerBubbleProtocol> bubbleClass;

@property (nonatomic, strong, nullable) ACCStickerGeometryModel *geometryModel;

@property (nonatomic, strong, null_resettable) ACCStickerTimeRangeModel *timeRangeModel;

@property (nonatomic, copy, nullable) void (^secondTapCallback)(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *contentView, UITapGestureRecognizer *gesture);
@property (nonatomic, copy, nullable) void (^onceTapCallback)(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *contentView, UITapGestureRecognizer *gesture);

@property (nonatomic, copy, nullable) BOOL (^gestureCanStartCallback)(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *contentView, UIGestureRecognizer *gesture);

@property (nonatomic, copy, nullable) void (^gestureEndCallback)(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *contentView, UIGestureRecognizer *gesture);

@property (nonatomic, copy, nullable) void (^locationDidChangedCallback)(ACCStickerGeometryModel *geometryModel);

@property (nonatomic, copy, nullable) NSArray <ACCStickerBubbleConfig *> *bubbleActionList;

@property (nonatomic, copy) void (^willDeleteCallback)(void);
@property (nonatomic, copy) void (^didDeleteCallback)(void);

@property (nonatomic, assign) BOOL showSelectedHint; // default is YES; currently in Arch, will move out in the future

@property (nonatomic, assign) UIEdgeInsets boxPadding;

@property (nonatomic, assign) UIEdgeInsets boxMargin;

@property (nonatomic, assign) BOOL changeAnchorForRotateAndScale;

@property (nonatomic, copy) void (^didChangedTimeRange)(__kindof ACCBaseStickerView *stickerView);

/* Defines the align point of the sticker's bounds rect, as a point in
 * normalized coordinates - '(0, 0)' is the top left corner of
 * the bounds rect, '(1, 1)' is the bottom right corner. */
@property (nonatomic, strong, nullable) NSValue *alignPoint;

/* Defines the align position of the sticker's frame rect,
 * as a point in container's coordinates. If not set, sticker
 * will be self-aligned according to alignPoint.
 */
@property (nonatomic, strong, nullable) NSValue *alignPosition;

@end

@interface ACCStickerConfig (External)

@property (nonatomic, copy) void (^externalHandlePanGestureAction)(__kindof UIView<ACCStickerProtocol> *theView, CGPoint point);

@property (nonatomic, copy) void (^externalHandlePinchGestureeAction)(__kindof UIView<ACCStickerProtocol> *theView, CGFloat scale);

@property (nonatomic, copy) void (^externalHandleRotationGestureAction)(__kindof UIView<ACCStickerProtocol> *theView, CGFloat rotation);

@property (nonatomic, copy) void (^externalEndGestureAction)(__kindof UIView<ACCStickerProtocol> *theView, UIGestureRecognizer *gesture);

@end

NS_ASSUME_NONNULL_END
