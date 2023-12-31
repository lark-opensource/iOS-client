//
//  CJPayBioConfirmViewController.m
//  Pods
//
//  Created by wangxiaohong on 2020/11/13.
//

#import "CJPayBioConfirmViewController.h"

#import "CJPayStyleButton.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayUIMacro.h"


@interface CJPayBioConfirmViewController ()

@property (nonatomic, strong) CJPayBioConfirmHomeView *homeView;
@property (nonatomic, strong) CJPayButton *passCodeVerifyButton;

@end

@implementation CJPayBioConfirmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setNavTitle];
    [self p_setupUI];
}

- (void)setConfirmButtonEnableStatus:(BOOL)isEnable {
    self.homeView.confirmButton.enabled = isEnable;
}

- (void)back{
    if (self.cjBackBlock) {
        CJ_CALL_BLOCK(self.cjBackBlock);
    } else {
        [super back];
    }
}

#pragma mark - Getter

- (CJPayBioConfirmHomeView *)homeView
{
    if (!_homeView) {
        _homeView = [CJPayBioConfirmHomeView new];
        [_homeView updateUI:self.model];
        @CJWeakify(self)
        _homeView.confirmButtonClickBlock = ^{
            @CJStrongify(self)
            [self p_confirmButtonClick];
        };
        _homeView.trackerBlock = ^(NSString * _Nonnull event, NSDictionary * _Nonnull params) {
            @CJStrongify(self)
            [self p_trackWithEventName:event params:params];
        };
    }
    return _homeView;
}

- (CJPayButton *)passCodeVerifyButton {
    if (!_passCodeVerifyButton) {
        _passCodeVerifyButton = [CJPayButton new];
        _passCodeVerifyButton.titleLabel.font = [UIFont cj_fontOfSize:13];
        [_passCodeVerifyButton setTitle:CJPayLocalizedStr(@"使用密码") forState:UIControlStateNormal];
        [self.passCodeVerifyButton cj_setBtnTitleColor:[UIColor cj_161823WithAlpha:0.75]];
        [_passCodeVerifyButton addTarget:self action:@selector(p_passCodeVerifyPay) forControlEvents:UIControlEventTouchUpInside];
        _passCodeVerifyButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _passCodeVerifyButton;
}

#pragma mark - Private Methods

- (void)p_setupUI {
    [self.navigationBar addSubview:self.passCodeVerifyButton];
    [self.contentView addSubview:self.homeView];
    
    CJPayMasMaker(self.homeView, {
        make.top.left.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(- CJ_TabBarSafeBottomMargin - 20);
    });
    
    CJPayMasMaker(self.passCodeVerifyButton, {
        make.right.equalTo(self.navigationBar.mas_right).offset(-16);
        make.centerY.equalTo(self.navigationBar.titleLabel);
        make.height.mas_equalTo(18);
        make.left.greaterThanOrEqualTo(self.navigationBar.titleLabel.mas_right);
    });
}

- (void)p_setNavTitle {
    if (Check_ValidString([CJPayBrandPromoteABTestManager shared].model.cashierTitle)) {
        self.navigationBar.title = CJPayLocalizedStr([CJPayBrandPromoteABTestManager shared].model.cashierTitle);
    } else {
        self.navigationBar.title = CJPayLocalizedStr(@"支付");
    }
}

- (void)p_confirmButtonClick {
    CJ_DelayEnableView(self.homeView.confirmButton);
    CJ_CALL_BLOCK(self.confirmPayBlock, [self.homeView isCheckBoxSelected]);
}

- (void)p_passCodeVerifyPay {
    CJ_CALL_BLOCK(self.passCodePayBlock);
}


- (void)p_trackWithEventName:(NSString *)event
                      params:(NSDictionary *)params {
    CJ_CALL_BLOCK(self.trackerBlock, CJString(event), params);
}

@end
