//
//  ACCMusicTextEditAlertView.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/12.
//

#import "ACCMusicTextEditAlertView.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCMusicTextEditAlertView()<UITextFieldDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) ACCAnimatedButton *confirmButton;
@property (nonatomic, strong) ACCAnimatedButton *cancelButton;

@property (nonatomic, strong) UIView *textBackgroundView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) ACCAnimatedButton *clearButton;

@property (nonatomic, strong) UIView *horizontalLine;
@property (nonatomic, strong) UIView *verticalLine;
@property (nonatomic, assign) BOOL isAnimating;

@end

@implementation ACCMusicTextEditAlertView
#pragma mark - public

+ (void)showAlertOnView:(UIView *)view
              withTitle:(NSString *)title
     confirmButtonTitle:(NSString *)confirmTitle
      cancelButtonTitle:(NSString *)cancelTitle
           confirmBlock:(ACCTextEditConfirmAction)actionBlock
            cancelBlock:(dispatch_block_t)cancelBlock{
    ACCMusicTextEditAlertView *alert = [[ACCMusicTextEditAlertView alloc] initWithFrame:[UIScreen mainScreen].bounds
                                                                              withTitle:title
                                                                     confirmButtonTitle:confirmTitle
                                                                      cancelButtonTitle:cancelTitle
                                                                           confirmBlock:actionBlock
                                                                            cancelBlock:cancelBlock];
    [alert showOnView:view];
}

- (instancetype)initWithFrame:(CGRect)frame
                    withTitle:(NSString *)title
           confirmButtonTitle:(NSString *)confirmTitle
            cancelButtonTitle:(NSString *)cancelTitle
                 confirmBlock:(ACCTextEditConfirmAction)actionBlock
                  cancelBlock:(dispatch_block_t)cancelBlock{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.text = title;
        [self.confirmButton setTitle:confirmTitle forState:UIControlStateNormal];
        [self.cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
        self.confirmAction = actionBlock;
        self.cancelAction = cancelBlock;
        [self p_addObservers];
        [self setupUI];
        
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapViewGes:)];
        [self addGestureRecognizer:tapGes];
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanViewGes:)];
        [self addGestureRecognizer:panGes];
    }
    return self;
}

- (void)dealloc{
    [self p_removeObservers];
}

- (void)showOnView:(UIView *)view
{
    if (!view) return;
    if (self.isAnimating) return;
    if (!self.superview) {
        [view addSubview:self];
    }
    
    self.isAnimating = YES;
    self.containerView.alpha = 0;
    self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.containerView.alpha = 1;
        self.containerView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.isAnimating = NO;
        [self.textField becomeFirstResponder];
    }];
    self.clearButton.hidden = YES;
}

- (void)p_dismiss
{
    if (!self.superview) return;
    if (self.isAnimating) return;
    self.isAnimating = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self endEditing:YES];
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.containerView.alpha = 0;
            self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            self.isAnimating = NO;
            [self removeFromSuperview];
        }];
    });
}

#pragma mark init

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self p_addObservers];
        
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapViewGes:)];
        [self addGestureRecognizer:tapGes];
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanViewGes:)];
        [self addGestureRecognizer:panGes];
    }
    return self;
}

