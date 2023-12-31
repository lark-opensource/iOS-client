//
//  CJPayLoginViewController.m
//  Aweme
//
//  Created by 陈博成 on 2023/3/22.
//

#import "CJPayLoginViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseLynxView.h"
#import "CJPayOuterPayUtil.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayLoginBillView.h"
#import "CJPayQueryPayOrderInfoRequest.h"
#import "CJPayLoginBillStatusView.h"
#import "CJPayLoginBillDetailView.h"
#import "UIView+CJPay.h"
#import "CJPayRequestParam.h"
#import "CJPayKVContext.h"
 
@interface CJPayLoginViewController () <CJPayLynxViewDelegate>
 
@property (nonatomic, strong) CJPayButton *confirmButton;
@property (nonatomic, strong) CJPayBaseLynxView *lynxCard;
@property (nonatomic, strong) CJPayLoginBillView *loginBillView;

@property (nonatomic, assign) BOOL useNativeSignLogin;
@property (nonatomic, assign) BOOL isBackClicked;

@end

@implementation CJPayLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor cj_colorWithHexString:@"#F5F5F5"];
    self.navigationBar.backgroundColor = [UIColor cj_colorWithHexString:@"#F5F5F5"];
    CJPaySignPayConfig *signPayConfig = [CJPaySettingsManager shared].currentSettings.signPayConfig;
    self.useNativeSignLogin = signPayConfig ? signPayConfig.useNativeSignLogin : YES;
    [self p_setupUI];
    [self p_trackWithEvent:@"wallet_cashier_draw_prelogin_result" params:@{}];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self p_login];
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.loginBillView.contentView cj_clipBottomCorner:4];
    [self.loginBillView.contentView cj_applySketchShadow:[UIColor cj_colorWithRed:0 green:0 blue:0 alpha:1] alpha:0.05 x:0 y:6 blur:14 spread:0];
}

- (void)back {
    if (!self.isBackClicked) { // 只尝试展示一次lynx挽留
        [self.lynxCard publishEvent:@"back_pressed" data:@{}];
        self.isBackClicked = YES;
    } else {
        [self p_back];
    }
}

- (void)p_back {
    [super back];
    [self p_trackWithEvent:@"wallet_cashier_prelogin_pay_page_click" params:@{@"button_name": @"0"}];
    NSString *appID = [self.schemaParams cj_stringValueForKey:@"app_id"];
    BOOL isFromApp = NO;
    
    if (Check_ValidString(appID)) {
        isFromApp = YES;
    }
    
    NSString *jumpBackSchema = [self.schemaParams cj_stringValueForKey:@"jump_back_schema"]; //app通过schema传，浏览器后端下发
    [CJPayOuterPayUtil closeCashierDeskVC:self signType:isFromApp ? CJPayOuterTypeAppPay : CJPayOuterTypeWebPay jumpBackURL:jumpBackSchema jumpBackResult:CJPayDypayResultTypeCancel complettion:nil];
}
 
- (void)p_setupUI {
    [self.view addSubview:self.confirmButton];
    if (self.useNativeSignLogin) {
        // native
        [self.view addSubview:self.loginBillView];
        
        CJPayMasMaker(self.confirmButton, {
            make.bottom.equalTo(self.view).offset(- CJ_TabBarSafeBottomMargin - 16);
            make.left.equalTo(self.view).offset(24);
            make.right.equalTo(self.view).offset(-24);
            make.height.mas_equalTo(44);
        });
        
        CJPayMasMaker(self.loginBillView, {
            make.top.equalTo(self.view).offset(107);
            make.left.right.equalTo(self.view);
            make.bottom.equalTo(self.confirmButton.mas_top).offset(-20);
        });
        
        [self p_requestQueryPayOrderInfo];
    } else {
        // lynx
        [self.view addSubview:self.lynxCard];
        
        CJPayMasMaker(self.confirmButton, {
            make.bottom.equalTo(self.view).offset(- CJ_TabBarSafeBottomMargin - 16);
            make.left.equalTo(self.view).offset(24);
            make.right.equalTo(self.view).offset(-24);
            make.height.mas_equalTo(44);
        })
        
        CJPayMasMaker(self.lynxCard, {
            make.top.equalTo(self.view).offset(107);
            make.left.right.equalTo(self.view);
            make.bottom.equalTo(self.confirmButton.mas_top).offset(-20);
        })
        [self.lynxCard reload];
    }
}

- (void)p_requestQueryPayOrderInfo {
    NSDictionary *allParams = [[self.schemaParams cj_stringValueForKey:@"all_params"] cj_toDic];
    NSDictionary *bizContent = @{
        @"params" : [allParams cj_toStr],
        @"risk_info" : [CJPayRequestParam getRiskInfoParams],
        @"dev_info" : [CJPayRequestParam commonDeviceInfoDic],
        @"method" : @"cashdesk.pay.query_pay_order"
    };
    NSDictionary *params = @{
        @"biz_content": [bizContent cj_toStr],
        @"method" : @"bytepay.cashdesk.query_pay_order_info",
        @"merchant_id" : CJString([allParams cj_stringValueForKey:@"partnerid" defaultValue:@""]),
    };
    [self.loginBillView showStatus:CJPayLoginOrderStatusProcess msg:nil];
    [CJPayQueryPayOrderInfoRequest startWithRequestParams:params completion:^(NSError * _Nonnull error, CJPayQueryPayOrderInfoResponse * _Nonnull response) {
        [self p_updateLoginBillView:response];
    }];
}

