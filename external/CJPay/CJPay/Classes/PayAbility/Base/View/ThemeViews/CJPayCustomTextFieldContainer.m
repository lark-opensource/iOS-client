//
//  CJPayCustomTextFieldContainer.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/11.
//

#import "CJPayCustomTextFieldContainer.h"
#import "CJPaySafeKeyboard.h"
#import "CJPayCustomTextField.h"
#import "CJPayUIMacro.h"
#import "CJPayCustomRightView.h"
#import "CJPayCustomKeyboardTopView.h"
#import "CJPayAlertUtil.h"
#import "CJPayButton.h"

@interface CJPayCustomTextFieldContainer() <CJPayCustomTextFieldDelegate>

#pragma mark - view
@property (nonatomic, strong) UILabel *inputTitleLabel;
@property (nonatomic, strong) CJPayButton *infoButton;
@property (nonatomic, strong) CJPaySafeKeyboard *safeKeyBoard;
@property (nonatomic, strong) CJPayCustomKeyboardTopView *keyBoardTopView;
@property (nonatomic, strong) UIView *boardContainerView;

#pragma mark - flag
@property (nonatomic, assign) CJPayTextFieldType textFieldType;
@property (nonatomic, assign) BOOL isPlaceHolderStatus;
@property (nonatomic, assign) BOOL isInputInvalid;
@property (nonatomic, assign) BOOL isInit;
@property (nonatomic, assign) BOOL isNeedUpdateTipsText;
@property (nonatomic, assign) BOOL isNeedUpdatePreFillText;
@property (nonatomic, assign) BOOL isNeedClearText;
@property (nonatomic, assign) BOOL isNeedSetPlaceHolderText;
@property (nonatomic, assign) BOOL isNeedSetSubTitleText;

@property (nonatomic, assign) CJPayCustomTextFieldContainerStyle containerStyle;
#pragma mark - temp storage
@property (nonatomic, copy) NSString *tipsText;
@property (nonatomic, copy) NSString *preFillText;
   
@end

