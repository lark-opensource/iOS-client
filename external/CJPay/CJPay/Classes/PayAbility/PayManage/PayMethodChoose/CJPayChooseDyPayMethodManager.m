//
//  CJPayChooseDyPayMethodManager.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/19.
//

#import "CJPayChooseDyPayMethodManager.h"
#import "CJPaySDKMacro.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayQueryPayTypeRequest.h"
#import "CJPayQueryPayTypeResponse.h"
#import "CJPayChooseDyPayMethodViewController.h"
#import "CJPayDySignPayChooseCardViewController.h"
#import "CJPayChooseDyPayMethodGroupModel.h"
#import "CJPayKVContext.h"
#import "CJPayUIMacro.h"
#import "CJPayFrontCashierResultModel.h"

#import "CJPayIntegratedChannelModel.h"
#import "CJPaySubPayTypeGroupInfo.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayCreditPayMethodModel.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayToast.h"

@interface CJPayChooseDyPayMethodManager ()
#pragma mark - data
@property (nonatomic, assign) BOOL hasFetchPayMethodList; // 是否已获取到支付方式数据
@property (nonatomic, strong) NSArray<NSString *> *payMethodSortList; // 支付方式组排序（即支付工具、资金渠道两组的顺序）

@property (nonatomic, strong) CJPayChooseDyPayMethodGroupModel *paymentToolListModel; // 支付工具groupViewModel
@property (nonatomic, strong) CJPayChooseDyPayMethodGroupModel *financeChannelListModel; // 资金渠道groupViewModel

@property (nonatomic, copy) NSArray<CJPayDefaultChannelShowConfig*> *paymentToolChannelConfigs; // 支付工具列表
@property (nonatomic, copy) NSArray<CJPayDefaultChannelShowConfig*> *financeChannelConfigs; // 资金渠道列表
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *creditChannelConfig; // 资金渠道（月付）信息
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *balanceChannelConfig; // 余额支付方式信息
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *incomeChannelConfig; // 业务收入支付方式信息

@property (nonatomic, strong) CJPayQueryPayTypeResponse *payTypeResponse;

#pragma mark - viewController
@property (nonatomic, strong) CJPayChooseDyPayMethodViewController *choosePayMethodVC;

@property (nonatomic, strong) CJPayDySignPayChooseCardViewController *signPayChoosePayMethodVC;

@end


@implementation CJPayChooseDyPayMethodManager

- (instancetype)initWithOrderResponse:(CJPayBDCreateOrderResponse *)response {
    self = [super init];
    if (self) {
        _response = response;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_bindcardSuccess) name:CJPayBindCardSuccessNotification object:nil];
        [self createPayTypeResponse];
    }
    return self;
}

- (void)createPayTypeResponse {
    if (self.response && self.response.payTypeInfo.subPayTypeGroupInfoList) {
        self.payTypeResponse = [[CJPayQueryPayTypeResponse alloc] init];
        self.payTypeResponse.tradeInfo = [[CJPayIntegratedChannelModel alloc] init];
        self.payTypeResponse.tradeInfo.subPayTypeGroupInfoList = self.response.payTypeInfo.subPayTypeGroupInfoList;
        self.payTypeResponse.tradeInfo.subPayTypeSumInfo = self.response.payTypeInfo.subPayTypeSumInfo;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setSelectedBalancePayMethod {
    [self.paymentToolChannelConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.isSelected = obj.type == BDPayChannelTypeBalance;
    }];
}

- (void)setSelectedPayMethod:(CJPayDefaultChannelShowConfig *)config {
    [self.paymentToolChannelConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.isSelected = [obj isEqual:config];
    }];
}

- (void)refreshPayMethodSelectStatus:(CJPayDefaultChannelShowConfig *)config {
    [self.choosePayMethodVC refreshPayMethodSelectStatus:config];
}

