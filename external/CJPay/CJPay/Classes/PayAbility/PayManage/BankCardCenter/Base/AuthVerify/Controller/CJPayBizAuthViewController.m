//
//  CJPayBizAuthViewController.m
//  Pods
//
//  Created by xiuyuanLee on 2020/11/2.
//

#import "CJPayBizAuthViewController.h"
#import "CJPayAuthVerifiedView.h"
#import "CJPayStyleButton.h"
#import "CJPayWebViewUtil.h"
#import "CJPayMemCreateBizOrderResponse.h"
#import "CJPayMemAgreementModel.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPaySDKMacro.h"
#import "CJPayAlertUtil.h"
#import "CJPayProtocolViewManager.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayUserInfo.h"
#import "CJPayUnionPaySignInfo.h"
#import "CJPayLoadingManager.h"
#import "CJPayBindCardManager.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayCommonBindCardUtil.h"
#import "CJPayProtocolPopUpViewController.h"

@implementation CJPayBizAuthVerifyModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"userInfo" : CJPayBindCardShareDataKeyUserInfo,
        @"memCreatOrderResponse" : CJPayBindCardShareDataKeyMemCreatOrderResponse,
        @"quickBindCardModel" : CJPayBindCardShareDataKeyQuickBindCardModel,
        @"bizAuthInfo" : CJPayBindCardShareDataKeyBizAuthInfoModel,
        @"bizAuthType" : CJPayBindCardShareDataKeyBizAuthType,
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@interface CJPayBizAuthViewController () <CJPayBindCardPageProtocol>

#pragma mark - view
@property (nonatomic, strong) CJPayAuthVerifiedView *authView;

#pragma mark - block
@property (nonatomic, copy, nullable) CJPayBizAuthCompletionBlock authCompletionBlock;
@property (nonatomic, copy) CJPayAuthVerifiedViewAction clickExclamatoryMarkBlock;
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) CJPayCommonProtocolModel *protocolModel;

#pragma mark - data
@property (nonatomic, strong) CJPayBizAuthVerifyModel *viewModel;

@end

@implementation CJPayBizAuthViewController

+ (Class)associatedModelClass {
    return [CJPayBizAuthVerifyModel class];
}

- (void)createAssociatedModelWithParams:(NSDictionary<NSString *,id> *)dict {
    if (dict.count > 0) {
        NSError *error;
        self.viewModel = [[CJPayBizAuthVerifyModel alloc] initWithDictionary:dict error:&error];
        self.viewModel.bizAuthInfo.protocolCheckBox = [dict cj_stringValueForKey:CJPayBindCardPageParamsKeyIsProtocolCheckBox];
        if (error) {
            CJPayLogError(@"error: %@", error);
        }

        if (!self.viewModel.bizAuthInfo && self.viewModel.memCreatOrderResponse.bizAuthInfoModel) {
            self.viewModel.bizAuthInfo = self.viewModel.memCreatOrderResponse.bizAuthInfoModel;
        }

        CJPayLogInfo(@"self.bizAuthModel= %@", self.viewModel);
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.animationType = HalfVCEntranceTypeFromBottom;
        self.navigationBar.hidden = YES;
        self.isFirstAppear = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupUI];
    // 兼容暗黑模式
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    [self p_trackWithEventName:@"wallet_businesstopay_auth_imp" params:@{@"auth_type" : CJString(self.from)}];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.authView cj_clipTopCorner:8];
}

#pragma mark - CJPayBaseLoadingProtocol

- (void)startLoading {
    [self.authView.authButton startLoading];
}

- (void)stopLoading {
    [self.authView.authButton stopLoading];
}

#pragma mark - Private Methods
- (void)p_setupUI {
    [self.containerView addSubview:self.authView];

    //self.containerView.backgroundColor = [UIColor colorWithWhite:1 alpha:0];
    //self.contentView.hidden = YES;
    [self showMask:YES];
    [self p_setupAuthViewUI];

    CJPayMasMaker(self.authView, {
        make.edges.equalTo(self.containerView);
    });

}

