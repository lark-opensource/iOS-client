//
//  BulletXNavigationBar.h
//  Bullet-Pods-AwemeLite
//
//  Created by 王丹阳 on 2020/11/9.
//

#import <UIKit/UIKit.h>
#import <BDXServiceCenter/BDXPageContainerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class BDXNavigationBar;
typedef void (^BulletNavigationBarAction)(BDXNavigationBar *navigationBar);

@interface BDXNavigationBar : UIView

/// 底部分隔线线宽（默认0.5pt）
@property(nonatomic, assign) CGFloat bottomLineHeight;

/// 底部分隔线颜色（默认0xF8F8F8）
@property(nonatomic, strong) UIColor *bottomLineColor;

/// title字体（默认regular 18.0）
@property(nonatomic, strong) UIFont *titleFont;

/// title颜色
@property(nonatomic, strong) UIColor *titleColor;

/// title文案
@property(nonatomic, copy) NSString *title;

/// 左按钮
@property(nonatomic, strong, readonly) UIButton *leftNaviButton;

/// 左按钮图片
@property(nonatomic, strong) UIImage *leftButtonImage;

/// 左按钮背景图
@property(nonatomic, strong) UIImage *leftButtonBackgroundImage;

/// 左按钮文字
@property(nonatomic, copy) NSString *leftButtonTitle;

/// 左按钮文字字体（默认sytemFont 14.0）
@property(nonatomic, strong) UIFont *leftButtonFont;

/// 左按钮文字颜色（默认0x404040）
@property(nonatomic, strong) UIColor *leftButtonTitleColor;

/// 关闭按钮
@property(nonatomic, strong, readonly) UIButton *closeNaviButton;

/// 关闭按钮图片
@property(nonatomic, strong) UIImage *closeButtonImage;

/// 关闭按钮背景图
@property(nonatomic, strong) UIImage *closeButtonBackgroundImage;

/// 关闭按钮文字
@property(nonatomic, copy) NSString *closeButtonTitle;

/// 关闭按钮文字字体（默认sytemFont 14.0）
@property(nonatomic, strong) UIFont *closeButtonFont;

/// 关闭按钮文字颜色（默认0x404040）
@property(nonatomic, strong) UIColor *closeButtonTitleColor;

/// 右按钮
@property(nonatomic, strong, readonly) UIButton *rightNaviButton;

/// 右按钮图片
@property(nonatomic, strong) UIImage *rightButtonImage;

/// 右按钮背景图
@property(nonatomic, strong) UIImage *rightButtonBackgroundImage;

/// 右按钮文字
@property(nonatomic, copy) NSString *rightButtonTitle;

/// 右按钮文字字体（默认sytemFont 14.0）
@property(nonatomic, strong) UIFont *rightButtonFont;

/// 右按钮文字颜色（默认0x404040）
@property(nonatomic, strong) UIColor *rightButtonTitleColor;

/**
 *  默认样式：只有title
 */
+ (instancetype)defaultNavigationBar;

/**
 *  设置左按钮动作
 */
- (void)setLeftButtonActionBlock:(BulletNavigationBarAction)actionBlock;

/**
 *  设置关闭按钮动作
 */
- (void)setCloseButtonActionBlock:(BulletNavigationBarAction)actionBlock;

/**
 *  设置右按钮动作
 */
- (void)setRightButtonActionBlock:(BulletNavigationBarAction)actionBlock;

@end

NS_ASSUME_NONNULL_END