// 前往支付中选卡页
- (void)gotoChooseDyPayMethod {
    [self gotoChooseDyPayMethodFromCombinedPay:NO];
}
// 前往O项目唤端 选卡页
- (void)gotoSignPayChooseDyPayMethod {
    self.signPayChoosePayMethodVC = [self p_createSignPayChoosePayMethodVC];
    [self p_tryPushSignPayChoosePayMethodVC:self.signPayChoosePayMethodVC];
}

- (void)closeSignPayChooseDyPayMethod {
    if (!self.signPayChoosePayMethodVC) {
        return;
    }
    @CJWeakify(self)
    // 这里切卡页退出的动画和lynx的动画冲突了，目前暂时无治本的解决办法，待标准化上线后跟着一起修了
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self)
        [self.signPayChoosePayMethodVC closeWithAnimation:YES comletion:nil];
    });
}

- (void)gotoChooseDyPayMethodFromCombinedPay:(BOOL)isCombinedPay {
    self.isCombinePay = isCombinedPay;
    NSMutableArray *channelConfigs = [NSMutableArray new];
    [channelConfigs addObjectsFromArray:self.paymentToolChannelConfigs];
    [channelConfigs addObjectsFromArray:self.financeChannelConfigs];
    [self p_buildSinglePayMethodModels:channelConfigs];
    self.choosePayMethodVC = [self p_createChoosePayMethodVC];
    [self p_tryPushChoosePayMethodVC:self.choosePayMethodVC];
}

// 获取支付方式列表数据
- (void)getPayMethodListSlient:(BOOL)needSlient completion:(nullable void (^)(NSArray<CJPayChooseDyPayMethodGroupModel *> * _Nonnull))completionBlock {
    
    __block NSArray<CJPayChooseDyPayMethodGroupModel *> *payMethodList = [NSArray new];
    if (self.hasFetchPayMethodList && !self.needUpdatePayMethodList) {
        payMethodList = [self p_getPayMethodList];
        CJ_CALL_BLOCK(completionBlock, payMethodList);
        return;
    }
    
    if (self.payTypeResponse) {
        // 处理支付方式数据
        if (self.needUpdatePayMethodList) {
            [self createPayTypeResponse];
        }
        
        [self p_handlePayMethodListResponse:self.payTypeResponse.tradeInfo];
        self.needUpdatePayMethodList = NO;
        // 将支付方式数据格式转换为NSArray<CJPayChooseDyPayMethodViewModel *>格式
        payMethodList = [self p_getPayMethodList];
        CJ_CALL_BLOCK(completionBlock, payMethodList);
        return;
    }
    
    // 当没有数据 或 需要刷新数据时，重新请求一次queryPayType
    if (!needSlient) {
        [self p_startLoading];
    }
    @CJWeakify(self)
    
    [CJPayQueryPayTypeRequest startWithParams:[self p_cardListParams]
                                       completion:^(NSError * _Nonnull error, CJPayQueryPayTypeResponse * _Nonnull response) {
        @CJStrongify(self)
        if (!needSlient) {
            [self p_stopLoading];
        }
        // 处理支付方式数据
        UIViewController *topVC = [UIViewController cj_topViewController];
        if (![response isSuccess] && !needSlient) {
            NSString *toastMsg = Check_ValidString(response.msg) ? CJString(response.msg) : CJPayNoNetworkMessage;
            [CJToast toastText:toastMsg inWindow:topVC.cj_window];
            return;
        }
        [self p_handlePayMethodListResponse:response.tradeInfo];
        self.needUpdatePayMethodList = ![response isSuccess];
        // 将支付方式数据格式转换为NSArray<CJPayChooseDyPayMethodViewModel *>格式
        payMethodList = [self p_getPayMethodList];
        CJ_CALL_BLOCK(completionBlock, payMethodList);
    }];
}

