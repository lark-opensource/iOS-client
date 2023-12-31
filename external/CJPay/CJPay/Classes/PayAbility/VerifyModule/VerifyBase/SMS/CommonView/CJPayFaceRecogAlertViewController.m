//
//  CJPayFaceRecogAlertViewController.m
//  Pods
//
//  Created by chenbocheng on 2022/1/13.
//

#import "CJPayFaceRecogAlertViewController.h"

#import "CJPayStyleButton.h"
#import "CJPayFaceRecogAlertContentView.h"
#import "CJPayWebViewUtil.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayGetTicketResponse.h"
#import "CJPayFaceRecognitionModel.h"
#import "CJPayFaceRecogSignRequest.h"
#import "CJPayProtocolPopUpViewController.h"

@interface CJPayFaceRecogAlertViewController ()

@property (nonatomic, strong) CJPayButton *closeButton;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;
@property (nonatomic, strong) CJPayButton *bottomButton;
@property (nonatomic, strong) CJPayFaceRecogAlertContentView *contentView;
@property (nonatomic, strong) CJPayFaceRecognitionModel *model;

@property (nonatomic, copy) NSString *agreementName;
@property (nonatomic, copy) NSString *agreementURL;
@property (nonatomic, copy) NSString *protocolCheckBox;

@end

@implementation CJPayFaceRecogAlertViewController

- (instancetype)initWithFaceRecognitionModel:(CJPayFaceRecognitionModel *)model {
    self = [super init];
    if (self) {
        _model = model;
    }
    return self;
}

- (void)setupUI {
    [super setupUI];
    [CJKeyboard prohibitKeyboardShow];
    self.containerView.layer.cornerRadius = 12;
    CJPayMasReMaker(self.containerView, {
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.centerY.equalTo(self.view);
    });
    
    if (CJ_Pad) {
        CJPayMasReMaker(self.containerView, {
            make.center.equalTo(self.view);
            make.width.mas_lessThanOrEqualTo(272);
        });
    }
    
    [self.containerView addSubview:self.confirmButton];
    [self.containerView addSubview:self.contentView];
    [self.containerView addSubview:self.closeButton];
    [self.containerView addSubview:self.bottomButton];
    
    if (Check_ValidString(self.model.bottomButtonText)) {
        self.bottomButton.hidden = NO;
        CJPayMasMaker(self.bottomButton, {
            make.bottom.equalTo(self.containerView).offset(-13);
            make.left.equalTo(self.containerView).offset(20);
            make.right.equalTo(self.containerView).offset(-20);
            make.height.mas_equalTo(18);
        });
        
        CJPayMasMaker(self.confirmButton, {
            make.bottom.equalTo(self.bottomButton.mas_top).offset(-13);
            make.left.equalTo(self.containerView).offset(20);
            make.right.equalTo(self.containerView).offset(-20);
            make.height.mas_equalTo(44);
        });
        
    } else {
        self.bottomButton.hidden = YES;
        CJPayMasMaker(self.confirmButton, {
            make.bottom.equalTo(self.containerView).offset(-20);
            make.left.equalTo(self.containerView).offset(20);
            make.right.equalTo(self.containerView).offset(-20);
            make.height.mas_equalTo(44);
        });
    }
    
    if (Check_ValidString(self.model.title)) {
        [self.contentView updateWithTitle:self.model.title];
    }
    
    CJPayMasMaker(self.closeButton, {
        make.height.width.mas_equalTo(20);
        make.top.equalTo(self.containerView).offset(16);
        make.left.equalTo(self.containerView).offset(16);
    });
    
    CJPayMasMaker(self.contentView, {
        make.left.equalTo(self.containerView);
        make.right.equalTo(self.containerView);
        make.top.equalTo(self.containerView);
        if (self.model.showStyle == CJPayFaceRecognitionStyleExtraTestInPayment) {
            make.bottom.equalTo(self.confirmButton.mas_top).offset(-20);
        } else {
            make.bottom.equalTo(self.confirmButton.mas_top).offset(-12);
        }
    });
}

- (void)closeButtonTapped {
    @CJWeakify(self)
    [CJKeyboard permitKeyboardShow];
    [self dismissSelfWithCompletionBlock:^{
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.closeBtnBlock);
    }];
}

- (void)p_onConfirmPayAction {
    @CJWeakify(self)
    if (self.model.shouldShowProtocolView) {
        if (self.model.showStyle == CJPayFaceRecognitionStyleExtraTestInBindCard) {
            [self.contentView.protocolView executeWhenProtocolSelected:^{
                @CJStrongify(self)
                [self p_signFaceRecognition];
            } notSeleted:nil hasToast:YES];
        } else {
            [self.contentView.protocolView executeWhenProtocolSelected:^{
                @CJStrongify(self)
                [self dismissSelfWithCompletionBlock:^{
                    @CJStrongify(self)
                    [CJKeyboard permitKeyboardShow];
                    CJ_CALL_BLOCK(self.confirmBtnBlock);
                }];
            } notSeleted:nil hasToast:YES];
        }
    } else {
        [self dismissSelfWithCompletionBlock:^{
            @CJStrongify(self)
            [CJKeyboard permitKeyboardShow];
            CJ_CALL_BLOCK(self.confirmBtnBlock);
        }];
    }

}

