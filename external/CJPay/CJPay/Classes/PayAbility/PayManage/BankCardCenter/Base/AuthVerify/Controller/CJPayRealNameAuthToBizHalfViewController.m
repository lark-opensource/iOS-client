//
//  CJPayRealNameAuthToBizHalfViewController.m
//  BDAlogProtocol
//
//  Created by qiangang on 2020/7/17.
//
// 曾用名：CJPayAuthVerifiedHalfViewController

#import "CJPayRealNameAuthToBizHalfViewController.h"

#import "CJPayAuthVerifiedHalfView.h"
#import "CJPayAlertUtil.h"
#import "CJPayStyleButton.h"
#import "CJPayLineUtil.h"
#import "CJPayAuthQueryResponse.h"
#import "CJPayAuthCreateRequest.h"
#import "CJPayAuthCreateResponse.h"
#import "CJPayManagerDelegate.h"
#import "CJPayWebViewUtil.h"
#import "CJPayRequestParam.h"
#import "CJPayProtocolListViewController.h"
#import "CJPayBizWebViewController.h"
#import "CJPayUIMacro.h"


@interface CJPayRealNameAuthToBizHalfViewController ()

@property (nonatomic, strong) CJPayAuthQueryResponse *authQueryResponse;
@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, copy) NSDictionary *trackAndStyleParams;

@property (nonatomic, strong) CJPayAuthVerifiedHalfView *authView;
@property (nonatomic, strong) UIView *hiddenBottomCornerView;

@property (nonatomic, copy) CJPayAuthVerifiedCallBack authCallbackBlock;

@property (nonatomic, assign) BOOL isFirstAppear;

@property (nonatomic, strong) MASConstraint *authViewTopConstraint;

@end

@implementation CJPayRealNameAuthToBizHalfViewController

- (instancetype)initWithParams:(NSDictionary *)params authQueryResponse:(CJPayAuthQueryResponse *)response authCallback:(CJPayAuthVerifiedCallBack)callBack;
{
    self = [super init];
    if (self) {
        _params = [params copy];
        _trackAndStyleParams = [params[@"data"] copy];
        _authQueryResponse = response;
        _authCallbackBlock = callBack;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupUI];
    [self p_setupBlock];
    // 兼容暗黑模式
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    NSDictionary *trackAndStyleParams = [self p_buildTrackerParams];
    [CJTracker event:@"finance_account_paytobusiness_auth_imp1" params:trackAndStyleParams];
    self.animationType = HalfVCEntranceTypeFromBottom;
}

- (void)p_setupUI
{
    [self.view addSubview:self.hiddenBottomCornerView];
    [self.containerView addSubview:self.authView];
    self.animationType = HalfVCEntranceTypeFromBottom;
    self.navigationBar.hidden = YES;
    CJPayMasMaker(self.hiddenBottomCornerView, {
        make.right.left.bottom.equalTo(self.view);
        make.height.mas_equalTo(@10);
    });
    CJPayMasMaker(self.authView, {
        make.left.right.equalTo(self.containerView);
        make.edges.equalTo(self.containerView);
    });
    [self showMask:YES];
    [self.authView updateWithModel:self.authQueryResponse.agreementContentModel];
}

- (void)p_setupBlock
{
    @CJWeakify(self)
    self.authView.authVerifiedBlock = ^{
        @CJStrongify(self)
        NSDictionary *trackAndStyleParams = [self p_buildTrackerParams];
        [CJTracker event:@"finance_account_paytobusiness_auth_click1" params:trackAndStyleParams];
        @CJStartLoading(self.authView.authButton)
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithDictionary:self.params];
        [params cj_setObject:@(self.authQueryResponse.agreementContentModel.authorizeItem) forKey:@"authorize_item"];
        [CJPayAuthCreateRequest startWithBizParams:params
                                        completion:^(NSError * _Nonnull error, CJPayAuthCreateResponse * _Nonnull response) {
            @CJStrongify(self)
            @CJStopLoading(self.authView.authButton)
            NSMutableDictionary *trackAndStyleParams = [[self p_buildTrackerParams] mutableCopy];
            [trackAndStyleParams cj_setObject:([response isSuccess] ? @1 : @0) forKey:@"result"];
            [trackAndStyleParams cj_setObject:@"tp.customer.api_create_authorization" forKey:@"url"];
            [trackAndStyleParams cj_setObject:response.code forKey:@"fail_code"];
            [trackAndStyleParams cj_setObject:response.msg forKey:@"fail_reason"];
            [CJTracker event:@"finance_account_paytobusiness_auth_result1" params:trackAndStyleParams];
            if ([response isSuccess]) {
                [self closeWithAnimation:YES comletion:^(BOOL isFinish) {
                    @CJStrongify(self)
                    CJ_CALL_BLOCK(self.authCallbackBlock,CJPayAuthDeskCallBackTypeSuccess);
                }];
            } else {
                NSString *alertMessage = Check_ValidString(response.msg)? response.msg : CJPayLocalizedStr(CJPayNetworkBusyMessage);

                [CJPayAlertUtil customSingleAlertWithTitle:alertMessage
                                                   content:@""
                                                buttonDesc:CJPayLocalizedStr(@"我知道了")
                                               actionBlock:nil
                                                     useVC:self];
            }
        }];
    };
}