// 处理queryPayType拿到的支付数据
- (void)p_handlePayMethodListResponse:(CJPayIntegratedChannelModel *)channelModel {
    
    // 获取所有支付方式
    NSArray<CJPayDefaultChannelShowConfig *> *showConfigArray = [channelModel buildConfigsWithIdentify:@""];
    self.hasFetchPayMethodList = Check_ValidArray(showConfigArray);

    // 分别记录“支付工具”、“资金渠道”group的数据
    __block NSMutableArray<NSString *> *payMethodSortArr = [NSMutableArray new];
    [channelModel.subPayTypeGroupInfoList enumerateObjectsUsingBlock:^(CJPaySubPayTypeGroupInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        CJPayChooseDyPayMethodGroupModel *payMethodModel = [CJPayChooseDyPayMethodGroupModel new];
        payMethodModel.addBankCardFoldDesc = obj.addBankCardFoldDesc;
        payMethodModel.methodGroupType = [self p_payMethodTypeWithGroupTypeStr:obj.groupType];
        payMethodModel.methodGroupTitle = obj.groupTitle;
        payMethodModel.subPayTypeIndexList = obj.subPayTypeIndexList;
        [payMethodSortArr btd_addObject:obj.groupType];
        
        if (payMethodModel.methodGroupType == CJPayPayMethodTypePaymentTool) {
            payMethodModel.displayNewBankCardCount = obj.displayNewBankCardCount + 1; //后端下发的展示数限制不包括普通的“添加银行卡”，因此绑卡总限制展示数需加1
            self.paymentToolListModel = payMethodModel;

        } else if (payMethodModel.methodGroupType == CJPayPayMethodTypeFinanceChannel) {
            payMethodModel.creditPayDesc = obj.creditPayDesc;
            self.financeChannelListModel = payMethodModel;
        }
    }];
    
    [self p_buildSinglePayMethodModels:showConfigArray];
    
    self.payMethodSortList = [payMethodSortArr copy];
    [self p_modifyMethodGroupSortList:self.curSelectConfig];
    [self p_modifyFinaceChannelSortList:self.curSelectConfig];
}

