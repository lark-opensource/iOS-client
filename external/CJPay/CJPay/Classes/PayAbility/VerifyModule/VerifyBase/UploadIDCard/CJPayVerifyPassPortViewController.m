//
//  CJPayVerifyPassPortViewController.m
//  CJPay
//
//  Created by 王新华 on 4/21/20.
//

#import "CJPayVerifyPassPortViewController.h"
#import "CJPayStyleButton+Freeze.h"
#import "CJPayCustomTextFieldContainer.h"
#import "CJPayBindCardCachedIdentityInfoModel.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPayToast.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@interface CJPayVerifyPassPortViewController ()<CJPayCustomTextFieldContainerDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) CJPayCustomTextFieldContainer *idCardInputView;
@property (nonatomic, strong) CJPayStyleButton *verifyBtn;
@property (nonatomic, strong) CJPayStyleErrorLabel *errorInfoLabel;

@property (nonatomic, assign) CJPayBindCardChooseIDType bindCardChooseIDType;

@property (nonatomic, assign) BOOL shouldHandleInputTracker; // 第一次输入时埋点上报

@end

@implementation CJPayVerifyPassPortViewController

// protocol 中声明的属性需要手动同步
@synthesize trackDelegate = _trackDelegate;
@synthesize completion = _completion;
@synthesize response = _response;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_applyStyle];
    self.descLabel.attributedText = [self p_attributedDescString];
    [CJKeyboard becomeFirstResponder:self.idCardInputView.textField];
    
    if ([self isTWPass]) {
        [self setupType:CJPayBindCardChooseIDTypeTW];
    } else if ([self isHKMPass]){
        [self setupType:CJPayBindCardChooseIDTypeHK];
    } else if ([self isPassport]) {
        [self setupType:CJPayBindCardChooseIDTypePD];
    }
    self.verifyBtn.enabled = NO;
    
    [self p_trackWithEventName:@"wallet_riskcontrol_identified_page_imp" params:nil];
}

- (void)p_setupUI
{
    self.view.backgroundColor = UIColor.whiteColor;

    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.descLabel];
    [self.view addSubview:self.idCardInputView];
    [self.view addSubview:self.verifyBtn];
    [self.view addSubview:self.errorInfoLabel];
        
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.view.mas_top).offset(24 + self.navigationHeight);
        make.left.equalTo(self.view).offset(24);
        make.height.equalTo(@24);
        make.width.equalTo(self.view).offset(-24);
    });
    
    CJPayMasMaker(self.descLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.equalTo(self.view).offset(24);
        make.right.equalTo(self.view).offset(-24);
    });
    
    CJPayMasMaker(self.idCardInputView, {
        make.top.equalTo(self.descLabel.mas_bottom).offset(16);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.height.equalTo(@(69));
    });
    
    CJPayMasMaker(self.verifyBtn, {
        make.left.equalTo(self.view).offset(24);
        make.right.equalTo(self.view).offset(-24);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        make.top.equalTo(self.idCardInputView.mas_bottom).offset(32);
    });
    
    CJPayMasMaker(self.errorInfoLabel, {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.verifyBtn. mas_bottom).offset(24);
    });
}

- (void)p_applyStyle
{
    NSString *styleString = self.response.resultConfig.showStyle;
    if ([styleString length] == 0) {
        return;
    }
    
    if ([styleString isEqualToString:@"4"]) {
        UIColor *douyinRedColor = [UIColor cj_colorWithHexString:@"#FE2C55"];
        self.idCardInputView.textField.tintColor = douyinRedColor;
        self.errorInfoLabel.textColor = douyinRedColor;
    }
}

- (NSAttributedString *)p_attributedDescString
{
    NSDictionary *weakAttributes = @{NSFontAttributeName: [UIFont cj_fontOfSize:13],
                                     NSForegroundColorAttributeName: [UIColor cj_999999ff]};

    NSAttributedString *result;
    NSString *dynamicText;
    if ([self isHKMPass]) {
        dynamicText =[NSString stringWithFormat:CJPayLocalizedStr(@"为保障你的账户安全，请验证%@的港澳来往大陆通行证"), CJString(self.response.userInfo.mName) ];
    }
    else if ([self isTWPass]) {
        dynamicText =[NSString stringWithFormat:CJPayLocalizedStr(@"为保障你的账户安全，请验证%@的台湾居民来往大陆通行"), CJString(self.response.userInfo.mName) ];
    }
    else if ([self isPassport]) {
        dynamicText =[NSString stringWithFormat:CJPayLocalizedStr(@"为保障你的账户安全，请验证%@的护照信息"), CJString(self.response.userInfo.mName) ];
    }
    else{
        dynamicText =[NSString stringWithFormat:CJPayLocalizedStr(@"为保障你的账户安全，请验证%@的身份证号后6位"), CJString(self.response.userInfo.mName) ];
    }
    result = [[NSAttributedString alloc] initWithString:CJString(dynamicText)
                                                                   attributes:weakAttributes];
    return result;
}

- (BOOL)isHKMPass {
    return [self.response.userInfo.certificateType isEqualToString:@"HKMPASS"];
}

- (BOOL)isTWPass {
    return [self.response.userInfo.certificateType isEqualToString:@"TAIWANPASS"];
}

- (BOOL)isPassport {
    return [self.response.userInfo.certificateType isEqualToString:@"PASSPORT"];
}

#pragma mark - Subviews

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = UIColor.cj_222222ff;
        _titleLabel.font = [UIFont cj_boldFontOfSize:24];
        _titleLabel.text = CJPayLocalizedStr(@"验证实名信息");
    }
    return _titleLabel;
}

