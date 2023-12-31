//
//  CJPayUniteSignViewController.m
//  CJPay-7351af12
//
//  Created by 王新华 on 2022/9/14.
//

#import "CJPayUniteSignViewController.h"
#import "CJPayUniteSignContentView.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPaySignRequestUtil.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayAlertUtil.h"
#import "CJPayCountDownTimerView.h"
#import "CJPayAlertController.h"
#import "CJPayDeskConfig.h"
#import "CJPayBDTypeInfo.h"
#import "CJPayButtonInfoHandler.h"
#import "CJPayToast.h"
#import "CJPayLoadingManager.h"

@interface CJPayUniteSignViewController ()<CJPayCountDownTimerViewDelegate, CJPayTrackerProtocol>

@property (nonatomic, strong) CJPayCountDownTimerView *countDownView;
@property (nonatomic, strong) UIView<CJPaySignDataProtocol> *dataView;
@property (nonatomic, strong) CJPayStyleButton *confirmBtn;
@property (nonatomic, strong) CJPaySignCreateResponse *createResponse;
@property (nonatomic, copy) void (^completionBlock)(CJPaySignQueryResponse * _Nullable queryResponse, CJPayDypayResultType resType);
@property (nonatomic, assign) BOOL becomeActiveNotiNeedQuery;

@end

@implementation CJPayUniteSignViewController

- (instancetype)initWithBizParams:(NSDictionary *)bizParams
                         response:(CJPaySignCreateResponse *)response completionBlock:(nonnull void (^)(CJPaySignQueryResponse * _Nullable queryResponse, CJPayDypayResultType status))completionBlock {
    self = [super init];
    if (self) {
        _createResponse = response;
        _completionBlock = [completionBlock copy];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        _becomeActiveNotiNeedQuery = NO;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGFloat)containerHeight {
    return 426;
}

- (void)appDecomeActive {
    CJPayLogInfo(@"needQuery: becomeActive");
    if (self.becomeActiveNotiNeedQuery && [UIViewController cj_foundTopViewControllerFrom:self] == self) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:self title:CJString(@"查询签约状态...")];
        [self p_startQueryResultWithMaxRetryCount:1 completion:^(NSError * _Nullable error, CJPaySignQueryResponse * _Nullable response) {
            [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeTopLoading];
            [self p_queryFinish:response fromSignCallback:NO];
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationBar setTitle:CJPayLocalizedStr(@"选择签约方式")];
    [self.containerView addSubview:self.countDownView];
    [self.contentView addSubview:self.dataView];
    [self.contentView addSubview:self.confirmBtn];
    CJPayMasMaker(self.countDownView, {
        make.centerX.equalTo(self.containerView);
        make.top.equalTo(self.containerView).offset(1);
        make.width.equalTo(self.containerView).offset(-100);
        make.height.mas_equalTo(48);
    });
    CJPayMasMaker(self.dataView, {
        make.left.top.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView);
    });
    CJPayMasMaker(self.confirmBtn, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        if (CJ_Pad) {
            make.bottom.equalTo(self).offset(-16);
        } else {
            if (@available(iOS 11.0, *)) {
                make.bottom.equalTo(self.contentView.mas_safeAreaLayoutGuideBottom).offset(CJ_IPhoneX ? 0 : -8);
            } else {
                make.bottom.equalTo(self).offset(-8);
            }
        }
    });
    
    [self p_refreshContent];
    self.confirmBtn.enabled = [self.dataView currentChoosePayMethod].enable;
    [self p_trackEvent:@"wallet_cashier_imp" params:@{}];
}

- (void)back {
    [self p_closeAndCallback:CJPayDypayResultTypeCancel response:nil];
}

- (void)p_refreshContent {
    [self.countDownView startTimerWithCountTime:@(self.createResponse.signTypeInfo.deskConfig.leftTime).intValue];
    // 外部 App 拉起时不展示倒计时
    if (self.createResponse.signTypeInfo.deskConfig.whetherShowLeftTime) {
        self.countDownView.hidden = NO;
    }
    // 刷新数据
    [self.dataView bindData:self.createResponse.signTypeInfo];
}

