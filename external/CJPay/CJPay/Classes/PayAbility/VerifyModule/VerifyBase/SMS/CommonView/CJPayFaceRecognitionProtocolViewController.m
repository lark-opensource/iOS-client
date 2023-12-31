//
//  CJPayFaceRecognitionProtocolViewController.m
//  CJPay
//
//  Created by 尚怀军 on 2020/8/18.
//

#import "CJPayFaceRecognitionProtocolViewController.h"
#import "CJPayFaceRecognitionProtocolView.h"
#import "CJPayStyleButton.h"
#import "CJPay/CJPayProtocolManager.h"
#import "CJPayFaceRecogSignRequest.h"
#import "CJPayGetTicketRequest.h"
#import "CJPayGetTicketResponse.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayFaceRecognitionModel.h"
#import "CJPayProtocolPopUpViewController.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayToast.h"

@interface CJPayFaceRecognitionProtocolViewController ()

@property (nonatomic, strong) UIImageView *faceImgView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) CJPayFaceRecognitionProtocolView *protocolView;
@property (nonatomic, strong) CJPayStyleButton *nextStepButton;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) CJPayFaceRecognitionModel *model;

@end

@implementation CJPayFaceRecognitionProtocolViewController

- (instancetype) initWithFaceRecognitionModel:(CJPayFaceRecognitionModel *)model {
    self = [super init];
    if (self) {
        _model = model;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_makeConstraints];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.trackDelegate event:@"wallet_alivecheck_firstasignment_guide_imp" params:@{}];
}

- (void)p_setupUI {
    [self.view addSubview:self.faceImgView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.subTitleLabel];
    [self.view addSubview:self.protocolView];
    [self.view addSubview:self.nextStepButton];
    [self.view addSubview:self.footerLabel];
    
    self.titleLabel.text = CJPayLocalizedStr(@"人脸验证");
    NSString *headStr = CJPayLocalizedStr(@"验证你的身份信息，请确保为 ");
    NSString *tailStr = CJPayLocalizedStr(@" 本人操作");
    NSDictionary *normalAttributes = @{NSFontAttributeName:[UIFont cj_fontOfSize:13],
                                       NSForegroundColorAttributeName:[UIColor cj_999999ff]};
    NSDictionary *highlightAttributes = @{NSFontAttributeName:[UIFont cj_fontOfSize:13],
                                          NSForegroundColorAttributeName:[UIColor cj_222222ff]};

    NSMutableAttributedString *subtitleAttrStr = [[NSMutableAttributedString alloc] initWithString:headStr
                                                                                        attributes:normalAttributes];
    NSAttributedString *highlightAttrStr = [[NSAttributedString alloc] initWithString:CJString(self.model.userMaskName)
                                                                           attributes:highlightAttributes];
    NSAttributedString *tailAttrStr = [[NSAttributedString alloc] initWithString:tailStr
                                                                      attributes:normalAttributes];
    
    
    [subtitleAttrStr appendAttributedString:highlightAttrStr];
    [subtitleAttrStr appendAttributedString:tailAttrStr];
    self.subTitleLabel.attributedText = subtitleAttrStr;
    
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self.view addSubview:self.safeGuardTipView];
        CJPayMasMaker(self.safeGuardTipView, {
            make.height.mas_equalTo(18);
            make.bottom.equalTo(self.view).offset(-16-CJ_TabBarSafeBottomMargin);
            make.centerX.equalTo(self.view);
        });
        self.footerLabel.hidden = YES;
    }
}

- (void)setTrackDelegate:(id<CJPayTrackerProtocol>)trackDelegate {
    self.protocolView.trackDelegate = trackDelegate;
    _trackDelegate = trackDelegate;
}

- (void)p_makeConstraints {
    CJPayMasMaker(self.protocolView, {
        make.centerY.equalTo(self.view).offset(42);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
    });
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.protocolView.mas_top).offset(-48);
        make.bottom.lessThanOrEqualTo(self.protocolView.mas_top);
        make.centerX.equalTo(self.view);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.bottom.equalTo(self.subTitleLabel.mas_top).offset(-4);
        make.left.equalTo(self.view.mas_left).offset(24);
        make.right.equalTo(self.view.mas_right).offset(-24);
        make.height.mas_equalTo(28);
    });
    
    CJPayMasMaker(self.faceImgView, {
        make.bottom.equalTo(self.titleLabel.mas_top).offset(-12);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(72);
        make.height.mas_equalTo(72);
    });
    
    CJPayMasMaker(self.nextStepButton, {
        make.top.equalTo(self.protocolView.mas_bottom).offset(16);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
    });
    
    CJPayMasMaker(self.footerLabel, {
        make.bottom.equalTo(self.view).offset(-CJ_TabBarSafeBottomMargin - 12);
        make.left.equalTo(self.view).offset(24);
        make.right.equalTo(self.view).offset(-24);
        make.height.mas_equalTo(18);
    });
}
#pragma mark - event oncall