- (void)p_bottomButtonTapped {
    @CJWeakify(self)
    [self dismissSelfWithCompletionBlock:^{
        @CJStrongify(self)
        [CJKeyboard permitKeyboardShow];
        CJ_CALL_BLOCK(self.bottomBtnBlock);
    }];
}

- (void)p_signFaceRecognition {
    [self.confirmButton startLoading];
    NSDictionary *baseRequestParam = @{@"app_id": CJString(self.model.appId),
                                       @"merchant_id": CJString(self.model.merchantId)};
    @CJWeakify(self)
    [CJPayFaceRecogSignRequest startWithRequestparams:baseRequestParam
                                     bizContentParams:@{}
                                           completion:^(NSError * _Nonnull error, CJPayBaseResponse * _Nonnull response) {
        @CJStrongify(self)
        [self.confirmButton stopLoading];
        if (response && [response.code isEqualToString:@"MP000000"]) {
            [self dismissSelfWithCompletionBlock:^{
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.confirmBtnBlock);
            }];
            return;
        }
        if (Check_ValidString(response.msg)) {
            [CJToast toastText:response.msg inWindow:self.cj_window];
        }
    }];
}

- (void)showOnTopVC:(UIViewController *)vc {
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:vc];
    if (!CJ_Pad && topVC.navigationController && [topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        [topVC.navigationController pushViewController:self animated:YES];
    } else {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [topVC presentViewController:self animated:NO completion:^{}];
    }
}

#pragma mark - lazy view
- (CJPayButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [CJPayButton new];
        [_closeButton cj_setImageName:@"cj_close_denoise_icon" forState:UIControlStateNormal];
        [_closeButton addTarget:self
                         action:@selector(closeButtonTapped)
               forControlEvents:UIControlEventTouchUpInside];
        _closeButton.accessibilityLabel = @"返回";
        _closeButton.hidden = self.model.hideCloseButton;
    }
    return _closeButton;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[CJPayStyleButton alloc] init];
        _confirmButton.cornerRadius = 8;
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_confirmButton.titleLabel setTextColor:[UIColor whiteColor]];
        NSString *buttonText = Check_ValidString(self.model.buttonText) ? CJPayLocalizedStr(self.model.buttonText) : CJPayLocalizedStr(@"安全刷脸验证");
        [_confirmButton setTitle:buttonText forState:UIControlStateNormal];
        [_confirmButton addTarget:self
                           action:@selector(p_onConfirmPayAction)
                 forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (CJPayButton *)bottomButton {
    if (!_bottomButton) {
        _bottomButton = [CJPayButton new];
        [_bottomButton setTitleColor:[UIColor cj_161823WithAlpha:0.6]
                            forState:UIControlStateNormal];
        [_bottomButton.titleLabel setFont:[UIFont cj_fontOfSize:13]];
        [_bottomButton setTitle:CJString(self.model.bottomButtonText)
                       forState:UIControlStateNormal];
        [_bottomButton addTarget:self action:@selector(p_bottomButtonTapped)
                forControlEvents:UIControlEventTouchUpInside];
    }
    return _bottomButton;
}

- (CJPayFaceRecogAlertContentView *)contentView {
    if (!_contentView) {
        CJPayMemAgreementModel *agreementModel = [CJPayMemAgreementModel new];
        agreementModel.name = self.model.agreementName;
        agreementModel.group = @"customeFaceProtocol";
        agreementModel.url = self.model.agreementURL;
        
        CJPayCommonProtocolModel *model = [CJPayCommonProtocolModel new];
        if (self.model.shouldShowProtocolView) {
            model.guideDesc = CJPayLocalizedStr(@"阅读并签署");
        }
        model.groupNameDic = @{@"customeFaceProtocol": CJString(self.model.agreementName)};
        model.agreements = @[agreementModel];
        model.protocolFont = [UIFont cj_fontOfSize:14];
        model.protocolTextAlignment = NSTextAlignmentLeft;
        model.protocolLineHeight = 20;
        model.protocolColor = [UIColor cj_161823WithAlpha:0.75];
        model.protocolJumpColor = [UIColor cj_douyinBlueColor];
        model.protocolCheckBoxStr = self.model.protocolCheckBox;
        model.supportRiskControl = YES;
        model.title = self.model.title;
        model.iconUrl = self.model.iconUrl;
        @CJWeakify(self)
        _contentView = [[CJPayFaceRecogAlertContentView alloc] initWithProtocolModel:model showType:self.model.showStyle shouldShowProtocolView:self.model.shouldShowProtocolView  protocolDidClick:^(NSArray<CJPayMemAgreementModel *> *agreements, UIViewController *topVC) {
            @CJStrongify(self)
            [self.contentView.trackDelegate event:@"wallet_alivecheck_safetyassurace_contract_click" params:@{}];
            CJPayMemAgreementModel *model = agreements.firstObject;
            [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:topVC
                                                               toUrl:CJString((model.url))
                                                              params:@{}
                                                   nativeStyleParams:@{@"title": model.name}];
        }];
    }
    return _contentView;
}

@end