@implementation CJPayCustomTextFieldContainer

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_installDefaultAppearance];
        _isInit = YES;
        _isNeedUpdateTipsText = NO;
        _isNeedUpdatePreFillText = NO;
        _isNeedClearText = NO;
        _isNeedSetPlaceHolderText = NO;
        _isNeedSetSubTitleText = NO;
        _containerStyle = CJPayCustomTextFieldContainerStyleWhite;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame textFieldType:(CJPayTextFieldType)textFieldType style:(CJPayCustomTextFieldContainerStyle)containerStyle {
    self = [self initWithFrame:frame];
    if (self) {
        self.textFieldType = textFieldType;
        _containerStyle = containerStyle;
        [self configTextField];
        if (CJ_Pad) {
            [self p_configOrientationListen];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame textFieldType:(CJPayTextFieldType)textFieldType {
    self = [self initWithFrame:frame textFieldType:textFieldType style:CJPayCustomTextFieldContainerStyleWhite];
    return self;
}

- (void)setupUI {
    self.isPlaceHolderStatus = YES;
    self.isInputInvalid = YES;
    [self p_setupKeyBoard];
    [self p_setupTitleText];
    self.textField.rightView = self.customClearView;
    self.textField.rightViewMode = UITextFieldViewModeWhileEditing;
    [self addSubview:self.infoButton];

    if (self.containerStyle == CJPayCustomTextFieldContainerStyleWhiteAndBottomTips) {
        [self p_setupUIForWhiteStyleAndBottomTips];
    } else {
        [self p_setupUIForNormalStyle];
    }
}

- (void)p_setupTitleText {
    if (self.textFieldType == CJPayTextFieldTypeIdentity) {
        self.inputTitleLabel.text = Check_ValidString(self.customInputTitle) ? self.customInputTitle: CJPayLocalizedStr(@"证件号");
    } else if (self.textFieldType == CJPayTextFieldTypePhone) {
        self.inputTitleLabel.text = CJPayLocalizedStr(@"手机号");
    } else if (self.textFieldType == CJPayTextFieldTypeName) {
        self.inputTitleLabel.text = CJPayLocalizedStr(@"姓名");
    }
}

- (void)p_setupUIForWhiteStyleAndBottomTips {
    self.bottomLine.backgroundColor = [UIColor cj_e8e8e8ff];
    
    CJPayMasMaker(self.inputTitleLabel, {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self).offset(18);
        make.height.mas_equalTo(22);
    });
    
    CJPayMasMaker(self.textField, {
        make.left.equalTo(self.inputTitleLabel.mas_left).offset(88);
        make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(self.inputTitleLabel);
        make.height.mas_equalTo(48);
    });
    
    CJPayMasMaker(self.infoButton, {
        make.right.equalTo(self.bottomLine);
        make.centerY.equalTo(self.textField);
        make.width.height.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.placeHolderLabel, {
        make.left.centerY.equalTo(self.textField);
        make.right.equalTo(self);
        make.height.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.bottomLine, {
        make.bottom.equalTo(self.mas_bottom);
        make.left.equalTo(self.inputTitleLabel.mas_left);
        make.right.equalTo(self.mas_right).offset(-16);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    });
}

- (void)p_setupUIForNormalStyle {
    self.bottomLine.backgroundColor = [UIColor cj_e8e8e8ff];
    CJPayMasMaker(self.placeHolderLabel, {
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.bottom.equalTo(self).offset(-16);
        make.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.bottomLine, {
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.top.equalTo(self).offset(68);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    });
    
    CJPayMasMaker(self.textField, {
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.top.equalTo(self).offset(10.5);
        make.height.mas_equalTo(48);
    });
    
    CJPayMasMaker(self.infoButton, {
        make.right.equalTo(self).offset(-24);
        make.centerY.equalTo(self.textField);
        make.width.height.mas_equalTo(24);
    });
}

- (BOOL)hasTipsText {
    return Check_ValidString(self.tipsText);
}

- (void)updateTips:(NSString *)tipsText {
    self.tipsText = tipsText;
    self.isNeedUpdateTipsText = YES;
    [self p_updateTips];
    
}

- (void)preFillText:(NSString *)text {
    self.preFillText = text;
    self.isNeedUpdatePreFillText = YES;
    [self p_preFillText];
}

- (void)clearText {
    self.isNeedClearText = YES;
    [self p_clearText];
}

- (CGFloat)getKeyBoardHeight {
    if (self.keyBoardType == CJPayKeyBoardTypeSystomDefault) {
        return 216;
    } else {
        return self.boardContainerView.cj_height;
    }
}

- (void)textFieldBeginEditAnimation {
    if (self.containerStyle == CJPayCustomTextFieldContainerStyleWhiteAndBottomTips) {
        [self p_hideInfoButton:YES];
        [self layoutIfNeeded];
        return;
    }
    
    [UIView animateWithDuration:0.2 animations:^{

        if (self.isInputInvalid) {
            self.placeHolderLabel.text = self.subTitleText;
            self.placeHolderLabel.textColor = [UIColor cj_999999ff];
        }
        self.bottomLine.backgroundColor = [UIColor cj_222222ff];
        CJPayMasReMaker(self.placeHolderLabel, {
            make.left.equalTo(self).offset(24);
            make.top.equalTo(self).offset(12);
            make.height.mas_equalTo(13*1.4);
        });
        self.placeHolderLabel.font = [UIFont cj_fontOfSize:13];
        
        CJPayMasUpdate(self.textField, {
            make.left.equalTo(self).offset(24);
            make.top.equalTo(self).offset(23);
        });

        [self layoutIfNeeded];
    }];
}

- (void)textFieldEndEditAnimation {

    [self p_hideInfoButton:NO];
    
    if (!Check_ValidString(self.textField.userInputContent) &&
        self.containerStyle == CJPayCustomTextFieldContainerStyleWhiteAndBottomTips) {
        [self layoutIfNeeded];
        return;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        self.bottomLine.backgroundColor = [UIColor cj_e8e8e8ff];
        if (self.textField.userInputContent.length == 0) {

            self.placeHolderLabel.text = self.placeHolderText;
            self.placeHolderLabel.textColor = [UIColor cj_999999ff];
            
            CJPayMasReMaker(self.placeHolderLabel, {
                make.left.equalTo(self).offset(24);
                make.right.equalTo(self).offset(-24);
                make.bottom.equalTo(self).offset(-16);
                make.height.mas_equalTo(16);
            });
            self.placeHolderLabel.font = [UIFont cj_fontOfSize:16];
            
            CJPayMasUpdate(self.textField, {
                make.left.equalTo(self).offset(24);
                make.top.equalTo(self).offset(12.5);
            });
        }
        [self layoutIfNeeded];
    }];
}

- (void)configTextField {
    if (self.textFieldType == CJPayTextFieldTypeBankCard) {
        self.textField.separateCount = 4;
        self.textField.limitCount = 21;
        self.textField.supportCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        self.textField.supportSeparate = YES;
        self.textField.keyboardType = UIKeyboardTypePhonePad;
        if (!CJ_Pad) {
            self.textField.inputView = self.boardContainerView;
        }
        
        NSString *preText = CJPayLocalizedStr(@"点击输入");
        NSString *midText = CJPayLocalizedStr(@"本人");
        NSString *postText = CJPayLocalizedStr(@"银行卡号");
        
        self.placeHolderText = [NSString stringWithFormat:@"%@%@%@", preText, midText, postText];
        self.subTitleText = self.placeHolderText;
    } else if (self.textFieldType == CJPayTextFieldTypeIdentity) {
        self.textField.separateArray = @[@"6",@"8",@"4"];
        self.textField.limitCount = 18;
        self.textField.supportCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789xX"];
        self.textField.supportSeparate = YES;
        if (self.containerStyle == CJPayCustomTextFieldContainerStyleWhiteAndBottomTips) {
            self.placeHolderText = CJPayLocalizedStr(@"输入持卡人证件号");
            self.subTitleText = CJPayLocalizedStr(@"");
        } else {
            self.placeHolderText = CJPayLocalizedStr(@"请输入证件号码");
            self.subTitleText = CJPayLocalizedStr(@"证件号码");
        }
    } else if (self.textFieldType == CJPayTextFieldTypePhone) {
        self.textField.separateArray = @[@"3",@"4",@"4"];
        self.textField.limitCount = 11;
        self.textField.supportCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        self.textField.supportSeparate = YES;
        self.placeHolderText = CJPayLocalizedStr(@"点击输入银行预留手机号");
        self.subTitleText = CJPayLocalizedStr(@"银行预留手机号");
    } else {
        self.textField.supportSeparate = NO;
        self.placeHolderText = CJPayLocalizedStr(@"请输入本人真实姓名");
        self.subTitleText = CJPayLocalizedStr(@"姓名");
    }
}

#pragma mark - Life Cycle

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.isInit) {
        [self setupUI];
        self.isKeyBoardSupportEasyClose = YES;
        self.isInit = NO;
        if (self.isNeedSetPlaceHolderText) {
            [self p_setPlaceHolderText];
            self.isNeedSetPlaceHolderText = NO;
        }
        if (self.isNeedSetSubTitleText) {
            [self p_setSubTitleText];
            self.isNeedSetSubTitleText = NO;
        }
        if(self.isNeedUpdateTipsText) {
            [self p_updateTips];
            self.isNeedUpdateTipsText = NO;
        }
        if(self.isNeedUpdatePreFillText) {
            [self p_preFillText];
            self.isNeedUpdatePreFillText = NO;
        }
        if(self.isNeedClearText) {
            [self p_clearText];
            self.isNeedClearText = NO;
        }
    }
}

#pragma mark - private method

- (void)p_configOrientationListen {
    if (CJ_Pad) {
        if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) { // 开启方向监听
            [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        }
        [[NSNotificationCenter defaultCenter]addObserver:self      selector:@selector(p_handleDeviceOrientationChange)
                                                        name:UIDeviceOrientationDidChangeNotification object:nil];
    }
}

- (void)p_handleDeviceOrientationChange {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.boardContainerView cj_setViewWidthEqualToScreen];
    });
}

