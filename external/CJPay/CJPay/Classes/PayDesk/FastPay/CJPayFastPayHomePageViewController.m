//
//  CJPayFastPayHomePageViewController.m
//  Pods
//
//  Created by wangxiaohong on 2022/10/31.
//

#import "CJPayFastPayHomePageViewController.h"

#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayIntegratedCashierProcessManager.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayFastConfirmRequest.h"
#import "CJPayResultPageViewController.h"
#import "CJPayOrderResultRequest.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPaySettingsManager.h"
#import "CJPayFastPayVerifyManager.h"
#import "CJPayFastPayVerifyManagerQueen.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPayDeskServiceHeader.h"
#import "CJPayToast.h"
#import "CJPayFrontCashierResultModel.h"

@interface CJPayFastPayHomePageViewController ()<CJPayHomeVCProtocol>

@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic,copy) void(^completionBlock)(CJPayOrderResultResponse *_Nullable response, CJPayOrderStatus orderStatus);
@property (nonatomic, assign) NSInteger queryTimes;
@property (nonatomic, copy) NSDictionary *createOrderParams;
@property (nonatomic, strong) CJPayOrderResultResponse *resResponse;

@property (nonatomic, strong) CJPayFastPayVerifyManager *verifyManager;
@property (nonatomic, strong) CJPayFastPayVerifyManagerQueen *verifyManagerQueen;

@property (nonatomic, strong) CJPayBDCreateOrderResponse *bdCreateResponse;

@property (nonatomic, weak)id<CJPayAPIDelegate> delegate;

@end

@implementation CJPayFastPayHomePageViewController

- (instancetype)initWithBizParams:(NSDictionary *)bizParams
                           bizurl:(NSString *)bizUrl
                         delegate:(id<CJPayAPIDelegate>)delegate
                  completionBlock:(nonnull void (^)(CJPayOrderResultResponse * _Nullable response, CJPayOrderStatus orderStatus))completionBlock
{
    self = [super init];
    if (self) {
        self.animationType = HalfVCEntranceTypeFromBottom;
        self.completionBlock = completionBlock;
        self.createOrderParams = bizParams;
        
        self.verifyManager.verifyManagerQueen = self.verifyManagerQueen;
        self.delegate = delegate;
    }
    return self;
}

#pragma mark - IntegratedCashierHomeVCProtocol

- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayHomeVCCloseActionSource)source {
    [self.navigationController popToViewController:self animated:NO];
    if (time < 0) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJWeakify(self)
        [self closeWithAnimation:YES comletion:^(BOOL finish) {
            @CJStrongify(self)
            if (self.navigationController) {
                [self.navigationController dismissViewControllerAnimated:NO completion:nil];
            } else {
                [self dismissViewControllerAnimated:NO completion:nil];
            }
            //消失后执行
            CJ_CALL_BLOCK(self.completionBlock, self.resResponse, [self p_convertSourceToStatus:source]);
        }];
    });
}

- (CJPayOrderStatus)p_convertSourceToStatus:(CJPayHomeVCCloseActionSource)source {
    switch (source) {
        case CJPayHomeVCCloseActionSourceFromBack:
        case CJPayHomeVCCloseActionSourceFromCloseAction:
            return CJPayOrderStatusCancel;
        case CJPayHomeVCCloseActionSourceFromOrderTimeOut:
            return CJPayOrderStatusTimeout;
        default:
            return CJPayOrderStatusNull;
    }
}

#pragma mark - CJPayIntegratedCashierHomeVCProtocol
- (void)p_updateRiskTipWithContent:(NSString *)content {
    if (!content || content.length <= 0) {
        self.titleLabel.hidden = YES;
        self.titleLabel.text = @"";
    } else {
        self.titleLabel.hidden = NO;
        self.titleLabel.text = content;
        [self.contentView bringSubviewToFront:self.titleLabel];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigatinBar];
    [self setupUI];
    [self p_fastPayWithConfig:nil];
}

