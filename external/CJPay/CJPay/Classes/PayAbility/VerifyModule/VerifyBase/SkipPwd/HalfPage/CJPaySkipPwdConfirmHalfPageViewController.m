//
//  CJPaySkipPwdConfirmHalfPageViewController.m
//  Aweme
//
//  Created by 陈博成 on 2023/5/21.
//

#import "CJPaySkipPwdConfirmHalfPageViewController.h"
#import "CJPaySkipPwdConfirmHalfPageView.h"
#import "CJPayStyleButton.h"
#import "CJPayStyleCheckBox.h"
#import "UIViewController+CJTransition.h"
#import "CJPayEnumUtil.h"
#import "CJPaySDKMacro.h"
#import "CJPaySkipPwdConfirmModel.h"
#import "CJPayBaseVerifyManagerQueen.h"
#import "CJPaySecondaryConfirmInfoModel.h"
#import "CJPayMarketingMsgView.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayUIMacro.h"

@interface CJPaySkipPwdConfirmHalfPageViewController ()

@property (nonatomic, strong) CJPaySkipPwdConfirmHalfPageView *confirmView;
@property (nonatomic, strong) CJPaySecondaryConfirmInfoModel *confirmInfo;
@property (nonatomic, assign) BOOL isSetupUIFinished;

@end

@implementation CJPaySkipPwdConfirmHalfPageViewController

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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_pay_page_imp"
                        params:@{@"pswd_type": @"1",
                                 @"pop_type" : @"0",
                                 @"rec_check_type" : @"",
                                 @"activity_label" : @""
                               }];
    [self p_setupUI];
}

- (void)p_setupUI {
    [self useCloseBackBtn];
    [self.contentView addSubview:self.confirmView];
    
    CJPayMasMaker(self.confirmView, {
        make.top.left.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(- CJ_TabBarSafeBottomMargin);
    })
    
    CJPayMasReMaker(self.containerView, {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(self.contentView).offset(CJ_TabBarSafeBottomMargin + 50); //50-navigationBar.height
    })

    self.isSetupUIFinished = YES;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (CGFloat)containerHeight {
    if (self.isSetupUIFinished && self.containerView.cj_height > 0) {
        return self.containerView.cj_height;
    }
    return [super containerHeight];
}

- (void)back {
    [self p_trackWithEventName:@"wallet_cashier_onesteppswd_pay_page_click"
                        params:@{@"button_name": @"0",
                                 @"pswd_type": @"1",
                                 @"pop_type" : @"0",
                                 @"rec_check_type" : @"",
                                 @"activity_label" : @""
                               }];
    if (self.backCompletionBlock) {
        CJ_CALL_BLOCK(self.backCompletionBlock);
        return;
    }
    [super back];
}

- (void)p_checkBoxTapped {
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

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    [self.confirmView.confirmPayBtn startLoading];
}

- (void)stopLoading {
    [self.confirmView.confirmPayBtn stopLoading];
}

#pragma mark - getter

- (CJPaySkipPwdConfirmHalfPageView *)confirmView {
    if (!_confirmView) {
        _confirmView = [[CJPaySkipPwdConfirmHalfPageView alloc] initWithModel:self.confirmInfo];
        [_confirmView.marketingMsgView updateWithModel:self.createOrderResponse isFromSkipPwdConfirm:YES];
        [_confirmView.confirmPayBtn addTarget:self
                                              action:@selector(p_onConfirmPayAction)
                                    forControlEvents:UIControlEventTouchUpInside];
        [_confirmView.checkBox addTarget:self
                                         action:@selector(p_checkBoxTapped)
                               forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmView;
}

@end
