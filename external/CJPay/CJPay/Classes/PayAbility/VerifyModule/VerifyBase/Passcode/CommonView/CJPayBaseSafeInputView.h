//
//  CJPayBaseSafeInputView.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/21.
//

#import <UIKit/UIKit.h>
#import "CJPaySafeKeyboard.h"
#import "CJPayEnumUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBaseSafeInputView : UITextField

// 内容
@property (nonatomic, strong, setter=setContentText:) NSMutableString *contentText;
//输入完成的block
@property (nonatomic, copy) void(^completeBlock)(void);
// 改变输入的回调
@property (nonatomic, copy) void(^changeBlock)(void);
//输入完成又删除一个的回调
@property (nonatomic, copy) void(^deleteBlock)(void);
//几位验证码
@property (nonatomic, assign) NSInteger numCount;
//允许粘贴
@property (nonatomic, assign) BOOL allowPaste;
//允许激活键盘
@property (nonatomic, assign) BOOL allowBecomeFirstResponder;

- (instancetype)init;
- (instancetype)initWithKeyboard:(BOOL)needKeyboard;
- (instancetype)initWithKeyboardForDenoise:(BOOL)needKeyboard;
- (instancetype)initWithKeyboardForDenoise:(BOOL)needKeyboard denoiseStyle:(CJPayViewType)viewStyle;

// 自定义键盘回调
- (void)deleteBackWord;

- (void)inputNumber:(NSInteger)number;

- (void)clearInput;

- (CGFloat)getFixKeyBoardHeight;
// 设置是否展示键盘安全险，传入FALSE为展示
- (void)setIsNotShowKeyboardSafeguard:(BOOL)notShowSafeGuard;
- (void)setKeyboardDenoise:(CJPaySafeKeyboardType)keyboardType;

@end

NS_ASSUME_NONNULL_END