- (void)p_onConfirmAction {
    [self p_trackEvent:@"wallet_cashier_confirm_click" params:@{@"button_name": CJString(self.confirmBtn.titleLabel.text)}];
    if (!self.countDownView.curTimeIsValid) {
        [self showTimeOutAlertVC];
        return;
    }
    // 点击确认签约
    [self p_startConfirmSign];
}

- (void)p_startConfirmSign {
    CJPayChannelType curType = [self.dataView currentChoosePayMethod].type;
    NSString *curChannel;
    switch (curType) {
        case CJPayChannelTypeWX:
            curChannel = @"wx";
            break;
        case CJPayChannelTypeTbPay:
            curChannel = @"alipay";
            break;
        case CJPayChannelTypeDyPay:
            curChannel = @"dypay";
            break;
        default:
            CJPayLogAssert(NO, @"当前选择的支付方式不可用，showConfig: %@", [self.dataView currentChoosePayMethod]);
            break;
    }
    @CJStartLoading(self.confirmBtn);
    [CJPaySignRequestUtil startSignConfirmRequestWithParams:@{
        @"process" : CJString(self.createResponse.processStr)
    } bizContentParams:@{
        @"ptcode": CJString(curChannel)
    } completion:^(NSError * _Nonnull error, CJPaySignConfirmResponse * _Nonnull response) {
        @CJStopLoading(self.confirmBtn);
        if ([response isSuccess]) {
            [self p_payWithChannelType:curType response:response];
            return;
        }
        
        if ([self p_buttonInfoHandler:response]) { // 如果通过buttonInfo来展示信息，直接返回即可
            return;
        } else {
            [CJToast toastText:response.msg ?: CJString(CJPayNoNetworkMessage) inWindow:self.cj_window];
        }
    }];
}

- (BOOL)p_buttonInfoHandler:(CJPaySignConfirmResponse *)response {
    CJPayButtonInfoHandlerActionModel *actionModel = [CJPayButtonInfoHandlerActionModel new];
    @CJWeakify(self)
    actionModel.singleBtnAction = ^(NSInteger type) {
        @CJStrongify(self)
        if (type == 1) {
            [self p_closeAndCallback:CJPayDypayResultTypeTimeout response:nil];
        }
    };
    return [CJPayButtonInfoHandler handleResponse:response fromVC:self withActionsModel:actionModel];
}


- (void)p_closeAndCallback:(CJPayDypayResultType)resultType response:(CJPaySignQueryResponse *)response {
    [self invalidateCountDownView];
    @CJWeakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ //延时0.1s解决退出动画闪烁问题
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            @CJStrongify(self);
            CJ_CALL_BLOCK(self.completionBlock, response, resultType);
        }];
    });
}

- (void)p_queryFinish:(CJPaySignQueryResponse * _Nullable) response fromSignCallback:(BOOL) fromSignCallback{
    CJPayLogInfo(@"签约查询结果: %@", response.signStatus);
    [self p_trackEvent:@"wallet_cashier_result" params:@{}];
    if (![response isSuccess]) { // 只有订单在有效时间范围内，才会进行弹toast，订单无效时，已经弹窗了。
        if (self.countDownView.curTimeIsValid) {
            [CJToast toastText:response.msg ?: CJString(CJPayNoNetworkMessage) inWindow:self.cj_window];
        }
        return;
    }
    // 回调签约结果
    if ([response.signOrderStatus isEqualToString:@"SUCCESS"]) {
        [CJToast toastText:CJString(@"签约成功") inWindow:self.cj_window];
        [self p_closeAndCallback:CJPayDypayResultTypeSuccess response:response];
        return;
    }

    if (fromSignCallback) { // 只有触发后的首次回调才需要进行相应的处理
        if ([response.signOrderStatus isEqualToString:@"FAIL"] ) {
            [self p_closeAndCallback:CJPayDypayResultTypeFailed response:response];
        } else if ([response.signOrderStatus isEqualToString:@"PROCESSING"]) {
            [CJPayAlertUtil doubleAlertWithTitle:CJString(@"请确认是否完成签约") content:@"" leftButtonDesc:CJString(@"未完成") rightButtonDesc:CJString(@"已完成") leftActionBlock:^{
                
            } rightActioBlock:^{
                [self p_closeAndCallback:CJPayDypayResultTypeProcessing response:response];
            } cancelPosition:CJPayAlertBoldRight useVC:self];
        }
    }
}

