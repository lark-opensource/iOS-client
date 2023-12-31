//
//  CJPayVerifyIDCardViewController.m
//  CJPay
//
//  Created by liyu on 2020/3/24.
//

#import "CJPayVerifyIDCardViewController.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayVerifySMSInputModule.h"
#import "CJPayIDCardLast6DigitsInputView.h"
#import "CJPayBaseSafeInputView.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPayThemeStyleManager.h"
#import "CJPayToast.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayServerThemeStyle.h"

@interface CJPayVerifyIDCardViewController ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) CJPayIDCardLast6DigitsInputView *inputModule;
@property (nonatomic, strong) CJPayStyleErrorLabel *errorLabel;

@end

@implementation CJPayVerifyIDCardViewController

// protocol 中声明的属性需要手动同步
@synthesize trackDelegate = _trackDelegate;
@synthesize completion = _completion;
@synthesize response = _response;

#pragma mark - Public

- (void)clearInput
{
    self.inputModule.textField.text = @"";
}

- (void)updateTips:(NSString *)text
{
    self.errorLabel.text = text;
}

#pragma mark - VC lifecyle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self p_setupUI];
    [self p_applyStyle];

    self.descLabel.attributedText = [self p_attributedDescString];
    [CJKeyboard becomeFirstResponder:self.inputModule.textField];

    [self p_trackWithEventName:@"wallet_riskcontrol_identified_page_imp" params:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

#pragma mark - Private

- (void)back
{
    if (self.cjBackBlock) {
        CJ_CALL_BLOCK(self.cjBackBlock);
        return;
    }
    [super back];
}

- (void)p_setupUI
{
    self.view.backgroundColor = UIColor.cj_f4f5f6ff;
    self.navigationBar.backgroundColor = UIColor.cj_f4f5f6ff;

    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.descLabel];
    [self.view addSubview:self.inputModule];
    [self.view addSubview:self.errorLabel];
    
    CGFloat top = 112 - 64 + self.navigationHeight;
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.view.mas_top).offset(top);
        make.centerX.equalTo(self.view);
        make.height.equalTo(@24);
        make.width.equalTo(self.view);
    });
    
    CJPayMasMaker(self.descLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(20);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
    });
    
    CJPayMasMaker(self.inputModule, {
        make.top.equalTo(self.descLabel.mas_bottom).offset(24);
        make.leading.trailing.equalTo(self.view);
    });
    
    CJPayMasMaker(self.errorLabel, {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.inputModule.mas_bottom).offset(24);
    });

    [[CJPayIDCardLast6DigitsInputView appearance] setCursorColor:[CJPayThemeStyleManager shared].serverTheme.cursorColor];
}

- (void)p_applyStyle
{
    NSString *styleString = self.response.resultConfig.showStyle;
    if ([styleString length] == 0) {
        return;
    }
    
    if ([styleString isEqualToString:@"4"]) {
        UIColor *douyinRedColor = [UIColor cj_colorWithHexString:@"#FE2C55"];
        self.inputModule.textField.tintColor = douyinRedColor;
        self.errorLabel.textColor = douyinRedColor;
    }
}

- (NSAttributedString *)p_attributedDescString
{
    NSDictionary *weakAttributes = @{NSFontAttributeName: [UIFont cj_fontOfSize:13],
                                     NSForegroundColorAttributeName: [UIColor cj_999999ff]};

    
    NSDictionary *mainAttributes = @{NSFontAttributeName: [UIFont cj_fontOfSize:13],
                                     NSForegroundColorAttributeName: [UIColor cj_222222ff]};

    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:CJPayLocalizedStr(@"为保障你的账户安全，请验证 ")
                                                                               attributes:weakAttributes];
    
    NSString *name = [NSString stringWithFormat:@" %@ ", CJString(self.response.userInfo.mName) ];
    [result appendAttributedString:[[NSAttributedString alloc] initWithString:CJString(name)
                                                                   attributes:mainAttributes]];
    NSString *dynamicText = CJPayLocalizedStr(@"的身份证后6位");
    [result appendAttributedString:[[NSAttributedString alloc] initWithString:CJString(dynamicText)
                                                                   attributes:weakAttributes]];

    return result;
}

#pragma mark - Subviews

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = UIColor.cj_222222ff;
        _titleLabel.font = [UIFont cj_boldFontOfSize:24];
        _titleLabel.text = CJPayLocalizedStr(@"验证实名信息");
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)descLabel
{
    if (!_descLabel) {
        _descLabel = [[UILabel alloc] init];
        _descLabel.textAlignment = NSTextAlignmentCenter;
        _descLabel.numberOfLines = 0;
    }
    return _descLabel;
}

- (CJPayStyleErrorLabel *)errorLabel
{
    if (!_errorLabel) {
        _errorLabel = [CJPayStyleErrorLabel new];
        NSMutableAttributedString *errorAttr = [[NSMutableAttributedString alloc] init];
        NSMutableParagraphStyle *paraghStyle = [NSMutableParagraphStyle new];
        paraghStyle.cjMaximumLineHeight = 16;
        paraghStyle.cjMinimumLineHeight = 16;
        NSDictionary *attributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:14],NSParagraphStyleAttributeName:paraghStyle,
                                     
        };
        [errorAttr addAttributes:attributes range:NSMakeRange(0, errorAttr.length)];
        
        _errorLabel.attributedText = errorAttr;
        _errorLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _errorLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _errorLabel;
}

- (CJPayIDCardLast6DigitsInputView *)inputModule
{
    if (!_inputModule) {
        _inputModule = [[CJPayIDCardLast6DigitsInputView alloc] init];
        @CJWeakify(self)
        _inputModule.completion = ^(NSString * last6Digits) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.completion, last6Digits);
        };
        _inputModule.didStartInputBlock = ^() {
            @CJStrongify(self)
            [self updateTips:@""];
            
            [self p_trackWithEventName:@"wallet_riskcontrol_identified_page_input" params:nil];
        };
    }
    return _inputModule;
}

- (void)updateErrorText:(NSString *)text{
    if (!self.navigationController) {
        [CJToast toastText:text inWindow:self.cj_window];
        return;
    }
    
    if (Check_ValidString(text)) {
        self.errorLabel.hidden = NO;
        self.errorLabel.text = text;
        CJPayMasReMaker(self.errorLabel,{
            make.leading.trailing.equalTo(self.view);
            make.top.equalTo(self.inputModule.mas_bottom).offset(24);
        });
    } else {
        self.errorLabel.hidden = YES;
    }

}

#pragma mark - Tracker

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    if (self.trackDelegate && [self.trackDelegate respondsToSelector:@selector(event:params:)]) {
        [self.trackDelegate event:eventName params:params];
    }
}

@end