// 处理一遍支付方式（不可用的支付方式手动置灰置底）
- (void)p_buildSinglePayMethodModels:(nullable NSArray<CJPayDefaultChannelShowConfig *> *)payInfoModels {
    
    NSMutableArray<CJPayDefaultChannelShowConfig *> *paymentToolsArray = [NSMutableArray new];
    NSMutableArray<CJPayDefaultChannelShowConfig *> *financeChannelArray = [NSMutableArray new];
    __block NSMutableArray<CJPayDefaultChannelShowConfig *> *enableMethods = [NSMutableArray new];
    __block NSMutableArray<CJPayDefaultChannelShowConfig *> *disableMethods = [NSMutableArray new];

    /*
     排序逻辑：可用支付方式（当前选中支付方式 > 可用零钱 > 业务收入 > 已绑银行卡使用时间倒序）> 添加银行卡（添加银行卡>添加xx银行卡）> 不可用支付方式
     */
    [payInfoModels enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

        if (obj.isSelected) {
            self.curSelectConfig = obj;
        }
        
        if ([[self.payMethodDisabledReasonMap allKeys] containsObject:obj.cjIdentify] || obj.enable == NO) {
            // 不可用支付方式
            obj.canUse = NO;
            obj.isSelected = NO;
            if (!Check_ValidString(obj.reason)) {
                if ([[self.payMethodDisabledReasonMap allKeys] containsObject:obj.cjIdentify]) {
                    NSString *disableReasonStr = [self.payMethodDisabledReasonMap cj_stringValueForKey:obj.cjIdentify];
                    obj.reason = disableReasonStr;
                    obj.subTitle = disableReasonStr;
                } else {
                    obj.reason = CJPayLocalizedStr(@"余额不足");
                    obj.subTitle = CJPayLocalizedStr(@"余额不足");
                }
            }
            [disableMethods btd_addObject:obj];
        } else {
            // 当前已绑卡/零钱可用
            if (obj.type == BDPayChannelTypeBalance) {
                self.balanceChannelConfig = obj; //零钱单独记录，排序时有特殊逻辑
            }
            if (obj.type == BDPayChannelTypeIncomePay) {
                self.incomeChannelConfig = obj;
            }
            [enableMethods btd_addObject:obj];
        }
    }];
    BOOL isPaymentCanUse = [self hasAvailableOldCards:payInfoModels];
    if (self.incomeChannelConfig && [enableMethods containsObject:self.incomeChannelConfig]) {
        NSUInteger insertIndex = ([self.incomeChannelConfig isEqual:self.curSelectConfig] || !isPaymentCanUse) ? 0 : 1;
        [enableMethods btd_removeObject:self.incomeChannelConfig];
        [enableMethods btd_insertObject:self.incomeChannelConfig atIndex:insertIndex];
    }
    if (self.balanceChannelConfig && [enableMethods containsObject:self.balanceChannelConfig]) {
        NSUInteger insertIndex = ([self.balanceChannelConfig isEqual:self.curSelectConfig] || !isPaymentCanUse) ? 0 : 1;
        [enableMethods btd_removeObject:self.balanceChannelConfig];
        [enableMethods btd_insertObject:self.balanceChannelConfig atIndex:insertIndex];
    }
    
    //可用支付方式分组
    [enableMethods enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self.financeChannelListModel.subPayTypeIndexList containsObject:@(obj.index)]) {
            [financeChannelArray addObject:obj];
        } else {
            [paymentToolsArray addObject:obj];
        }
    }];
    
    //不可用支付方式分组
    [disableMethods enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self.financeChannelListModel.subPayTypeIndexList containsObject:@(obj.index)]) {
            [financeChannelArray addObject:obj];
        } else {
            [paymentToolsArray addObject:obj];
        }
    }];
    
    self.paymentToolChannelConfigs = [paymentToolsArray copy];
    self.financeChannelConfigs = [financeChannelArray copy];
}
// 判断是否有可用老卡，用来给零钱、收入排序
- (BOOL)hasAvailableOldCards:(NSArray<CJPayDefaultChannelShowConfig *> *)paymentToolList {
    __block BOOL isPaymentCanUse = NO;
    [paymentToolList enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.canUse && obj.type == BDPayChannelTypeBankCard) {
            isPaymentCanUse = YES;
            *stop = YES;
        }
    }];
    return isPaymentCanUse;
}

// 组合支付情形且仅更改主支付方式时，需屏蔽资产类型的支付方式（零钱、业务收入）
- (NSArray <CJPayDefaultChannelShowConfig *>*)p_removeBalancePayMethod:(NSArray <CJPayDefaultChannelShowConfig *>*)configList {
    NSMutableArray <CJPayDefaultChannelShowConfig *>*newConfigList = [NSMutableArray new];
    if (configList.count) {
        [newConfigList addObjectsFromArray:configList];
        [newConfigList removeObject:self.balanceChannelConfig];
        [newConfigList removeObject:self.incomeChannelConfig];
    }
    
    return newConfigList;
}

// 获取支付方式
- (NSArray<CJPayChooseDyPayMethodGroupModel *> *)p_getPayMethodList {
    
    if (self.isCombinePay) {
        self.paymentToolListModel.methodList = [self p_removeBalancePayMethod:self.paymentToolChannelConfigs];
    } else {
        self.paymentToolListModel.methodList = self.paymentToolChannelConfigs;
    }
    if (self.financeChannelConfigs.count > 0) {
        self.financeChannelListModel.methodList = self.financeChannelConfigs;
    }
    
    NSMutableArray<CJPayChooseDyPayMethodGroupModel *> *payMethodList = [NSMutableArray new];
    // 按payMethodSortList决定”支付工具“、”资金渠道“的排序
    [self.payMethodSortList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CJPayPayMethodType methodType = [self p_payMethodTypeWithGroupTypeStr:obj];
        switch (methodType) {
            case CJPayPayMethodTypePaymentTool:
                if (Check_ValidArray(self.paymentToolListModel.methodList)) {
                    [payMethodList btd_addObject:self.paymentToolListModel];
                }
                break;
            case CJPayPayMethodTypeFinanceChannel:
                if (Check_ValidArray(self.financeChannelListModel.methodList) && !self.isCombinePay) {
                    [payMethodList btd_addObject:self.financeChannelListModel];
                }
                break;
            default:
                break;
        }
    }];
    return [payMethodList copy];
}

