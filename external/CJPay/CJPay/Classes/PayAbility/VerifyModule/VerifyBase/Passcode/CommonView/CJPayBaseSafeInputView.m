//
//  CJPayBaseSafeInputView.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/21.
//

#import "CJPayBaseSafeInputView.h"
#import "CJPayFixKeyboardView.h"
#import "CJPayUIMacro.h"
#import "CJPaySafeKeyboard.h"

@interface CJPayBaseSafeInputView () <UITextFieldDelegate>

@property (nonatomic, strong) CJPaySafeKeyboard *safeKeyBoard;
@property (nonatomic, strong) CJPayFixKeyboardView *boardFixView;
//键盘样式
@property (nonatomic, assign) CJPayViewType viewStyle;

@end

@implementation CJPayBaseSafeInputView

- (instancetype)init {
    return [self initWithKeyboard:YES];
}

- (instancetype)initWithKeyboard:(BOOL)needKeyboard {
    self = [super init];
    if (self) {
        _allowPaste = NO;
        _allowBecomeFirstResponder = YES;
        _contentText = [NSMutableString string];
        _viewStyle = CJPayViewTypeNormal;
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        if (needKeyboard) {
            _boardFixView = [[CJPayFixKeyboardView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 200 - CJ_TabBarSafeBottomMargin, CJ_SCREEN_WIDTH, 220 + CJ_TabBarSafeBottomMargin)];
            _safeKeyBoard = _boardFixView.safeKeyboard;
            self.inputView = _boardFixView;
            [self setupKeyBoard];
        }
    }
    return self;
}

- (instancetype)initWithKeyboardForDenoise:(BOOL)needKeyboard {
    return [self initWithKeyboardForDenoise:needKeyboard denoiseStyle:CJPayViewTypeDenoise];
}

- (instancetype)initWithKeyboardForDenoise:(BOOL)needKeyboard denoiseStyle:(CJPayViewType)viewStyle {
    self = [super init];
    if (self) {
        _allowPaste = NO;
        _allowBecomeFirstResponder = YES;
        _contentText = [NSMutableString string];
        _viewStyle = viewStyle;
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        if (needKeyboard) {
            CGFloat keyboardViewHeight = viewStyle == CJPayViewTypeDenoiseV2 ? 200 : 208;
            _boardFixView = [[CJPayFixKeyboardView alloc] initWithFrameForDenoise:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - keyboardViewHeight - CJ_NewTabBarSafeBottomMargin, CJ_SCREEN_WIDTH, keyboardViewHeight + CJ_NewTabBarSafeBottomMargin)];
            _safeKeyBoard = _boardFixView.safeKeyboard;
            self.inputView = _boardFixView;
            [self setupKeyBoard];
        }
    }
    return self;
}

- (void)setupKeyBoard{
    @CJWeakify(self)
    _safeKeyBoard.deleteClickedBlock = ^{
        [weak_self deleteBackWord];
    };
    _safeKeyBoard.numberClickedBlock = ^(NSInteger number) {
        [weak_self inputNumber:number];
    };
}

#pragma mark responder
-(BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder{
    if (!self.allowBecomeFirstResponder) {
        return NO;
    }
    if (![super becomeFirstResponder]) {
         [[self findViewThatIsFirstResponder] resignFirstResponder];
    }
    return [super becomeFirstResponder];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    return CGRectContainsPoint(self.bounds, point) ? self : nil;
}

- (void)deleteBackWord{
    if (_contentText.length <= 0) {
        return;
    }
    if (_contentText.length == self.numCount) {
        CJ_CALL_BLOCK(_deleteBlock);
    }
    [_contentText deleteCharactersInRange:NSMakeRange(_contentText.length - 1, 1)];
    [self setContentText:_contentText];
}

- (void)inputNumber:(NSInteger)number{
    [_contentText appendString:@(number).stringValue];
    [self setContentText:_contentText];
    if (_contentText.length >= self.numCount) {
        CJ_CALL_BLOCK(_completeBlock);
    }
}

- (void)clearInput{
    self.contentText = [NSMutableString stringWithString:@""];
    CJ_CALL_BLOCK(self.deleteBlock);
}

- (CGFloat)getFixKeyBoardHeight {
    return self.boardFixView.frame.size.height;
}

- (void)setContentText:(NSMutableString *)contentText{
    if (contentText.length > self.numCount) {
        [contentText deleteCharactersInRange:NSMakeRange(self.numCount, contentText.length - self.numCount)];
    }
    _contentText = contentText;
    [self setText:_contentText];
    CJ_CALL_BLOCK(self.changeBlock);
}

- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender {
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    if (menuController) {
        [UIMenuController sharedMenuController].menuVisible = NO;
    }
    return NO;
}

- (void)insertText:(NSString *)text {

}

// 设置键盘安全险是否展示
- (void)setIsNotShowKeyboardSafeguard:(BOOL)notShowSafeGuard {
    if (_boardFixView) {
        _boardFixView.notShowSafeguard = notShowSafeGuard;
        if (self.viewStyle == CJPayViewTypeDenoise) {
            _boardFixView.cj_height = notShowSafeGuard ? 208 + CJ_NewTabBarSafeBottomMargin : 232 + CJ_NewTabBarSafeBottomMargin;
        } else if (self.viewStyle == CJPayViewTypeDenoiseV2) {
            _boardFixView.cj_height = notShowSafeGuard ? 200 + CJ_NewTabBarSafeBottomMargin : 224 + CJ_NewTabBarSafeBottomMargin;
        } else {
            _boardFixView.cj_height = notShowSafeGuard ? 220 + CJ_TabBarSafeBottomMargin : 250 + CJ_TabBarSafeBottomMargin;
        }
    }
    return;
}

- (void)setKeyboardDenoise:(CJPaySafeKeyboardType)keyboardType {
    if (_boardFixView) {
        _boardFixView.safeKeyboard.keyboardType = keyboardType;
    }
}

@end