- (void)p_fastPayWithConfig:(nullable NSDictionary *)currentConfig {
    self.queryTimes = 0;
    @CJStartLoading(self)
    @CJWeakify(self)
    [CJPayFastConfirmRequest startFastWithBizParams:self.createOrderParams bizUrl:@"" completion:^(NSError * _Nonnull error, CJPayOrderResultResponse * _Nonnull response) {
        @CJStrongify(self);
        @CJStopLoading(self)
        if ([response isSuccess]) {
            if (response.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) {
                [self p_showResultWithResponse:response];
                [self p_trackFastPayResultWithResponse:response result:@"1"];
            } else if (response.tradeInfo && response.tradeInfo.tradeStatus == CJPayOrderStatusProcess) {
                [self startQueryWithResponse:response config:currentConfig];
            } else {
                [self p_showFailForTwoSecondsThenOpenStandardPayDeskWithConfig:[NSDictionary new] code:response.code msg:response.msg];
                [self p_trackFastPayResultWithResponse:response result:@"0"];
            }
        } else if ([response.code isEqualToString:@"CA3009"]) {
            [self p_startFrontCashierPayWithData:response.errorData];
        } else {
            [self p_showFailForTwoSecondsThenOpenStandardPayDeskWithConfig:[NSDictionary new] code:response.code msg:response.msg];
            [self p_trackFastPayResultWithResponse:response result:@"0"];
        }
    }];
}

//调用风控加验
- (void)p_startFrontCashierPayWithData:(NSString *)data {
    CJPayBDCreateOrderResponse *response = [[CJPayBDCreateOrderResponse alloc] initWithDictionary:@{@"response": [data cj_toDic] ?: @{}} error:nil];
    self.bdCreateResponse = response;
    self.verifyManager.isOneKeyQuickPay = YES;
    self.verifyManager.trackParams = @{};
    [self.verifyManager begin];
}

//调用标准收银台
- (void)p_openStandardPayDeskWithConfig:(NSDictionary *)currentConfig code:(NSString *)code {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:^{
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.createOrderParams];
        if ([code isEqualToString:@"CA3007"]) {
            [params cj_setObject:@"2" forKey:@"cashier_source"];
        } else {
            [params cj_setObject:@"1" forKey:@"cashier_source"];
        }
        [params cj_setObject:@"1" forKey:@"show_loading"];
        [CJ_OBJECT_WITH_PROTOCOL(CJPayCashierModule) i_openPayDeskWithConfig:currentConfig params:params delegate:self.delegate];
    }];
}

- (CJPayOrderResultResponse *)p_setOrderResultResponseWith:(CJPayFrontCashierResultModel *)resModel{
    if (!resModel || !resModel.tradeStatus) {
        return nil;
    }
    CJPayOrderResultResponse *response = [CJPayOrderResultResponse new];
    response.tradeInfo = [CJPayTradeInfo new];
    response.tradeInfo.status = resModel.tradeStatus;
    return response;
}

//调用回调block
- (void)p_callCompletionBlock:(CJPayOrderResultResponse *)response orderStatus:(CJPayOrderStatus)orderStatus {
    CJ_CALL_BLOCK(self.completionBlock, response, orderStatus);
}

- (CJPayOrderResultResponse *)p_cjResultResponseWithBDResposne:(CJPayBDOrderResultResponse *)bdResultResponse {
    if (!bdResultResponse || !bdResultResponse.tradeInfo.tradeStatusString) {
        return nil;
    }
    CJPayOrderResultResponse *response = [CJPayOrderResultResponse new];
    response.tradeInfo = [CJPayTradeInfo new];
    response.tradeInfo.status = bdResultResponse.tradeInfo.tradeStatusString;
    return response;
}

- (void)p_processBdFastpayResultResponse:(CJPayOrderResultResponse *)resultResponse orderStatus:(CJPayOrderStatus)orderStatus {
    self.resResponse = resultResponse;
    switch (orderStatus) {
        case CJPayOrderStatusSuccess:
            [self p_callCompletionBlock:self.resResponse orderStatus:CJPayOrderStatusNull];
            break;
        default:
            [self p_openStandardPayDeskWithConfig:nil code:self.resResponse.code];
            break;
    }
}