- (void)p_clearText {
    self.textField.text = @"";
    self.isInputInvalid = YES;

    if (self.containerStyle == CJPayCustomTextFieldContainerStyleWhiteAndBottomTips) {
        [self p_hideInfoButton:YES];
        [self layoutIfNeeded];
        return;
    }
    
    CJPayMasUpdate(self.textField, {
        make.left.equalTo(self).offset(24);
        make.top.equalTo(self).offset(12.5);
    });
    
    [UIView animateWithDuration:0.2 animations:^{
        self.bottomLine.backgroundColor = [UIColor cj_e8e8e8ff];
        self.placeHolderLabel.text = self.placeHolderText;
        
        self.placeHolderLabel.textColor = [UIColor cj_999999ff];
        
        CJPayMasReMaker(self.placeHolderLabel, {
            make.left.equalTo(self).offset(24);
            make.right.equalTo(self).offset(-24);
            make.bottom.equalTo(self).offset(-16);
            make.height.mas_equalTo(16);
        });
        self.placeHolderLabel.font = [UIFont cj_fontOfSize:16];
        
        
        [self p_hideInfoButton:YES];
        [self layoutIfNeeded];
    }];
}

- (void)p_preFillText {
    if (Check_ValidString(self.preFillText)) {
        self.textField.text = self.preFillText;
        self.placeHolderLabel.text = self.subTitleText;
        if (self.containerStyle == CJPayCustomTextFieldContainerStyleWhiteAndBottomTips) {
            CJPayMasReMaker(self.placeHolderLabel, {
                make.left.equalTo(self.textField);
                make.bottom.equalTo(self.mas_bottom).offset(-8);
                make.height.mas_equalTo(16);
            });
            self.placeHolderLabel.font = [UIFont cj_fontOfSize:12];
            self.placeHolderLabel.text = @"";
        } else {//旧样式
            self.placeHolderLabel.textColor = [UIColor cj_999999ff];
            CJPayMasReMaker(self.placeHolderLabel, {
                make.left.equalTo(self).offset(24);
                make.top.equalTo(self).offset(12);
                make.height.mas_equalTo(13*1.4);
            });
            self.placeHolderLabel.font = [UIFont cj_fontOfSize:13];
            
            CJPayMasUpdate(self.textField, {
                make.left.equalTo(self).offset(24);
                make.top.equalTo(self).offset(23);
            });
        }
        
        [self layoutIfNeeded];
    }
}

