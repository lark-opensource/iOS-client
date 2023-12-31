//
//  CJPayKeyboardManager.h
//  CJPaySandBox
//
//  Created by wangxinhua on 2023/7/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
#define CJKeyboard [CJPayKeyboardManager sharedInstance]

/// 支付流程键盘管理类
@interface CJPayKeyboardManager : NSObject

+ (instancetype)sharedInstance;

// 对应view，变成第一响应者
- (BOOL)becomeFirstResponder:(UIView *)view;

/// 对应view，关闭键盘
/// - Parameter view: view
- (BOOL)resignFirstResponder:(UIView *)view;

/// 禁止键盘弹出
- (void)prohibitKeyboardShow;

/// 允许键盘弹出
- (void)permitKeyboardShow;

/// 延迟一定时间后才允许键盘弹出
/// - Parameter delayTime: 延迟时间
- (void)delayPermitKeyboardShow:(CGFloat)delayTime;

/// 是否允许键盘弹出
- (BOOL)keyboardShowIsPermited;

/// 恢复第一响应者
- (BOOL)recoverFirstResponder;

@end

NS_ASSUME_NONNULL_END
