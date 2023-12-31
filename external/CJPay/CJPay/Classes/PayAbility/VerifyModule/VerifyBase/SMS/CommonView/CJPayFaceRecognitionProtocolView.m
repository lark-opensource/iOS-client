//
//  CJPayFaceRecognitionProtocolView.m
//  CJPay
//
//  Created by 尚怀军 on 2020/8/18.
//

#import "CJPayFaceRecognitionProtocolView.h"
#import "CJPayStyleCheckBox.h"
#import "CJPayUIMacro.h"
#import "UITapGestureRecognizer+CJPay.h"
#import "CJPayWebViewUtil.h"
#import "CJPayThemeStyleManager.h"

@interface CJPayFaceRecognitionProtocolView()

@property (nonatomic, strong) CJPayStyleCheckBox *checkBoxButton;
@property (nonatomic, strong) UILabel *protocolLabel;

@end

@implementation CJPayFaceRecognitionProtocolView

- (instancetype)initWithAgreementName:(NSString *)agreementName
                         agreementURL:(NSString *)agreementURL {
    self = [self init];
    if (self) {
        _agreementName = agreementName;
        _agreementURL = agreementURL;
        [self p_setupUI];
        [self updateWithProtocolURL:@""];
    }
    return self;
}

- (void)p_setupUI {
    self.clipsToBounds = NO;
    [self addSubview:self.checkBoxButton];
    [self addSubview:self.protocolLabel];
    self.checkBoxButton.selected = NO;
    
    CJPayMasMaker(self.checkBoxButton, {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self).offset(3);
        make.width.mas_equalTo(16);
        make.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.protocolLabel, {
        make.left.equalTo(self.checkBoxButton.mas_right).offset(6);
        make.right.equalTo(self).offset(-16);
        make.top.equalTo(self);
        make.bottom.equalTo(self);
    });
}

- (void)updateWithProtocolURL:(NSString *)urlStr {
    NSMutableParagraphStyle *paraghStyle = [NSMutableParagraphStyle new];
    paraghStyle.cjMaximumLineHeight = 20;
    paraghStyle.cjMinimumLineHeight = 20;
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont cj_fontOfSize:13],
                       NSParagraphStyleAttributeName:paraghStyle,
                      NSForegroundColorAttributeName:[UIColor cj_999999ff]};
    NSMutableAttributedString *protocolStr = [[NSMutableAttributedString alloc] initWithString:[self getProtocolHeadStr]
                                                                                    attributes:attributes];
    UIColor *protocolColor = [CJPayThemeStyleManager shared].serverTheme.agreementTextColor ?: [UIColor cj_douyinBlueColor];
    NSDictionary *jumpAttributes = @{NSFontAttributeName:[UIFont cj_fontOfSize:13],
                           NSParagraphStyleAttributeName:paraghStyle,
                          NSForegroundColorAttributeName:protocolColor};
    NSString *jumpText = [NSString stringWithFormat:@"《%@》", self.agreementName];
    NSAttributedString *jumpStr = [[NSAttributedString alloc] initWithString:jumpText
                                                                  attributes:jumpAttributes];
    [protocolStr appendAttributedString:jumpStr];

    self.protocolLabel.attributedText = protocolStr;
}

- (void)checkBoxButtonClick {
    self.checkBoxButton.selected = !self.checkBoxButton.isSelected;
    if (self.checkBoxButton.isSelected) {
        [self.trackDelegate event:@"wallet_alivecheck_firstasignment_guide_contract_click"
                     params:@{}];
    }
}

- (void)protocolLabelTapped:(UITapGestureRecognizer *)tapGesture {
    NSInteger addLength = 4;
    BOOL isClickProtocolDetail = [tapGesture cj_didTapAttributedTextInLabel:self.protocolLabel inRange:NSMakeRange([self getProtocolHeadStr].length, [self.agreementName length] + addLength)];
    if (isClickProtocolDetail) {
        // 跳转协议详情
        [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[self cj_responseViewController]
                                                           toUrl:CJString(self.agreementURL)
                                                          params:@{}
                                               nativeStyleParams:@{@"title": CJString(self.agreementName)}];
    }
}

- (CJPayStyleCheckBox *)checkBoxButton {
    if (!_checkBoxButton) {
        _checkBoxButton = [[CJPayStyleCheckBox alloc] init];
        [_checkBoxButton addTarget:self action:@selector(checkBoxButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [_checkBoxButton updateWithCheckImgName:@"cj_front_select_card_icon"
                                 noCheckImgName:@"cj_noselect_icon"];
    }
    return _checkBoxButton;
}

- (UILabel *)protocolLabel {
    if (!_protocolLabel) {
        _protocolLabel = [[UILabel alloc] init];
        _protocolLabel.userInteractionEnabled = YES;
        _protocolLabel.numberOfLines = 0;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(protocolLabelTapped:)];
        [_protocolLabel addGestureRecognizer:tapGesture];
    }
    return _protocolLabel;
}

- (NSString *)getProtocolHeadStr {
    return CJPayLocalizedStr(@"同意");
}

- (NSString *)agreementName {
    if (!_agreementName) {
        return CJPayLocalizedStr(@"人脸验证协议");
    }
    return _agreementName;
}

- (BOOL)checkBoxIsSelect {
    return  self.checkBoxButton.isSelected;
}

@end