// 选中了某个支付方式
- (void)didSelectPayMethod:(CJPayDefaultChannelShowConfig *)showConfig loadingView:(UIView *)loadingView {
    if (showConfig.type != BDPayChannelTypeAddBankCard && ![showConfig isNeedReSigning]) { //新卡 & 补签约卡不需要参与置顶逻辑
        // 非绑卡时，根据当前选择的支付方式来调整支付方式的排列顺序
        if (self.curSelectConfig != showConfig && !self.hasChangePayMethod) {
            self.hasChangePayMethod = YES;
        }
        
        self.curSelectConfig = showConfig;
        [self p_modifyMethodGroupSortList:showConfig];
        [self p_modifyPaymentToolSortList:showConfig];
        [self p_modifyFinaceChannelSortList:showConfig];
        if (self.closeChoosePageAfterChangeMethod) {
            @CJWeakify(self)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.choosePayMethodVC closeWithAnimation:YES comletion:nil];
            });
        }
    }
    // 回调代理 支付方式变更
    showConfig.isCombinePay = self.isCombinePay;
    if (self.isCombinePay) {
        [self.delegate changeCombinedBankPayMethod:[self payContextWithConfig:showConfig] loadingView:loadingView];
    } else {
        [self.delegate changePayMethod:[self payContextWithConfig:showConfig] loadingView:loadingView];
    }
}

- (void)didSelectSignPayPayMethod:(CJPayDefaultChannelShowConfig *)showConfig loadingView:(UIView *)loadingView {
    if (showConfig.type != BDPayChannelTypeAddBankCard) {
        // 非绑卡时，根据当前选择的支付方式来调整支付方式的排列顺序
        self.curSelectConfig = showConfig;
        [self p_modifyMethodGroupSortList:showConfig];
        [self p_modifyPaymentToolSortList:showConfig];
        [self p_modifyFinaceChannelSortList:showConfig];
        if (self.closeChoosePageAfterChangeMethod) {
            @CJWeakify(self)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @CJStrongify(self)
                [self.signPayChoosePayMethodVC closeWithAnimation:YES comletion:nil];
            });
        }
    }
    // 回调代理 支付方式变更
    if (self.delegate && [self.delegate respondsToSelector:@selector(changePayMethod:loadingView:)]) {
        [self.delegate changePayMethod:[self payContextWithConfig:showConfig] loadingView:loadingView];
    }
}

// 根据选中支付方式的类型来调整”支付工具“、”资金渠道“的排序
- (void)p_modifyMethodGroupSortList:(CJPayDefaultChannelShowConfig *)config {
    NSString *groupTypeStr = [self payMethodGroupTypeStrWithShowConfig:config];
    NSMutableArray<NSString *> *payMethodSortList = [self.payMethodSortList mutableCopy];
    if ([payMethodSortList containsObject:groupTypeStr]) {
        [payMethodSortList btd_removeObject:groupTypeStr];
        [payMethodSortList btd_insertObject:groupTypeStr atIndex:0];
    }
    self.payMethodSortList = [payMethodSortList copy];
}

