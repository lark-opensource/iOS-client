//
//  CJPayBindCardBaseViewController.m
//  Pods
//
//  Created by renqiang on 2021/9/10.
//

#import "CJPayBindCardBaseViewController.h"
#import "CJPayBindCardFirstStepInputProtocol.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPayBizAuthViewController.h"
#import "CJPayUserInfo.h"
#import "CJPayBindCardVCModel.h"
#import "CJPayTimer.h"
#import "CJPayBindCardFirstStepBaseInputView.h"
#import "CJPayCenterTextFieldContainer.h"
#import "CJPayAlertUtil.h"
#import "CJPayBankCardAddRequest.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayMemBankSupportListResponse.h"
#import "CJPayQuickBindCardManager.h"
#import "CJPayCommonBindCardUtil.h"
#import "CJPayDyTextPopUpViewController.h"
#import "CJPayKVContext.h"
#import "CJPaySDKDefine.h"
#import "CJPayBindCardRetainUtil.h"

@implementation BDPayBindCardBaseViewModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"isCertification" : CJPayBindCardShareDataKeyIsCertification,
        @"isBizAuthVCShown" : CJPayBindCardShareDataKeyIsBizAuthVCShown,
        @"specialMerchantId" : CJPayBindCardShareDataKeySpecialMerchantId,
        @"signOrderNo" : CJPayBindCardShareDataKeySignOrderNo,
        @"bankMobileNoMask" : CJPayBindCardShareDataKeyBankMobileNoMask,
        @"voucherBankStr" : CJPayBindCardShareDataKeyVoucherBankStr,
        @"voucherMsgStr" : CJPayBindCardShareDataKeyVoucherMsgStr,
        @"firstStepMainTitle" : CJPayBindCardShareDataKeyFirstStepMainTitle,
        @"userInfo" : CJPayBindCardShareDataKeyUserInfo,
        @"cardBindSource" : CJPayBindCardShareDataKeyCardBindSource,
        @"bizAuthInfo" : CJPayBindCardShareDataKeyBizAuthInfoModel,
        @"skipPwd" : CJPayBindCardShareDataKeySkipPwd,
        @"startTimestamp" : CJPayBindCardShareDataKeyStartTimestamp,
        @"firstStepVCTimestamp" : CJPayBindCardShareDataKeyFirstStepVCTimestamp,
        @"isQuickBindCardListHidden" : CJPayBindCardPageParamsKeyIsQuickBindCardListHidden,
        @"isFromQuickBindCard" : CJPayBindCardPageParamsKeyIsFromQuickBindCard,
        @"isShowKeyboard" : CJPayBindCardPageParamsKeyIsShowKeyboard,
        @"selectedBankIcon" : CJPayBindCardPageParamsKeySelectedBankIcon,
        @"selectedBankName" : CJPayBindCardPageParamsKeySelectedBankName,
        @"selectedBankType" : CJPayBindCardPageParamsKeySelectedBankType,
        @"selectedCardTypeVoucher" : CJPayBindCardPageParamsKeySelectedCardTypeVoucher,
        @"bizAuthType" : CJPayBindCardShareDataKeyBizAuthType,
        @"bankListResponse" : CJPayBindCardShareDataKeyBankListResponse,
        @"isEcommerceAddBankCardAndPay" : CJPayBindCardShareDataKeyIsEcommerceAddBankCardAndPay,
        @"isSyncUnionCard" : CJPayBindCardShareDataKeyIsSyncUnionCard,
        @"pageFromCashierDesk" : CJPayBindCardPageParamsKeyPageFromCashierDesk,
        @"orderInfo" : CJPayBindCardShareDataKeyOrderInfo,
        @"iconURL" : CJPayBindCardShareDataKeyIconURL,
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@interface CJPayBindCardBaseViewController () <CJPayTimerProtocol, CJPayBindCardPageProtocol>

#pragma mark - flag
@property (nonatomic, assign) BOOL isFirstAppear;

#pragma mark - model
@property (nonatomic, strong) BDPayBindCardBaseViewModel *viewModel;
@property (nonatomic, strong) CJPayBindCardVCModel *bindCardVCModel;

#pragma mark - view
@property (nonatomic, strong, readwrite) CJPayBindCardFirstStepBaseInputView *frontBindCardView;

@end

@implementation CJPayBindCardBaseViewController

+ (Class)associatedModelClass {
    return [BDPayBindCardBaseViewModel class];
}

- (void)createAssociatedModelWithParams:(NSDictionary<NSString *,id> *)dict {
    if (dict.count > 0) {
        self.viewModel = [[BDPayBindCardBaseViewModel alloc] initWithDictionary:dict error:nil];
    }
}

