//
//  CJPayRealNameAuthToBizViewController.m
//  CJPay
//
//  Created by wangxiaohong on 2020/5/22.
//
// 曾用名：CJPayAuthVerifiedViewController

#import "CJPayRealNameAuthToBizViewController.h"

#import "CJPayAuthVerifiedView.h"
#import "CJPayAlertUtil.h"
#import "CJPayStyleButton.h"
#import "CJPayLineUtil.h"
#import "CJPayAuthQueryResponse.h"
#import "CJPayAuthCreateRequest.h"
#import "CJPayAuthCreateResponse.h"
#import "CJPayWebViewUtil.h"
#import "CJPayRequestParam.h"
#import "CJPayProtocolListViewController.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayMemAgreementModel.h"
#import "CJPayBizWebViewController.h"
#import "CJPayUIMacro.h"

@interface CJPayRealNameAuthToBizViewController()

@property (nonatomic, strong) CJPayAuthQueryResponse *authQueryResponse;
@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, copy) NSDictionary *trackAndStyleParams;

@property (nonatomic, copy) CJPayAuthVerifiedCallBack authCallbackBlock;

@property (nonatomic, strong) CJPayAuthVerifiedView *authView;
@property (nonatomic, strong) UIView *backColorView;
@property (nonatomic, strong) UIView *hiddenBottomCornerView;

@property (nonatomic, assign) BOOL isFirstAppear;

@property (nonatomic, strong) MASConstraint *authViewTopConstraint;

@end

@implementation CJPayRealNameAuthToBizViewController

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
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self p_setupUI];
    [self p_setupBlock];
    // 兼容暗黑模式
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    NSDictionary *trackAndStyleParams = [self p_buildTrackerParams];
    [CJTracker event:@"finance_account_paytobusiness_auth_imp1" params:trackAndStyleParams];

}

#pragma mark - Private Methods
- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.backColorView];
    [self.view addSubview:self.hiddenBottomCornerView];
    [self.view addSubview:self.authView];
    CJPayMasMaker(self.backColorView, {
        make.edges.equalTo(self.view);
    });
    CJPayMasMaker(self.hiddenBottomCornerView, {
        make.right.left.bottom.equalTo(self.view);
        make.height.mas_equalTo(@10);
    });
    CJPayMasMaker(self.authView, {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view.mas_bottom).offset(CJ_IPhoneX ? -384 : -350);
    });
    
    [self.authView updateWithModel:self.authQueryResponse.agreementContentModel ];
    [self p_updateProtocolView];
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
                [self p_runExitAnimationWithCompletion:^{
                    @CJStrongify(self)
                    CJ_CALL_BLOCK(self.authCallbackBlock, CJPayAuthDeskCallBackTypeSuccess);
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
                        [self p_runExitAnimationWithCompletion:^{
                            @CJStrongify(self)
                            CJ_CALL_BLOCK(self.authCallbackBlock, CJPayAuthDeskCallBackTypeLogout);
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

- (void)p_showAuthorizedTips {
    [CJPayAlertUtil customSingleAlertWithTitle:CJPayLocalizedStr(@"你曾在抖音上填写过实名信息，可享受全面的支付服务，具体可前往抖音钱包查看")
                                 content:nil
                              buttonDesc:CJPayLocalizedStr(@"我知道了")
                             actionBlock:^{
    }
                                   useVC:self];
}

- (void)p_runExitAnimationWithCompletion:(void (^)(void))completion {
        [self dismissViewControllerAnimated:NO completion:completion];
}

- (void)p_updateProtocolView {
    CJPayCommonProtocolModel *commonModel = [CJPayCommonProtocolModel new];
    commonModel.guideDesc = CJPayLocalizedStr(@"阅读并同意");
    NSMutableDictionary *groupNameDic = [NSMutableDictionary dictionary];
    NSMutableArray *agreements = [NSMutableArray array];
    [self.authQueryResponse.agreementContentModel.agreementContents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayAuthDisplayContentModel.class]) {
            NSString *key = CJConcatStr(@"protocolNo",[NSString stringWithFormat:@"%lu",idx]);
            CJPayAuthDisplayContentModel *contentModel = (CJPayAuthDisplayContentModel *)obj;
            CJPayMemAgreementModel *agreementModel = [CJPayMemAgreementModel new];
            if(Check_ValidString(contentModel.displayDesc) && Check_ValidString(contentModel.displayUrl)) {
                agreementModel.group = key;
                agreementModel.name = contentModel.displayDesc;
                agreementModel.url = contentModel.displayUrl;
                agreementModel.isChoose = NO;
                [agreements btd_addObject:agreementModel];
                [groupNameDic addEntriesFromDictionary:@{key:agreementModel.name}];
            }
        }
    }];
    [self.authQueryResponse.agreementContentModel.secondAgreementContents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayAuthDisplayMultiContentModel.class]) {
            NSString *key = CJConcatStr(@"protocolMutiNo",[NSString stringWithFormat:@"%lu",idx]);
            CJPayAuthDisplayMultiContentModel *secondContentModel = (CJPayAuthDisplayMultiContentModel *)obj;
            if(Check_ValidString(secondContentModel.oneDisplayDesc)) {
                [groupNameDic addEntriesFromDictionary:@{key:secondContentModel.oneDisplayDesc}];
                [secondContentModel.secondDisplayContents enumerateObjectsUsingBlock:^(id  _Nonnull content, NSUInteger index, BOOL * _Nonnull secondStop) {
                    if ([content isKindOfClass:CJPayAuthDisplayContentModel.class]) {
                        CJPayAuthDisplayContentModel *contentModel = (CJPayAuthDisplayContentModel *)content;
                        CJPayMemAgreementModel *agreementModel = [CJPayMemAgreementModel new];
                        if(Check_ValidString(contentModel.displayDesc) && Check_ValidString(contentModel.displayUrl)) {
                            agreementModel.group = key;
                            agreementModel.name = contentModel.displayDesc;
                            agreementModel.url = contentModel.displayUrl;
                            agreementModel.isChoose = NO;
                            [agreements btd_addObject:agreementModel];
                        }
                    }
                }];
            }
        }
    }];
    commonModel.groupNameDic = groupNameDic;
    commonModel.agreements = agreements;
    [self.authView updateWithCommonModel:commonModel];
}