- (void)p_showNotMeAlertWithDisagreeUrl:(NSString *)url
{
    @CJWeakify(self)
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"若实名不是本人，请联系客服处理后再试或尝试注销支付账户")
                                       content:@""
                                leftButtonDesc:CJPayLocalizedStr(@"暂不处理")
                               rightButtonDesc:CJPayLocalizedStr(@"去注销")
                               leftActionBlock:^{
        }
                               rightActioBlock:^{
        @CJStrongify(self)
        NSDictionary *trackAndStyleParams = [self p_buildTrackerParams];
        [CJTracker event:@"finance_account_paytobusiness_notme_pop_click1" params:trackAndStyleParams];
        
        NSString *appId = [self.params cj_stringValueForKey:@"app_id"];
        NSString *merchantId = [self.params cj_stringValueForKey:@"merchant_id"];
        NSString *logoutUrl = [NSString stringWithFormat:@"%@?app_id=%@&merchant_id=%@&service=122&source=sdk", url, appId, merchantId];
        if (Check_ValidString(logoutUrl)) {
            CJPayBizWebViewController *webVC = [[CJPayBizWebViewController alloc] initWithUrlString:logoutUrl];
            webVC.closeCallBack = ^(id  _Nonnull data) {
                @CJStrongify(self)
                if ([data isKindOfClass:NSDictionary.class]) {
                    NSDictionary *dic = (NSDictionary *)data;
                    NSString *service = [dic cj_stringValueForKey:@"service"];
                    if ([service isEqualToString:@"122"]) {
                        [self closeWithAnimation:YES comletion:^(BOOL isFinish) {
                            CJ_CALL_BLOCK(self.authCallbackBlock,CJPayAuthDeskCallBackTypeLogout);
                        }];
                    }
                }
            };
            webVC.lifeCycleBlock = ^(CJPayVCLifeType type) {
            };
            
            [self.navigationController pushViewController:webVC animated:YES];
        }
    }
                                   useVC:self];
    
    NSDictionary *trackAndStyleParams = [self p_buildTrackerParams];
    [CJTracker event:@"finance_account_paytobusiness_notme_pop_imp1" params:trackAndStyleParams];
}