- (void)p_updateTips {
    if (self.containerStyle == CJPayCustomTextFieldContainerStyleWhiteAndBottomTips) {
        if (Check_ValidString(self.textField.text)) {
            CJPayMasReMaker(self.placeHolderLabel, {
                make.left.equalTo(self.textField);
                make.bottom.equalTo(self.mas_bottom).offset(-8);
                make.height.mas_equalTo(16);
            });
            self.placeHolderLabel.font = [UIFont cj_fontOfSize:12];
            self.placeHolderLabel.text = CJString(self.tipsText);
        } else {
            CJPayMasReMaker(self.placeHolderLabel, {
                make.left.centerY.equalTo(self.textField);
                make.right.equalTo(self);
                make.height.mas_equalTo(24);
            });
            
            self.placeHolderLabel.font = [UIFont cj_fontOfSize:16];
            self.placeHolderLabel.text = self.placeHolderText;
        }
    }
    
    if (Check_ValidString(self.tipsText)) {
        self.placeHolderLabel.textColor = self.warningTitleColor;
        if (self.containerStyle != CJPayCustomTextFieldContainerStyleWhiteAndBottomTips) {
            self.bottomLine.backgroundColor = self.warningTitleColor;
        }
        self.placeHolderLabel.text = CJString(self.tipsText);
        self.isInputInvalid = NO;
    } else {
        self.placeHolderLabel.textColor = [UIColor cj_999999ff];

        if (self.containerStyle != CJPayCustomTextFieldContainerStyleWhiteAndBottomTips) {
            self.placeHolderLabel.text = CJString(self.subTitleText);
            if (self.textField.isFirstResponder) {
                self.bottomLine.backgroundColor = [UIColor cj_222222ff];
            } else {
                self.bottomLine.backgroundColor = [UIColor cj_e8e8e8ff];
            }
        }
        self.isInputInvalid = YES;
    }
    self.isNeedUpdateTipsText = NO;
}

- (void)p_setSubTitleText {
    if (!self.isPlaceHolderStatus) {
        self.placeHolderLabel.text = _subTitleText;
    }
}

- (void)p_setPlaceHolderText {
    if (self.isPlaceHolderStatus) {
        self.placeHolderLabel.text = _placeHolderText;
    }
}