// 根据选中支付方式的类型来调整”支付工具“卡列表的排序
- (void)p_modifyPaymentToolSortList:(CJPayDefaultChannelShowConfig *)config {
    if (config.type == BDPayChannelTypeAddBankCard) {
        return;
    }
    
    NSMutableArray<CJPayDefaultChannelShowConfig *> *paymentToolList = [self.paymentToolChannelConfigs mutableCopy];
    if ([paymentToolList containsObject:config]) {
        // 最后选中的支付方式排在最上面
        [paymentToolList btd_removeObject:config];
        [paymentToolList btd_insertObject:config atIndex:0];
        if ([self hasAvailableOldCards:paymentToolList]) {
            // 当 业务收入 可用且非选中时，固定排在支付工具第二位
            if ([paymentToolList containsObject:self.incomeChannelConfig] && ![self.incomeChannelConfig isEqual:config]) {
                [paymentToolList btd_removeObject:self.incomeChannelConfig];
                [paymentToolList btd_insertObject:self.incomeChannelConfig atIndex:1];
            }
            // 当零钱可用且非选中时，固定排在支付工具第二位，且优先级高于 业务收入
            if ([paymentToolList containsObject:self.balanceChannelConfig] && ![self.balanceChannelConfig isEqual:config]) {
                [paymentToolList btd_removeObject:self.balanceChannelConfig];
                [paymentToolList btd_insertObject:self.balanceChannelConfig atIndex:1];
            }
        }
    }
    self.paymentToolChannelConfigs = [paymentToolList copy];
}

// 根据选中支付方式的类型来调整”资金渠道“支付方式的排序
- (void)p_modifyFinaceChannelSortList:(CJPayDefaultChannelShowConfig *)config {
    NSMutableArray<CJPayDefaultChannelShowConfig *> *financeChannelList = [self.financeChannelConfigs mutableCopy];
    if ([financeChannelList containsObject:config]) {
        // 最后选中的支付方式排在最上面
        [financeChannelList btd_removeObject:config];
        [financeChannelList btd_insertObject:config atIndex:0];
    }
    self.financeChannelConfigs = [financeChannelList copy];
}


// 绑卡成功，（下次进来时）需刷新选卡页数据
- (void)p_bindcardSuccess {
    self.needUpdatePayMethodList = YES;
    if (!self.isNotCloseChooseVCWhenBindCardSuccess) {
        [self.choosePayMethodVC closeWithAnimation:NO comletion:nil];
    }
}

// 创建选卡页VC
- (CJPayChooseDyPayMethodViewController *)p_createChoosePayMethodVC {
    CJPayChooseDyPayMethodViewController *choosePayMethodVC = [[CJPayChooseDyPayMethodViewController alloc] initWithManager:self];
    choosePayMethodVC.height = self.height;
    @CJWeakify(self)
    choosePayMethodVC.didSelectedBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull selectConfig, UIView * _Nonnull loadingView) {
        @CJStrongify(self)
        [self didSelectPayMethod:selectConfig loadingView:loadingView];
    };
    return choosePayMethodVC;
}

//创建签约并支付选卡页VC
- (CJPayDySignPayChooseCardViewController *)p_createSignPayChoosePayMethodVC {
    CJPayDySignPayChooseCardViewController *signPayChooseCardVC = [[CJPayDySignPayChooseCardViewController alloc] initWithManager:self];
    @CJWeakify(self)
    signPayChooseCardVC.didSelectedBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull selectConfig, UIView * _Nonnull loadingView) {
        @CJStrongify(self)
        [self didSelectSignPayPayMethod:selectConfig loadingView:loadingView];
    };
    signPayChooseCardVC.warningText = self.response.payTypeInfo.subPayTypeSumInfo.subPayTypePageSubtitle;
    return signPayChooseCardVC;
}

// 尝试push选卡页VC
- (void)p_tryPushChoosePayMethodVC:(CJPayChooseDyPayMethodViewController *)choosePayMethodVC {
    if ([self.delegate respondsToSelector:@selector(pushChoosePayMethodVC:animated:)]) {
        [self.delegate pushChoosePayMethodVC:choosePayMethodVC animated:YES];
        return;
    }
    
    UIViewController *topVC = [UIViewController cj_topViewController];
    choosePayMethodVC.animationType = [topVC isKindOfClass:CJPayHalfPageBaseViewController.class] ? HalfVCEntranceTypeFromRight : HalfVCEntranceTypeFromBottom;
    [choosePayMethodVC presentWithNavigationControllerFrom:topVC useMask:YES completion:nil];
}

