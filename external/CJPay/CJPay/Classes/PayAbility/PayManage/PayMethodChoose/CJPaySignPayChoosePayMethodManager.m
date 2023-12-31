//
//  CJPaySignPayChoosePayMethodManager.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/26.
//

#import "CJPaySignPayChoosePayMethodManager.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayDySignPayChooseCardViewController.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPaySignPayChoosePayMethodGroupModel.h"
#import "CJPaySignSetMemberFirstPayTypeRequest.h"
#import "CJPaySignSetMemberFirstPayTypeResponse.h"
#import "CJPaySubPayTypeGroupInfo.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKDefine.h"

@interface CJPaySignPayChoosePayMethodManager ()

#pragma mark - viewController

@property (nonatomic, strong) CJPayDySignPayChooseCardViewController *signPayChoosePayMethodVC;
@property (nonatomic, copy) NSArray<CJPaySignPayChoosePayMethodGroupModel *> *payMethodList;

@property (nonatomic, copy) NSDictionary<NSString *, CJPaySignPayChoosePayMethodGroupModel *> *indexLinkPayMethodGroupModelDict; // 让下标和groupModel对应

@end

@implementation CJPaySignPayChoosePayMethodManager

- (instancetype)initWithOrderResponse:(CJPayBDCreateOrderResponse *)response {
    self = [super init];
    if (self) {
        _response = response;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_bindcardSuccess) name:CJPayBindCardSuccessNotification object:nil];
    }
    return self;
}

#pragma mark - public func

- (void)gotoSignPayChooseDyPayMethod {
    self.signPayChoosePayMethodVC = [self p_createSignPayChoosePayMethodVC];
    [self p_tryPushSignPayChoosePayMethodVC:self.signPayChoosePayMethodVC];
}

- (void)getChoosePayMethodList:(void (^)(NSArray<CJPaySignPayChoosePayMethodGroupModel *> * _Nonnull))completionBlock {
    CJ_CALL_BLOCK(completionBlock, [self p_getPayMethodList]);
}

- (void)trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    if ([self.delegate respondsToSelector:@selector(trackEvent:params:)]) {
        [self.delegate trackEvent:eventName params:params];
    } else {
        [CJTracker event:eventName params:params];
    }
}

- (void)closeSignPayChooseDyPayMethod {
    if (!self.signPayChoosePayMethodVC) {
        return;
    }
    [self.signPayChoosePayMethodVC closeWithAnimation:YES comletion:nil];
}