- (void)p_payWithChannelType:(CJPayChannelType)channelType response: (CJPaySignConfirmResponse *)response {
    CJPayChannelType trueChannelType = channelType;
    if ([response.ptCode isEqualToString:@"wx"]) {
        if ([response.tradeType isEqualToString:@"MWEB"]) {
            trueChannelType = CJPayChannelTypeWXH5;
        }
    } else if ([response.ptCode isEqualToString:@"alipay"]) {
        if ([response.tradeType isEqualToString:@"ALI_WAP"]) {
            trueChannelType = CJPayChannelTypeSignTbPay;
        }
    } else if ([response.ptCode isEqualToString:@"dypay"]) {
        trueChannelType = CJPayChannelTypeDyPay;
    } else {
        CJPayLogAssert(NO, @"选定的签约方式不能正确处理");
    }

    NSDictionary *dataDict = [response payDataDict];
    self.becomeActiveNotiNeedQuery = NO;
    @CJWeakify(self)
    [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) i_payActionWithChannel:trueChannelType
                                                                       dataDict:dataDict
                                                                completionBlock:^(CJPayChannelType channelType, CJPayResultType resultType, NSString *errorCode) {
        @CJStrongify(self)
        CJPayLogInfo(@"needQuery: callback, type: %lu", (unsigned long)resultType);
        [self p_handleChannelResult:channelType resultType:resultType];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.becomeActiveNotiNeedQuery = YES;
            CJPayLogInfo(@"needQuery: dispatch_after");
        });
    }];
}

- (void)p_trackEvent:(NSString *)event params:(NSDictionary *)params {
    
    NSString *chooseMethod = [CJPayBDTypeInfo getTrackerMethodByChannelConfig:[self.dataView currentChoosePayMethod]];
    
    NSMutableArray *signMethods = [NSMutableArray new];
    [self.createResponse.signTypeInfo.payChannels enumerateObjectsUsingBlock:^(CJPayChannelModel *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.signStatus == 1) {
            [signMethods btd_addObject:obj.code];
        }
    }];
    NSString *signMethodStr = [signMethods componentsJoinedByString:@","];
    NSMutableDictionary *mutableParams = [NSMutableDictionary new];
    [mutableParams addEntriesFromDictionary:@{
        @"pay_source" : @"2",
        @"app_id": CJString(self.createResponse.merchantInfo.appId),
        @"merchant_id": CJString(self.createResponse.merchantInfo.merchantId),
        @"process_id": CJString(self.createResponse.processStr),
        @"sign_method": CJString(signMethodStr),
        @"is_downgrade": @"0",
        @"method" : CJString(chooseMethod),
    }];
    
    [CJTracker event:event params:[mutableParams copy]];
}

