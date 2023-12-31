//
//  CJPayBDBioConfirmViewController.m
//  Pods
//
//  Created by 尚怀军 on 2021/5/17.
//

#import "CJPayBDBioConfirmViewController.h"
#import "CJPayStyleButton.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayUIMacro.h"

@interface CJPayBDBioConfirmViewController ()

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;

@end

@implementation CJPayBDBioConfirmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self setTitle:CJPayLocalizedStr(@"极速支付")];
}

- (void)onConfirmClick {
    CJ_CALL_BLOCK(self.confirmBlock);
}

- (void)p_setupUI {
    [self.contentView addSubview:self.iconImageView];
    [self.contentView addSubview:self.descLabel];
    [self.contentView addSubview:self.confirmButton];
    if (Check_ValidString(self.verifyReasonText)) {
        self.descLabel.text = self.verifyReasonText;
    } else {
        self.descLabel.text = @"请进行面容安全验证";
    }
    
    CJPayMasMaker(self.iconImageView, {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(100);
        make.width.height.mas_equalTo(52);
    });
    
    CJPayMasMaker(self.descLabel, {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.iconImageView.mas_bottom).offset(12);
        make.height.mas_equalTo(22);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.descLabel.mas_bottom).offset(16);
        make.width.mas_equalTo(160);
        make.height.mas_equalTo(40);
    });
    
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self.view addSubview:self.safeGuardTipView];
        CJPayMasMaker(self.safeGuardTipView, {
            make.bottom.equalTo(self.contentView).offset(-16 - CJ_TabBarSafeBottomMargin);
            make.centerX.width.equalTo(self.view);
            make.height.mas_equalTo(18);
        });
    }

}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
        [_iconImageView cj_setImage:@"cj_face_icon"];
    }
    return _iconImageView;
}

- (UILabel *)descLabel {
    if (!_descLabel) {
        _descLabel = [UILabel new];
        _descLabel.font = [UIFont cj_fontOfSize:16];
        _descLabel.textColor = [UIColor cj_222222ff];
    }
    return _descLabel;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[CJPayStyleButton alloc] init];
        _confirmButton.titleLabel.font = [UIFont cj_fontOfSize:16];
        [_confirmButton setTitle:CJPayLocalizedStr(@"面容安全验证")
                        forState:UIControlStateNormal];
        [_confirmButton addTarget:self
                           action:@selector(onConfirmClick)
                 forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}


@end