+ (void)setMemberFirstPayMethod:(NSDictionary *)bizParams needLoading:(BOOL)needLoading completion:(nonnull void (^)(BOOL))completion {
    if (needLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
    }
    [CJPaySignSetMemberFirstPayTypeRequest startWithBizParams:bizParams completion:^(NSError * _Nonnull error, CJPaySignSetMemberFirstPayTypeResponse * _Nonnull response) {
        if (needLoading) {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
        CJ_CALL_BLOCK(completion, [response isSuccess]);
    }];
}

+ (NSString *)getPayMode:(CJPayChannelType)channelType {
    if (channelType == BDPayChannelTypeBalance) {
        return @"1";
    } else if (channelType == BDPayChannelTypeBankCard) {
        return @"2";
    } else if(channelType == BDPayChannelTypeCreditPay) {
        return @"4";
    }
    return @"";
}

#pragma mark - private func

// 获取切卡页的分组信息
- (NSArray<CJPaySignPayChoosePayMethodGroupModel *> *)p_getPayMethodList {
    if (!self.payMethodList || self.needUpdatePayMethodList) {
        self.payMethodList = [self p_buildPayMethodListWithResponse];
    }
    return self.payMethodList;
}

//通过response 来创建payMethodList
- (NSArray<CJPaySignPayChoosePayMethodGroupModel *> *)p_buildPayMethodListWithResponse {
    self.needUpdatePayMethodList = NO;
    
    CJPayIntegratedChannelModel *tradeInfo = [[CJPayIntegratedChannelModel alloc] init];
    tradeInfo.subPayTypeGroupInfoList = self.response.payTypeInfo.subPayTypeGroupInfoList;
    tradeInfo.subPayTypeSumInfo = self.response.payTypeInfo.subPayTypeSumInfo;
    // 获取所有支付方式, 并存在dictionary中，优化枚举流程。
    NSArray<CJPayDefaultChannelShowConfig *> *showConfigArray =  [tradeInfo buildConfigsWithIdentify:@""];
    NSMutableDictionary<NSString *,CJPayDefaultChannelShowConfig *> *showConfigDict = [NSMutableDictionary new];
    for (NSInteger index = 0; index < showConfigArray.count; index++) {
        CJPayDefaultChannelShowConfig *config = [showConfigArray cj_objectAtIndex:index];
        NSString *indexKey = [NSString stringWithFormat:@"%ld",config.index];
        [showConfigDict cj_setObject:config forKey:indexKey];
    }
    // 根据subPayTypeIndexList 处理分组
    return [self p_buildPayMethodListInGroup:tradeInfo showConfigDict:[showConfigDict copy]];
}

// 根据subPayTypeIndexList 处理分组
- (NSArray<CJPaySignPayChoosePayMethodGroupModel *> *)p_buildPayMethodListInGroup:(CJPayIntegratedChannelModel *)tradeInfo showConfigDict:(NSDictionary<NSString *,CJPayDefaultChannelShowConfig *> *)showConfigDict {
    // 将config依照group分组
    NSMutableArray<CJPaySignPayChoosePayMethodGroupModel *> * payMethodListGroupModelArray = [NSMutableArray new];
    // 将每个config的index 映射 methodGroupModel 相当于区分是哪个组的。 在改变卡片顺序的时候会用到
    NSMutableDictionary<NSString *, CJPaySignPayChoosePayMethodGroupModel *> *indexLinkPayMethodGroupModelDict = [NSMutableDictionary new];
    
    NSArray<CJPaySubPayTypeGroupInfo *> *subPayTypeGroupInfoList = tradeInfo.subPayTypeGroupInfoList;
    for (NSInteger group = 0; group < subPayTypeGroupInfoList.count; group++) {
        CJPaySignPayChoosePayMethodGroupModel *choosePayMethodGroupModel = [CJPaySignPayChoosePayMethodGroupModel new];
        
        CJPaySubPayTypeGroupInfo *subPayTypeGroupInfo = [subPayTypeGroupInfoList cj_objectAtIndex:group];
        NSMutableArray<CJPayDefaultChannelShowConfig *> *groupMethodList = [NSMutableArray new];
        for (NSInteger index = 0; index < subPayTypeGroupInfo.subPayTypeIndexList.count; index++) {
            NSInteger configIndex = [[subPayTypeGroupInfo.subPayTypeIndexList cj_objectAtIndex:index] integerValue];
            NSString *indexKey = [NSString stringWithFormat:@"%ld",configIndex];
            [groupMethodList btd_addObject:[showConfigDict cj_objectForKey:indexKey]];
            [indexLinkPayMethodGroupModelDict cj_setObject:choosePayMethodGroupModel forKey:indexKey];
        }
        choosePayMethodGroupModel.groupTitle = subPayTypeGroupInfo.groupTitle;
        choosePayMethodGroupModel.displayNewBankCardCount = subPayTypeGroupInfo.displayNewBankCardCount;
        choosePayMethodGroupModel.subPayTypeIndexList = [groupMethodList copy];
        [payMethodListGroupModelArray btd_addObject:choosePayMethodGroupModel];
    }
    self.indexLinkPayMethodGroupModelDict = indexLinkPayMethodGroupModelDict;
    return [payMethodListGroupModelArray copy];
}

//创建签约并支付选卡页VC
- (CJPayDySignPayChooseCardViewController *)p_createSignPayChoosePayMethodVC {
    CJPayDySignPayChooseCardViewController *signPayChooseCardVC = [[CJPayDySignPayChooseCardViewController alloc] initWithManager:self];
    signPayChooseCardVC.height = self.height;
    @CJWeakify(self)
    signPayChooseCardVC.didSelectedBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull selectConfig, UIView * _Nonnull loadingView) {
        @CJStrongify(self)
        [self p_didSelectSignPayPayMethod:selectConfig loadingView:loadingView];
    };
    signPayChooseCardVC.warningText = self.response.payTypeInfo.subPayTypeSumInfo.subPayTypePageSubtitle;
    return signPayChooseCardVC;
}

