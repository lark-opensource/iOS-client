//
//  DYOpenBasePopupView.h
//  DouyinOpenPlatformSDK
//
//  Created by arvitwu on 2022/9/16.
//

#import <UIKit/UIView.h>

typedef void(^DYOpenBasePopupViewDidDismissBlock)(void);

@class DYOpenBasePopupView;

@protocol DYOpenBasePopupViewDelegate <NSObject>

@optional
- (void)dyopenPopupViewWillDismiss:(DYOpenBasePopupView *)popupView;
- (void)dyopenPopupViewWillAppear:(DYOpenBasePopupView *)popupView;
- (void)dyopenPopupViewDidDismiss:(DYOpenBasePopupView *)popupView;

@end

@interface DYOpenBasePopupView : UIView

@property (nonatomic, weak) id<DYOpenBasePopupViewDelegate> delegate;

@property (nonatomic, copy) DYOpenBasePopupViewDidDismissBlock didDismissBlock;
@property (nonatomic, strong, readonly) UIView *backgroundView;
@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, assign, readonly) BOOL isShowing;

#pragma mark - Life Cycle
- (instancetype)initWithContentHeight:(NSInteger)height;
- (instancetype)initWithContentViweFrame:(CGRect)contentFrame;
+ (instancetype)popupView;

#pragma mark - Override Config
/// 子类可重载此方法进行 UI 布局
- (void)setupPopupSubviews;

/// 背景 view
+ (Class)backgroundViewClass;

/// 如果子类要重写关闭方法，记得调一下这个父类方法
- (void)backgroundTapped NS_REQUIRES_SUPER;

/// 背景颜色
+ (UIColor *)defaultBackgroundColor;

/// contentView 颜色
+ (UIColor *)defaultContentViewColor;

/// contentView 高度
+ (NSInteger)defaultContentHeight;

#pragma mark - Public Methods
/// 显示
- (void)showInView:(UIView *)view;

/// 消失
- (void)dismiss;

/// 刷新 contentView 高度
- (void)refreshConentHeight:(CGFloat)height;

/// 更新顶部圆角（左上 + 右上）
- (void)updateTopCorner:(CGFloat)radius;

/// 是否响应背景层的点击（默认 YES）
- (void)enableTapBackground:(BOOL)enable;

@end