- (void)p_configKeyBoard {
    switch (self.keyBoardType) {
        case CJPayKeyBoardTypeCustomNumOnly:
            self.safeKeyBoard.keyboardType = CJPaySafeKeyboardTypeDefault;
            [self.safeKeyBoard setupUI];
            self.textField.keyboardType = UIKeyboardTypePhonePad;
            if (!CJ_Pad) {
                self.textField.inputView = self.boardContainerView;
            }
            break;
        case CJPayKeyBoardTypeCustomXEnable:
            self.safeKeyBoard.keyboardType = CJPaySafeKeyboardTypeIDCard;
            self.textField.keyboardType = UIKeyboardTypeDefault;
            [self.safeKeyBoard setupUI];
            if (!CJ_Pad) {
                self.textField.inputView = self.boardContainerView;
            }
            break;
        case CJPayKeyBoardTypeSystomDefault:
            self.textField.inputView = nil;
            self.textField.keyboardType = UIKeyboardTypeDefault;
            break;
        default:
            self.textField.inputView = nil;
            self.textField.keyboardType = UIKeyboardTypeDefault;
            break;
    }
}

- (void)p_setupKeyBoard {
    @CJWeakify(self)
    self.safeKeyBoard.deleteClickedBlock = ^{
        [weak_self p_deleteBackWord];
    };
    
    self.safeKeyBoard.characterClickedBlock = ^(NSString * _Nonnull string) {
        [weak_self p_inputStr:string];
    };
}

- (void)p_inputStr:(NSString *)str {
    BOOL allowInput = NO;
    NSString *oldStr = self.textField.text;
    NSRange selectRange = [self p_selectedRange];
    if (selectRange.location >= 0) {
        if (selectRange.length == 0) {
            allowInput = [self.textField textField:self.textField
        shouldChangeCharactersInRange:NSMakeRange(selectRange.location, 0)
                    replacementString:str];
        } else {
            allowInput = [self.textField textField:self.textField
        shouldChangeCharactersInRange:NSMakeRange(selectRange.location, selectRange.length)
                    replacementString:str];
        }
    }
    if (allowInput) {
        self.textField.text = [oldStr stringByReplacingCharactersInRange:selectRange withString:str];
        [self textFieldContentChange];
    }
}

- (void)p_deleteBackWord {
    BOOL allowInput = NO;
    NSString *oldStr = self.textField.text;
    NSRange selectRange = [self p_selectedRange];
    NSRange newRange = NSMakeRange(0, 0);
    
    if (selectRange.length == 0 && selectRange.location > 0) {
        // 删除一个字符
        newRange = NSMakeRange(selectRange.location - 1, 1);
        allowInput =  [self.textField textField:self.textField shouldChangeCharactersInRange:newRange replacementString:@""];
    } else if (selectRange.length > 0) {
        // 删除多个字符
        newRange = selectRange;
        allowInput =  [self.textField textField:self.textField shouldChangeCharactersInRange:newRange replacementString:@""];
    }
    
    if (allowInput) {
        self.textField.text = [oldStr stringByReplacingCharactersInRange:newRange withString:@""];
        [self textFieldContentChange];
    }
}

- (NSRange)p_selectedRange
{
    UITextPosition* beginning = self.textField.beginningOfDocument;
    
    UITextRange* selectedRange = self.textField.selectedTextRange;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    
    const NSInteger location = [self.textField offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [self.textField offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

- (void)p_installDefaultAppearance {
    CJPayCustomTextFieldContainer *appearance = [CJPayCustomTextFieldContainer appearance];
    if (appearance.warningTitleColor == nil) {
        self.warningTitleColor = [UIColor cj_fe2c55ff];
    }
    
    if (appearance.cursorColor == nil) {
        self.cursorColor = [UIColor cj_fe2c55ff];
    }
    
}

- (void)p_hideInfoButton:(BOOL)hidden {
    if (!Check_ValidString(self.infoContentStr)) {
        // 没有 infoContentStr 时，按钮一定不显示
        self.infoButton.hidden = YES;
        return;
    }
    
    self.infoButton.hidden = hidden;
}

#pragma mark - click method
- (void)p_clearButtonClick {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldWillClear:)]) {
        [self.delegate textFieldWillClear:self];
    }
    self.textField.text = @"";
    self.customClearView.hidden = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldDidClear:)]) {
        [self.delegate textFieldDidClear:self];
    }
}

