//
//  ACCMVTextEditorInputView.m
//  CameraClient
//
//  Created by long.chen on 2020/3/19.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCMVTextEditorInputView.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface ACCMVTextEditorInputView () <UITextViewDelegate>

@property (nonatomic, strong) UIView *maskView;

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) ACCAnimatedButton *confirmButton;

@property (nonatomic, assign) CGSize lastContentSize;

@end

@implementation ACCMVTextEditorInputView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self p_setupUI];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(p_keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(p_keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(p_keyboardWillChangeFrame:)
                                                     name:UIKeyboardWillChangeFrameNotification
                                                   object:nil];
    }
    return self;
}

- (void)p_setupUI
{
    self.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
    
    [self addSubview:self.confirmButton];
    ACCMasMaker(self.confirmButton, {
        make.centerY.equalTo(self);
        make.right.equalTo(self).offset(-16);
    });
    
    [self addSubview:self.textView];
    ACCMasMaker(self.textView, {
        make.top.equalTo(self).offset(13);
        make.left.equalTo(self).offset(16);
        make.bottom.equalTo(self).offset(-13);
        make.right.equalTo(self).offset(-80);
    });
}

- (CGSize)intrinsicContentSize
{
    CGFloat textViewHeight = MIN(63, MAX(self.textView.contentSize.height, 24)) + 26;
    return CGSizeMake(ACC_SCREEN_WIDTH, textViewHeight);
}

#pragma mark - Public

- (void)setInitialContent:(NSString *)initialContent
{
    _initialContent = initialContent.copy;
    self.textView.text = initialContent;
    [self.textView layoutIfNeeded]; 
    [self textViewDidChange:self.textView]; 
}

- (void)becomeActive
{
    [self.textView becomeFirstResponder];
}

- (void)resignActive
{
    [self.textView resignFirstResponder];
    ACCBLOCK_INVOKE(self.didEndEditBlock, ![self.textView.text isEqualToString:self.initialContent]);
}

#pragma mark - Actions

- (void)p_handleMaskViewTapped:(UIGestureRecognizer *)gestureRecognizer
{
    [self resignActive];
}

- (void)p_handleConfirmButtonClicked:(UIButton *)button
{
    [self resignActive];
}

#pragma mark - Notification

- (void)p_keyboardWillShow:(NSNotification *)notification
{
    if (!self.superview) return;
    if (!self.window || !self.textView.isFirstResponder) {
        return;
    }
    
    [self.superview insertSubview:self.maskView belowSubview:self];
    ACCMasMaker(self.maskView, {
        make.edges.equalTo(self.superview);
    });
    
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    ACCMasUpdate(self, {
        make.bottom.equalTo(self.superview.mas_bottom).offset(-keyboardSize.height);
    });
    [UIView animateWithDuration:duration
                          delay:0
                        options:(curve<<16)
                     animations:^{
        [self.superview layoutIfNeeded];
    } completion:nil];
}

- (void)p_keyboardWillHide:(NSNotification *)notification
{
    if (!self.superview) return;
    
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    ACCMasUpdate(self, {
        make.bottom.equalTo(self.superview).offset(100);
    });
    [UIView animateWithDuration:duration
                          delay:0
                        options:(curve<<16)
                     animations:^{
        [self.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.maskView removeFromSuperview];
        [self removeFromSuperview];
    }];
}

- (void)p_keyboardWillChangeFrame:(NSNotification *)notification
{
    if (!self.superview) return;
        
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    ACCMasUpdate(self, {
        make.bottom.equalTo(self.superview.mas_bottom).offset(-keyboardSize.height);
    });
    [UIView animateWithDuration:duration
                          delay:0
                        options:(curve<<16)
                     animations:^{
        [self.superview layoutIfNeeded];
    } completion:nil];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    if (!CGSizeEqualToSize(self.lastContentSize, textView.contentSize)) {
        self.lastContentSize = textView.contentSize;
        [self invalidateIntrinsicContentSize];
    }
    ACCBLOCK_INVOKE(self.textDidChangedBlock, textView.text);
}

#pragma mark - Getters

- (UIView *)maskView
{
    if (!_maskView) {
        _maskView = [UIView new];
        [_maskView acc_addSingleTapRecognizerWithTarget:self action:@selector(p_handleMaskViewTapped:)];
    }
    return _maskView;
}

- (UITextView *)textView
{
    if (!_textView) {
        _textView = [UITextView new];
        _textView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
        _textView.font = [ACCFont() systemFontOfSize:15];
        _textView.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _textView.tintColor = ACCResourceColor(ACCColorPrimary);
        _textView.delegate = self;
        _textView.textContainerInset = UIEdgeInsetsMake(3, 0, 0, 0);
    }
    return _textView;
}

- (ACCAnimatedButton *)confirmButton
{
    if (!_confirmButton) {
        _confirmButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [_confirmButton setTitle:ACCLocalizedString(@"done", @"完成") forState:UIControlStateNormal];
        _confirmButton.titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
        _confirmButton.titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        [_confirmButton addTarget:self action:@selector(p_handleConfirmButtonClicked:)
                 forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

@end