- (void)nextButtonClick {
    if (!self.protocolView.checkBoxIsSelect) {
        CJPayCommonProtocolModel *protocolModel = [CJPayCommonProtocolModel new];
        protocolModel.selectPattern = CJPaySelectButtonPatternCheckBox;
        protocolModel.supportRiskControl = NO;
        protocolModel.protocolFont = [UIFont cj_fontOfSize:14];
        protocolModel.protocolTextAlignment = NSTextAlignmentLeft;
        protocolModel.guideDesc = @"同意";
        CJPayMemAgreementModel *agreementModel = [CJPayMemAgreementModel new];
        agreementModel.group = @"face";
        agreementModel.name = CJString(self.model.agreementName);
        agreementModel.url = CJString(self.model.agreementURL);
        protocolModel.agreements = @[agreementModel];
        protocolModel.protocolCheckBoxStr = @"0";
        protocolModel.groupNameDic = @{@"face" : self.model.agreementName};//response.protocolModel.protocolGroupNames;
        
        CJPayProtocolPopUpViewController *popupProtocolVC = [[CJPayProtocolPopUpViewController alloc] initWithProtocolModel:protocolModel from:@"支付刷脸全屏授权页"];
        @CJWeakify(self);
        popupProtocolVC.confirmBlock = ^{
            @CJStrongify(self);
            [self.protocolView.checkBoxButton setSelected:YES];
            [self nextButtonClick];
        };
        [self.navigationController pushViewController:popupProtocolVC animated:YES];
        return;
    }
    [self.trackDelegate event:@"wallet_alivecheck_firstasignment_guide_next_click" params:@{
        @"alivecheck_scene" : CJString(self.model.alivecheckScene),
        @"alivecheck_type" : @(self.model.alivecheckType),
    }];
    [self.nextStepButton startLoading];
    NSDictionary *baseRequestParam = @{@"app_id": CJString(self.model.appId),
                                       @"merchant_id": CJString(self.model.merchantId)};
    [CJPayFaceRecogSignRequest startWithRequestparams:baseRequestParam
                                     bizContentParams:@{}
                                           completion:^(NSError * _Nonnull error, CJPayBaseResponse * _Nonnull response) {
        [self.nextStepButton stopLoading];
        if (response && [response.code isEqualToString:@"MP000000"]) {
            if (self.navigationController.viewControllers.count == 1) {
                if (self.shouldCloseCallBack) {
                    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES
                                                                                           completion:^{
                        CJ_CALL_BLOCK(self.signSuccessBlock, @"");
                    }];
                } else {
                    CJ_CALL_BLOCK(self.signSuccessBlock, @"");
                }
            } else {
                [CATransaction begin];
                [CATransaction setCompletionBlock:^{
                    CJ_CALL_BLOCK(self.signSuccessBlock,@"");
                }];
                [self.navigationController popViewControllerAnimated:YES];
                [CATransaction commit];
            }
            return;
        }
        if (Check_ValidString(response.msg)) {
            [CJToast toastText:response.msg inWindow:self.cj_window];
        }
    }];
}

- (void)back {
    if (self.cjBackBlock) {
        CJ_CALL_BLOCK(self.cjBackBlock);
        return;
    }
    [super back];
}

#pragma mark - lazy load

- (UIImageView *)faceImgView {
    if (!_faceImgView) {
        _faceImgView = [UIImageView new];
        [_faceImgView cj_setImage:@"cj_person_face_icon"];
    }
    return _faceImgView;
}


- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_semiboldFontOfSize:20];
        _titleLabel.textColor = [UIColor cj_222222ff];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.font = [UIFont cj_fontOfSize:13];
        _subTitleLabel.textColor = [UIColor cj_999999ff];
        _subTitleLabel.textAlignment = NSTextAlignmentLeft;
        _subTitleLabel.numberOfLines = 0;
    }
    return _subTitleLabel;
}

- (CJPayFaceRecognitionProtocolView *)protocolView {
    if (!_protocolView) {
        _protocolView = [[CJPayFaceRecognitionProtocolView alloc] initWithAgreementName:self.model.agreementName agreementURL:self.model.agreementURL];
    }
    return _protocolView;
}

- (CJPayStyleButton *)nextStepButton {
    if (!_nextStepButton) {
        _nextStepButton = [[CJPayStyleButton alloc] init];
        _nextStepButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_nextStepButton setTitleColor:[UIColor cj_colorWithHexString:@"ffffff"] forState:UIControlStateNormal];
        [_nextStepButton setTitle:Check_ValidString(self.model.buttonText) ? self.model.buttonText : CJPayLocalizedStr(@"下一步") forState:UIControlStateNormal];
        _nextStepButton.layer.cornerRadius = 5;
        _nextStepButton.layer.masksToBounds = YES;
        _nextStepButton.cjEventInterval = 2;
        [_nextStepButton addTarget:self action:@selector(nextButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nextStepButton;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
        _safeGuardTipView.hidden = YES;
    }
    return _safeGuardTipView;
}

- (UILabel *)footerLabel {
    if (!_footerLabel) {
        _footerLabel = [UILabel new];
        _footerLabel.font = [UIFont cj_fontOfSize:13];
        _footerLabel.textColor = [UIColor cj_cacacaff];
        _footerLabel.textAlignment = NSTextAlignmentCenter;
        _footerLabel.text = CJPayLocalizedStr(@"本服务由合众易宝提供");
    }
    return _footerLabel;
}

@end
