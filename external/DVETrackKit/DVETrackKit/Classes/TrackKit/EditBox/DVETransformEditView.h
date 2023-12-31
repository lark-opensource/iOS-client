//
//  DVETransformEditView.h
//  TTVideoEditorDemo
//
//  created by bytedance on 2020/12/8.
//  Copyright © 2020 bytedance. All rights reserved.
//
//  覆盖整个预览区的编辑区域
#import <UIKit/UIKit.h>
#import "DVEEditBoxView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVETransformEditViewDelegate;

@interface DVETransformEditViewConfig : NSObject

@property (nonatomic, strong) DVEEditBoxConfig *boxConfig;

@property (nonatomic) CGFloat hAlignLineMargin;
@property (nonatomic) CGFloat vAlignLineMargin;

@property (nonatomic) CGFloat hAlignLineWidth;
@property (nonatomic) CGFloat vAlignLineHeight;

@property (nonatomic) CGFloat hAlignLineLength;
@property (nonatomic) CGFloat vAlignLineLength;

@property (nonatomic) UIColor *alignLineColor;

@end

@interface DVETransformEditView : UIView <DVEEditBoxViewDelegate>

- (instancetype)initWithConfig:(nullable DVETransformEditViewConfig *)config;

@property (nonatomic, weak) id<DVETransformEditViewDelegate> delegate;

@property (nonatomic, strong, readonly) DVEEditBoxView *editBox;

- (NSInteger)numberOfItems;

- (void)addEditItems:(NSArray<DVEEditItem *> *)items;

- (void)removeAllEditItems;

- (void)removeEditItems:(NSArray<NSString *> *)resourceIds;

- (void)activeEditItem:(nullable NSString *)resourceId;

- (void)updateEditItems:(void (^)(NSArray<DVEEditItem *> *))updater;

- (void)updateEditItem:(NSString *)resourceId updater:(void (^)(DVEEditItem *))updater;

- (NSArray<DVEEditItem *> *)editItemHitWithPoint:(CGPoint)point;

- (NSArray<DVEEditItem *> *)editItemsInEditView;

#pragma mark - Handle Gesture

- (void)tapOnCanvas:(UITapGestureRecognizer *)tap;

- (void)doubleTapOnCanvas:(UITapGestureRecognizer *)tap;

- (void)handlePanGesture:(UIPanGestureRecognizer *)pan;

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinch;

- (void)handleRotateGesture:(UIRotationGestureRecognizer *)rotate;

@end

@protocol DVETransformEditViewDelegate <NSObject>

- (void)transformView:(DVETransformEditView *)editView didTriggerAction:(DVEEditCornerType)type item:(DVEEditItem *)item;

- (void)transformView:(DVETransformEditView *)editView didTapBoxView:(nullable UITapGestureRecognizer *)tap item:(nullable DVEEditItem *)item;
/// 点击虚线框
- (void)transformView:(DVETransformEditView *)editView didTapBorderView:(nullable DVEEditItem *)item;

- (void)transformView:(DVETransformEditView *)editView didDoubleTapBoxView:(UITapGestureRecognizer *)tap item:(nullable DVEEditItem *)item;

- (void)transformView:(DVETransformEditView *)editView beginTransform:(DVEEditItem *)item;

- (void)transformView:(DVETransformEditView *)editView didUpdateTransform:(DVEEditItem *)item;

- (void)transformView:(DVETransformEditView *)editView endTransform:(DVEEditItem *)item;

- (void)transformView:(DVETransformEditView *)editView outTapBoxView:(UITapGestureRecognizer *)tap;

@end

NS_ASSUME_NONNULL_END