- (void)startQueryWithResponse:(CJPayOrderResultResponse *) response
                        config:(NSDictionary *)currentConfig {
    self.queryTimes += 1;
    [CJPayOrderResultRequest startWithTradeNo:response.tradeInfo.tradeNo processInfo:response.processStr completion:^(NSError *error, CJPayOrderResultResponse *queryResponse) {
        response.responseDuration += queryResponse.responseDuration + 100;
        if (queryResponse.tradeInfo.tradeStatus == CJPayOrderStatusProcess && self.queryTimes < [[CJPaySettingsManager shared].currentSettings.fastPayModel maxQueryTimes]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self startQueryWithResponse:response config:currentConfig];
            });
        } else if (queryResponse.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) {
            response.tradeInfo.status = queryResponse.tradeInfo.status;
            [self p_showResultWithResponse:response];
            [self p_trackFastPayResultWithResponse:response result:@"1"];
        } else {
            [self p_showFailForTwoSecondsThenOpenStandardPayDeskWithConfig:currentConfig code:response.code msg:response.msg];
            [self p_trackFastPayResultWithResponse:response result:@"0"];
        }
    }];
}

- (void)p_showFailForTwoSecondsThenOpenStandardPayDeskWithConfig:(NSDictionary *)currentConfig code:(NSString *)code msg:(NSString *)msg {
    if (!msg || msg.length < 1) {
        msg = @"极速支付处理中，正在前往收银台";
    }
    CJPayStateShowModel *showModel = [CJPayStateShowModel new];
    showModel.titleStr = @"";
    showModel.iconName = @"cj_sorry_icon";
    [self.stateView updateShowConfigsWithType:CJPayStateTypeFailure model:showModel];
    [self showState:CJPayStateTypeFailure];
    [self hideBackButton];
    [self p_updateRiskTipWithContent:msg];
    @CJWeakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self);
        [self p_openStandardPayDeskWithConfig:currentConfig code:code];
    });
}

- (void)p_showResultWithResponse:(CJPayOrderResultResponse *)response {
    @CJWeakify(self)
    CJPayResultPageViewController *resultVC = [CJPayResultPageViewController new];
    resultVC.resultResponse = response;
    resultVC.commonTrackerParams = [self buildfastPayCommenTrackDicWithResponse:response andParam:@{}];
    self.resResponse = response;
    resultVC.closeActionCompletionBlock = ^(BOOL isClose) {
        @CJStrongify(self);
        [self p_callCompletionBlock:self.resResponse orderStatus:CJPayOrderStatusNull];
    };
    resultVC.isOneKeyQuickPay = YES;
    [(CJPayNavigationController *)self.navigationController pushViewControllerSingleTop:resultVC animated:NO completion:nil];
}

- (NSDictionary *)buildfastPayCommenTrackDicWithResponse:(CJPayOrderResultResponse *)response andParam:(NSDictionary *)dic {
    NSMutableDictionary *mutableDic = [NSMutableDictionary new];
    NSString *scene = @([[response.tradeInfo.statInfo cj_toDic] cj_integerValueForKey:@"scene"]).stringValue;
    [mutableDic addEntriesFromDictionary:@{
        @"app_id": [self.createOrderParams cj_stringValueForKey:@"app_id"],
        @"merchant_id" : CJString(response.tradeInfo.merchantId),
        @"trade_no" : CJString(response.tradeInfo.tradeNo),
        @"check_type" : @"极速",
        @"is_chaselight" : @"1",
        @"identity_type" : @"1",
        @"is_new_user" : @"0",
        @"dy_charge_scene": CJString(scene)
    }];
    
    [mutableDic addEntriesFromDictionary:dic];
    return [mutableDic copy];
}

