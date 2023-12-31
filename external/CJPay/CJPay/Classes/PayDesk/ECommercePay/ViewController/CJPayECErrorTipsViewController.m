//
//  CJPayECErrorTipsViewController.m
//  Pods
//
//  Created by 尚怀军 on 2021/10/22.
//

#import "CJPayECErrorTipsViewController.h"
#import "CJPaySubPayTypeIconTipModel.h"
#import "CJPayStyleButton.h"
#import "CJPaySDKMacro.h"

@interface CJPayECErrorTipsViewController ()

@property (nonatomic, strong) CJPayButton *closeButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;

@end

@implementation CJPayECErrorTipsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)p_setupUI {
    [self.containerView addSubview:self.closeButton];
    [self.containerView addSubview:self.titleLabel];
    self.titleLabel.text = CJString(self.iconTips.title);
    
    CJPayMasMaker(self.closeButton, {
        make.right.equalTo(self.containerView).offset(-12);
        make.top.equalTo(self.containerView).offset(12);
        make.width.height.mas_equalTo(20);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.top.equalTo(self.containerView).offset(36);
        make.height.mas_equalTo(24);
    });
    
    UIView *lastObject = self.titleLabel;
    
    for (CJPaySubPayTypeIconTipInfoModel *model in self.iconTips.contentList) {
        UILabel *titleLabel = [self p_createSubTitleLabelWithText:model.subTitle];
        [self.containerView addSubview:titleLabel];
        
        CJPayMasMaker(titleLabel, {
            make.left.equalTo(self.containerView).offset(20);
            make.right.equalTo(self.containerView).offset(-20);
            make.top.equalTo(lastObject.mas_bottom).offset(10);
            make.height.mas_equalTo(Check_ValidString(model.subTitle) ? 20 : 0);
        });
        
        UILabel *contentLabel = [self p_createSubContentLabelWithText:model.subContent];
        [self.containerView addSubview:contentLabel];
        CJPayMasMaker(contentLabel, {
            make.left.equalTo(self.containerView).offset(20);
            make.right.equalTo(self.containerView).offset(-20);
            if (Check_ValidString(model.subTitle)) {
                make.top.equalTo(titleLabel.mas_bottom).offset(4);
            } else {
                make.top.equalTo(titleLabel.mas_bottom).offset(0);
            }
        });
        
        lastObject = contentLabel;
    }
    
    [self.containerView addSubview:self.confirmButton];
    CJPayMasMaker(self.confirmButton, {
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.top.equalTo(lastObject.mas_bottom).offset(24);
        make.height.mas_equalTo(44);
    });
    
    CJPayMasReMaker(self.containerView, {
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.centerY.equalTo(self.view);
        make.bottom.equalTo(self.confirmButton).offset(20);
    });
}

- (void)p_closeButtonTapped {
    [self dismissSelfWithCompletionBlock:^{
        CJ_CALL_BLOCK(self.closeCompletionBlock);
    }];
}

- (void)p_onConfirmButtonAction {
    [self dismissSelfWithCompletionBlock:^{
        CJ_CALL_BLOCK(self.closeCompletionBlock);
    }];
}

- (UILabel *)p_createSubTitleLabelWithText:(NSString *)text {
    UILabel *titleLabel = [UILabel new];
    titleLabel.font = [UIFont cj_boldFontOfSize:14];
    titleLabel.textColor = [UIColor cj_161823ff];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    [titleLabel btd_SetText:text lineHeight:20];
    titleLabel.numberOfLines = 0;
    return titleLabel;
}

- (UILabel *)p_createSubContentLabelWithText:(NSString *)text {
    UILabel *contentLabel = [UILabel new];
    contentLabel.font = [UIFont cj_fontOfSize:14];
    contentLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
    contentLabel.textAlignment = NSTextAlignmentLeft;
    [contentLabel btd_SetText:text lineHeight:20];
    contentLabel.numberOfLines = 0;
    return contentLabel;
}

- (CJPayButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [CJPayButton new];
        [_closeButton cj_setImageName:@"cj_close_icon" forState:UIControlStateNormal];
        [_closeButton addTarget:self
                         action:@selector(p_closeButtonTapped)
               forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _closeButton;
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

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[CJPayStyleButton alloc] init];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_confirmButton.titleLabel setTextColor:[UIColor whiteColor]];
        [_confirmButton cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        [_confirmButton setTitle:CJPayLocalizedStr(@"我知道了") forState:UIControlStateNormal];
        [_confirmButton addTarget:self
                           action:@selector(p_onConfirmButtonAction)
                 forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

@end
