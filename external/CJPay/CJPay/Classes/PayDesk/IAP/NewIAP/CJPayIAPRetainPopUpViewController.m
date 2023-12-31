//
//  CJPayIAPRetainPopUpViewController.m
//  Aweme
//
//  Created by chenbocheng.moon on 2023/2/28.
//

#import "CJPayIAPRetainPopUpViewController.h"
#import "CJPayUIMacro.h"

@interface CJPayIAPRetainPopUpViewController ()

@property (nonatomic, strong) CJPayButton *confirmButton;
@property (nonatomic, strong) CJPayButton *cancelButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UILabel *helpLabel;
@property (nonatomic, strong) UIImageView *arrowView;

@end

@implementation CJPayIAPRetainPopUpViewController

- (instancetype)initWithTitle:(NSString *)title content:(NSString *)content {
    self = [super init];
    if (self) {
        self.titleLabel.text = title;
        self.contentLabel.text = content;
    }
    return self;
}

- (void)showOnTopVC:(UIViewController *)vc {
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:vc];
    if (!CJ_Pad && topVC.navigationController && [topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        [topVC.navigationController pushViewController:self animated:YES];
    } else {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self presentWithNavigationControllerFrom:topVC useMask:YES completion:nil];
    }
}

- (void)setupUI {
    [super setupUI];
    self.containerView.layer.cornerRadius = 16;
    [self.containerView addSubview:self.titleLabel];
    [self.containerView addSubview:self.contentLabel];
    [self.containerView addSubview:self.helpLabel];
    [self.containerView addSubview:self.arrowView];
    [self.containerView addSubview:self.confirmButton];
    [self.containerView addSubview:self.cancelButton];
    
    CJPayMasReMaker(self.containerView, {
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.centerY.equalTo(self.view);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.containerView.mas_top).offset(16);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.height.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.contentLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
    });
    
    CJPayMasMaker(self.helpLabel, {
        make.top.equalTo(self.contentLabel.mas_bottom).offset(8);
        make.centerX.equalTo(self.view).offset(-12);
    });
    
    CJPayMasMaker(self.arrowView, {
        make.centerY.equalTo(self.helpLabel);
        make.left.equalTo(self.helpLabel.mas_right);
        make.height.width.mas_equalTo(12);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.top.equalTo(self.helpLabel.mas_bottom).offset(20);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.height.mas_equalTo(44);
    });
    
    CJPayMasMaker(self.cancelButton, {
        make.top.equalTo(self.confirmButton.mas_bottom).offset(12);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.containerView.mas_bottom).offset(-12);
    });
}

- (void)p_confirmClick {
    CJ_CALL_BLOCK(self.clickConfirmBlock);
}

- (void)p_helpClick {
    CJ_CALL_BLOCK(self.clickHelpBlock);
}

- (void)p_cancelClick {
    CJ_CALL_BLOCK(self.clickCancelBlock);
}

#pragma mark - getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [UILabel new];
        _contentLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _contentLabel.font = [UIFont cj_fontOfSize:14];
        _contentLabel.textAlignment = NSTextAlignmentCenter;
        _contentLabel.numberOfLines = 0;
    }
    return _contentLabel;
}

- (CJPayButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [CJPayButton new];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmButton.titleLabel.textColor = [UIColor whiteColor];
        [_confirmButton cj_setBtnBGColor:[UIColor cj_colorWithHexString:@"#FE2C55"]];
        [_confirmButton setTitle:CJPayLocalizedStr(@"继续支付") forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(p_confirmClick) forControlEvents:UIControlEventTouchUpInside];
        _confirmButton.layer.cornerRadius = 8;
        _confirmButton.layer.masksToBounds = YES;
        _confirmButton.cjEventInterval = 1;
    }
    return _confirmButton;
}

- (CJPayButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [CJPayButton new];
        [_cancelButton cj_setBtnTitle:CJPayLocalizedStr(@"放弃")];
        [_cancelButton cj_setBtnTitleColor:[UIColor cj_161823WithAlpha:0.6]];
        [_cancelButton addTarget:self action:@selector(p_cancelClick) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.titleLabel.font = [UIFont cj_fontOfSize:15];
        _cancelButton.cjEventInterval = 1;
    }
    return _cancelButton;
}

- (UILabel *)helpLabel {
    if (!_helpLabel) {
        _helpLabel = [UILabel new];
        _helpLabel.textColor = [UIColor cj_colorWithHexString:@"#04498D"];
        _helpLabel.font = [UIFont cj_fontOfSize:14];
        _helpLabel.text = CJPayLocalizedStr(@"问题帮助");
        _helpLabel.textAlignment = NSTextAlignmentCenter;
        [_helpLabel cj_viewAddTarget:self action:@selector(p_helpClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _helpLabel;
}

- (UIImageView *)arrowView {
    if (!_arrowView) {
        _arrowView = [UIImageView new];
        [_arrowView cj_setImage:@"cj_blue_arrow_icon"];
        [_arrowView cj_viewAddTarget:self action:@selector(p_helpClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _arrowView;
}

@end