// 尝试push选卡页VC
- (void)p_tryPushSignPayChoosePayMethodVC:(CJPayDySignPayChooseCardViewController *)signPayChooseCardVC {
    if ([self.delegate respondsToSelector:@selector(pushChoosePayMethodVC:animated:)]) {
        [self.delegate pushChoosePayMethodVC:signPayChooseCardVC animated:YES];
        return;
    }
    
    UIViewController *topVC = [UIViewController cj_topViewController];
    signPayChooseCardVC.animationType = [topVC isKindOfClass:CJPayHalfPageBaseViewController.class] ? HalfVCEntranceTypeFromRight : HalfVCEntranceTypeFromBottom;
    [signPayChooseCardVC presentWithNavigationControllerFrom:topVC useMask:YES completion:nil];
}

- (void)p_didSelectSignPayPayMethod:(CJPayDefaultChannelShowConfig *)showConfig loadingView:(UIView *)loadingView {
    if (showConfig.type != BDPayChannelTypeAddBankCard) {
        // 非绑卡时，根据当前选择的支付方式来调整支付方式的排列顺序
//        self.curSelectConfig = showConfig;
        [self p_modifyPayMethodGroupSort:showConfig];
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
        [self.delegate changePayMethod:[self p_payContextWithConfig:showConfig] loadingView:loadingView];
    }
}

// 绑卡成功，（下次进来时）需刷新选卡页数据
- (void)p_bindcardSuccess {
    self.needUpdatePayMethodList = YES;
}

// 对支付方式重新排序
- (void)p_modifyPayMethodGroupSort:(CJPayDefaultChannelShowConfig *)config {
    if (config.type == BDPayChannelTypeAddBankCard) {
        return;
    }
    
    NSMutableArray<CJPaySignPayChoosePayMethodGroupModel *> *payMethodList = [NSMutableArray new];
    NSString *indexKey = [NSString stringWithFormat:@"%ld",config.index];
    CJPaySignPayChoosePayMethodGroupModel *choosePayMethodGroupModel = [self.indexLinkPayMethodGroupModelDict cj_objectForKey:indexKey defaultObj:nil];
    if (!choosePayMethodGroupModel) {
        return ;
    }
    NSMutableArray<CJPayDefaultChannelShowConfig *> *subPayTypeIndexList = [choosePayMethodGroupModel.subPayTypeIndexList mutableCopy];
    if ([subPayTypeIndexList containsObject:config]) {
        // 最后选中的支付方式排在最上面
        [subPayTypeIndexList btd_removeObject:config];
        [subPayTypeIndexList btd_insertObject:config atIndex:0];
    }
    
    choosePayMethodGroupModel.subPayTypeIndexList = [subPayTypeIndexList copy];
}

// 构造payContext，发起支付时使用
- (CJPayFrontCashierContext *)p_payContextWithConfig:(CJPayDefaultChannelShowConfig *)selectConfig {
    CJPayFrontCashierContext *context = [CJPayFrontCashierContext new];
    context.defaultConfig = selectConfig;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSDictionary *extParams = [self p_extParams];
    if (extParams.count > 0) {
        [params addEntriesFromDictionary:extParams];
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

- (NSDictionary *)p_extParams {
    if ([self.delegate respondsToSelector:@selector(payContextExtParams)]) {
        return [self.delegate payContextExtParams];
    }
    return [NSDictionary new];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