- (instancetype)init {
    if (self = [super init]) {
        self.isFirstAppear = YES;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForground) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)appDidEnterForground {
    if ([[UIViewController cj_foundTopViewControllerFrom:self] isKindOfClass:[self class]]) {
        [[CJPayQuickBindCardManager shared] queryOneKeySignStateAppDidEnterForground];
    }
}

- (void)changeOtherBank {
    //子类覆写
}

- (void)back {
    @CJWeakify(self)
    void(^cancelBlock)(void) = ^() {
        @CJStrongify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            @CJStrongify(self)
            [self p_closeBindProcess];
        });
    };
    
    CJPayBindCardRetainInfo *retainInfo = self.bindCardVCModel.supportCardListResponse.retainInfo;
    retainInfo.cancelBlock = [cancelBlock copy];
    @CJWeakify(retainInfo)
    void(^continueBlock)(void) = ^() {
        @CJStrongify(self)
        @CJStrongify(retainInfo)
        if (self.viewModel.isQuickBindCardListHidden) {
            [self changeOtherBank];
        } else {
            self.bindCardVCModel.latestVCStyle = self.bindCardVCModel.vcStyle;
            self.bindCardVCModel.vcStyle = CJPayBindCardStyleUnfold;
            [self.bindCardVCModel reloadQuickBindCardList];
            self.scrollView.contentOffset = CGPointZero;
        }
        return;
        
    };
    retainInfo.continueBlock = [continueBlock copy];
    retainInfo.appId = self.viewModel.appId;
    retainInfo.merchantId = self.viewModel.merchantId;
    retainInfo.trackDelegate = self;
    
    if ([self p_needRetain]) {
        //记录已经展示过挽留弹框
        [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:@{
            CJPayBindCardShareDataKeyIsHadShowRetain: @(YES)
        } completion:nil];
        self.bindCardVCModel.supportCardListResponse.retainInfo.isHadShowRetain = YES;
        [CJPayBindCardRetainUtil showRetainWithModel:retainInfo fromVC:self];
        
        // 处理弹窗时键盘不收回问题
        if ([self.frontBindCardView.cardNumContainer.textField isFirstResponder]) {
            [self.frontBindCardView.cardNumContainer.textField resignFirstResponder];
        }
    } else {
        [self p_closeBindProcess];
    }
    
    [self p_trackWithEventName:@"wallet_page_back_click"
                        params:@{@"page_name": @"wallet_addbcard_first_page"}];
}

- (void)updateCertificationStatus {
        /* 子类复写，用于更新授权状态
         问题：绑卡首页vc及各subView、subVCModel都和commonModel解耦后，一些commonModel的更新可能同步不到子类的model
         例：绑卡首页firstStepVC懒加载CJPayBindCardNumberViewModel后，如果在首页弹出的bizAuthVC点击同意授权，会把commonModel和firstStepVC.viewModel的isCertification置为YES
            但是CJPayBindCardNumberViewModel.dataModel.isCertification只会在其初始化时加载一次，因此firstStepVC或commonModel的变化无法同步至CJPayBindCardNumberViewModel
         解决方法（暂时）：更新授权状态时手动去更新一下subView\subModel的对应值
         */
}

#pragma mark - private method
// 弹窗频控
- (BOOL)p_needRetain {
    CJPayBindCardRetainInfo *retainInfo = self.bindCardVCModel.supportCardListResponse.retainInfo;
    if (retainInfo) {
        if (self.navigationController.viewControllers.count > 1) {
            return NO;
        }
        return !([retainInfo.controlFrequencyStr isEqualToString:@"1"] || retainInfo.isHadShowRetain);
    }
    return NO;
}

