//
//  CJPaySkipPwdConfirmViewController.m
//  Pods
//
//  Created by 尚怀军 on 2021/3/8.
//

#import "CJPaySkipPwdConfirmViewController.h"
#import "CJPayStyleButton.h"
#import "CJPayStyleCheckBox.h"
#import "UIViewController+CJTransition.h"
#import "CJPayEnumUtil.h"
#import "CJPaySDKMacro.h"
#import "CJPaySkipPwdConfirmModel.h"
#import "CJPaySkipPwdConfirmView.h"
#import "CJPayBaseVerifyManagerQueen.h"
#import "CJPaySecondaryConfirmInfoModel.h"
#import "CJPaySubPayTypeData.h"

@interface CJPaySkipPwdConfirmViewController ()

@property (nonatomic, strong) CJPaySkipPwdConfirmView *confirmView;

@property (nonatomic, strong) CJPaySecondaryConfirmInfoModel *confirmInfo;

@end

@implementation CJPaySkipPwdConfirmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_pay_page_imp"
                        params:@{@"pswd_type": @"1",
                                 @"pop_type" : @"0",
                                 @"rec_check_type" : @"",
                                 @"activity_label" : @""
                               }];
}

- (instancetype)initWithModel:(CJPaySkipPwdConfirmModel *)model {
    if (self = [super init]) {
        self.createOrderResponse = model.createOrderResponse;
        self.confirmBlock = model.confirmBlock;
        self.backCompletionBlock = model.backCompletionBlock;
        self.checkboxClickBlock = model.checkboxClickBlock;
        self.verifyManager = model.verifyManager;
        CJPayDefaultChannelShowConfig *currentShowConfig = self.verifyManager.defaultConfig;
        if (self.verifyManager.isStandardDouPayProcess) {
            model.confirmInfo.standardRecDesc = currentShowConfig.payVoucherMsg;
            model.confirmInfo.standardShowAmount = currentShowConfig.payAmount;
        } else {
            model.confirmInfo.standardRecDesc = model.createOrderResponse.payInfo.standardRecDesc;
            model.confirmInfo.standardShowAmount = model.createOrderResponse.payInfo.standardShowAmount;
        }
        self.confirmInfo = model.confirmInfo;
    }
    return self;
}

- (void)setupUI {
    [super setupUI];
    self.containerView.layer.cornerRadius = 8;
    [self.containerView addSubview:self.confirmView];
    
    CGFloat interval = 48;
    if (Check_ValidString(self.confirmInfo.style)) {
        interval = [[UIScreen mainScreen] bounds].size.width * 0.125;
    }
    
    CJPayMasReMaker(self.containerView, {
        make.bottom.equalTo(self.confirmView.mas_bottom);
        make.left.equalTo(self.view).offset(interval);
        make.right.equalTo(self.view).offset(-interval);
        make.centerY.equalTo(self.view);
    })
    
    CJPayMasMaker(self.confirmView, {
        make.top.left.right.equalTo(self.containerView);
    })
}

- (BOOL)cjShouldShowBottomView {
    return YES;
}

- (void)closeButtonTapped {
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_pay_page_click"
                        params:@{@"button_name": @"0",
                                 @"pswd_type": @"1",
                                 @"pop_type" : @"0",
                                 @"rec_check_type" : @"",
                                 @"activity_label" : @""
                               }];
    if(self.backCompletionBlock) {
        CJ_CALL_BLOCK(self.backCompletionBlock);
    } else {
        [self dismissSelfWithCompletionBlock:nil];
    }
}

- (void)p_agreeCheckBoxTapped {
    self.confirmView.checkBox.selected = !self.confirmView.checkBox.isSelected;
    NSString *buttonName = self.confirmView.checkBox.isSelected ? @"2" : @"3";
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_pay_page_click"
                        params:@{@"button_name": buttonName,
                                 @"pswd_type": @"1",
                                 @"pop_type" : @"0",
                                 @"rec_check_type" : @"",
                                 @"activity_label" : @""
                               }];
    CJ_CALL_BLOCK(self.checkboxClickBlock, self.confirmView.checkBox.isSelected);
}

- (void)p_onConfirmPayAction {
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_pay_page_click"
                        params:@{@"button_name": @"1",
                                 @"pswd_type": @"1",
                                 @"pop_type" : @"0",
                                 @"rec_check_type" : @"",
                                 @"activity_label" : @""
                               }];
    
    CJ_CALL_BLOCK(self.confirmBlock);
}

- (void)p_trackWithEventName:(NSString *)eventName
                      params:(NSDictionary *)params {
    CJPayBaseVerifyManagerQueen *verifyManagerQueen = self.verifyManager.verifyManagerQueen;
    [verifyManagerQueen trackCashierWithEventName:eventName
                                           params:params];
}

- (NSString *)p_getButtonName {
    NSString *buttonText = CJPayLocalizedStr(@"免密支付");
    NSUInteger voucherType = [self.createOrderResponse.payInfo.voucherType integerValue];
    BOOL hasRandomDiscount = self.createOrderResponse.payInfo.hasRandomDiscount;
    // 如果有营销且没有随机立减则显示具体金额
    if (voucherType != CJPayVoucherTypeNone && !hasRandomDiscount) {
        buttonText = CJConcatStr(buttonText, @" ¥", CJString(self.createOrderResponse.payInfo.realTradeAmount));
    }
    return buttonText;
}

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    [self.confirmView.confirmPayBtn startLoading];
}

- (void)stopLoading {
    [self.confirmView.confirmPayBtn stopLoading];
}

#pragma mark - Getter

- (CJPaySkipPwdConfirmView *)confirmView {
    if (!_confirmView) {
        _confirmView = [[CJPaySkipPwdConfirmView alloc] initWithModel:self.confirmInfo];
        [_confirmView.closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [_confirmView.marketingMsgView updateWithModel:self.createOrderResponse isFromSkipPwdConfirm:YES];
        [_confirmView.confirmPayBtn addTarget:self action:@selector(p_onConfirmPayAction) forControlEvents:UIControlEventTouchUpInside];
        [_confirmView.checkBox addTarget:self action:@selector(p_agreeCheckBoxTapped) forControlEvents:UIControlEventTouchUpInside];
        if (!Check_ValidString(self.confirmInfo.style)) {//实验组不展示组合支付信息
            NSArray *combineShowInfo = self.createOrderResponse.payInfo.combineShowInfo;
            if (!combineShowInfo) {
                combineShowInfo = self.verifyManager.defaultConfig.payTypeData.combineShowInfo;
            }
            if (combineShowInfo) {
                [_confirmView.combineDetailView updateWithCombineShowInfo:combineShowInfo];
                [_confirmView.confirmPayBtn cj_setBtnTitle:CJString(self.createOrderResponse.deskConfig.confirmBtnDesc)];
            } else {
                [_confirmView.confirmPayBtn cj_setBtnTitle:[self p_getButtonName]];
            }
            [_confirmView updateWithIsShowCombine:(combineShowInfo.count != 0)];
        }
    }
    return _confirmView;
}

@end
