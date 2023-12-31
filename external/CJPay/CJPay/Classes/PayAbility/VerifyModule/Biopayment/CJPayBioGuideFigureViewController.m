//
//  CJPayBioGuideFigureViewController.m
//  Pods
//
//  Created by 利国卿 on 2021/12/13.
//

#import "CJPayBioGuideFigureViewController.h"
#import "CJPayBaseVerifyManager.h"

#import "CJPayOpenBioGuideView.h"
#import "CJPayUIMacro.h"
#import "CJPayBioManager.h"
#import "CJPayTouchIdManager.h"
#import "CJPaySafeManager.h"
#import "CJPayRequestParam.h"
#import "CJPayTracker.h"
#import "CJPaySafeUtil.h"
#import "CJPayBioPaymentBaseRequestModel.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayCashdeskEnableBioPayRequest.h"
#import "CJPayResultFigureGuideView.h"
#import "CJPayResultPageGuideInfoModel.h"

@interface CJPayBioGuideFigureViewController ()

@property (nonatomic, copy) void (^completionBlock)(void);
@property (nonatomic, strong) CJPayResultFigureGuideView *figureGuideView;
@property (nonatomic, strong) CJPayButton *cancelButton;

@end

@implementation CJPayBioGuideFigureViewController

#pragma mark - Lifecycle

+ (CJPayResultPageGuideInfoModel *)setDefaultModel:(CJPayResultPageGuideInfoModel *)resModel {
    CJPayResultPageGuideInfoModel *model = [CJPayResultPageGuideInfoModel new];
    model.guideType = CJString(resModel.guideType);
    model.confirmBtnDesc = Check_ValidString(resModel.confirmBtnDesc) ? resModel.confirmBtnDesc : CJPayLocalizedStr(@"一键升级");
    if ([resModel isNewGuideShowStyle] || [resModel isNewGuideShowStyleForOldPeople]) {
        model.cancelBtnDesc = CJString(resModel.cancelBtnDesc);
    } else {
        model.cancelBtnDesc = Check_ValidString(resModel.cancelBtnDesc) ? resModel.cancelBtnDesc : CJPayLocalizedStr(@"放弃升级");
    }
    model.cancelBtnLocation = Check_ValidString(resModel.cancelBtnLocation) ? resModel.cancelBtnLocation : @"left";
    
    NSString *defaultAfterOpenDesc = [resModel.bioType isEqualToString:@"FINGER"] ? CJPayLocalizedStr(@"已开通 指纹支付") : CJPayLocalizedStr(@"已开通 面容支付");
    model.afterOpenDesc = Check_ValidString(resModel.afterOpenDesc) ? resModel.afterOpenDesc : defaultAfterOpenDesc;
    
    NSString *defaultTitle = [resModel.bioType isEqualToString:@"FINGER"] ? CJPayLocalizedStr(@"设备支持升级指纹支付") : CJPayLocalizedStr(@"设备支持升级面容支付");
    model.title = Check_ValidString(resModel.title) ? resModel.title : defaultTitle;
    
    model.subTitle = Check_ValidString(resModel.subTitle) ? resModel.subTitle : CJPayLocalizedStr(@"防范密码泄露 $|$ 支付快人一步");
    model.headerDesc = Check_ValidString(resModel.headerDesc) ? resModel.headerDesc : CJPayLocalizedStr(@"支付成功");
    model.pictureUrl = Check_ValidString(resModel.pictureUrl) ? resModel.pictureUrl : @"https://lf26-static.bytednsdoc.com/obj/eden-cn/zly_zvp_fhwqj/ljhwZthlaukjlkulzlp/prod/cj_result_guide_bio.png";
    model.subTitleIconUrl = CJString(resModel.subTitleIconUrl);
    model.voucherAmount = resModel.voucherAmount;
    model.isButtonFlick = resModel.isButtonFlick;
    model.subTitleColor = resModel.subTitleColor;
    model.guideShowStyle = resModel.guideShowStyle;
    model.bubbleText = resModel.bubbleText;
    model.headerPicUrl = resModel.headerPicUrl;
    return model;
}

