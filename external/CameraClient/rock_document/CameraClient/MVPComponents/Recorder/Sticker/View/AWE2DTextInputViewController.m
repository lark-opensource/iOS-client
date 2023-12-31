//
//  AWE2DTextInputViewController.m
//  AAWELaunchMainPlaceholder-iOS8.0
//
//  Created by 赖霄冰 on 2019/4/14.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWE2DTextInputViewController.h"
#import <TTVideoEditor/IESMMEffectMessage.h>
#import <CreativeKit/UIColor+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

static CGFloat const kAWE2DTextInputViewVerticalMargin = 52.f;
static CGFloat const kAWE2DTextInputViewHorizontalMargin = 29.f;

@interface AWE2DTextInputViewController ()<UITextViewDelegate>

@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UIView *textViewContainerView;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, assign) CGFloat textViewMaxCenterY;

@end

@implementation AWE2DTextInputViewController

#pragma mark - life circle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self addObserver];
}

- (void)viewDidAppear:(BOOL)animate {
    [super viewDidAppear:animate];
    [self.textView becomeFirstResponder];
}

#pragma mark - setup UI

- (void)setupUI {
    self.view.backgroundColor = ACCResourceColor(ACCUIColorConstSDSecondary);
    
    [self.view acc_addSingleTapRecognizerWithTarget:self action:@selector(p_doneButtonClicked:)];
    
    [self.view addSubview:self.textViewContainerView];
    [self.textViewContainerView addSubview:self.textView];
    [self.textView becomeFirstResponder];
    
    [self.view addSubview:self.doneButton];
    ACCMasMaker(self.doneButton, {
        make.width.equalTo(@(50));
        make.height.equalTo(@(44));
        make.right.equalTo(self.view).offset(-12);
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(4);
        } else {
            make.top.equalTo(self.view.mas_top).offset(4);
        }
    });
    
    [self p_updateFrame];
}

- (void)p_updateFrame {
    
    CGFloat textViewWidth = ACC_SCREEN_WIDTH - 2 * kAWE2DTextInputViewHorizontalMargin;
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
    textViewSize.width = textViewWidth;

    // 偏移textview的originY
    CGRect visibleRect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - self.keyboardHeight);
    CGFloat visibleRectCenterY = CGRectGetMidY(visibleRect);
    _textViewMaxCenterY = visibleRectCenterY - kAWE2DTextInputViewVerticalMargin;
    CGFloat textViewCenterY = 0;
    // 取textview的bottomY 和textview下面虚拟view的topY的差值
    CGFloat textViewBottomViewTopY = (ACC_SCREEN_HEIGHT - self.keyboardHeight - kAWE2DTextInputViewVerticalMargin);
    CGFloat delta = visibleRectCenterY + textViewSize.height * 0.5 - textViewBottomViewTopY;
    if (delta > 0) {
        textViewCenterY = _textViewMaxCenterY - delta;
    } else {
        textViewCenterY = _textViewMaxCenterY;
    }
    self.textViewContainerView.frame = CGRectMake(0, kAWE2DTextInputViewVerticalMargin, self.view.acc_width, textViewBottomViewTopY - kAWE2DTextInputViewVerticalMargin);
    self.textView.frame = CGRectMake(0, 0, textViewSize.width, textViewSize.height);
    self.textView.center = CGPointMake(CGRectGetMidX(visibleRect), textViewCenterY);
}

#pragma mark - public method

- (void)refreshTextStateWithEffectMessageModel:(IESMMEffectMessage *)messageModel {
    messageModel = messageModel ?: self.effectMessageModel;
    if (messageModel.arg1 == 1) {
        self.textView.text = @"";
    } else {
        self.textView.text = messageModel.arg3;
    }
}

#pragma mark - observe

- (void)addObserver {
    [self addNotificationObserver];
}

- (void)addNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

#pragma mark - notification handler

- (void)keyboardWillChangeFrame:(NSNotification *)note {
    // 取出键盘最终的frame
    CGRect rect = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    // 取出键盘弹出需要花费的时间
    double duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    // 修改transform
    [UIView animateWithDuration:duration animations:^{
        CGFloat kbH = ACC_SCREEN_HEIGHT - rect.origin.y;
        self.keyboardHeight = kbH;
        [self p_updateFrame];
    }];
}

#pragma mark - Gesture
//平移手势的回调方法
- (void)panAction:(UIPanGestureRecognizer *)sender {
    
    CGPoint currentPoint = [sender translationInView:sender.view];
    
    if (_textViewContainerView.acc_height >= _textView.acc_height ||
        self.textView.acc_top + currentPoint.y >= 0 ||
        self.textView.acc_bottom + currentPoint.y < self.textViewContainerView.acc_height) {
        return;
    }
    self.textView.center = CGPointMake(self.textView.center.x, self.textView.center.y + currentPoint.y);
    
    [sender setTranslation:CGPointZero inView:sender.view];
}

#pragma mark - lazy init property

- (UIButton *)doneButton {
    if (!_doneButton) {
        _doneButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_doneButton setImage:ACCResourceImage(@"iconARTextDone") forState:UIControlStateNormal];
        [_doneButton addTarget:self action:@selector(p_doneButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneButton;
}

- (UIView *)textViewContainerView {
    if (!_textViewContainerView) {
        _textViewContainerView = [UIView new];
        _textViewContainerView.clipsToBounds = YES;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
        [_textViewContainerView addGestureRecognizer:pan];
    }
    return _textViewContainerView;
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:CGRectZero];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.textColor = [UIColor whiteColor];
        _textView.font = [ACCFont() systemFontOfSize:28 weight:ACCFontWeightMedium];
        _textView.delegate = self;
        _textView.showsVerticalScrollIndicator = NO;
        _textView.showsHorizontalScrollIndicator = NO;
        _textView.textAlignment = NSTextAlignmentCenter;
        _textView.scrollEnabled = NO;
        _textView.tintColor = [UIColor acc_colorWithHexString:@"#E2A226"];
    }
    return _textView;
}

#pragma mark - <UITextViewDelegate>

- (void)textViewDidChange:(UITextView *)textView {
    
    BOOL isNewAddText = self.effectMessageModel.arg1 == 1; // 是占位符点进来的

    NSInteger currentTextLength = textView.text.length;
    NSInteger initialTextCount = isNewAddText ? 0 : self.effectMessageModel.arg3.length;

    NSInteger maxTextCount = initialTextCount + self.remainingTextCount;
    if (currentTextLength > maxTextCount) {
        [ACCToast() show: ACCLocalizedString(@"record_artext_input_limit_hint", @"达到字数上限了")];
        
        // 处理emoji截断问题
        NSString *currentText = textView.text;
        NSRange composedCharacterSequenceRange = [currentText rangeOfComposedCharacterSequenceAtIndex:maxTextCount];
        if (composedCharacterSequenceRange.length == 1) {
            textView.text = [currentText substringToIndex:maxTextCount];
        } else {
            textView.text = [currentText substringToIndex:composedCharacterSequenceRange.location];
        }
    }

    [self p_updateFrame];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self dismiss];
}

#pragma mark - actions

- (void)p_doneButtonClicked:(id)sender {
    [self dismiss];
}

- (void)dismiss {
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    [self didMoveToParentViewController:nil];
    ACCBLOCK_INVOKE(self.textDidFinishEditingBlock, self.textView.text, self.effectMessageModel);
}

@end