- (void)showBizAuthViewController {
    
    if (self.viewModel.bizAuthType == CJPayBizAuthTypeSilent && self.viewModel.bizAuthInfo.isNeedAuthorize) {
        // 静默实名授权
        [self p_authVerifyCompletion];
        return;
    }
    
    CJPayBizAuthInfoModel *bizAuthInfoModel = self.viewModel.bizAuthInfo;
    BOOL isBizAuth = bizAuthInfoModel.isNeedAuthorize && !self.viewModel.isBizAuthVCShown;
    
    if (isBizAuth) {
        self.viewModel.isBizAuthVCShown = YES; // 标记已经展示过业务方授权页
        [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:@{CJPayBindCardShareDataKeyIsBizAuthVCShown : @(self.viewModel.isBizAuthVCShown)} completion:^(NSArray<NSString *> * _Nonnull modifyedKeysArray) {
            
        }];
        
        @CJWeakify(self)
        UIViewController *halfBizAuthVC = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeHalfBizAuth params:nil completion:nil];
        CJPayBizAuthViewController *bizAuthVC;
        if ([halfBizAuthVC isKindOfClass:CJPayBizAuthViewController.class]) {
            bizAuthVC = (CJPayBizAuthViewController *)halfBizAuthVC;
        }
        if (bizAuthVC == nil) {
            CJPayLogAssert(NO, @"创建授权弹框页面失败.");
            return;
        }
        
        @CJWeakify(bizAuthVC)
        bizAuthVC.noAuthCompletionBlock = ^(CJPayBizAuthCompletionType type) {
            @CJStrongify(self)
            switch (type) {
                case CJPayBizAuthCompletionTypeCancel:
                case CJPayBizAuthCompletionTypeLogout:
                default:
                    self.viewModel.isCertification = NO;
                    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:@{CJPayBindCardShareDataKeyIsCertification : @(self.viewModel.isCertification)} completion:^(NSArray<NSString *> * _Nonnull modifyedKeysArray) {
                        
                    }];
                    [self updateCertificationStatus];
                    break;
            }
        };
        bizAuthVC.authVerifiedBlock = ^{
            @CJStrongify(bizAuthVC)
            [bizAuthVC closeWithAnimation:YES comletion:^(BOOL isFinish) {
                @CJStrongify(self)
                [self p_authVerifyCompletion];
            }];
            return;
        };
        
        [self.navigationController pushViewController:bizAuthVC animated:YES];
    }
}

- (void)p_authVerifyCompletion {
    self.viewModel.userInfo.mName = self.viewModel.bizAuthInfo.idNameMask;
    self.viewModel.isCertification = YES;
    
    NSDictionary *dict = @{
        CJPayBindCardShareDataKeyIsCertification : @(self.viewModel.isCertification),
        CJPayBindCardShareDataKeyUserInfo : [self.viewModel.userInfo toDictionary] ?: @{}
    };
    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:dict completion:nil];
    
    [self updateCertificationStatus];
}

- (void)p_closeBindProcess {
    if (self.viewModel.isFromQuickBindCard && !self.viewModel.pageFromCashierDesk) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    if (![[CJPayBindCardManager sharedInstance] cancelBindCard]) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
}

- (NSDictionary *)p_genDictionaryByKeys:(NSArray <NSString *>*)keys fromViewModel:(BDPayBindCardBaseViewModel *)viewModel {
    if (keys == nil || keys.count == 0 || viewModel == nil) {
        return nil;
    }
    
    NSDictionary *allSharedDataDict = [viewModel toDictionary];
    NSMutableDictionary *returnDict = [NSMutableDictionary new];
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([allSharedDataDict cj_objectForKey:key]) {
            [returnDict cj_setObject:[allSharedDataDict cj_objectForKey:key] forKey:key];
        }
    }];
    
    return [returnDict copy];
}

#pragma mark - Tracker

- (void)p_trackWithEventName:(NSString *)eventName
                    params:(nullable NSDictionary *)params {

    NSDictionary *baseDic = [[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams];
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc] initWithDictionary:baseDic];
    if (params) {
        [paramsDic addEntriesFromDictionary:params];
    }
    
    paramsDic[@"show_onestep"] = ([self.bindCardVCModel isShowOneStep] && !self.viewModel.isQuickBindCardListHidden) ? @(1) : @(0);
    
    [CJTracker event:eventName params:paramsDic];
}

#pragma mark - CJPayTrackerProtocol
- (void)event:(NSString *)event params:(NSDictionary *)params {
    [self p_trackWithEventName:event params:params];
}

#pragma mark - getter & setter
- (CJPayBindCardVCModel *)bindCardVCModel {
    if (!_bindCardVCModel) {
        NSArray *needParams = [CJPayBindCardVCModel dataModelKey];
        NSDictionary *paramsDict = [self p_genDictionaryByKeys:needParams fromViewModel:self.viewModel];
        _bindCardVCModel = [[CJPayBindCardVCModel alloc] initWithBindCardDictonary:paramsDict];
        
        _bindCardVCModel.vcStyle = CJPayBindCardStyleFold;
        _bindCardVCModel.trackerDelegate = self;
        _bindCardVCModel.viewController = self;
        _bindCardVCModel.isSyncUnionCard = self.viewModel.isSyncUnionCard;
    }
    return _bindCardVCModel;
}

- (CJPayTimer *)smsTimer {
    if (!_smsTimer) {
        _smsTimer = [CJPayTimer new];
        _smsTimer.delegate = self;
    }
    return _smsTimer;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.clipsToBounds = YES;
        _scrollView.bounces = YES;
        if (@available(iOS 11.0, *)) {
            [_scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        } else {
            // Fallback on earlier versions
        }
    }
    return _scrollView;
}

#pragma mark - CJPayTimerProtocol
- (void)currentCountChangeTo:(int)value {
    if (value <= 0) {
        [self.smsTimer reset];
    }
}

@end
