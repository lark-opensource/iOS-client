//
//  DVEEditBoxView.h
//  TTVideoEditorDemo
//
//  created by bytedance on 2020/12/8.
//  Copyright © 2020 bytedance. All rights reserved.
//
//  四周有按钮的编辑区
#import <UIKit/UIKit.h>
#import "DVEEditTransform.h"
#import "DVEEditItem.h"
#import "DVEEditBoxCornerInfo.h"
#import "DVETransformEventHandler.h"

NS_ASSUME_NONNULL_BEGIN


@interface DVEEditBoxConfig : NSObject

@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic) CGPoint contentEdge;   // 加上贴纸大小决定了BoxView的大小
@property (nonatomic) CGFloat boxMargin;     // 加上BoxView大小决定了线的位置，也就是按钮的中心

@property (nonatomic) CGFloat controlSize;
@property (nonatomic) CGFloat pinchExpand;

@property (nonatomic) DVEEditBoxCornerInfo *topLeft;
@property (nonatomic) DVEEditBoxCornerInfo *topRight;
@property (nonatomic) DVEEditBoxCornerInfo *bottomLeft;
@property (nonatomic) DVEEditBoxCornerInfo *bottomRight;

@end

@protocol DVEEditBoxViewDelegate;

@interface DVEEditBoxView : UIView<DVEHandlerDataSource>

- (void)handlePanGesture:(UIPanGestureRecognizer *)pan;

- (void)handlePinch:(UIPinchGestureRecognizer *)pinch;

- (void)handleRotateGesture:(UIRotationGestureRecognizer *)rotate;

- (void)update:(DVEEditItem *)item;

- (instancetype)initWithConfig:(nullable DVEEditBoxConfig *)config NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) id<DVEEditBoxViewDelegate> delegate;

@end

@protocol DVEEditBoxViewDelegate <DVEHanlderAlignmentDelegate>

- (void)onActionTrigger:(DVEEditItem *)item behavior:(DVEEditCornerType)type;

- (void)onTrasnformBegin:(DVEEditItem *)item gesture:(UIGestureRecognizer *)gesture;

- (void)onTransformUpdate:(DVEEditItem *)item gesture:(UIGestureRecognizer *)gesture;

- (void)onTransformEnd:(DVEEditItem *)item gesture:(UIGestureRecognizer *)gesture;

- (void)onDoubleTapBoxView:(DVEEditItem *)item tapGestureRecognizer:(UITapGestureRecognizer *)tap;

- (void)onTapBoxView:(DVEEditItem *)item tapGestureRecognizer:(UITapGestureRecognizer *)tapp;

@end

NS_ASSUME_NONNULL_END