+ (instancetype)createWithWithParams:(NSDictionary *)params completionBlock:(void (^)(void))completionBlock {
    CJPayBaseVerifyManager *verifyManager = [params cj_objectForKey:@"verify_manager"];
    CJPayResultPageGuideInfoModel *model = [CJPayBioGuideFigureViewController setDefaultModel:verifyManager.resResponse.resultPageGuideInfoModel];
    
    CJPayBioGuideFigureViewController *vc = [[CJPayBioGuideFigureViewController alloc] initWithGuideInfoModel:model];
    vc.verifyManager = verifyManager;
    vc.completionBlock = [completionBlock copy];
    vc.isTradeCreateAgain = verifyManager.resResponse.tradeInfo.isTradeCreateAgain;
    BOOL useCloseBtn = [params cj_boolValueForKey:@"use_close_btn"];
    if (useCloseBtn) {
        [vc useCloseBackBtn];
    }
    return vc;
}

- (instancetype)initWithGuideInfoModel:(CJPayResultPageGuideInfoModel *)model {
    if (self = [super init]) {
        self.model = model;
    }
    return self;
}

#pragma mark - Override

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_pop_imp"
                        params:@{@"is_awards_show" : @"1",
                                 @"awards_info" : CJString(self.model.voucherDisplayText),
                                 @"bio_guide_type" : @"bio_guide_figure"}];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.figureGuideView confirmButtonAnimation];
    });
}

- (void)back {
    [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_pop_click"
                        params:@{@"button_name" : @"关闭",
                                 @"is_awards_show" : @"1",
                                 @"awards_info" : CJString(self.model.voucherDisplayText),
                                 @"bio_guide_type" : @"bio_guide_figure"
                               }];
    [self closePage];
}

- (void)closePage {
    if (self.completionBlock) {
        CJ_CALL_BLOCK(self.completionBlock);
    } else {
        [super back];
    }
}

#pragma mark - Private Method

- (void)p_setupUI {
    if (Check_ValidString(self.model.cancelBtnDesc)) {
        self.navigationBar.backBtn.hidden = YES;
        [self.navigationBar addSubview:self.cancelButton];
        
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
        [self useCloseBackBtn];
    }
    
    [self p_setNavbarTitle];
    [self.contentView addSubview:self.figureGuideView];
    CJPayMasMaker(self.figureGuideView, {
        make.edges.equalTo(self.contentView);
    });
    
}

- (void)p_setNavbarTitle {
    if (self.model.headerPicUrl.length) {
        // 同时显示图片和文字
        self.navigationBar.titleImageView.hidden = NO;
        [self.navigationBar.titleImageView cj_setImageWithURL:[NSURL URLWithString:self.model.headerPicUrl]];
        CJPayMasReMaker(self.navigationBar.titleImageView, {
            make.centerY.equalTo(self.navigationBar);
            make.right.equalTo(self.navigationBar.titleLabel.mas_left).offset(-5);
            make.size.mas_equalTo(CGSizeMake(17, 17));
        });
        
        self.navigationBar.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        CJPayMasReMaker(self.navigationBar.titleLabel, {
            make.centerX.equalTo(self.navigationBar).offset(20);
            make.centerY.equalTo(self.navigationBar);
            make.width.lessThanOrEqualTo(self.navigationBar).offset(-96);
        });
    }
    
    self.navigationBar.titleLabel.text = Check_ValidString(self.model.headerDesc) ? self.model.headerDesc : CJPayLocalizedStr(@"支付成功");
}

- (void)p_confirmButtonClick {
    [self p_trackPageClickWithButtonName:CJString(self.model.confirmBtnDesc)];
    [self p_openBioPayment];
}

- (void)p_cancelButtonClick {
    [self p_trackPageClickWithButtonName:CJString(self.model.cancelBtnDesc)];
    [self closePage];
}

