//
//  CJPaySafeInputView.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/16.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseSafeInputView.h"

@class CJPaySafeInputView;

NS_ASSUME_NONNULL_BEGIN


@protocol CJPaySafeInputViewDelegate <NSObject>

// 完成输入
- (void)inputView:(CJPaySafeInputView *)inputView completeInputWithCurrentInput:(NSString *)currentStr;

// 文本改变的回调
- (void)inputView:(CJPaySafeInputView *)inputView textDidChangeWithCurrentInput:(NSString *)currentStr;

@optional
// first responder
- (BOOL)inputViewShouldBecomeFirstResponder:(CJPaySafeInputView *)inputView;
- (BOOL)inputViewShouldResignFirstResponder:(CJPaySafeInputView *)inputView;

@end

@interface CJPaySafeInputViewStyleModel : NSObject

@property (nonatomic, assign) CJPayViewType viewStyle;
@property (nonatomic, assign) BOOL needKeyboard;
@property (nonatomic, assign) BOOL isDenoise;
@property (nonatomic, assign) CGFloat fixedSpacing;

@end

@interface CJPaySafeInputView : CJPayBaseSafeInputView

- (instancetype)init;
- (instancetype)initWithKeyboard:(BOOL)needKeyboard;
- (instancetype)initWithKeyboardForDenoise:(BOOL)needKeyboard;
- (instancetype)initWithInputViewStyleModel:(CJPaySafeInputViewStyleModel *)model;

// 安全输入框的状态回调
@property (nonatomic, weak) id<CJPaySafeInputViewDelegate> safeInputDelegate;

//当前是否显示黑色小球的样式
@property (nonatomic, assign) BOOL mineSecureTextEntry;

@property (nonatomic, assign) BOOL showCursor;

@property (nonatomic, assign) BOOL mineSecureSupportShortShow;

//是否有过输入行为
@property (nonatomic, assign) BOOL hasInputHistory;

@end


NS_ASSUME_NONNULL_END
