//
//  CJPayBioSystemSettingGuideViewController.m
//  CJPay-CJPayDemoTools-Example
//
//  Created by liwenyou on 2022/6/18.
//

#import "CJPayBioSystemSettingGuideViewController.h"

#import "CJPayBaseVerifyManager.h"
#import "CJPayResultPageGuideInfoModel.h"
#import "CJPayResultFigureGuideView.h"
#import "CJPayServerEventCenter.h"
#import "CJPayPrivacyMethodUtil.h"
#import "CJPayToast.h"

@interface CJPayBioSystemSettingGuideViewController ()

@property (nonatomic, strong) CJPayResultPageGuideInfoModel *model;

@property (nonatomic, strong) CJPayResultFigureGuideView *figureGuideView;
@property (nonatomic, strong) CJPayButton *cancelButton;
@property (nonatomic, assign) BOOL isToOpened;

@end

@implementation CJPayBioSystemSettingGuideViewController

- (instancetype)initWithGuideInfoModel:(CJPayResultPageGuideInfoModel *)model {
    if (self = [super init]) {
        self.model = model;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupUI];
    [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_pop_imp"
                        params:@{@"bio_guide_type" : @"bio_guide_system_set"}];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];

}

#pragma mark - Override

- (void)back {
    // 新转场无需关闭自身再给回调
    CJ_CALL_BLOCK(self.completeBlock);
}

#pragma mark - private

- (void)p_setupUI {
    self.navigationBar.backBtn.hidden = YES;
    [self p_setNavbarTitle];
    
    [self.navigationBar addSubview:self.cancelButton];
    [self.contentView addSubview:self.figureGuideView];
    
    if (Check_ValidString(self.model.cancelBtnDesc)) {
        CJPayMasMaker(self.cancelButton, {
            make.centerY.equalTo(self.navigationBar);
            make.height.mas_equalTo(18);
            
            if ([self.model.cancelBtnLocation isEqualToString:@"right"]) {
                make.right.equalTo(self.navigationBar).offset(-24);
                make.left.greaterThanOrEqualTo(self.navigationBar.titleLabel.mas_right);
            } else {
                make.left.equalTo(self.navigationBar).offset(24);
                make.right.lessThanOrEqualTo(self.navigationBar.titleLabel.mas_left);
            }
        });
    } else {
        CJPayMasMaker(self.cancelButton, {
            make.centerY.equalTo(self.navigationBar);
            make.size.mas_equalTo(CGSizeMake(20, 20));
            
            if ([self.model.cancelBtnLocation isEqualToString:@"right"]) {
                make.right.equalTo(self.navigationBar).offset(-16);
            } else {
                make.left.equalTo(self.navigationBar).offset(16);
            }
        });
    }

    CJPayMasMaker(self.figureGuideView, {
        make.edges.equalTo(self.contentView);
    });
}

- (void)p_confirmButtonClick {
    [self.figureGuideView.confirmButton startLoading];
    self.figureGuideView.confirmButton.userInteractionEnabled = NO;
    // 调用AppJump敏感方法，需走BPEA鉴权
    @CJWeakify(self)
    [CJPayPrivacyMethodUtil applicationOpenUrl:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                    withPolicy:@"bpea-caijing_bio_available_goto_setting"
                               completionBlock:^(NSError * _Nullable error) {
        @CJStrongify(self)
        if (error) {
            [self p_openFailed];
        } else {
            self.isToOpened = YES;
        }
    }];
    
    [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_pop_click"
                        params:@{@"button_name": CJString(self.model.confirmBtnDesc),
                                 @"bio_guide_type" : @"bio_guide_system_set"
                               }];
}

- (void)p_didBecomeActive {
    if (self.isToOpened) {
        [self p_openFailed];
    }
}

- (void)p_openFailed {
    [self.figureGuideView.confirmButton stopLoading];
    [CJToast toastText:CJPayLocalizedStr(@"开启失败") inWindow:self.cj_window];

    @CJWeakify(self)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self)
        [self back];
    });
}

- (void)p_cancelButtonClick {
    NSString *buttonText = Check_ValidString(self.cancelButton.titleLabel.text) ? self.cancelButton.titleLabel.text : @"关闭";
    [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_pop_click"
                        params:@{@"button_name": buttonText,
                                 @"bio_guide_type" : @"bio_guide_system_set"
                               }];
    
    [[CJPayServerEventCenter defaultCenter] postEvent:@"bio_fail_retain"
                                intergratedMerchantId:self.verifyManager.response.merchant.intergratedMerchantId
                                                extra:@{@"bio_type": @"2"}
                                           completion:nil];
    [self back];
}

- (void)p_setNavbarTitle {
    NSString *title = Check_ValidString(self.model.headerDesc) ? self.model.headerDesc : CJPayLocalizedStr(@"支付成功");
    [self.navigationBar setTitle:title];
}

#pragma mark - tracker

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    [self.verifyManager.verifyManagerQueen trackCashierWithEventName:eventName params:params];
}


#pragma mark - lazy View

- (CJPayResultFigureGuideView *)figureGuideView {
    if (!_figureGuideView) {
        _figureGuideView = [[CJPayResultFigureGuideView alloc] initWithGuideInfoModel:self.model showBackView:YES];
        @CJWeakify(self)
        _figureGuideView.confirmBlock = ^{
            @CJStrongify(self)
            [self p_confirmButtonClick];
        };
    }
    return _figureGuideView;
}

- (CJPayButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [CJPayButton new];
        
        if (Check_ValidString(self.model.cancelBtnDesc)) {
            [_cancelButton.titleLabel setFont:[UIFont cj_fontOfSize:14]];
            [_cancelButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
            [_cancelButton setTitle:CJString(self.model.cancelBtnDesc) forState:UIControlStateNormal];
            [_cancelButton setTitleColor:[UIColor cj_161823WithAlpha:0.75] forState:UIControlStateNormal];
        } else {
            [_cancelButton setImage:[UIImage cj_imageWithName:@"cj_close_denoise_icon"] forState:UIControlStateNormal];
        }
       
        [_cancelButton addTarget:self action:@selector(p_cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

@end
