//
//  CJPayPasswordLockPopUpViewController.m
//  Pods
//  密码锁定弹窗
//  Created by 孟源 on 2022/1/11.
//
#import "CJPayErrorButtonInfo.h"
#import "CJPayPasswordLockPopUpViewController.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"

@interface CJPayPasswordLockPopUpViewController ()

@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;
@property (nonatomic, strong) CJPayStyleButton *forgetPwdBtn;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) CJPayButton *cancelBtn;

@end

@implementation CJPayPasswordLockPopUpViewController

- (instancetype)initWithButtonInfo:(CJPayErrorButtonInfo *)buttonInfo {
    self = [super init];
    
    if (self) {
        _buttonInfo = buttonInfo;
    }
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    self.view.hidden = NO;
    [super viewDidAppear:animated];
}

- (void)setupUI {
    [super setupUI];
    self.containerView.layer.cornerRadius = 12;
    
    [self.containerView addSubview:self.forgetPwdBtn];
    [self.containerView addSubview:self.cancelBtn];
    [self.containerView addSubview:self.descLabel];
    
    CJPayMasReMaker(self.containerView, {
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.centerY.equalTo(self.view);
    });
    
    CJPayMasMaker(self.descLabel, {
        make.top.equalTo(self.containerView).offset(24);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
    });
    
    CJPayMasMaker(self.forgetPwdBtn, {
        make.top.equalTo(self.descLabel.mas_bottom).offset(24);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.height.mas_equalTo(44);
    })
    
    CJPayMasMaker(self.cancelBtn, {
        make.top.equalTo(self.forgetPwdBtn.mas_bottom).offset(13);
        make.left.equalTo(self.containerView).offset(32);
        make.right.equalTo(self.containerView).offset(-32);
        make.height.mas_equalTo(18);
        make.bottom.equalTo(self.containerView.mas_bottom).offset(-13);
    })
}

- (void)p_forgetPwd {
    CJ_CALL_BLOCK(self.forgetPwdBlock);
}

- (void)p_cancel {
    CJ_CALL_BLOCK(self.cancelBlock);
}

- (CJPayStyleButton *)forgetPwdBtn {
    if (!_forgetPwdBtn) {
        _forgetPwdBtn = [CJPayStyleButton new];
        _forgetPwdBtn.cornerRadius = 4;
        [_forgetPwdBtn setTitle:Check_ValidString(self.buttonInfo.right_button_desc) ? CJPayLocalizedStr(self.buttonInfo.right_button_desc) : CJPayLocalizedStr(@"忘记密码") forState:UIControlStateNormal];
        [_forgetPwdBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _forgetPwdBtn.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_forgetPwdBtn addTarget:self action:@selector(p_forgetPwd) forControlEvents:UIControlEventTouchUpInside];
    }
    return _forgetPwdBtn;
}

- (CJPayButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [CJPayButton new];
        [_cancelBtn setTitle:Check_ValidString(self.buttonInfo.left_button_desc) ? CJPayLocalizedStr(self.buttonInfo.left_button_desc) : CJPayLocalizedStr(@"取消") forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:[UIColor cj_161823WithAlpha:0.6] forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [UIFont cj_fontOfSize:13];
        [_cancelBtn addTarget:self action:@selector(p_cancel) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (UILabel *)descLabel {
    if (!_descLabel) {
        _descLabel = [UILabel new];
        _descLabel.text = Check_ValidString(self.buttonInfo.page_desc) ? CJPayLocalizedStr(self.buttonInfo.page_desc) : CJPayLocalizedStr(@"密码频繁错误已被锁定");
        _descLabel.textColor = [UIColor blackColor];
        _descLabel.font = [UIFont cj_boldFontOfSize:17];
        _descLabel.textAlignment = NSTextAlignmentCenter;
        _descLabel.numberOfLines = 0;
    }
    return _descLabel;
}
@end