#pragma mark - Getter
- (CJPayAuthVerifiedHalfView *)authView
{
    if (!_authView) {
        _authView = [[CJPayAuthVerifiedHalfView alloc]initWithStyle:[self.trackAndStyleParams cj_dictionaryValueForKey:@"style"]];
        [_authView cj_showCornerRadius:8];
        @CJWeakify(self)
        _authView.closeBlock = ^{
            @CJStrongify(self)
            NSDictionary *trackAndStyleParams = [self p_buildTrackerParams];
            [CJTracker event:@"finance_account_paytobusiness_auth_close1" params:trackAndStyleParams];
            [self closeWithAnimation:YES comletion:^(BOOL isFinish) {
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.authCallbackBlock, CJPayAuthDeskCallBackTypeCancel);
            }];
        };
        _authView.notMeBlock = ^(NSString * _Nonnull logoutUrl) {
            @CJStrongify(self)
            NSDictionary *trackAndStyleParams = [self p_buildTrackerParams];
            [CJTracker event:@"finance_account_paytobusiness_notme_click" params:trackAndStyleParams];
            [self p_showNotMeAlertWithDisagreeUrl:logoutUrl];
        };
        _authView.logoutBlock = ^{
            @CJStrongify(self)
            [self closeWithAnimation:YES comletion:^(BOOL isFinish) {
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.authCallbackBlock, CJPayAuthDeskCallBackTypeLogout);
            }];
        };
        [_authView hideExclamatoryMark:YES];
        _authView.clickExclamatoryMarkBlock = nil;//定高授权页不显示
        _authView.protocolClickedBlock = ^(UILabel * _Nonnull label, NSString * _Nonnull protocolName, NSRange range, NSInteger index){
                 @CJStrongify(self)
                 NSString *url = [self p_getProtocolUrlWithName:protocolName];
                 if (Check_ValidString(url)) {
                     [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self toUrl:url];
                 }
                 else{//second protocol
                     NSInteger protocolIndex = index-self.authQueryResponse.agreementContentModel.agreementContents.count;
                     CJPayLogAssert(protocolIndex >= 0,@"协议序号不可小于0");
                     if (protocolIndex < 0) { return; }
                     CJPayProtocolListViewController *protocolListVc = [CJPayProtocolListViewController new];
                     
                     [protocolListVc showMask:YES];
                     protocolListVc.showContinueButton = NO;
                     protocolListVc.isForBindCardService = NO;
                     NSMutableArray<CJPayQuickPayUserAgreement *> *userAgreements = [NSMutableArray new];
                     NSArray<CJPayAuthDisplayContentModel *> *userAuthAgreements=[self.authQueryResponse.agreementContentModel.secondAgreementContents[protocolIndex]  valueForKeyPath:@"secondDisplayContents"];
                     [userAuthAgreements enumerateObjectsUsingBlock:^(CJPayAuthDisplayContentModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                         CJPayQuickPayUserAgreement *agreement = [CJPayQuickPayUserAgreement new];
                         agreement.contentURL = obj.displayUrl;
                         agreement.title = obj.displayDesc;
                         agreement.defaultChoose = NO;
                         [userAgreements addObject:agreement];
                     }];
                     protocolListVc.userAgreements = userAgreements;
                     @CJWeakify(protocolListVc);
                     protocolListVc.protocolListClick =^(NSInteger index){
                         @CJStrongify(protocolListVc)
                         CJPayQuickPayUserAgreement *agreement = [protocolListVc.userAgreements cj_objectAtIndex:index];
                         [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self toUrl:agreement.contentURL];
                     };
                     [self.navigationController pushViewController:protocolListVc animated:YES];
                 }
        };
    }
    return _authView;
}

- (UIView *)hiddenBottomCornerView
{
    if (!_hiddenBottomCornerView) {
        _hiddenBottomCornerView = [UIView new];
        _hiddenBottomCornerView.backgroundColor = [UIColor whiteColor];
    }
    return _hiddenBottomCornerView;
}

- (NSDictionary*)p_buildTrackerParams
{
    NSMutableDictionary *trackAndStyleParams = [NSMutableDictionary new];
    [trackAndStyleParams cj_setObject:@"通用版本一" forKey:@"front_style"];
    [trackAndStyleParams cj_setObject:[CJPayRequestParam gAppInfoConfig].appId forKey:@"aid"];
    [trackAndStyleParams cj_setObject:[self.params cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [trackAndStyleParams cj_setObject:[self.params cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [trackAndStyleParams cj_setObject:@"0" forKey:@"type"];
    [trackAndStyleParams cj_setObject:@"" forKey:@"scene"];
    [trackAndStyleParams cj_setObject:self.trackAndStyleParams[@"enter_from"] forKey:@"enter_from"];
    [trackAndStyleParams cj_setObject:self.trackAndStyleParams[@"request_page"] forKey:@"request_page"];
    return [trackAndStyleParams copy];
}

- (NSString *)p_getProtocolUrlWithName:(NSString *)name
{
    __block NSString *protocolUrl = @"";
    [self.authQueryResponse.agreementContentModel.agreementContents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayAuthDisplayContentModel.class]) {
            CJPayAuthDisplayContentModel *contentModel = (CJPayAuthDisplayContentModel *)obj;
            if ([contentModel.displayDesc isEqualToString:[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]]) {
                protocolUrl = contentModel.displayUrl;
                *stop = YES;
            }
        }
    }];
    return protocolUrl;
}

@end