- (void)p_trackFastPayResultWithResponse:(CJPayOrderResultResponse *)response result:(NSString *)result {
    [CJTracker event:@"wallet_cashier_fastpay_result" params:[self buildfastPayCommenTrackDicWithResponse:response andParam:@{
        @"result" : result,
        @"method" : CJString([response.tradeInfo.bdpayResultResponse payTypeDescText]),
        @"activity_info" : [self p_activityInfoParamsWithVoucherArray:response.tradeInfo.bdpayResultResponse.voucherDetails],
        @"risk_type" : @"无",
        @"amount" : @(response.tradeInfo.amount),
        @"real_amount" : @(response.tradeInfo.bdpayResultResponse.tradeInfo.payAmount),
        @"reduce_amount" : @(response.tradeInfo.bdpayResultResponse.tradeInfo.reduceAmount),
    }]];
    
    [CJTracker event:@"wallet_cashier_fastpay_loading_time" params:[self buildfastPayCommenTrackDicWithResponse:response andParam:@{
        @"amount" : @(response.tradeInfo.amount),
        @"result" : result,
        @"loading_time": [NSString stringWithFormat:@"%f", response.responseDuration],
        @"error_code": CJString(response.code),
        @"error_message": CJString(response.msg)
    }]];
}

- (void)setupNavigatinBar {
    self.navigationBar.backBtn.hidden = YES;
    NSString *quickPayCashierTitle = [CJPayBrandPromoteABTestManager shared].model.oneKeyQuickCashierTitle;
    if (Check_ValidString(quickPayCashierTitle)) {
        [self setTitle:CJPayLocalizedStr(quickPayCashierTitle)];
    } else {
        [self setTitle:CJPayLocalizedStr(@"极速支付")];
    }
}

- (NSArray *)p_activityInfoParamsWithVoucherArray:(NSArray<NSDictionary *> *)voucherArray {
    NSMutableArray *activityInfos = [NSMutableArray array];
    [voucherArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.count > 0) {
            [activityInfos addObject:@{
                @"id" : CJString([obj cj_stringValueForKey:@"voucher_no"]),
                @"type": [[obj cj_stringValueForKey:@"voucher_type"] isEqualToString:@"discount_voucher"] ? @"0" : @"1",
                @"front_bank_code": CJString([obj cj_stringValueForKey:@"front_bank_code"]),
                @"reduce" : @([obj cj_intValueForKey:@"used_amount"]),
                @"label": CJString([obj cj_stringValueForKey:@"label"])
            }];
        }
    }];
    return activityInfos;
}

- (void)setupUI {
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self.contentView addSubview:self.safeGuardTipView];
        
        CJPayMasMaker(self.safeGuardTipView, {
            make.bottom.equalTo(self.contentView).offset(-16 - CJ_TabBarSafeBottomMargin);
            make.centerX.equalTo(self.contentView);
            make.height.mas_equalTo(16);
        });
    }
    self.titleLabel.hidden = YES;
    [self.contentView addSubview:self.titleLabel];
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.contentView).offset(187);
        make.centerX.equalTo(self.contentView);
    });
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}

- (UILabel *)titleLabel {
    if(!_titleLabel){
        _titleLabel = [UILabel new];
        _titleLabel.numberOfLines = 2;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont cj_fontOfSize:13];
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
    }
    return _titleLabel;
}

- (CJPayFastPayVerifyManagerQueen *)verifyManagerQueen {
    if (!_verifyManagerQueen) {
        _verifyManagerQueen = [[CJPayFastPayVerifyManagerQueen alloc] init];
        [_verifyManagerQueen bindManager:self.verifyManager];
    }
    return _verifyManagerQueen;
}

- (CJPayFastPayVerifyManager *)verifyManager {
    if (!_verifyManager) {
        _verifyManager = [CJPayFastPayVerifyManager managerWith:self];
    }
    return _verifyManager;
}

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:CJPayLocalizedStr(@"抖音极速支付")];
}

- (void)stopLoading {
    [[CJPayLoadingManager defaultService] stopLoading];
}

- (void)p_userCancelRiskVerify {
    [self p_openStandardPayDeskWithConfig:nil code:@""];
}
- (void)p_occurUnHandleConfirmError {
    // 顶部是极速支付聚合的首页就回调给聚合极速支付失败
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:self];
    if (topVC && topVC == self) {
        [self p_openStandardPayDeskWithConfig:nil code:@""];
    }
}

