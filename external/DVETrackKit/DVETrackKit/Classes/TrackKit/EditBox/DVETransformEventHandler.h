//
//  DVEPanGestureHandler.h
//  TTVideoEditorDemo
//
//  created by bytedance on 2020/12/10.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVEEditTransform.h"
#import "DVEEditItem.h"
#import "DVEPinchControl.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVEHandlerDataSource <NSObject>

- (UIView *)canvasView;
- (CGPoint)boxCenterInCanvas;
- (DVEEditItem *)currentEditItem;

@end

@protocol DVEHandlerTransformDelegate <NSObject>

- (void)onTransformBegin:(nullable UIGestureRecognizer *)gesture;

- (void)onTransformChanged:(DVEEditItem *)item gesture:(nullable UIGestureRecognizer *)gesture;

- (void)onTransformEnd:(nullable UIGestureRecognizer *)gesture;

- (void)onTransformBeginPinchCtl;

- (void)onTransformEndPinchCtl;

@end

@protocol DVEHanlderAlignmentDelegate <NSObject>

- (void)onHorizontalAlignmentMagneting:(BOOL)mag;

- (void)onVerticalAlignmentMagneting:(BOOL)mag;

@end

@interface DVEHanlderBase : NSObject

@property (nonatomic, weak) id<DVEHandlerDataSource> dataSource;
@property (nonatomic, weak) id<DVEHandlerTransformDelegate> transformDelegate;
@property (nonatomic, weak) id<DVEHanlderAlignmentDelegate> alignDelegate;
@end

@interface DVEPanGestureHandler : DVEHanlderBase

- (void)handlePanGesture:(UIPanGestureRecognizer *)pan;

@end

@interface DVEScaleRotateHandler : DVEHanlderBase

- (void)pinchControlBeginAction:(DVEPinchControl *)pinch;

- (void)pinchControlEndAction:(DVEPinchControl *)pinch;

- (void)pinchControlValueChanged:(DVEPinchControl *)pinch;

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinch;

- (void)handleRotateGesture:(UIRotationGestureRecognizer *)rotation;

@end

NS_ASSUME_NONNULL_END
