//
//  BDPXScreenNavigationBar.h
//  TTMicroApp
//
//  Created by qianhongqiang on 2022/8/10.
//

#import <UIKit/UIKit.h>
#import <OPFoundation/BDPUniqueID.h>

@interface BDPXScreenNavigationBar : UIView

@property (nonatomic, strong, readonly) UIButton *backButton;;
@property (nonatomic, strong, readonly) UIButton *closeButton;

- (instancetype)initWithFrame:(CGRect)frame UniqueID:(BDPUniqueID *)uniqueID;

/// 更新导航栏标题
/// @param title 标题文案
- (void)setNavigationBarTitle:(NSString *)title;

/// 隐藏返回按钮
/// @param hidden YES为隐藏
- (void)setNavigationBarBackButtonHidden:(BOOL)hidden;

/// 设置导航为透明背景
/// @param transparent YES为透明
- (void)setNavigationBarTransparent:(BOOL)transparent;

/// 设置导航栏背景色
/// @param backgroundColor 背景色
- (void)setNavigationBarBackgroundColor:(UIColor *)backgroundColor;

@end
