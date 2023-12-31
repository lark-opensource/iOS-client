//
//  CJPayPayAgainCombinationPaymentViewController.m
//  Pods
//
//  Created by 高航 on 2022/6/20.
//

#import "CJPayPayAgainCombinationPaymentViewController.h"

#import "CJPayTypeInfo+Util.h"
#import "CJPayCombinePaymentAmountModel.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayCreateOrderResponse.h"
#import "CJPayBytePayMethodView.h"
#import "CJPayCombinationPaymentAmountView.h"
#import "CJPayStyleButton.h"
#import "CJPayThemeStyleManager.h"
#import "CJPayUIMacro.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayCardManageModule.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayPayAgainViewModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayPrimaryCombinePayInfoModel.h"
#import "CJPaySecondaryCombinePayInfoModel.h"
#import "CJPayCombinePayInfoModel.h"

@interface CJPayPayAgainCombinationPaymentViewController ()<CJPayMethodTableViewDelegate>

#pragma mark - views
@property (nonatomic, strong) CJPayCombinationPaymentAmountView *combinationPaymentAmountView;
@property (nonatomic, strong) CJPayBytePayMethodView *payMethodView;

#pragma mark - data
@property (nonatomic, strong) CJPayCreateOrderResponse *response;
@property (nonatomic, strong) CJPayPayAgainViewModel *viewModel;
@property (nonatomic, copy) NSArray<CJPaySubPayTypeInfoModel *> *subPayTypeInfoList;

@property (nonatomic, assign) NSInteger balanceAmount;
@property (nonatomic, assign) NSInteger incomeAmount;
@property (nonatomic, assign) NSInteger bankCardAmount;
@property (nonatomic, assign) NSInteger combinePayIndex;

@property (nonatomic, assign) CJPayLoadingType loadingType;

@end

@implementation CJPayPayAgainCombinationPaymentViewController

- (instancetype)initWithViewModel:(CJPayPayAgainViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.subPayTypeInfoList = self.viewModel.cardListModel.subPayTypeSumInfo.subPayTypeInfoList;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_updateWithResponse:) name:BDPayBindCardSuccessRefreshNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_bindCardSuccess:) name:CJPayBindCardSuccessPreCloseNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_setupConfig];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    [self.combinationPaymentAmountView updateStyleIfShowNotSufficient:NO];
}

- (void)p_bindCardSuccess:(NSNotification *)notification {
    self.loadingType = CJPayLoadingTypeDouyinHalfLoading;
}

- (void)back {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [self p_trackWithEventName:@"wallet_cashier_combine_back_click" params:dict];
    [super back];
}


- (void)startLoading {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self];
    if (vc == self) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
    } else if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
        self.loadingType = CJPayLoadingTypeDouyinHalfLoading;
    } else {
       [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        self.loadingType = CJPayLoadingTypeTopLoading;
    }

}

- (void)stopLoading {
    [[CJPayLoadingManager defaultService] stopLoading];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - private method
- (void)p_setupUI {
    [self.contentView addSubview:self.combinationPaymentAmountView];
    [self.contentView addSubview:self.payMethodView];
    CJPayMasMaker(self.combinationPaymentAmountView, {
        make.top.equalTo(self.contentView).offset(-4);
        make.left.right.equalTo(self.contentView);
    })
    
    CJPayMasMaker(self.payMethodView, {
        make.top.equalTo(self.combinationPaymentAmountView.mas_bottom);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.contentView.mas_safeAreaLayoutGuideBottom).offset(CJ_IPhoneX ? 0 : -8);
        } else {
            make.bottom.equalTo(self.contentView).offset(-8);
        }
        make.left.right.equalTo(self.contentView);
    })
}

