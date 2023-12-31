//
//  CJPayChooseDyPayMethodViewController.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/19.
//

#import "CJPayChooseDyPayMethodViewController.h"
#import "CJPayChoosePayMethodGroupView.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayCreditPayUtil.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayInfo.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayChooseDyPayMethodGroupModel.h"
#import "CJPayToast.h"
#import "CJPayUIMacro.h"

@interface CJPayChooseDyPayMethodViewController ()

@property (nonatomic, weak) CJPayChooseDyPayMethodManager *manager;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentView;
@property (nonatomic, strong) CJPayChoosePayMethodGroupView *paymentToolGroupView; // ”支付工具“groupView
@property (nonatomic, strong) CJPayChoosePayMethodGroupView *financeChannelGroupView;// ”资金渠道“groupView

@property (nonatomic, strong) NSArray<CJPayChooseDyPayMethodGroupModel *> *payMethodsGroupModel; // 所有支付方式数据（删掉model）

@end

@implementation CJPayChooseDyPayMethodViewController

- (instancetype)initWithManager:(CJPayChooseDyPayMethodManager *)manager {
    self = [super init];
    if (self) {
        _manager = manager;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    @CJWeakify(self)
    // 选卡页加载时从manager处获取支付方式数据
    [self.manager getPayMethodListSlient:NO
                                   completion:^(NSArray<CJPayChooseDyPayMethodGroupModel *> * _Nonnull payMethodList) {
        @CJStrongify(self)
        if (!Check_ValidArray(payMethodList)) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [super back];
            });
            return;
        }
        self.payMethodsGroupModel = payMethodList;
        [self p_setupUI];
        [self p_trackerViewDidLoad];
    }];
    NSString *naviBarTitle = CJPayLocalizedStr(@"选择付款方式");
    if (self.manager.isCombinePay) {
        naviBarTitle = self.manager.curSelectConfig.combineType == BDPayChannelTypeIncomePay ? CJPayLocalizedStr(@"选择与业务收入组合的付款方式") : CJPayLocalizedStr(@"选择与零钱组合的付款方式");
    }
    self.navigationBar.title = naviBarTitle;
}

- (void)back {
    [self p_trackerWithEventName:@"wallet_cashier_choose_method_close" params:@{}];
    [super back];
}

- (void)p_setupUI {
    self.containerView.backgroundColor = [UIColor cj_f8f8f8ff];
    self.contentView.backgroundColor = [UIColor cj_f8f8f8ff];
    
    [self.contentView addSubview:self.scrollView];
    [self.scrollView addSubview:self.scrollContentView];
    CJPayMasMaker(self.scrollView, {
        make.edges.equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.scrollContentView, {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.view);
    });
    
    NSUInteger methodGroupCount = self.payMethodsGroupModel.count;
    __block UIView *previousGroupView = nil;
    @CJWeakify(self)
    // 依次布局”支付方式“、”资金渠道“groupView到页面
    [self.payMethodsGroupModel enumerateObjectsUsingBlock:^(CJPayChooseDyPayMethodGroupModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        
        CJPayChoosePayMethodGroupView *methodGroupView = [[CJPayChoosePayMethodGroupView alloc] initWithPayMethodViewModel:obj];
        methodGroupView.didSelectedBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull selectConfig, UIView  * _Nullable loadingView) {
            @CJStrongify(self)
            [self didSelectPayMethod:selectConfig loadingView:loadingView];
        };
        [self.scrollContentView addSubview:methodGroupView];
        CJPayMasMaker(methodGroupView, {
            if (previousGroupView) {
                make.top.equalTo(previousGroupView.mas_bottom).offset(8);
            } else {
                make.top.equalTo(methodGroupView.superview).offset(5);
            }
            make.left.equalTo(self.scrollContentView).offset(12);
            make.right.equalTo(self.scrollContentView).offset(-12);
            if (idx == methodGroupCount - 1) {
                make.bottom.equalTo(self.scrollContentView).offset(-20);
            }
        });
        methodGroupView.layer.cornerRadius = 8;
        methodGroupView.clipsToBounds = YES;

        previousGroupView = methodGroupView;
        if (obj.methodGroupType == CJPayPayMethodTypePaymentTool) {
            self.paymentToolGroupView = methodGroupView;
        } else if (obj.methodGroupType == CJPayPayMethodTypeFinanceChannel) {
            self.financeChannelGroupView = methodGroupView;
        }
    }];
    
}