- (void)setupUI{
    //make other vision weaken dim
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [self addSubview:self.containerView];
    
    [self.containerView addSubview:self.titleLabel];
    [self.containerView addSubview:self.textBackgroundView];
    [self.containerView addSubview:self.clearButton];
    [self.containerView addSubview:self.textField];
    [self.containerView addSubview:self.confirmButton];
    [self.containerView addSubview:self.cancelButton];
    [self.containerView addSubview:self.horizontalLine];
    [self.containerView addSubview:self.verticalLine];
    
    ACCMasMaker(self.containerView, {
        make.center.equalTo(self);
        make.width.mas_equalTo(280);
        make.height.mas_equalTo(172);
    });
    ACCMasMaker(self.titleLabel, {
        make.centerX.equalTo(self.containerView);
        make.height.mas_equalTo(24);
        make.top.equalTo(self.containerView).offset(24);
        make.leading.equalTo(self.containerView.mas_leading).offset(20);
        make.trailing.equalTo(self.containerView.mas_trailing).offset(-20);
    });
    
    ACCMasMaker(self.textBackgroundView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12);
        make.left.equalTo(self.titleLabel);
        make.right.equalTo(self.titleLabel);
        make.height.mas_equalTo(40);
    });
    
    ACCMasMaker(self.textField, {
        make.left.equalTo(self.textBackgroundView).offset(10);
        make.centerY.equalTo(self.textBackgroundView);
        make.right.equalTo(self.clearButton.mas_left);
    });
    
    ACCMasMaker(self.clearButton, {
        make.right.equalTo(self.textBackgroundView).offset(-8);
        make.centerY.equalTo(self.textBackgroundView);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    });
    
    ACCMasMaker(self.horizontalLine, {
        make.width.centerX.equalTo(self.containerView);
        make.top.equalTo(self.textBackgroundView.mas_bottom).offset(24);
        make.height.mas_equalTo(0.5);
    });
    ACCMasMaker(self.verticalLine, {
        make.centerX.bottom.equalTo(self.containerView);
        make.width.mas_equalTo(0.5);
        make.height.mas_equalTo(47.5);
    });
    ACCMasMaker(self.cancelButton, {
        make.left.bottom.equalTo(self.containerView);
        make.top.equalTo(self.horizontalLine.mas_bottom);
        make.right.equalTo(self.verticalLine.mas_left);
    });
    ACCMasMaker(self.confirmButton, {
        make.right.bottom.equalTo(self.containerView);
        make.top.equalTo(self.horizontalLine.mas_bottom);
        make.left.equalTo(self.verticalLine.mas_right);
    });
}

- (void)p_addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardShowNoti:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardHideNoti:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)p_removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didMoveToSuperview
{
    if (self.superview) {
        ACCMasMaker(self, {
            make.edges.equalTo(self.superview);
        });
    }
}

#pragma mark - Actions

- (void)didClickConfirmButton
{
    if (self.confirmAction) {
        if (self.confirmAction(self.textField.text) == YES){
            [self p_dismiss];
        } else {
            //如果不满足确定条件，不消失view
            return;
        }
    } else {
        [self p_dismiss];
    }
}

- (void)didClickCancelButton
{
    ACCBLOCK_INVOKE(self.cancelAction);
    [self p_dismiss];
}

- (void)clickClearBtn
{
    self.textField.text = @"";
    self.clearButton.hidden = YES;
}

- (void)handleTapViewGes:(UITapGestureRecognizer *)ges {
    CGPoint point = [ges locationInView:self];
    if (!CGRectContainsPoint(self.containerView.frame, point)) {
        [self endEditing:YES];
    }
}

- (void)handlePanViewGes:(UIPanGestureRecognizer *)ges {
    CGPoint point = [ges locationInView:self];
    if (!CGRectContainsPoint(self.containerView.frame, point)) {
        [self endEditing:YES];
    }
}

