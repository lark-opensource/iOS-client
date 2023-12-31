//
//  CJPayGuideResetPwdPopUpViewController.m
//  Aweme
//
//  Created by 尚怀军 on 2022/12/2.
//

#import "CJPayGuideResetPwdPopUpViewController.h"
#import "CJPayStyleButton.h"
#import "CJPayGuideResetPwdRequest.h"
#import "CJPayGuideResetPwdResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayGuideResetPwdRequest.h"
#import "CJPayDeskUtil.h"
#import "CJPayToast.h"

@interface CJPayGuideResetPwdPopUpViewController()

@property (nonatomic, strong) UIImageView *headerImgView;
@property (nonatomic, strong) UILabel *headerDescLabel;
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) CJPayStyleButton *topButton;
@property (nonatomic, strong) CJPayButton *bottomButton;

@end

@implementation CJPayGuideResetPwdPopUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CJ_CALL_BLOCK(self.trackerBlock, @"wallet_password_forget_afterpay_guide_pop_show", @{@"title": CJString(self.guideInfoModel.title)});
}

- (void)setupUI {
    [super setupUI];
    self.containerView.layer.cornerRadius = 12;
    self.topButton.cornerRadius = 4;
    
    [self.containerView addSubview:self.headerImgView];
    [self.containerView addSubview:self.headerDescLabel];
    [self.containerView addSubview:self.mainTitleLabel];
    [self.containerView addSubview:self.subTitleLabel];
    [self.containerView addSubview:self.topButton];
    [self.containerView addSubview:self.bottomButton];
    
    CJPayMasReMaker(self.containerView, {
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.centerY.equalTo(self.view);
        make.bottom.equalTo(self.bottomButton).offset(13);
    });

    CJPayMasMaker(self.headerDescLabel, {
        make.top.equalTo(self.containerView).offset(28);
        make.centerX.equalTo(self.containerView).offset(10);
        make.height.mas_equalTo(20);
    });
    
    CJPayMasMaker(self.headerImgView, {
        make.centerY.equalTo(self.headerDescLabel);
        make.right.equalTo(self.headerDescLabel.mas_left).offset(-3);
        make.width.height.mas_equalTo(17);
    });
    
    CJPayMasMaker(self.mainTitleLabel, {
        make.top.equalTo(self.headerDescLabel.mas_bottom).offset(19);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.height.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(10);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
    });
    
    CJPayMasMaker(self.topButton, {
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.top.equalTo(self.subTitleLabel.mas_bottom).offset(24);
        make.height.mas_equalTo(44);
    });
    
    CJPayMasMaker(self.bottomButton, {
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.top.equalTo(self.topButton.mas_bottom).offset(13);
        make.height.mas_equalTo(18);
    });
}

- (void)p_topButtonTapped {
    CJ_CALL_BLOCK(self.trackerBlock, @"wallet_password_forget_afterpay_guide_pop_click",
                  @{@"title": CJString(self.guideInfoModel.title),
                    @"button_name": CJString(self.guideInfoModel.confirmBtnDesc)});
    [self.topButton startLoading];
    self.bottomButton.userInteractionEnabled = NO;
    @CJWeakify(self)
    [CJPayGuideResetPwdRequest startWithOrderResponse:self.verifyManager.response
                                           completion:^(NSError * _Nonnull error, CJPayGuideResetPwdResponse * _Nonnull response) {
        @CJStrongify(self)
        [self.topButton stopLoading];
        self.bottomButton.userInteractionEnabled = YES;
        if ([response isSuccess]) {
            if (Check_ValidString(response.jumpUrl)) {
                [CJPayDeskUtil openLynxPageBySchema:response.jumpUrl completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {
                    @CJStrongify(self)
                    [self dismissSelfWithCompletionBlock:^{
                        @CJStrongify(self)
                        CJ_CALL_BLOCK(self.completeBlock);
                    }];
                }];
            } else {
                CJPayLogInfo(@"reset_pwd request return empty url!")
                [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
            }
        } else {
            NSString *toastMsg = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
            [CJToast toastText:toastMsg inWindow:self.cj_window];
        }
    }];
}

- (void)p_bottomButtonTapped {
    CJ_CALL_BLOCK(self.trackerBlock, @"wallet_password_forget_afterpay_guide_pop_click",
                  @{@"title": CJString(self.guideInfoModel.title),
                    @"button_name": CJString(self.guideInfoModel.cancelBtnDesc)});
    [self dismissSelfWithCompletionBlock:^{
        CJ_CALL_BLOCK(self.completeBlock);
    }];
}

- (UIImageView *)headerImgView {
    if (!_headerImgView) {
        _headerImgView = [UIImageView new];
        _headerImgView.clipsToBounds = YES;
        if (Check_ValidString(self.guideInfoModel.pictureUrl)) {
            [_headerImgView cj_setImageWithURL:[NSURL URLWithString:self.guideInfoModel.pictureUrl]];
        }
    }
    return _headerImgView;
}

- (UILabel *)headerDescLabel {
    if (!_headerDescLabel) {
        _headerDescLabel = [UILabel new];
        _headerDescLabel.font = [UIFont cj_fontOfSize:14];
        _headerDescLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _headerDescLabel.text = CJString(self.guideInfoModel.headerDesc);
    }
    return _headerDescLabel;
}

- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [UILabel new];
        _mainTitleLabel.font = [UIFont cj_boldFontOfSize:17];
        _mainTitleLabel.textColor = [UIColor cj_161823ff];
        _mainTitleLabel.text = CJString(self.guideInfoModel.title);
        _mainTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _mainTitleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.font = [UIFont cj_fontOfSize:14];
        _subTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _subTitleLabel.text = CJString(self.guideInfoModel.subTitle);
        _subTitleLabel.textAlignment = NSTextAlignmentCenter;
        _subTitleLabel.numberOfLines = 0;
    }
    return _subTitleLabel;
}

- (CJPayStyleButton *)topButton {
    if (!_topButton) {
        _topButton = [CJPayStyleButton new];
        _topButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_topButton.titleLabel setTextColor:[UIColor whiteColor]];
        [_topButton cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        [_topButton setTitle:CJString(self.guideInfoModel.confirmBtnDesc)
                    forState:UIControlStateNormal];
        [_topButton addTarget:self action:@selector(p_topButtonTapped)
             forControlEvents:UIControlEventTouchUpInside];
    }
    return _topButton;
}

- (CJPayButton *)bottomButton {
    if (!_bottomButton) {
        _bottomButton = [CJPayButton new];
        [_bottomButton setTitleColor:[UIColor cj_161823WithAlpha:0.6]
                            forState:UIControlStateNormal];
        [_bottomButton.titleLabel setFont:[UIFont cj_fontOfSize:13]];
        [_bottomButton setTitle:CJString(self.guideInfoModel.cancelBtnDesc)
                       forState:UIControlStateNormal];
        [_bottomButton addTarget:self action:@selector(p_bottomButtonTapped)
                forControlEvents:UIControlEventTouchUpInside];
    }
    return _bottomButton;
}


@end