#pragma mark - Getter
- (CJPayAuthVerifiedView *)authView
{
    if (!_authView) {
        _authView = [[CJPayAuthVerifiedView alloc]initWithStyle:[self.trackAndStyleParams cj_dictionaryValueForKey:@"style"]];
        [_authView cj_showCornerRadius:8];
        @CJWeakify(self)
        _authView.closeBlock = ^{
            @CJStrongify(self)
            NSDictionary *trackAndStyleParams = [self p_buildTrackerParams];
            [CJTracker event:@"finance_account_paytobusiness_auth_close1" params:trackAndStyleParams];
            [self p_runExitAnimationWithCompletion:^{
                CJ_CALL_BLOCK(self.authCallbackBlock, CJPayAuthDeskCallBackTypeCancel);
            }];
        };
        _authView.notMeBlock = ^(NSString * _Nonnull logoutUrl) {
            @CJStrongify(self)
            NSDictionary *trackAndStyleParams = [self p_buildTrackerParams];
            [CJTracker event:@"finance_account_paytobusiness_notme_click" params:trackAndStyleParams];
            [self p_showNotMeAlertWithDisagreeUrl:logoutUrl];
        };
        [_authView hideExclamatoryMark:NO];
        _authView.clickExclamatoryMarkBlock = ^{
            @CJStrongify(self)
            [self p_showAuthorizedTips];
        };
        _authView.logoutBlock = ^{
            @CJStrongify(self)
            [self p_runExitAnimationWithCompletion:^{
                CJ_CALL_BLOCK(self.authCallbackBlock, CJPayAuthDeskCallBackTypeLogout);
            }];
        };
    }
    return _authView;
}

- (UIView *)backColorView
{
    if (!_backColorView) {
        _backColorView = [UIView new];
        _backColorView.backgroundColor = [UIColor cj_maskColor];
        _backColorView.alpha = 1.0;
    }
    return _backColorView;
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
    [trackAndStyleParams cj_setObject:@"0" forKey:@"type"];
    [trackAndStyleParams cj_setObject:@"" forKey:@"scene"];
    [trackAndStyleParams cj_setObject:[self.params cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [trackAndStyleParams cj_setObject:[self.params cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [trackAndStyleParams cj_setObject:self.trackAndStyleParams[@"enter_from"] forKey:@"enter_from"];
    [trackAndStyleParams cj_setObject:self.trackAndStyleParams[@"request_page"] forKey:@"request_page"];
    return [trackAndStyleParams copy];
}

@end
 