- (void)handleKeyboardShowNoti:(NSNotification *)noti {
    if (!self.window || !self.superview){
        return;
    }
    NSTimeInterval duration = [[noti.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[noti.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect keyboardBounds;
    [[noti.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    [UIView animateWithDuration:duration delay:0 options:(curve<<16) animations:^{
        [self didUpdateKeyboardFrame:keyboardBounds willShowKeyboard:YES];
    } completion:nil];
}

- (void)handleKeyboardHideNoti:(NSNotification *)noti {
    if (!self.window || !self.superview){
        return;
    }
    NSTimeInterval duration = [[noti.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[noti.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    [UIView animateWithDuration:duration delay:0 options:(curve<<16) animations:^{
        [self didUpdateKeyboardFrame:CGRectZero willShowKeyboard:NO];
    } completion:nil];
}

- (void)didUpdateKeyboardFrame:(CGRect)frame willShowKeyboard:(BOOL)willShowKeyboard {
    if (willShowKeyboard) {
        self.containerView.acc_bottom = frame.origin.y - 80;
    } else {
        if (!self.isAnimating) {
            self.containerView.center = self.center;
        }
    }
}

#pragma mark - TextFieldDelegate

- (void)textFieldDidChange:(UITextField *)textField
{
    NSString *resultText = textField.text;
    self.clearButton.hidden = ACC_isEmptyString(resultText);
    [self.confirmButton.titleLabel setFont:[ACCFont() systemFontOfSize:15.0 weight:ACCFontWeightMedium]];
    UITextRange *selectedRange = [textField markedTextRange];
    UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
    NSInteger maxLength = 20;
    if (!position) {
        if (resultText.length > maxLength) {
            [ACCToast() show:@"已超出最大字数限制"];
            NSRange rangeIndex = [resultText rangeOfComposedCharacterSequenceAtIndex:maxLength];
            if (rangeIndex.length == 1) {
                textField.text = [resultText substringToIndex:maxLength];
            } else {
                NSRange rangeRange = [resultText rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, maxLength)];
                textField.text = [resultText substringWithRange:rangeRange];
            }
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField.text && ![textField.text isEqualToString:@""]) {
        self.clearButton.hidden = NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.clearButton.hidden = YES;
}

#pragma mark - getter

- (UIView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = ACCResourceColor(ACCColorBGReverse);
        _containerView.layer.cornerRadius = 12;
    }
    return _containerView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() acc_systemFontOfSize:17 weight:ACCFontWeightMedium];
        _titleLabel.textColor = ACCResourceColor(ACCColorTextReverse);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UITextField *)textField
{
    if (!_textField) {
        _textField = [[UITextField alloc] initWithFrame:CGRectZero];
        _textField.delegate = self;
        _textField.font = [ACCFont() systemFontOfSize:15.0];
        _textField.tintColor = ACCResourceColor(ACCColorTextReverse3);
        _textField.textColor = ACCResourceColor(ACCColorTextReverse);
        _textField.clearButtonMode = UITextFieldViewModeNever;
        _textField.placeholder = @"输入内容";
        [_textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
    return _textField;
}

- (UIView *)textBackgroundView
{
    if (!_textBackgroundView) {
        _textBackgroundView = [[UIView alloc] init];
        _textBackgroundView.backgroundColor = ACCResourceColor(ACCColorBGInputReverse);
        _textBackgroundView.layer.cornerRadius = 6;
        _textBackgroundView.layer.masksToBounds = YES;
    }
    return _textBackgroundView;
}

- (ACCAnimatedButton *)clearButton
{
    if (!_clearButton) {
        _clearButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [_clearButton setImage:[UIImage imageNamed:@"icon_clearButton"] forState:UIControlStateNormal];
        [_clearButton addTarget:self action:@selector(clickClearBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _clearButton;
}

- (ACCAnimatedButton *)confirmButton
{
    if (!_confirmButton) {
        _confirmButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [_confirmButton addTarget:self action:@selector(didClickConfirmButton) forControlEvents:UIControlEventTouchUpInside];
        _confirmButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
        [_confirmButton setTitleColor:ACCResourceColor(ACCColorTextReverse) forState:UIControlStateNormal];
    }
    return _confirmButton;
}

- (ACCAnimatedButton *)cancelButton
{
    if (!_cancelButton) {
        _cancelButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [_cancelButton addTarget:self action:@selector(didClickCancelButton) forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton setTitleColor:ACCResourceColor(ACCColorTextReverse2) forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:15];
    }
    return _cancelButton;
}

- (UIView *)horizontalLine
{
    if (!_horizontalLine) {
        _horizontalLine = [[UIView alloc] init];
        _horizontalLine.backgroundColor = ACCResourceColor(ACCColorLineReverse2);
    }
    return _horizontalLine;
}

- (UIView *)verticalLine
{
    if (!_verticalLine) {
        _verticalLine = [[UIView alloc] init];
        _verticalLine.backgroundColor = ACCResourceColor(ACCColorLineReverse2);
    }
    return _verticalLine;
}

@end