#pragma mark - CJPayHomeVCProtocol
- (CJPayBDCreateOrderResponse *)createOrderResponse {
    return self.bdCreateResponse;
}

- (CJPayDefaultChannelShowConfig *)curSelectConfig {
    return nil;
}

- (CJPayVerifyType)firstVerifyType {
    NSString *confirmCode = [self.bdCreateResponse.tradeConfirmInfo cj_stringValueForKey:@"code"];
    if (confirmCode && [[self codeVerifyItemDic] objectForKey:CJString(confirmCode)]) {
        return [[self codeVerifyItemDic] cj_integerValueForKey:CJString(confirmCode)];
    } else {
        [CJToast toastText:@"没有找到追光的首次加验方式!!!" inWindow:self.cj_window];
        return CJPayVerifyTypePassword;
    }
}

- (NSDictionary *)codeVerifyItemDic {
    return  @{
        @"CD002005": @(CJPayVerifyTypePassword),
        @"CD002008": @(CJPayVerifyTypePassword),
        @"CD002006": @(CJPayVerifyTypeBioPayment),
        @"CD002007": @(CJPayVerifyTypeBioPayment),
        @"CD002001": @(CJPayVerifyTypeSMS),
        @"CD002104": @(CJPayVerifyTypeFaceRecog),
        @"CD001001": @(CJPayVerifyTypeIDCard),
        @"CD005010": @(CJPayVerifyTypeUploadIDCard),
        @"CD002003": @(CJPayVerifyTypeAddPhoneNum)
    };
}

- (BOOL)receiveDataBus:(CJPayHomeVCEvent)eventType obj:(id)object {
    switch (eventType) {
        case CJPayHomeVCEventUserCancelRiskVerify:
            [self p_userCancelRiskVerify];
            break;
        case CJPayHomeVCEventOccurUnHandleConfirmError:
            [self p_occurUnHandleConfirmError];
            break;
        case CJPayHomeVCEventDismissAllAboveVCs:
            break;
        case CJPayHomeVCEventConfirmRequestError:
            [self p_confirmRequestErrorWithDict:object];
            break;
        default:
            break;
    }
    return YES;
}

- (void)p_confirmRequestErrorWithDict:(NSDictionary *)dict {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.verifyManager.trackParams];
    [params addEntriesFromDictionary:dict];
    [CJTracker event:@"wallet_cashier_confirm_error_info" params:[params copy]];
}

- (void)push:(UIViewController *)vc animated:(BOOL)animated {
    // 极速支付需要拦截风控页面的返回，回调给聚合收银台
    NSArray *riskHomeVCList = @[@"CJPayHalfVerifySMSViewController",
                                @"CJPayVerifySMSViewController",
                                @"CJPayBizWebViewController",
                                @"CJPayVerifyIDCardViewController",
                                @"CJPayVerifyPassPortViewController",
                                @"CJPayHalfVerifyPasswordNormalViewController",
                                @"CJPayBDBioConfirmViewController"];
    
    NSString *vcTypeStr = NSStringFromClass([vc class]);
    if (vcTypeStr && [riskHomeVCList containsObject:vcTypeStr]) {
        @CJWeakify(self)
        vc.cjBackBlock = ^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.completionBlock, nil, CJPayOrderStatusFail);
        };
    }
    [self.navigationController pushViewController:vc animated:animated];
}

- (UIViewController *)topVC {
    return [UIViewController cj_foundTopViewControllerFrom:self];
}

- (void)endVerifyWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse {
    // 这里展示结果页
    if (![resultResponse isSuccess]) {
        [self.verifyManager sendEventTOVC:CJPayHomeVCEventShowState obj:@(CJPayStateTypeNone)];
        [CJToast toastText:CJString(resultResponse.msg) inWindow:self.cj_window];
        return;
    }
    [self p_processBdFastpayResultResponse:[self p_cjResultResponseWithBDResposne:resultResponse] orderStatus:CJPayOrderStatusNull];
    return;
}

@end