- (void)p_tryPushSignPayChoosePayMethodVC:(CJPayDySignPayChooseCardViewController *)signPayChooseCardVC {
    if ([self.delegate respondsToSelector:@selector(pushChoosePayMethodVC:animated:)]) {
        [self.delegate pushChoosePayMethodVC:signPayChooseCardVC animated:YES];
        return;
    }
    
    UIViewController *topVC = [UIViewController cj_topViewController];
    signPayChooseCardVC.animationType = [topVC isKindOfClass:CJPayHalfPageBaseViewController.class] ? HalfVCEntranceTypeFromRight : HalfVCEntranceTypeFromBottom;
    [signPayChooseCardVC presentWithNavigationControllerFrom:topVC useMask:YES completion:nil];
}

// 构造queryPayType请求参数
- (NSDictionary *)p_cardListParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params cj_setObject:[self.response.processInfo toDictionary] ?: @{} forKey:@"process_info"];
    [params cj_setObject:self.response.merchant.appId forKey:@"app_id"];
    [params cj_setObject:self.response.merchant.merchantId forKey:@"merchant_id"];
    [params cj_setObject:[self p_buildPreTradeParams] ?: @{} forKey:@"pre_trade_params"];
    return params;
}

// 构造支付中选卡页请求queryPayType特殊参数
- (NSDictionary *)p_buildPreTradeParams {
    CJPayDefaultChannelShowConfig *config = self.curSelectConfig;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    [params cj_setObject:@"trade_create" forKey:@"trade_scene"]; // 标记场景为支付中选卡页
    [params cj_setObject:CJString([self p_businessSceneString:config.type]) forKey:@"business_scene"]; // 告知后端当前客户端的选中支付方式
    switch (config.type) {
        case BDPayChannelTypeBankCard:
            [params cj_setObject:CJString(config.cjIdentify) forKey:@"bank_card_id"]; // 老卡需附上bankCardID
            break;
        case BDPayChannelTypeCreditPay:
            [params cj_setObject:CJString(config.payTypeData.curSelectCredit.installment) forKey:@"installment"]; //月付需附上选中分期数
            break;
        default:
            break;
    }
    return [params copy];
}

// 将channelType转为businessScene
- (NSString *)p_businessSceneString:(CJPayChannelType)channelType {
    switch (channelType) {
        case BDPayChannelTypeAddBankCard:
            return @"Pre_Pay_NewCard";
        case BDPayChannelTypeBalance:
            return @"Pre_Pay_Balance";
        case BDPayChannelTypeBankCard:
            return @"Pre_Pay_BankCard";
        case BDPayChannelTypeCreditPay:
            return @"Pre_Pay_Credit";
        case BDPayChannelTypeIncomePay:
            return @"Pre_Pay_Income";
        case BDPayChannelTypeCombinePay:
            return @"Pre_Pay_Combine";
        case BDPayChannelTypeFundPay:
            return @"Pre_Pay_FundPay";
        default:
            break;
    }
    return @"";
}

- (CJPayPayMethodType)p_payMethodTypeWithGroupTypeStr:(NSString *)groupType {
    if ([groupType isEqualToString:@"payment_tool"]) {
        return CJPayPayMethodTypePaymentTool;
    } else if ([groupType isEqualToString:@"finance_channel"]) {
        return CJPayPayMethodTypeFinanceChannel;
    }
    return CJPayPayMethodTypeUnknown;
}

- (NSString *)payMethodGroupTypeStr:(CJPayChannelType)channelType {
    NSString *typeStr = @"payment_tool";
    switch (channelType) {
        case BDPayChannelTypeCreditPay:
            typeStr = @"finance_channel";
            break;
        default:
            break;
    }
    return typeStr;
}