- (void)p_infoButtonClick {
    // 如果infoClickBlock被实例化，则执行 self.infoClickBlock()
    if (self.infoClickBlock) {
        self.infoClickBlock();
    } else {
        if (Check_ValidString(self.infoContentStr)) {
            [CJPayAlertUtil customSingleAlertWithTitle:CJString(self.infoContentStr)
                                         content:@""
                                      buttonDesc:CJPayLocalizedStr(@"我知道了") actionBlock:nil
                                           useVC:[self cj_responseViewController]];
        }
    }
}

- (void)p_textFieldDidChange:(id) sender {
    self.customClearView.hidden = [self.textField.text isEqualToString:@""];
    [self p_hideInfoButton:!self.customClearView.hidden];
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldContentChange:textContainer:)]) {
        [self.delegate textFieldContentChange:self.textField.userInputContent textContainer:self];
    }
}

#pragma mark - getter & setter
- (void)setCursorColor:(UIColor *)cursorColor {
    if (cursorColor == nil) {
        return;
    }
    _cursorColor = cursorColor;
    self.textField.tintColor = cursorColor;
}

- (void)setWarningTitleColor:(UIColor *)warningTitleColor {
    if (warningTitleColor == nil) {
        return;
    }
    
    _warningTitleColor = warningTitleColor;
}

- (void)setPlaceHolderText:(NSString *)placeHolderText {
    _placeHolderText = placeHolderText;
    _isNeedSetPlaceHolderText = YES;
    [self p_setPlaceHolderText];
}

- (void)setSubTitleText:(NSString *)subTitleText {
    _subTitleText = subTitleText;
    _isNeedSetSubTitleText = YES;
    [self p_setSubTitleText];
}

- (void)setIsKeyBoardSupportEasyClose:(BOOL)isKeyBoardSupportEasyClose {
    _isKeyBoardSupportEasyClose = isKeyBoardSupportEasyClose;
    if (_isKeyBoardSupportEasyClose) {
        self.boardContainerView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT - 276 - CJ_TabBarSafeBottomMargin, CJ_SCREEN_WIDTH, 266 + CJ_TabBarSafeBottomMargin);
        
        [self.keyBoardTopView removeFromSuperview];
        [self.boardContainerView addSubview:self.keyBoardTopView];

        CJPayMasMaker(self.keyBoardTopView, {
            make.top.left.right.equalTo(self.boardContainerView);
            make.height.mas_equalTo(30);
        });
        
        CJPayMasMaker(self.safeKeyBoard, {
            make.left.right.equalTo(self.boardContainerView);
            make.top.equalTo(self.boardContainerView).offset(30);
            make.height.mas_equalTo(224);
        });
    } else {
        self.boardContainerView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT - 266 - CJ_TabBarSafeBottomMargin, CJ_SCREEN_WIDTH, 266 + CJ_TabBarSafeBottomMargin);
        
        [self.keyBoardTopView removeFromSuperview];
        CJPayMasMaker(self.safeKeyBoard, {
            make.left.right.top.equalTo(self.boardContainerView);
            make.height.mas_equalTo(224);
        });
    }
    
    [self setKeyBoardType:self.keyBoardType];
}

- (void)setTextFiledRightPadding:(CGFloat)textFiledRightPadding
{
    _textFiledRightPadding = self.textFiledRightPadding;
    CJPayMasReMaker(self.textField, {
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.top.equalTo(self).offset(10.5);
        make.height.equalTo(self).offset(48);
    });
}

// 重置键盘
- (void)setKeyBoardType:(CJPayKeyBoardType)keyBoardType {
    _keyBoardType = keyBoardType;
    [self p_configKeyBoard];
}

- (void)setInfoContentStr:(NSString *)infoContentStr {
    _infoContentStr = infoContentStr;
    [self p_hideInfoButton:!Check_ValidString(infoContentStr)];
}

#pragma mark - lazy view
- (UILabel *)inputTitleLabel {
    if (!_inputTitleLabel) {
        _inputTitleLabel = [[UILabel alloc] init];
        _inputTitleLabel.textColor = [UIColor cj_161823ff];
        _inputTitleLabel.font = [UIFont cj_fontOfSize:16];
        [self addSubview:_inputTitleLabel];
    }
    return _inputTitleLabel;
}

- (UILabel *)placeHolderLabel {
    if (!_placeHolderLabel) {
        _placeHolderLabel = [[UILabel alloc] init];
        _placeHolderLabel.textColor = [UIColor cj_999999ff];
        _placeHolderLabel.font = [UIFont cj_fontOfSize:16];
        [self addSubview:_placeHolderLabel];
    }
    return _placeHolderLabel;
}

