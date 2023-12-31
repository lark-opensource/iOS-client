//
//  BDXLynxTabbarView.h
//  BDXElement
//
//  Created by bytedance on 2020/11/30.
//

#import <Lynx/LynxUI.h>
#import "BDXLynxTabbarItemView.h"

NS_ASSUME_NONNULL_BEGIN
@class BDXTabbarView;

@protocol BDXTabbarViewDelegate <NSObject>
- (void)tabbarViewDidSelectedItemAtIndex:(NSInteger)index;
@optional
- (void)tabbarViewDidChangeProps:(BDXTabbarView*)tabbarview;
@end

@interface BDXTabbarView : UIView

@property (nonatomic, weak) id<BDXTabbarViewDelegate> delegate;

@property (nonatomic) UIColor *tabIndicatorColor;
@property (nonatomic) CGFloat tabInterSpace;
@property (nonatomic) CGFloat tabIndicatorWidth;
@property (nonatomic) CGFloat tabIndicatorHeight;
@property (nonatomic) CGFloat tabIndicatorTop;

@property (nonatomic) NSInteger tabLayoutGravity;
@property (nonatomic) CGFloat borderHeight;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) CGFloat borderDistanceToBottom;
@property (nonatomic) UIColor *borderColor;
@property (nonatomic) CGFloat leftMargin;
@property (nonatomic) CGFloat rightMargin;

- (instancetype)init;
- (void)scrollToTargetIndex:(NSUInteger)targetIndex sourceIndex:(NSUInteger)sourceIndex percent:(CGFloat)percent;

- (void)reselectSelectedIndex;

- (BOOL)directSetSelectedIndex:(NSInteger)index;
@end

@interface BDXLynxTabbar : LynxUI <BDXTabbarView *>

@property (nonatomic) NSMutableArray<BDXLynxTabbarItemView *> *tabItems;
@property (nonatomic) NSInteger defaultSelectedIndex;
@property (nonatomic) NSString *tabLayoutGravity;
@property (nonatomic) CGFloat tabInterSpace;
@property (nonatomic) UIColor *tabIndicatorColor;
@property (nonatomic) CGFloat tabIndicatorWidth;
@property (nonatomic) CGFloat tabIndicatorHeight;
@property (nonatomic) CGFloat tabIndicatorTop;
@property (nonatomic) CGFloat borderHeight;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) CGFloat borderMarginBottom;
@property (nonatomic) UIColor *borderColor;
@property (nonatomic) UIColor *tabbarBackground;
@property (nonatomic, assign) BOOL hideIndicator;
@end

NS_ASSUME_NONNULL_END