- (UILabel *)descLabel
{
    if (!_descLabel) {
        _descLabel = [[UILabel alloc] init];
        _descLabel.numberOfLines = 0;
    }
    return _descLabel;
}

- (CJPayStyleButton *)verifyBtn {
    if (!_verifyBtn) {
        _verifyBtn = [CJPayStyleButton new];
        [_verifyBtn setTitle:CJPayLocalizedStr(@"立即验证") forState:UIControlStateNormal];
        [_verifyBtn addTarget:self action:@selector(verifyAction) forControlEvents:UIControlEventTouchUpInside];
        _verifyBtn.layer.cornerRadius = 5;
        _verifyBtn.clipsToBounds = YES;
    }
    return _verifyBtn;
}


- (CJPayCustomTextFieldContainer *)idCardInputView {
    if (!_idCardInputView) {
        _idCardInputView = [CJPayCustomTextFieldContainer new];
        _idCardInputView.delegate = self;
    }
    return _idCardInputView;
}

- (CJPayStyleErrorLabel *)errorInfoLabel
{
    if (!_errorInfoLabel) {
        _errorInfoLabel = [CJPayStyleErrorLabel new];
        NSMutableAttributedString *errorAttr = [[NSMutableAttributedString alloc] init];
        NSMutableParagraphStyle *paraghStyle = [NSMutableParagraphStyle new];
        paraghStyle.cjMaximumLineHeight = 16;
        paraghStyle.cjMinimumLineHeight = 16;
        NSDictionary *attributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:14],NSParagraphStyleAttributeName:paraghStyle,
                                     
        };
        [errorAttr addAttributes:attributes range:NSMakeRange(0, errorAttr.length)];
        _errorInfoLabel.attributedText = errorAttr;
        _errorInfoLabel.textAlignment = NSTextAlignmentCenter;
            self.errorInfoLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _errorInfoLabel;
}

- (void)setupType:(CJPayBindCardChooseIDType) type {
    
    self.bindCardChooseIDType = type;
    
    if (type == CJPayBindCardChooseIDTypeHK) {
        _idCardInputView.textField.supportCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"HhMm1234567890"];
        _idCardInputView.textField.limitCount = 9;
        _idCardInputView.textField.supportSeparate = YES;
        _idCardInputView.placeHolderText = CJPayLocalizedStr(@"请输入证件号码");
        _idCardInputView.subTitleText = CJPayLocalizedStr(@"证件号码");
        _idCardInputView.keyBoardType = CJPayKeyBoardTypeSystomDefault;
    } else if (type == CJPayBindCardChooseIDTypeTW) {
        _idCardInputView.textField.supportCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"1234567890"];
        _idCardInputView.textField.limitCount = 8;
        _idCardInputView.textField.supportSeparate = YES;
        _idCardInputView.placeHolderText = CJPayLocalizedStr(@"请输入证件号码");
        _idCardInputView.subTitleText = CJPayLocalizedStr(@"证件号码");
        _idCardInputView.keyBoardType = CJPayKeyBoardTypeCustomNumOnly;
    } else if (type == CJPayBindCardChooseIDTypePD) {
        NSMutableCharacterSet *set = [NSMutableCharacterSet uppercaseLetterCharacterSet];
        [set formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789"]];
        _idCardInputView.textField.supportCharacterSet = set;
        _idCardInputView.textField.limitCount = 9;
        _idCardInputView.textField.supportSeparate = YES;
        _idCardInputView.placeHolderText = CJPayLocalizedStr(@"请输入证件号码");
        _idCardInputView.subTitleText = CJPayLocalizedStr(@"证件号码");
        _idCardInputView.keyBoardType = CJPayKeyBoardTypeCustomXEnable;
    }
}

- (void)verifyAction {
    NSString *content = [self.idCardInputView.textField userInputContent];
    if (Check_ValidString(content)) {
        CJ_CALL_BLOCK(self.completion, content);
    } else {
        CJPayLogInfo(@"input nothing");
    }
}

#pragma MARK: CJPayCustomTextFieldContainerDelegate

- (void)textFieldContentChange:(NSString *)curText textContainer:(CJPayCustomTextFieldContainer *)textContainer {
    
    BOOL limitCountEnabled = (curText.length >= self.idCardInputView.textField.limitCount);
    BOOL passPortEnabled = (self.bindCardChooseIDType == CJPayBindCardChooseIDTypePD && curText.length >= 1);
    
    self.verifyBtn.enabled = limitCountEnabled || passPortEnabled;
    
    if (!self.shouldHandleInputTracker) {
        [self p_trackWithEventName:@"wallet_riskcontrol_identified_page_input" params:nil];
        self.shouldHandleInputTracker = YES;
    }
    
    [self updateTips:@""];
}

#pragma out api
- (void)clearInput
{
    self.idCardInputView.textField.text = @"";
}

- (void)updateTips:(NSString *)text
{
    [self.idCardInputView updateTips:text];
}

- (void)updateErrorText:(NSString *)text{
    if (!self.navigationController) {
        [CJToast toastText:text inWindow:self.cj_window];
        return;
    }

    if (Check_ValidString(text)) {
        self.errorInfoLabel.hidden = NO;
        self.errorInfoLabel.text = text;
        CJPayMasReMaker(self.errorInfoLabel,{
            make.leading.trailing.equalTo(self.view);
            make.top.equalTo(self.verifyBtn.mas_bottom).offset(24);
        });
    } else {
       self.errorInfoLabel.hidden = YES;
    }
}

#pragma mark - Tracker

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    if (self.trackDelegate && [self.trackDelegate respondsToSelector:@selector(event:params:)]) {
        [self.trackDelegate event:eventName params:params];
    }
}

@end