// 选中某个支付方式
- (void)didSelectPayMethod:(CJPayDefaultChannelShowConfig *)showConfig loadingView:loadingView {
    [self p_trackerWithEventName:@"wallet_cashier_choose_method_click"
                          params:@{@"activity_info": [self p_buildChannelActivityInfo:showConfig] ?: @[]                                 }];
    
    if (showConfig.type == BDPayChannelTypeCreditPay) {
        @CJWeakify(self)
        // 若选中月付，需额外进行激活逻辑
        [self p_activateCreditAndPay:showConfig completion:^(BOOL enableCreditPay) {
            if (enableCreditPay) {
                // 可以使用月付，则回调选中月付
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.didSelectedBlock, showConfig, loadingView);
                [self refreshPayMethodSelectStatus:showConfig];
            }
        }];
        return;
    }
    
    if ([self p_isNeedRefreshPayMethodSelectedWithShowConfig:showConfig]) {
        [self refreshPayMethodSelectStatus:showConfig];
    }
    CJ_CALL_BLOCK(self.didSelectedBlock, showConfig, loadingView);
}

- (BOOL)p_isNeedRefreshPayMethodSelectedWithShowConfig:(CJPayDefaultChannelShowConfig *)config {
    if ([config isNeedReSigning]) {
        return NO;
    }
    if (config.type == BDPayChannelTypeAddBankCard) {
        return NO;
    }
    return YES;
}

// 选中除绑卡外的可用支付方式，则刷新页面上所有支付方式的选中态
- (void)refreshPayMethodSelectStatus:(CJPayDefaultChannelShowConfig *)config {
    if (config.canUse) {
        [self.paymentToolGroupView updatePayMethodViewBySelectConfig:config];
        [self.financeChannelGroupView updatePayMethodViewBySelectConfig:config];
    }
}

// 激活月付
- (void)p_activateCreditAndPay:(CJPayDefaultChannelShowConfig *)config completion:(nullable void(^)(BOOL))completionBlock {
    if (config.type != BDPayChannelTypeCreditPay) {
        return;
    }
    if (config.payTypeData.isCreditActivate) {
        CJ_CALL_BLOCK(completionBlock, YES);
        return;
    }
    
    BOOL activateStatus = NO;
    NSString *creditActivateUrl = @"";
    if (self.manager.response.payInfo) {
        activateStatus = self.manager.response.payInfo.isCreditActivate;
        creditActivateUrl = CJString(self.manager.response.payInfo.creditActivateUrl);
    } else {
        activateStatus = config.isCreditActivate || config.payTypeData.isCreditActivate;
        creditActivateUrl = CJString(config.creditActivateUrl);
    }
    
    @CJWeakify(self)
    [CJPayCreditPayUtil activateCreditPayWithStatus:activateStatus activateUrl:creditActivateUrl completion:^(CJPayCreditPayServiceResultType type, NSString * _Nonnull msg, NSInteger creditLimit, CJPayCreditPayActivationLoadingStyle style, NSString * _Nonnull token) {
        @CJStrongify(self)
        switch (type) {
            case CJPayCreditPayServiceResultTypeActivated:
                CJ_CALL_BLOCK(completionBlock, YES);
                break;
            case CJPayCreditPayServiceResultTypeNoUrl:
            case CJPayCreditPayServiceResultTypeNoNetwork:
            case CJPayCreditPayServiceResultTypeFail:
                [CJToast toastText:CJString(msg) inWindow:self.cj_window];
                CJ_CALL_BLOCK(completionBlock, NO);
                break;
            case CJPayCreditPayServiceResultTypeSuccess:
                // 月付激活成功，则记录激活状态
                config.payTypeData.isCreditActivate = YES;
                if (creditLimit != -1) { // 需要判断额度
                    [self p_creditAmountComparisonWithAmount:creditLimit successDesc:msg completion:^(BOOL canUseCredit) {
                        if (!canUseCredit) {
                            // 激活成功但额度不足
                            config.canUse = NO;
                            config.subTitle = CJPayLocalizedStr(@"额度不足");
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                @CJStrongify(self)
                                [self back];
                            });
                        }
                        CJ_CALL_BLOCK(completionBlock, canUseCredit);
                    }];
                } else {
                    [CJToast toastText:CJString(msg) inWindow:[UIViewController cj_topViewController].cj_window];
                    CJ_CALL_BLOCK(completionBlock, YES);
                }
                break;
            case CJPayCreditPayServiceResultTypeCancel:
                [CJToast toastText:CJString(msg) inWindow:[UIViewController cj_topViewController].cj_window];
                CJ_CALL_BLOCK(completionBlock, NO);
                break;
            case CJPayCreditPayServiceResultTypeTimeOut:
                [CJToast toastText:CJPayLocalizedStr(@"抖音月付激活超时") inWindow:[UIViewController cj_topViewController].cj_window];
                CJ_CALL_BLOCK(completionBlock, NO);
            default:
                CJ_CALL_BLOCK(completionBlock, NO);
                break;
        }
    }];
}