- (NSString *)payMethodGroupTypeStrWithShowConfig:(CJPayDefaultChannelShowConfig *)showConfig {
    if ([self.financeChannelListModel.subPayTypeIndexList containsObject:@(showConfig.index)]) {
        return @"finance_channel";
    } else {
        return @"payment_tool";
    }
}

// 月付支付方式赋值时，顺便设上payTypeData和payTypeData
- (void)setCreditChannelConfig:(CJPayDefaultChannelShowConfig *)creditChannelConfig {
    _creditChannelConfig = creditChannelConfig;
    if ([creditChannelConfig.payChannel isKindOfClass:CJPaySubPayTypeInfoModel.class]) {
        CJPaySubPayTypeInfoModel *channel = (CJPaySubPayTypeInfoModel *)creditChannelConfig.payChannel;
        _creditChannelConfig.payTypeData = channel.payTypeData;
    }
}

// 让chooseVC来loading
- (void)p_startLoading {
    [self.choosePayMethodVC startLoading];
}

- (void)p_stopLoading {
    [self.choosePayMethodVC stopLoading];
}

// 构造payContext，发起支付时使用
- (CJPayFrontCashierContext *)payContextWithConfig:(CJPayDefaultChannelShowConfig *)selectConfig {
    CJPayFrontCashierContext *context = [CJPayFrontCashierContext new];
    context.defaultConfig = selectConfig;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([self extParams].count > 0) {
        [params addEntriesFromDictionary:[self extParams]];
    }

    NSDictionary *bindCardInfo = @{
        @"bank_code": CJString(selectConfig.frontBankCode),
        @"card_type": CJString(selectConfig.cardType),
        @"card_add_ext": CJString(selectConfig.cardAddExt),
        @"business_scene": CJString([selectConfig bindCardBusinessScene])
    };
    [params cj_setObject:bindCardInfo forKey:@"bind_card_info"];
    
    context.extParams = params;
    context.hasChangePayMethod = self.hasChangePayMethod;
    @CJWeakify(self);
    context.latestOrderResponseBlock = ^CJPayBDCreateOrderResponse * _Nonnull{
        @CJStrongify(self);
        return self.response;
    };
    return context;
}

- (void)trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    if ([self.delegate respondsToSelector:@selector(trackEvent:params:)]) {
        [self.delegate trackEvent:eventName params:params];
    } else {
        [CJTracker event:eventName params:params];
    }
}

- (NSDictionary *)extParams {
    if ([self.delegate respondsToSelector:@selector(payContextExtParams)]) {
        return [self.delegate payContextExtParams];
    }
    return [NSDictionary new];
}

- (NSArray<NSString *> *)payMethodSortList {
    if (!_payMethodSortList) {
        _payMethodSortList = [NSArray new];
    }
    return _payMethodSortList;
}

- (NSArray<CJPayDefaultChannelShowConfig*> *)paymentToolChannelConfigs {
    if (!_paymentToolChannelConfigs) {
        _paymentToolChannelConfigs = [NSArray new];
    }
    return _paymentToolChannelConfigs;
}

- (NSArray<CJPayDefaultChannelShowConfig*> *)financeChannelConfigs {
    if (!_financeChannelConfigs) {
        _financeChannelConfigs = [NSArray new];
    }
    return _financeChannelConfigs;
}

- (CJPayChooseDyPayMethodGroupModel *)paymentToolListModel {
    if (!_paymentToolListModel) {
        _paymentToolListModel = [CJPayChooseDyPayMethodGroupModel new];
    }
    return _paymentToolListModel;
}

- (CJPayChooseDyPayMethodGroupModel *)financeChannelListModel {
    if (!_financeChannelListModel) {
        _financeChannelListModel = [CJPayChooseDyPayMethodGroupModel new];
    }
    return _financeChannelListModel;
}

- (NSMutableDictionary *)payMethodDisabledReasonMap {
    if (!_payMethodDisabledReasonMap) {
        _payMethodDisabledReasonMap = [NSMutableDictionary new];
    }
    return _payMethodDisabledReasonMap;
}

@end