- (UIView *)bottomLine {
    if (!_bottomLine) {
        _bottomLine = [[UIView alloc] init];
        _bottomLine.backgroundColor = [UIColor cj_e8e8e8ff];
        [self addSubview:_bottomLine];
    }
    return _bottomLine;
}

- (CJPayCustomTextField *)textField {
    if (!_textField) {
        _textField = [[CJPayCustomTextField alloc] init];
        _textField.textFieldDelegate = self;
        _textField.textColor = [UIColor cj_222222ff];
        if (self.containerStyle == CJPayCustomTextFieldContainerStyleWhiteAndBottomTips) {
            _textField.font = [UIFont cj_boldFontOfSize:16];
        } else {
            _textField.font = [UIFont cj_fontOfSize:16];
        }
        [self addSubview:_textField];
        [_textField addTarget:self action:@selector(p_textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
    return _textField;
}

- (CJPayCustomRightView *)customClearView {
    if (!_customClearView) {
        _customClearView = [[CJPayCustomRightView alloc] initWithFrame:CGRectMake(0, 0, 32, 48)];
        _customClearView.rightButton.cj_size = CGSizeMake(16, 16);
//        _customClearView.rightButton.center = _customClearView.center;
        _customClearView.rightButton.center = CGPointMake(_customClearView.center.x + 4, _customClearView.center.y);
        [_customClearView setRightButtonImageWithName:@"cj_clear_button_icon"];
        [_customClearView.rightButton addTarget:self action:@selector(p_clearButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _customClearView;
}

- (CJPayButton *)infoButton {
    if (!_infoButton) {
        _infoButton = [CJPayButton new];
        _infoButton.cjEventInterval = 1;
        _infoButton.hidden = YES;
        [_infoButton cj_setImageName:@"cj_withdraw_info_button_3x_icon"
                     forState:UIControlStateNormal];
        [_infoButton addTarget:self action:@selector(p_infoButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _infoButton;
}

- (CJPaySafeKeyboard *)safeKeyBoard {
    if (!_safeKeyBoard) {
        _safeKeyBoard = [[CJPaySafeKeyboard alloc] init];
        [_safeKeyBoard setupUIWithModel:[CJPaySafeKeyboardStyleConfigModel modelWithType:CJPaySafeKeyboardTypeDenoise]];
    }
    return _safeKeyBoard;
}

- (CJPayCustomKeyboardTopView *)keyBoardTopView {
    if (!_keyBoardTopView) {
        _keyBoardTopView = [[CJPayCustomKeyboardTopView alloc] init];
        @CJWeakify(self)
        _keyBoardTopView.completionBlock = ^{
            @CJStrongify(self)
            [self.textField resignFirstResponder];
        };
    }
    return _keyBoardTopView;
}

- (UIView *)boardContainerView {
    if (!_boardContainerView) {
        _boardContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, CJ_SCREEN_HEIGHT - 240 - CJ_TabBarSafeBottomMargin, CJ_SCREEN_WIDTH, 240 + CJ_TabBarSafeBottomMargin)];
        _boardContainerView.backgroundColor = [UIColor cj_colorWithHexString:@"F1F1F2"];
        [_boardContainerView addSubview:self.safeKeyBoard];
    }
    return _boardContainerView;
}

#pragma mark CJPayCustomTextFieldDelegate
- (void)textFieldBeginEdit {
    self.customClearView.hidden = [self.textField.text isEqualToString:@""];
    [self textFieldBeginEditAnimation];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldBeginEdit:)]) {
        [self.delegate textFieldBeginEdit:self];
    }
}

- (void)textFieldEndEdit {
    [self textFieldEndEditAnimation];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldEndEdit:)]) {
        [self.delegate textFieldEndEdit:self];
    }
}

- (void)textFieldWillClear {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldWillClear:)]) {
        [self.delegate textFieldWillClear:self];
    }
}

- (void)textFieldContentChange {
    self.customClearView.hidden = [self.textField.text isEqualToString:@""];
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldContentChange:textContainer:)]) {
        [self.delegate textFieldContentChange:self.textField.userInputContent textContainer:self];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        return [self.delegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
    }
    return YES;
}

@end