- (void)p_setupConfig {
    self.payMethodView.delegate = self;
    [self p_setupAmount];
    self.payMethodView.models = [self p_buildPayMethodModels];
    NSArray *showConfigArray = [self p_getShouldShowConfigs];
    NSMutableArray *campaignInfos = [NSMutableArray array];
    NSMutableArray *methodLists = [NSMutableArray array];
    [showConfigArray enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj toActivityInfoTracker].count > 0) {
            [campaignInfos btd_addObject:[obj toActivityInfoTracker]];
        }
        if ([obj toActivityInfoTrackerForCreditPay].count > 0) {
            [campaignInfos addObjectsFromArray:[obj toActivityInfoTrackerForCreditPay]];
        }
        if ([obj toMethodInfoTracker].count > 0) {
            [methodLists btd_addObject:[obj toMethodInfoTracker]];
        }
    }];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"balance_amount" : @(self.balanceAmount),
        @"card_amount" : @(self.bankCardAmount),
        @"campaign_info" : campaignInfos,
        @"all_method_list" : methodLists,
    }];
    [self p_trackWithEventName:@"wallet_cashier_combine_imp" params:params];
}

- (void)p_setupAmount {
    if(Check_ValidArray(self.subPayTypeInfoList)) {
        __block CJPaySubPayTypeInfoModel *secondaryPayModel;
        [self.subPayTypeInfoList enumerateObjectsUsingBlock:^(CJPaySubPayTypeInfoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {            
            if (obj.channelType == self.type) {
                secondaryPayModel = obj;
                self.combinePayIndex = secondaryPayModel.index;
                *stop = YES;
            }
            
        }];
        CJPayCombinePaymentAmountModel *amountModel = [CJPayCombinePaymentAmountModel new];
        CJPaySecondaryCombinePayInfoModel *secondaryPayInfo = secondaryPayModel.payTypeData.combinePayInfo.secondaryPayInfo;
        self.balanceAmount = secondaryPayInfo.secondaryAmount;
        self.bankCardAmount = secondaryPayInfo.primaryAmount;

        amountModel.totalAmount = [NSString stringWithFormat:@"%.2f", secondaryPayInfo.tradeAmount/(double)100];
        amountModel.cashAmount = [NSString stringWithFormat:@"%.2f", secondaryPayInfo.secondaryAmount/(double)100];
        amountModel.bankCardAmount = [NSString stringWithFormat:@"%.2f", secondaryPayInfo.primaryAmount/(double)100];
        amountModel.detailInfo = CJString(self.response.tradeInfo.tradeName);
        
        [self.combinationPaymentAmountView updateAmount:amountModel];
    }
}

- (void)p_updateWithResponse:(NSNotification *)notification {
    if ([notification.object isKindOfClass:CJPayCreateOrderResponse.class]) {
        self.response = (CJPayCreateOrderResponse *)notification.object;
        self.payMethodView.models = [self p_buildPayMethodModels];
    }
}


- (NSArray<CJPayChannelBizModel *> *)p_buildPayMethodModels {
    NSMutableArray<CJPayChannelBizModel *> *array = [NSMutableArray array];
    
    NSMutableDictionary *invalidMethods = [NSMutableDictionary new];
    NSMutableArray<NSString *> *payDisabledFundIds = [[NSMutableArray alloc] initWithArray:[self.viewModel.payDisabledFundID2ReasonMap allKeys]];
    CJPayDefaultChannelShowConfig *firstChannelConfig = nil;
    for (CJPayDefaultChannelShowConfig *channelConfig in [self p_getShouldShowConfigs]) {
        CJPayChannelBizModel *model = [channelConfig toBizModel];
        model.isEcommercePay = YES;
        model.isChooseMethodSubPage = YES;
        if ([payDisabledFundIds containsObject:channelConfig.cjIdentify]) {
            model.enable = NO;
            model.isConfirmed = NO;
            if (!Check_ValidString(model.reasonStr)) {
                model.reasonStr = [self.viewModel.payDisabledFundID2ReasonMap cj_stringValueForKey:channelConfig.cjIdentify];
                model.subTitle = [self.viewModel.payDisabledFundID2ReasonMap cj_stringValueForKey:channelConfig.cjIdentify];
            }
            [invalidMethods cj_setObject:model forKey:channelConfig.cjIdentify];
        } else {
            if ((model.type != BDPayChannelTypeBalance) && (model.type != BDPayChannelTypeIncomePay) && (model.type != BDPayChannelTypeCreditPay)) {
                if (firstChannelConfig == nil) {
                    firstChannelConfig = channelConfig;
                }
                [array addObject:model];
            }
        }
    }
    
    // 根据余额不足要求重新排序展示卡列表
    for (NSString *cjidentify in payDisabledFundIds) {
        id object = [invalidMethods cj_objectForKey:cjidentify];
        if (object) {
            [array addObject:object];
        }
    }
    return [array copy];
}

- (CJPayPrimaryCombinePayInfoModel *)p_primaryCombineModelWithList:(NSArray<CJPayPrimaryCombinePayInfoModel *> *)modelList {
    __block CJPayPrimaryCombinePayInfoModel *primaryInfoModel = nil;
    [modelList enumerateObjectsUsingBlock:^(CJPayPrimaryCombinePayInfoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.channelType == self.type) {
            primaryInfoModel = obj;
            *stop = YES;
        }
    }];
    return primaryInfoModel;
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)p_getShouldShowConfigs {
    NSMutableArray *showConfigs = [NSMutableArray new];
    @CJWeakify(self)
    [self.subPayTypeInfoList enumerateObjectsUsingBlock:^(CJPaySubPayTypeInfoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        CJPayPrimaryCombinePayInfoModel *primartInfoModel = [self p_primaryCombineModelWithList:obj.payTypeData.combinePayInfo.primaryPayInfoList];
        if (primartInfoModel.secondaryPayTypeIndex == self.combinePayIndex) {
            CJPayDefaultChannelShowConfig *config = [[obj buildShowConfig] firstObject];
            config.isCombinePay = YES;
            config.combineType = self.type;
            [showConfigs addObject:config];
        }
    }];
    return showConfigs;
}

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:self.commonTrackerParams];
    [mutableDic addEntriesFromDictionary:params];
    [mutableDic cj_setObject:@6 forKey:@"show_style"];//CJPayDeskTypeBytePay
    [CJTracker event:eventName params:mutableDic];
}

