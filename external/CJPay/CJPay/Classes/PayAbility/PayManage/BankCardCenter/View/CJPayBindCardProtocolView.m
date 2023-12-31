//
//  CJPayBindCardProtocolView.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/15.
//

#import "CJPayBindCardProtocolView.h"
#import "CJPayProtocolDetailViewController.h"
#import "CJPayStyleCheckBox.h"
#import "CJPayUIMacro.h"
#import "CJPayThemeStyleManager.h"


@interface CJPayBindCardProtocolView()

@property (nonatomic,strong) CJPayStyleCheckBox *leftButton;
@property (nonatomic,strong) UILabel *protocolLabel;

@property (nonatomic,copy) NSArray<CJPayQuickPayUserAgreement *> *agreements;

@end

@implementation CJPayBindCardProtocolView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.leftButton];
    [self addSubview:self.protocolLabel];
    
    CJPayMasMaker(self.leftButton, {
        make.top.equalTo(self).offset(16);
        make.left.equalTo(self).offset(24);
        make.width.equalTo(@16);
        make.height.equalTo(@16);
    });
    
    CJPayMasMaker(self.protocolLabel, {
        make.top.equalTo(self).offset(12);
        make.bottom.equalTo(self).offset(-12);
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
    });
}

- (void)updateWithAgreements:(NSArray<CJPayQuickPayUserAgreement *> *)agreements isNeedAgree:(BOOL)isNeedAgree {
    self.agreements = agreements;
    NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
    paraStyle.cjMaximumLineHeight = 21;
    paraStyle.cjMinimumLineHeight = 21;
    
    NSDictionary *weakAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:13],
                                     NSForegroundColorAttributeName : [UIColor cj_999999ff],
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSDictionary *mainAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:13],
                                     NSForegroundColorAttributeName : [CJPayThemeStyleManager shared].serverTheme.agreementTextColor,
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSString *title = isNeedAgree ? CJPayLocalizedStr(@"阅读并同意"): CJPayLocalizedStr(@"阅读");
    NSMutableAttributedString *protocolAttrStr = [[NSMutableAttributedString alloc] initWithString:CJPayLocalizedStr(title) attributes:weakAttributes];
    
    [self.agreements enumerateObjectsUsingBlock:^(CJPayQuickPayUserAgreement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *protocolStr = [NSString stringWithFormat:@" 《%@》", obj.title];
        [protocolAttrStr appendAttributedString:[[NSAttributedString alloc] initWithString:CJString(protocolStr) attributes:mainAttributes]];
    }];
    
    self.protocolLabel.attributedText = protocolAttrStr;
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    self.leftButton.selected = _isSelected;
}

- (void)leftButtonClick {
    self.isSelected = !self.isSelected;
    CJ_CALL_BLOCK(self.protocolSelectCompletion, self.isSelected);
}

- (void)protocolLabelTapped {
    self.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.userInteractionEnabled = YES;
    });
    CJ_CALL_BLOCK(self.protocolClickCompletion);
    [self gotoProtocolDetail:YES
          showContinueButton:NO];
}

- (void)gotoProtocolDetail:(BOOL)supportClickMaskBack
        showContinueButton:(BOOL)showContinueButton {
    if (self.agreements.count <= 0) { return; }
    
    if (self.agreements.count > 1) {
        CJPayProtocolListViewController *vc = [CJPayProtocolListViewController new];
        vc.merchantId = self.merchantId;
        vc.appId = self.appId;
        vc.userAgreements = self.agreements;
        vc.animationType = HalfVCEntranceTypeFromBottom;
        vc.showContinueButton = showContinueButton;
        vc.isSupportClickMaskBack = supportClickMaskBack;
        [vc useCloseBackBtn];
        @CJWeakify(self)
        vc.agreeCompletion = ^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.agreeCompletion);
        };
        
        UIViewController *responseVC = [self cj_responseViewController];
        [responseVC.navigationController pushViewController:vc animated:YES];
    } else {
        CJPayQuickPayUserAgreement *agreement = self.agreements.firstObject;
        CJPayProtocolDetailViewController *vc = [CJPayProtocolDetailViewController new];
        vc.merchantId = self.merchantId;
        vc.appId = self.appId;
        vc.url = agreement.contentURL;
        vc.navTitle = agreement.title;
        vc.showContinueButton = showContinueButton;
        vc.animationType = HalfVCEntranceTypeFromBottom;
        vc.isSupportClickMaskBack = supportClickMaskBack;
        [vc useCloseBackBtn];
        @CJWeakify(self)
        vc.agreeCompletionBeforeAnimation = ^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.agreeCompletion);
        };
        
        UIViewController *responseVC = [self cj_responseViewController];
        [responseVC.navigationController pushViewController:vc animated:YES];
    }
}

- (CJPayButton *)leftButton {
    if (!_leftButton) {
        _leftButton = [[CJPayStyleCheckBox alloc] init];
        _leftButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_leftButton addTarget:self action:@selector(leftButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _leftButton.hidden = YES;
    }
    return _leftButton;
}

- (UILabel *)protocolLabel {
    if (!_protocolLabel) {
        _protocolLabel = [[UILabel alloc] init];
        _protocolLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _protocolLabel.userInteractionEnabled = YES;
        _protocolLabel.numberOfLines = 0;
        [_protocolLabel cj_viewAddTarget:self
                                  action:@selector(protocolLabelTapped)
                        forControlEvents:UIControlEventTouchUpInside];
    }
    return _protocolLabel;
}

@end
