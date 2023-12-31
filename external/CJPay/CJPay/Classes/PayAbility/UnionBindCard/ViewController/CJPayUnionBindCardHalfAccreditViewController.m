//
//  CJPayUnionBindCardHalfAccreditViewController.m
//  Pods
//
//  Created by chenbocheng on 2021/9/26.
//

#import "CJPayUnionBindCardHalfAccreditViewController.h"

#import "CJPayCommonProtocolModel.h"
#import "CJPayUnionBindCardSignResponse.h"
#import "CJPayUnionBindCardSignRequest.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayUnionBindCardHalfAccreditView.h"
#import "CJPayUnionBindCardAuthenticationView.h"
#import "CJPayStyleButton.h"
#import "CJPayUnionBindCardChooseListViewController.h"
#import "CJPayUnionBindCardManager.h"
#import "CJPayUnionBindCardListResponse.h"
#import "CJPayUnionBindCardAuthorizationResponse.h"
#import "CJPayMetaSecManager.h"
#import "CJPayBindCardManager.h"
#import "CJPayBindCardShareDataKeysDefine.h"
#import "CJPayUnionBindCardKeysDefine.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayProtocolPopUpViewController.h"
#import "CJPayToast.h"

@implementation CJPayUnionBindCardHalfAccreditViewModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"signOrderNo" : CJPayBindCardShareDataKeySignOrderNo,
        @"authorizationResponse": CJPayUnionBindCardPageParamsKeyAuthorizationResponse
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}

@end

@interface CJPayUnionBindCardHalfAccreditViewController ()

@property (nonatomic, strong) CJPayUnionBindCardHalfAccreditView *accreditView;

@property (nonatomic, strong) CJPayUnionBindCardHalfAccreditViewModel *viewModel;

@end

@implementation CJPayUnionBindCardHalfAccreditViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.animationType = HalfVCEntranceTypeFromBottom;
        self.exitAnimationType = HalfVCEntranceTypeFromBottom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_trackWithEventName:@"wallet_ysf_auth_page_imp" params:@{}];
}

- (void)p_setupUI {
    [self useCloseBackBtn];
    [self.containerView addSubview:self.accreditView];
    
    CJPayMasMaker(self.accreditView, {
        make.top.equalTo(self.containerView).offset(40);
        make.left.right.bottom.equalTo(self.containerView);
    });
    @CJWeakify(self);
    [self.accreditView.confirmButton btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
        @CJStrongify(self);
        [self.accreditView.protocolView executeWhenProtocolSelected:^{
            @CJStrongify(self);
            [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeUnionPayAuthRequest];
            [self p_unionSignRequest];
        } notSeleted:^{
            @CJStrongify(self)
            if (self.accreditView.protocolView.protocolModel.agreements.count) {
                CJPayProtocolPopUpViewController *popupProtocolVC = [[CJPayProtocolPopUpViewController alloc] initWithProtocolModel:self.accreditView.protocolView.protocolModel from:@"云闪付半屏授权页"];
                popupProtocolVC.confirmBlock = ^{
                    @CJStrongify(self)
                    [self.accreditView.protocolView setCheckBoxSelected:YES];
                    
                    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeUnionPayAuthRequest];
                    [self p_unionSignRequest];
                };
                [self.navigationController pushViewController:popupProtocolVC animated:YES];
            }
        } hasToast:NO];
    } forControlEvents:UIControlEventTouchUpInside];
}

- (void)p_gotoCardListVC {
    [self.accreditView.confirmButton startLoading];
    @CJWeakify(self)
    [[CJPayUnionBindCardManager shared] openChooseCardListWithCompletion:^(BOOL isOpenedSuccessed) {
        @CJStrongify(self)
        [self.accreditView.confirmButton stopLoading];
    }];
}

- (void)p_unionSignRequest {
    [self.accreditView.confirmButton startLoading];
    @CJWeakify(self)
    [CJPayUnionBindCardSignRequest startRequestWithAppId:CJString(self.viewModel.appId)
                                              merchantId:CJString(self.viewModel.merchantId)
                                         bizContentParam:@{
        @"member_biz_order_no": CJString(self.viewModel.signOrderNo)
    } completion:^(NSError * _Nonnull error, CJPayUnionBindCardSignResponse * _Nonnull response) {
        @CJStrongify(self)
        [self p_trackWithEventName:@"wallet_ysf_auth_page_click"
                            params:@{
                                @"button_name" : @"1",
                                @"result" : [response isSuccess] ? @"1" : @"0",
                                @"error_code" : CJString(response.code),
                                @"error_message" : CJString(response.msg)}];
        [self.accreditView.confirmButton stopLoading];
        if (error || !response) {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
            return;
        }
        if (![response isSuccess]) {
            if (response.buttonInfo) {
                CJPayButtonInfoHandlerActionsModel *actionModels = [self p_buttonInfoActions:response];
                [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo fromVC:self
                                                                errorMsg:response.buttonInfo.page_desc ?: CJString(response.msg)
                                                             withActions:actionModels
                                                               withAppID:self.viewModel.appId
                                                              merchantID:self.viewModel.merchantId];
            } else {
                [CJToast toastText:CJString(response.msg) inWindow:self.cj_window];
            }
        } else { //success
            [self p_gotoCardListVC];
        }
    }];
}

- (CJPayButtonInfoHandlerActionsModel *)p_buttonInfoActions:(CJPayUnionBindCardSignResponse *)response {
    CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];
    @CJWeakify(self)
    actionModel.errorInPageAction = ^(NSString * _Nonnull errorText) {
        @CJStrongify(self)
        [CJToast toastText:errorText inWindow:self.cj_window];
    };
    return actionModel;
}

- (void)p_protocolClickBlock {
    [self p_trackWithEventName:@"wallet_ysf_auth_page_click" params:@{@"button_name" : @"2"}];
}

- (void)back {
    [self p_trackWithEventName:@"wallet_ysf_auth_page_click" params:@{@"button_name" : @"0"}];
    [super back];
}

#pragma mark - protocol
- (void)createAssociatedModelWithParams:(NSDictionary<NSString *,id> *)dict {
    if (dict.count > 0) {
        NSError *error;
        self.viewModel = [[CJPayUnionBindCardHalfAccreditViewModel alloc] initWithDictionary:dict error:&error];
    }
}

+ (Class)associatedModelClass {
    return [CJPayUnionBindCardHalfAccreditViewModel class];
}

#pragma mark - lazyView

- (CJPayUnionBindCardHalfAccreditView *)accreditView {
    if (!_accreditView) {
        _accreditView = [[CJPayUnionBindCardHalfAccreditView alloc] initWithResponse:self.viewModel.authorizationResponse];
        @CJWeakify(self)
        _accreditView.protocolClickBlock = ^{
            @CJStrongify(self)
            [self p_protocolClickBlock];
        };
    }
    return _accreditView;
}

#pragma mark - tracker
    
- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {

    NSMutableDictionary *baseParams = [[[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams] mutableCopy];
    
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

@end
