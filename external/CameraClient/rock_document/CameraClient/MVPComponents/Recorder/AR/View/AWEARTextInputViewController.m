//
//  AWEARTextInputViewController.m
//  Pods
//
//  Created by 郝一鹏 on 2019/3/13.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEARTextInputViewController.h"
#import "AWETextField.h"
#import <TTVideoEditor/IESMMEffectMessage.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

@interface AWEARTextInputViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) AWETextField *textFiled;

@end

@implementation AWEARTextInputViewController

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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.textFiled becomeFirstResponder];
}

#pragma mark - setup UI

- (void)setupUI
{
    self.view.backgroundColor = ACCResourceColor(ACCUIColorConstSDSecondary);
    
    [self.view acc_addSingleTapRecognizerWithTarget:self action:@selector(p_doneButtonClicked:)];
    
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
    [self.view addSubview:self.textFiled];
    ACCMasMaker(self.textFiled, {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.height.equalTo(@(40));
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        } else {
            make.bottom.equalTo(self.view);
        }
    });
    [self.textFiled becomeFirstResponder];
}

#pragma mark - public method

- (void)refreshTextStateWithEffectMessageModel:(IESMMEffectMessage *)messageModel
{
    messageModel = messageModel ?: self.effectMessageModel;
    if (messageModel.arg1 == 1) {
        self.textFiled.placeholder = (NSString *)messageModel.arg3;
        [self.textFiled setPlaceHolderTextColor:ACCResourceColor(ACCUIColorConstTextInverse3)];
        self.textFiled.text = @"";
    } else {
        self.textFiled.text = messageModel.arg3;
    }
}

#pragma mark - observe

- (void)addObserver
{
    [self addNotificationObserver];
}

- (void)addNotificationObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

#pragma mark - notification handler

- (void)keyboardWillChangeFrame:(NSNotification *)note
{
    // 取出键盘最终的frame
    CGRect rect = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    // 取出键盘弹出需要花费的时间
    double duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    // 修改transform
    [UIView animateWithDuration:duration animations:^{
        CGFloat ty = [UIScreen mainScreen].bounds.size.height - rect.origin.y;
        self.textFiled.transform = CGAffineTransformMakeTranslation(0, - (ty + 12));
    }];
}

#pragma mark - lazy init property

- (UIButton *)doneButton
{
    if (!_doneButton) {
        _doneButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_doneButton setImage:ACCResourceImage(@"iconARTextDone") forState:UIControlStateNormal];
        [_doneButton addTarget:self action:@selector(p_doneButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneButton;
}

- (UITextField *)textFiled
{
    if (!_textFiled) {
        _textFiled = [[AWETextField alloc] initWithFrame:CGRectZero];
        _textFiled.backgroundColor = [UIColor clearColor];
        _textFiled.textColor = ACCResourceColor(ACCUIColorConstBGContainer);
        _textFiled.font = [ACCFont() systemFontOfSize:15];
        _textFiled.layer.borderColor = ACCResourceColor(ACCUIColorConstBGContainer).CGColor;
        _textFiled.layer.borderWidth = 0.5;
        _textFiled.layer.cornerRadius = 20.0f;
        _textFiled.leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 17.5, 0)];
        _textFiled.leftViewMode = UITextFieldViewModeAlways;
        _textFiled.tintColor = ACCResourceColor(ACCUIColorPrimary);
        _textFiled.delegate = self;
        _textFiled.returnKeyType = UIReturnKeyDone;
        [_textFiled addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
    return _textFiled;
}

- (void)textFieldDidChange:(UITextField *)textField
{
    if (textField == self.textFiled) {

        BOOL isNewAddText = self.effectMessageModel.arg1 == 1;
        
        NSInteger currentTextLength = textField.text.length;
        NSInteger initialTextCount = isNewAddText ? 0 : [self.effectMessageModel.arg3 length];

        BOOL isNewAddTextReachMaxCountLimit = isNewAddText && (currentTextLength > self.maxTextCount);
        BOOL isCurrentExsitTextReachMaxCountLimit = !isNewAddText && (currentTextLength >= initialTextCount + self.maxTextCount);
        if (isNewAddTextReachMaxCountLimit || isCurrentExsitTextReachMaxCountLimit) {
            [ACCToast() show: ACCLocalizedString(@"record_artext_input_limit_hint", @"达到字数上限了")];
            textField.text = [textField.text substringToIndex:initialTextCount + self.maxTextCount];
        }

        ACCBLOCK_INVOKE(self.textChangedBlock, textField.text, self.effectMessageModel);
    }
}

#pragma mark - actions

- (void)p_doneButtonClicked:(id)sender
{
    [self dismiss];
}

- (void)dismiss
{
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    [self didMoveToParentViewController:nil];
    if (self.effectMessageModel.arg1 == 1) {
        ACCBLOCK_INVOKE(self.textChangedBlock, self.textFiled.text, self.effectMessageModel);
    }
    ACCBLOCK_INVOKE(self.completionBlock, !ACC_isEmptyString(self.textFiled.text));
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self dismiss];
    return YES;
}

@end