#pragma mark - CJPayMethodTableViewDelegate
- (void)didSelectAtIndex:(int)selectIndex methodCell:(UITableViewCell *)cell{
    if (selectIndex < 0 || selectIndex >= self.payMethodView.models.count) {
        return;
    }
    
    CJPayChannelBizModel *model = [self.payMethodView.models cj_objectAtIndex:selectIndex];
    
    if(!model.enable) {
        return;
    }
    CJPayDefaultChannelShowConfig *selectChannelConfig = model.channelConfig;
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *infoDict = [selectChannelConfig toActivityInfoTracker];
    if (infoDict.count > 0) {
        [activityInfos addObject:infoDict];
    }
    
    if(selectChannelConfig.type == BDPayChannelTypeAddBankCard) {
        [self p_trackWithEventName:@"wallet_cashier_add_newcard_click" params:@{
            @"from" : @"组合支付页",
            @"activity_info": activityInfos,
            @"addcard_info" : CJString(selectChannelConfig.title),
        }];
    }
    
    [self p_trackWithEventName:@"wallet_cashier_combine_method_click" params:@{
        @"activity_info": activityInfos,
        @"front_bank_code": CJString(selectChannelConfig.frontBankCode),
        @"method" : [CJPayTypeInfo getTrackerMethodByChannelConfig:selectChannelConfig],
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didClickCombineMethodCell:channelBizModel:)]) {
        [self.delegate didClickCombineMethodCell:cell channelBizModel:model];
    }
    
}

- (void)didSelectAtIndex:(int)selectIndex {
    // 防止crash
}


#pragma mark - lazy views
- (CJPayCombinationPaymentAmountView *)combinationPaymentAmountView {
    if (!_combinationPaymentAmountView) {
        _combinationPaymentAmountView = [[CJPayCombinationPaymentAmountView alloc] initWithType:self.type];
    }
    return _combinationPaymentAmountView;
}

- (CJPayBytePayMethodView *)payMethodView {
    if (!_payMethodView) {
        _payMethodView = [CJPayBytePayMethodView new];
        _payMethodView.isChooseMethodSubPage = YES;
        _payMethodView.delegate = self;
    }
    return _payMethodView;
}


@end