// 判断月付额度
- (void)p_creditAmountComparisonWithAmount:(NSInteger)amount successDesc:(NSString *)desc completion:(nullable void(^)(BOOL))completionBlock {
    CJPayBDCreateOrderResponse *response = self.manager.response;
    
    // 实际付款金额大于信用额度，则额度不足
    if (response.payInfo.realTradeAmountRaw > amount) {
        [CJToast toastText:CJPayLocalizedStr(@"抖音月付激活成功，额度不足") inWindow:self.cj_window];
        CJ_CALL_BLOCK(completionBlock, NO);
    } else {
        [CJToast toastText:CJString(desc) inWindow:[UIViewController cj_topViewController].cj_window];
        CJ_CALL_BLOCK(completionBlock, YES);
    }
}

// 选卡页高度支持外部定制
- (CGFloat)containerHeight {
    if (self.height <= CGFLOAT_MIN) {
        return CJ_HALF_SCREEN_HEIGHT_LOW;
    } else {
        return self.height;
    }
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    [self.manager trackerWithEventName:eventName params:params];
}


- (void)p_trackerViewDidLoad {
    __block NSMutableArray<CJPayDefaultChannelShowConfig *> *payChannels = [NSMutableArray new];
    [self.payMethodsGroupModel enumerateObjectsUsingBlock:^(CJPayChooseDyPayMethodGroupModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (Check_ValidArray(obj.methodList)) {
            [payChannels addObjectsFromArray:obj.methodList];
        }
    }];
    
    __block NSArray *activityInfo = [NSArray new];
    NSMutableArray *methodLists = [NSMutableArray new];
    [payChannels enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isSelected) {
            activityInfo = [self p_buildChannelActivityInfo:obj];
        }
        if ([obj toMethodInfoTracker].count > 0) {
            [methodLists btd_addObject:[obj toMethodInfoTracker]];
        }
    }];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"activity_info" : activityInfo ?: @[],
        @"all_method_list": methodLists ?: @[]
    }];
    
    [self p_trackerWithEventName:@"wallet_cashier_method_page_imp" params:params];
}

- (NSArray *)p_buildChannelActivityInfo:(CJPayDefaultChannelShowConfig *)config {
    if (config.type == BDPayChannelTypeCreditPay) {
        return [config toActivityInfoTrackerForCreditPay];
    }
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *infoDict = [config toActivityInfoTracker];
    if (infoDict.count > 0) {
        [activityInfos btd_addObject:infoDict];
    }
    return [activityInfos copy];
}

#pragma mark - loading delegate
- (void)startLoading {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
}

- (void)stopLoading {
    [[CJPayLoadingManager defaultService] stopLoading];
}

#pragma mark - getter
- (NSArray<CJPayChooseDyPayMethodGroupModel *> *)payMethodsGroupModel {
    if (!_payMethodsGroupModel) {
        _payMethodsGroupModel = [NSArray new];
    }
    return _payMethodsGroupModel;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.clipsToBounds = YES;
        _scrollView.bounces = NO;
        if (@available(iOS 11.0, *)) {
            [_scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    }
    return _scrollView;
}

- (UIView *)scrollContentView {
    if (!_scrollContentView) {
        _scrollContentView = [[UIView alloc] init];
        _scrollContentView.clipsToBounds = NO;
    }
    return _scrollContentView;
}

- (CJPayChoosePayMethodGroupView *)paymentToolGroupView {
    if (!_paymentToolGroupView) {
        _paymentToolGroupView = [CJPayChoosePayMethodGroupView new];
    }
    return _paymentToolGroupView;
}

- (CJPayChoosePayMethodGroupView *)financeChannelGroupView {
    if (!_financeChannelGroupView) {
        _financeChannelGroupView = [CJPayChoosePayMethodGroupView new];
    }
    return _financeChannelGroupView;
}
@end
