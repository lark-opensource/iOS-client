//
//  CJPayButtonInfoViewController.m
//  Pods
//
//  Created by liutianyi on 2022/5/24.
//

#import "CJPayButtonInfoViewController.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPayStyleButton.h"
#import "CJPaySDKMacro.h"

@interface CJPayButtonInfoViewController ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;

@end

@implementation CJPayButtonInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)p_setupUI {
    self.containerView.layer.cornerRadius = 12;
    [self.containerView addSubview:self.titleLabel];
    [self.containerView addSubview:self.contentLabel];
    self.titleLabel.text = CJString(self.buttonInfo.mainTitle);
    self.contentLabel.text = CJString(self.buttonInfo.page_desc);
    
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.top.equalTo(self.containerView).offset(20);
        make.height.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.contentLabel, {
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
    });
    
    [self.containerView addSubview:self.confirmButton];
    CJPayMasMaker(self.confirmButton, {
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.top.equalTo(self.contentLabel.mas_bottom).offset(24);
        make.height.mas_equalTo(44);
    });
    
    CJPayMasReMaker(self.containerView, {
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.centerY.equalTo(self.view);
        make.bottom.equalTo(self.confirmButton).offset(20);
    });
}

- (void)p_onConfirmButtonAction {
    [self dismissSelfWithCompletionBlock:^{
    }];
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [UILabel new];
        _contentLabel.font = [UIFont cj_fontOfSize:14];
        _contentLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _contentLabel.textAlignment = NSTextAlignmentCenter;
        _contentLabel.numberOfLines = 0;
    }
    return _contentLabel;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[CJPayStyleButton alloc] init];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_confirmButton.titleLabel setTextColor:[UIColor whiteColor]];
        [_confirmButton cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        [_confirmButton setTitle:CJPayLocalizedStr(@"知道了") forState:UIControlStateNormal];
        [_confirmButton addTarget:self
                           action:@selector(p_onConfirmButtonAction)
                 forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

@end