- (void)p_updateLoginBillView:(CJPayQueryPayOrderInfoResponse *)response {
    CJPayLoginOrderStatus resultStatus = response ? [response resultStatus] : CJPayLoginOrderStatusError;
    NSDictionary *trackerParams = @{
        @"result" : resultStatus == CJPayLoginOrderStatusSuccess ? @"1" : @"0",
        @"payee" : CJString(response.merchantInfo.merchantShortToCustomer),
        @"discount" : @"",
        @"amount" : CJString(response.tradeInfo.payAmount),
    };
    [self p_trackWithEvent:@"wallet_cashier_prelogin_pay_page_imp" params:trackerParams];
    
    [self.loginBillView updateLoginBillViewWithResponse:response];
}

- (void)p_confirmClick {
    [self p_trackWithEvent:@"wallet_cashier_prelogin_pay_page_click" params:@{@"button_name": @"1"}];
    [self p_trackWithEvent:@"wallet_cashier_draw_prelogin_result" params:@{}];
    [self p_login];
}

- (void)p_login {
    NSMutableDictionary *eventCommonParams = [NSMutableDictionary new];
    [eventCommonParams addEntriesFromDictionary:@{@"from": @"outerpay_enter_cjpay"}];
    [self p_trackWithEvent:@"wallet_cashier_douyin_login_imp" params:eventCommonParams];
    @CJWeakify(self)
    [CJ_OBJECT_WITH_PROTOCOL(CJPayCarrierLoginProtocol) outerPayLogin:^(BOOL isSuccess) {
        @CJStrongify(self)
        if (isSuccess) {
            [CJ_OBJECT_WITH_PROTOCOL(CJPayOuterModule) i_openOuterDeskWithSchemaParams:self.schemaParams withDelegate:self.delegate];
        }
        [eventCommonParams btd_setObject:(isSuccess?@"1":@"0") forKey:@"result"];
        [self p_trackWithEvent:@"wallet_cashier_douyin_login_result" params:eventCommonParams];
    }];
}

- (void)p_pushProcessInfo:(NSString *)processId {
    [CJPayKVContext kv_setValue:processId forKey:CJPaySignPayRetainProcessId];
}

- (void)p_trackWithEvent:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
    double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
    [trackData addEntriesFromDictionary:@{@"client_duration":@(durationTime),
                                          @"caijing_source":@"outer_pay",
                                          @"params_for_special":@"tppp",
                                          @"is_chaselight":@"1",
                                          @"device_brand":@"apple"}];
    [trackData addEntriesFromDictionary:params];
    [CJPayTracker event:event params:trackData];
}

- (void)lynxView:(UIView *)lynxView receiveEvent:(NSString *)event withData:(NSDictionary *)data {
    if ([event isEqualToString:@"close"]) {
        [self p_back];
        return;
    }
    
    if ([event isEqualToString:@"push_process_info"]) {
        [self p_pushProcessInfo:[[data cj_dictionaryValueForKey:@"process_info"] cj_stringValueForKey:@"process_id"]];
        return;
    }
}
 
#pragma mark - getter
 
- (CJPayButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [CJPayButton new];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmButton.titleLabel.textColor = [UIColor whiteColor];
        [_confirmButton cj_setBtnBGColor:[UIColor cj_colorWithHexString:@"#FE2C55"]];
        [_confirmButton setTitle:CJPayLocalizedStr(@"登录并完成支付") forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(p_confirmClick) forControlEvents:UIControlEventTouchUpInside];
        _confirmButton.layer.cornerRadius = 8;
        _confirmButton.layer.masksToBounds = YES;
        _confirmButton.cjEventInterval = 1;
    }
    return _confirmButton;
}

- (CJPayBaseLynxView *)lynxCard {
    if (!_lynxCard) {
        NSString *schema = @"sslocal://webcast_lynxview?url=https%3A%2F%2Flf-webcast-sourcecdn-tos.bytegecko.com%2Fobj%2Fbyte-gurd-source%2F10181%2Fgecko%2Fresource%2Fcaijing_native_lynx%2Fmybankcard%2Frouter%2Ftemplate.js&web_bg_color=transparent&gravity=center&page_name=login_pay_info";//线上兜底
        
        CJPayLynxSchemaConfig *model = [CJPaySettingsManager shared].currentSettings.lynxSchemaConfig;
        if (Check_ValidString(model.loginInfo)) {
            schema = model.loginInfo;
        }
        
        CGFloat height = [UIScreen mainScreen].bounds.size.height - CJ_TabBarSafeBottomMargin - 70;
        CGRect frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, height);
        _lynxCard = [[CJPayBaseLynxView alloc] initWithFrame:frame scheme:schema initDataStr:[self.schemaParams cj_stringValueForKey:@"all_params"]];
        _lynxCard.delegate = self;
    }
    return _lynxCard;
}

- (CJPayLoginBillView *)loginBillView {
    if (!_loginBillView) {
        _loginBillView = [CJPayLoginBillView new];
    }
    return _loginBillView;
}

@end