- (void)p_handleChannelResult:(CJPayChannelType)channelType resultType:(CJPayResultType)resultType {
    void(^completionBlock)(NSError * _Nullable error, CJPaySignQueryResponse * _Nullable response) = ^(NSError * _Nullable error, CJPaySignQueryResponse * _Nullable response) {
        [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeTopLoading];
        [self p_queryFinish:response fromSignCallback:YES];
    };
    
    switch (resultType) {
        case CJPayResultTypeSuccess:{
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:self title:CJString(@"查询签约状态...")];
            [self p_startQueryResultWithMaxRetryCount:5 completion:completionBlock];
        }
            break;
        case CJPayResultTypeBackToForeground:{
            if ([UIViewController cj_foundTopViewControllerFrom:self] == self) {
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:self title:CJString(@"查询签约状态...")];
                [self p_startQueryResultWithMaxRetryCount:5 completion:completionBlock];
            }
        }
            break;
        case CJPayResultTypeFail:
            [self p_closeAndCallback:CJPayDypayResultTypeFailed response:nil];
            break;
        case CJPayResultTypeUnInstall:{
            if (channelType == CJPayChannelTypeWX || channelType == CJPayChannelTypeWXH5) {
                NSString *toastStr = [NSString stringWithFormat:@"未安装%@，请选择其他方式", CN_WX];
                [CJToast toastText:CJPayLocalizedStr(toastStr) inWindow:self.cj_window];
            } else if (channelType == CJPayChannelTypeTbPay || channelType == CJPayChannelTypeSignTbPay) {
                NSString *toastStr = [NSString stringWithFormat:@"未安装%@，请选择其他方式", CN_zfb];
                [CJToast toastText:CJPayLocalizedStr(toastStr) inWindow:self.cj_window];
            } else if (channelType == CJPayChannelTypeDyPay) {
                [CJToast toastText:CJPayLocalizedStr(@"未安装抖音，请选择其他方式") inWindow:self.cj_window];
            }
        }
            break;
        default:
            CJPayLogInfo(@"未成功签约：%lu", (unsigned long)resultType);
            break;
    }
}

- (void)p_startQueryResultWithMaxRetryCount:(int)count completion:(void (^) (NSError * _Nullable error, CJPaySignQueryResponse * _Nullable response))completionBlock {
    [CJPaySignRequestUtil startSignQueryRequestWithParams:@{
        @"process": CJString(self.createResponse.processStr)
    } completion:^(NSError * _Nonnull error, CJPaySignQueryResponse * _Nonnull response) {
        if ([response isSuccess] && ![response.signOrderStatus isEqualToString:@"PROCESSING"]) {
            CJ_CALL_BLOCK(completionBlock, error, response);
        } else {
            if (count <= 1) {
                CJ_CALL_BLOCK(completionBlock, error, response);
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self p_startQueryResultWithMaxRetryCount:count - 1 completion:completionBlock];
                });
            }
        }
    }];
}

- (void)showTimeOutAlertVC {
    CJPayAlertController *timeOutAlert = [CJPayAlertController alertControllerWithTitle:CJPayLocalizedStr(@"页面停留时间过长，请退出重新发起交易") message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *closeAction = [UIAlertAction actionWithTitle:CJPayLocalizedStr(@"我知道了") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self p_closeAndCallback:CJPayDypayResultTypeTimeout response:nil];
    }];
    [timeOutAlert addAction:closeAction];
    [self presentViewController:timeOutAlert animated:YES completion:nil];
}

#pragma mark - CJPayManagerBizDelegate
- (void)event:(NSString *)event params:(NSDictionary *)params {
    [self p_trackEvent:event params:params];
}

#pragma mark - CJPayCountDownTimerViewDelegate
- (void)countDownTimerRunOut {
    self.countDownView.hidden = YES;
    [self showTimeOutAlertVC];
}

- (void)invalidateCountDownView {
    [self.countDownView invalidate];
    self.countDownView.hidden = YES;
}

- (CJPayCountDownTimerView *)countDownView {
    if (!_countDownView) {
        _countDownView = [CJPayCountDownTimerView new];
        _countDownView.hidden = YES;
        _countDownView.delegate = self;
        _countDownView.style = CJPayCountDownTimerViewStyleNormal;
    }
    return _countDownView;
}

- (UIView<CJPaySignDataProtocol> *)dataView {
    if (!_dataView) {
        _dataView = [CJPayUniteSignContentView new];
        _dataView.trackDelegate = self;
    }
    return _dataView;
}

- (CJPayStyleButton *)confirmBtn {
    if (!_confirmBtn) {
        _confirmBtn = [[CJPayStyleButton alloc] init];
        _confirmBtn.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmBtn.titleLabel.textColor = [UIColor whiteColor];
        
        [_confirmBtn cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        [_confirmBtn setTitle:CJString(@"确认签约") forState:UIControlStateNormal];
        [_confirmBtn addTarget:self action:@selector(p_onConfirmAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmBtn;
}

@end