- (void)p_setupAuthViewUI {
    CJPayBizAuthInfoModel *bizAuthInfoModel = self.viewModel.bizAuthInfo;
    [self.authView updateWithModel:bizAuthInfoModel.authAgreementContentModel];
    CJPayCommonProtocolModel *commonModel = [CJPayCommonProtocolModel new];
    commonModel.guideDesc = [NSString stringWithFormat:@"%@ ", bizAuthInfoModel.guideMessage ?: CJPayLocalizedStr(@"阅读并同意")];
    commonModel.groupNameDic = bizAuthInfoModel.protocolGroupNames;
    commonModel.protocolFont = [UIFont cj_fontOfSize:12];
    commonModel.supportRiskControl = YES;
    commonModel.protocolCheckBoxStr = bizAuthInfoModel.protocolCheckBox;
    commonModel.agreements = self.viewModel.bizAuthInfo.agreements;
    commonModel.protocolDetailContainerHeight = @([self containerHeight]);
    self.protocolModel = commonModel;
    [self.authView updateWithCommonModel:commonModel];
}

- (CGFloat)containerHeight {
    return CJ_IPhoneX ? 384 : 350;
}

- (void)p_showSingleButtonAlert:(NSString *)content {
    
    [CJPayAlertUtil customSingleAlertWithTitle:CJString(content) content:@"" buttonDesc:CJPayLocalizedStr(@"我知道了") actionBlock:^{} useVC:self];
}

#pragma mark - Getter
- (CJPayAuthVerifiedView *)authView {
    if (!_authView) {
        _authView = [[CJPayAuthVerifiedView alloc] initWithStyle:@{@"btn_color": @"#FE2C55",
                                                                    @"text_color": @"#FFFFFF",
                                                                   @"corner_radius": @"2"}];
                                                   // style
        @CJWeakify(self)
        _authView.closeBlock = ^{
            @CJStrongify(self)
            
            [self p_trackWithEventName:@"wallet_businesstopay_auth_click" params:@{
                @"button_name" : @(0),
                @"auth_type" : CJString(self.from)
            }];
            
            [self closeWithAnimation:YES comletion:^(BOOL isFinish) {
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.noAuthCompletionBlock, CJPayBizAuthCompletionTypeCancel);
            }];
        };
        
        _authView.notMeBlock = ^(NSString * _Nonnull logoutUrl) {
            // 去注销宿主端账户能力降级处理，只展示文案，不跳转 url
            
            @CJStrongify(self)
            
            [self p_trackWithEventName:@"wallet_businesstopay_auth_click" params:@{
                @"button_name" : @(2),
                @"auth_type" : CJString(self.from)
            }];
            
            [self p_showSingleButtonAlert:self.viewModel.bizAuthInfo.disagreeContent];
        };
        
        _authView.logoutBlock = ^{
            @CJStrongify(self)
            [self closeWithAnimation:YES comletion:^(BOOL isFinish) {
//                CJ_CALL_BLOCK(self.authCompletionBlock, CJPayBizAuthCompletionTypeLogout);
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.noAuthCompletionBlock, CJPayBizAuthCompletionTypeCancel);
            }];
        };
        
        _authView.clickExclamatoryMarkBlock = ^{
            @CJStrongify(self)
            [self p_showSingleButtonAlert:self.viewModel.bizAuthInfo.tipsContent];
        };
        
        _authView.authVerifiedBlock = ^{
            @CJStrongify(self)
            [self p_trackWithEventName:@"wallet_businesstopay_auth_click" params:@{
                @"button_name" : @(1),
                @"auth_type" : CJString(self.from)
            }];
            CJ_CALL_BLOCK(self.authVerifiedBlock);
        };
    }
    return _authView;
}

#pragma mark - tracker
- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *baseParams = [[[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams] mutableCopy];

    [baseParams addEntriesFromDictionary:params ?: @{}];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

@end