- (void)p_openBioPayment {
    NSMutableDictionary *requestModel = [NSMutableDictionary new];
    [requestModel cj_setObject:self.verifyManager.response.merchant.appId forKey:@"app_id"];
    [requestModel cj_setObject:self.verifyManager.response.merchant.merchantId forKey:@"merchant_id"];
    [requestModel cj_setObject:self.verifyManager.response.userInfo.uid forKey:@"uid"];
    [requestModel cj_setObject:self.verifyManager.response.tradeInfo.tradeNo forKey:@"trade_no"];
    [requestModel cj_setObject:[self.verifyManager.response.processInfo dictionaryValue] forKey:@"process_info"];
    [requestModel cj_setObject:[CJPaySafeManager buildEngimaEngine:@""] forKey:@"engimaEngine"];
    [requestModel cj_setObject:self.verifyManager.lastPWD forKey:@"lastPwd"];
    
    @CJWeakify(self)
    [CJPayBioManager openBioPaymentOnVC:self
                      withBioRequestDic:requestModel
                        completionBlock:^(BOOL result, BOOL needBack) {
        @CJStrongify(self)
        if (result) {
            //生物识别开通成功
            [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_result"
                                params:@{@"result": @"成功"}];
            
            NSString *btnTitle = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? CJPayLocalizedStr(@"已开通 指纹支付") : CJPayLocalizedStr(@"已开通 面容支付");
            [self.figureGuideView.confirmButton setTitle:btnTitle forState:UIControlStateNormal];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @CJStrongify(self)
                [self closePage];
            });
        } else {
            //生物识别开通失败
            [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_result"
                                params:@{@"result": @"失败"}];
            
            if (needBack) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    @CJStrongify(self)
                    [self closePage];
                });
            }
        }
    }];
}

#pragma mark - CJPayBaseLoadingProtocol

- (void)startLoading {
    @CJStartLoading(self.figureGuideView.confirmButton);
}

- (void)stopLoading {
    @CJStopLoading(self.figureGuideView.confirmButton);
}

#pragma mark - Tracker

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *paramDic = [NSMutableDictionary new];
    if (params) {
        [paramDic addEntriesFromDictionary:params];
    }
    NSString *from = self.isTradeCreateAgain ? @"wallet_cashier_payafter_second" : @"wallet_cashier_payafter";
    [paramDic cj_setObject:from forKey:@"from"];
    [paramDic cj_setObject:CJString(self.model.pictureUrl) forKey:@"fingerprint_type"];
    [paramDic cj_setObject:CJString(self.model.guideShowStyle) forKey:@"guide_show_style"];
    [paramDic cj_setObject:CJString(self.model.subTitle) forKey:@"title"];
    if ([self.verifyManager.verifyManagerQueen respondsToSelector:@selector(trackVerifyWithEventName:params:)]) {
        [self.verifyManager.verifyManagerQueen performSelector:@selector(trackVerifyWithEventName:params:) withObject:eventName withObject:paramDic];
    }
}

- (void)p_trackPageClickWithButtonName:(NSString *)buttonName {
    [self p_trackWithEventName:@"wallet_cashier_fingerprint_enable_pop_click"
                        params:@{@"button_name" : CJString(buttonName),
                                 @"is_awards_show" : @"1",
                                 @"awards_info" : CJString(self.model.voucherDisplayText),
                                 @"bio_guide_type" : @"bio_guide_figure"
                               }];
}

#pragma mark - lazy View

- (CJPayResultFigureGuideView *)figureGuideView {
    if (!_figureGuideView) {
        _figureGuideView = [[CJPayResultFigureGuideView alloc] initWithGuideInfoModel:self.model];
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
        [_cancelButton.titleLabel setFont:[UIFont cj_fontOfSize:14]];
        [_cancelButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_cancelButton setTitle:CJString(self.model.cancelBtnDesc) forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor cj_161823WithAlpha:0.75] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(p_cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

@end
