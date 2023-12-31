//
//  CJPayBizChoosePayMethodViewController.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/18.
//

#import "CJPayBizChoosePayMethodViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayTracker.h"
#import "CJPayNotSufficientFundsView.h"
#import "CJPaySDKDefine.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayIntegratedCashierProcessManager.h"
#import "CJPayCurrentTheme.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayChannelBizModel.h"
#import "CJPayManager.h"
#import "CJPayBytePayMethodView.h"
#import "CJPayAlertUtil.h"
#import "CJPayPaddingLabel.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayKVContext.h"
#import "CJPaySubPayTypeIconTipModel.h"
#import "CJPayZoneSplitInfoModel.h"
#import "CJPayBizDeskUtil.h"
#import "CJPayAlertUtil.h"
#import "CJPayInComePayAlertContentView.h"
#import "CJPayDyTextPopUpViewController.h"

@interface CJPayBizChoosePayMethodViewController ()

#pragma mark - views
@property (nonatomic, strong) CJPayNotSufficientFundsView *notSufficientFundsView;
@property (nonatomic, strong) CJPayPaddingLabel *voucherTipLabel;

#pragma mark - model & manager
@property (nonatomic, copy) NSArray<CJPayChannelBizModel *> *bizModels;
@property (nonatomic, strong) CJPayIntegratedCashierProcessManager *processManager;

#pragma mark - constraint
@property (nonatomic, strong) MASConstraint *notSufficientViewHeightConstraint;
@property (nonatomic, strong) MASConstraint *payMethodViewTopBaseNotSufficientViewConstraint;
#pragma mark - data
@property (nonatomic, assign) CGSize notSufficientFunsSize;
@property (nonatomic, assign) NSInteger selectIndex;
@property (nonatomic, copy) NSDictionary *commonTrackerParams; // 通用埋点参数
@property (nonatomic, strong) CJPayChannelBizModel *currentSelectedBizModel; //记录当前选中的支付方式，埋点使用

@end

@implementation CJPayBizChoosePayMethodViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithOrderResponse:(CJPayCreateOrderResponse *)response
                        defaultConfig:(CJPayDefaultChannelShowConfig *)config
                       processManager:(CJPayIntegratedCashierProcessManager *)processManager {
    self = [super init];
    if (self) {
        self.orderResponse = response;
        self.outDefaultConfig = config;
        self.processManager = processManager;
        self.isSupportClickMaskBack = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_updateWithResponse:) name:BDPayBindCardSuccessRefreshNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_unionBindCardUnavailable) name:CJPayUnionBindCardUnavailableNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupUI];
    self.bizModels = [self p_buildPayMethodModels];
    [self p_updatePayMethodView];
    [self p_tracker];
}

- (void)didChangeCreditPayInstallment:(NSString *)installment{
    self.creditPayInstallment = installment;
    [self.payMethodView.models enumerateObjectsUsingBlock:^(CJPayChannelBizModel *bizModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if (bizModel.channelConfig.type == BDPayChannelTypeCreditPay) {
            self.selectIndex = idx;
        }
    }];
    [self p_modifyResponseModelSelectIndexTo:self.selectIndex];
}

- (void)notifyNotsufficient:(NSString *)bankCardId {
    NSMutableArray *notSufficientFundIds = [self.notSufficientFundsIDs mutableCopy];
    if (Check_ValidString(bankCardId) && ![notSufficientFundIds containsObject:bankCardId]) {
        [notSufficientFundIds addObject:bankCardId];
    }
    self.notSufficientFundsIDs = [notSufficientFundIds copy];
    
    [self p_reloadCurrentView];
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)p_getShouldShowConfigs {
    return [self.orderResponse.payInfo showConfigForCardList];
}

- (void)back {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([self.notSufficientFundsIDs count] > 0) {
        [params cj_setObject:@"1" forKey:@"error_info"];
    }
    [self p_trackWithEventName:@"wallet_cashier_method_page_back_click" params:params];
    
    if (self.isShowDetentionAlert) {
        NSString *title = [self p_isHaveDiscount] ? CJPayLocalizedStr(@"继续支付可享受优惠，确定放弃吗") : CJPayLocalizedStr(@"还差一步就支付完成了，确定放弃吗");
        
        @weakify(self);
        void(^leftButtonBlock)(void) = ^() {
            @strongify(self);
            [self p_trackWithEventName:@"wallet_cashier_method_keep_pop_click" params:@{
                @"button_name": @"放弃",
                @"is_discount": [self p_isHaveDiscount] ? @"1" : @"0"
            }];
            if ([self.delegate respondsToSelector:@selector(closeDesk)]) {
                [self.delegate closeDesk];
            }
        };
        void(^rightButtonBlock)(void) = ^() {
            @strongify(self);
            [self p_trackWithEventName:@"wallet_cashier_method_keep_pop_click" params:@{
                @"button_name": @"继续支付",
                @"is_discount": [self p_isHaveDiscount] ? @"1" : @"0"
            }];
        };
        
        [CJPayAlertUtil customDoubleAlertWithTitle:title
                                     content:nil
                              leftButtonDesc:CJPayLocalizedStr(@"放弃")
                             rightButtonDesc:CJPayLocalizedStr(@"继续支付")
                             leftActionBlock:leftButtonBlock
                             rightActioBlock:rightButtonBlock
                                       useVC:self];
        
        [self p_trackWithEventName:@"wallet_cashier_method_keep_pop_show" params:@{
            @"is_discount": [self p_isHaveDiscount] ? @"1" : @"0"
        }];
    } else {
        [super back];
    }
}

- (void)updateNotSufficientFundsViewTitle:(NSString *)title {
    [self.notSufficientFundsView updateTitle:title];
}

#pragma mark - private method

- (void)p_unionBindCardUnavailable {
    [CJPayKVContext kv_setValue:@"1" forKey:CJPayUnionPayIsUnAvailable];
    [self p_reloadCurrentView];
}

- (void)p_setupUI
{
    NSString *title = CJPayLocalizedStr(@"选择支付方式");
    if (self.outDefaultConfig.isCombinePay) {
        if (self.outDefaultConfig.combineType == BDPayChannelTypeBalance) {
            title = CJPayLocalizedStr(@"选择与零钱组合的支付方式");
        } else if (self.outDefaultConfig.combineType == BDPayChannelTypeIncomePay) {
            title = CJPayLocalizedStr(@"选择与业务收入组合的支付方式");
        }
    }
    [self.navigationBar setTitle:title];
    [self.contentView addSubview:self.notSufficientFundsView];
    self.notSufficientFunsSize = [self.notSufficientFundsView calSize];
    CJPayMasMaker(self.notSufficientFundsView, {
        make.top.left.equalTo(self.contentView);
        make.width.mas_equalTo(self.notSufficientFunsSize.width);
        self.notSufficientViewHeightConstraint = make.height.mas_equalTo(self.notSufficientFunsSize.height);
    });
    [self.contentView addSubview:self.voucherTipLabel];
    CJPayMasMaker(self.voucherTipLabel, {
        make.left.top.right.equalTo(self.contentView);
        make.height.mas_equalTo(36);
    });
    
    self.payMethodView = [CJPayBytePayMethodView new];
    self.payMethodView.isFromCombinePay = self.outDefaultConfig.isCombinePay;
    self.payMethodView.delegate = self;
    self.payMethodView.isChooseMethodSubPage = YES;
    [self.contentView addSubview:self.payMethodView];
    CJPayMasMaker(self.payMethodView, {
        make.left.right.bottom.equalTo(self.contentView);
        self.payMethodViewTopBaseNotSufficientViewConstraint = make.top.equalTo(self.notSufficientFundsView.mas_bottom);
        make.top.equalTo(self.contentView).priority(UILayoutPriorityDefaultLow);
    });
    
    self.notSufficientViewHeightConstraint.offset = self.showNotSufficientFundsHeaderLabel ? self.notSufficientFunsSize.height : 0;
    self.payMethodViewTopBaseNotSufficientViewConstraint.offset = self.showNotSufficientFundsHeaderLabel ? 0 : 8;
    if (!self.showNotSufficientFundsHeaderLabel && Check_ValidString(self.orderResponse.payInfo.bdPay.subPayTypeSumInfo.subPayTypePageSubtitle)) {
        CJPayMasReMaker(self.payMethodView, {
            make.left.right.bottom.equalTo(self.contentView);
            make.top.equalTo(self.voucherTipLabel.mas_bottom);
        });
        self.voucherTipLabel.text = self.orderResponse.payInfo.bdPay.subPayTypeSumInfo.subPayTypePageSubtitle;
        self.voucherTipLabel.hidden = NO;
    } else {
        self.voucherTipLabel.hidden = YES;
    }
    
    if (@available(iOS 13.0, *)) {
        self.modalInPresentation = CJ_Pad;
    } else {
        // Fallback on earlier versions
    }
}

- (void)p_updateWithResponse:(NSNotification *)notification {
    if (nil != notification.object && [notification.object isKindOfClass:CJPayCreateOrderResponse.class]) {
        self.orderResponse = (CJPayCreateOrderResponse *)notification.object;
        self.bizModels = [self p_buildPayMethodModels];
        [self p_updatePayMethodView];
    }
}

- (void)p_reloadCurrentView {
    self.bizModels = [self p_buildPayMethodModels];
    [self p_updatePayMethodView];
    [self.payMethodView scrollToTop];
}

- (void)p_updatePayMethodView {
    [self.bizModels enumerateObjectsUsingBlock:^(CJPayChannelBizModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isConfirmed = [obj isEqual:[self.outDefaultConfig toBizModel]];
        obj.isConfirmed = isConfirmed;
        if (isConfirmed) {
            self.currentSelectedBizModel = obj;
        }
    }];
    _payMethodView.models = self.bizModels;
    self.notSufficientViewHeightConstraint.offset = self.showNotSufficientFundsHeaderLabel ? self.notSufficientFunsSize.height : 0;
    self.payMethodViewTopBaseNotSufficientViewConstraint.offset = self.showNotSufficientFundsHeaderLabel ? 0 : 8;
}

- (NSArray *)p_buildPayMethodModels {
    NSMutableArray<CJPayChannelBizModel *> *array = [NSMutableArray array];
    
    NSMutableDictionary *invalidMethods = [NSMutableDictionary new];
    NSMutableArray *invalidModels = [NSMutableArray array];
    NSMutableArray *bindCardArray = [NSMutableArray new];
    
    CJPayChannelBizModel *limitBalanceModel = nil;
    CJPayChannelBizModel *limitIncomeModel = nil;
    CJPayChannelBizModel *unionBindCardModel = nil;
    
    for (CJPayDefaultChannelShowConfig *channelConfig in [self p_getShouldShowConfigs]) {
        CJPayChannelBizModel *model = [channelConfig toBizModel];
        model.isChooseMethodSubPage = YES;
        model.isIntegerationChooseMethodSubPage = YES;
        CJPayDeskType currentDeskType = [self.orderResponse.deskConfig currentDeskType];
        model.isCombinePayBackToHomePage = currentDeskType == CJPayDeskTypeBytePayHybrid;
        if (currentDeskType == CJPayDeskTypeBytePayHybrid &&
            self.outDefaultConfig.isCombinePay &&
            self.outDefaultConfig.combineType == model.type) { //新版开启组合支付后进入卡列表，隐藏首页已经展示的与银行卡组合的支付方式
            continue;
        }
        model.hasConfirmBtnWhenUnConfirm = YES;
        model.voucherMsgV2Type = CJPayVoucherMsgTypeCardList;
        if ([self.processManager.combineType isEqualToString:@"3"] && model.type == BDPayChannelTypeBalance) {
            model.enable = NO;
            model.showCombinePay = NO;
            model.subTitle = CJPayLocalizedStr(@"超出使用限额");
            limitBalanceModel = model;
        } else if ([self.notSufficientFundsIDs containsObject:channelConfig.cjIdentify]) {
            model.enable = NO;
            model.isConfirmed = NO;
            if (!Check_ValidString(model.reasonStr)) {
                if ([[self.channelDisableReason allKeys] containsObject:channelConfig.cjIdentify]) {
                    NSString *disableReasonStr = [self.channelDisableReason cj_stringValueForKey:channelConfig.cjIdentify];
                    model.reasonStr = disableReasonStr;
                    model.subTitle = disableReasonStr;
                } else {
                    model.reasonStr = CJPayLocalizedStr(@"银行卡余额不足");
                    model.subTitle = CJPayLocalizedStr(@"银行卡余额不足");
                }
            }
            [invalidMethods cj_setObject:model forKey:channelConfig.cjIdentify];
        } else if ([self.processManager.combineType isEqualToString:@"129"] && model.type == BDPayChannelTypeIncomePay) {
            model.enable = NO;
            model.subTitle = CJPayLocalizedStr(@"超出使用限额");
            limitIncomeModel = model;
        } else if (model.isUnionBindCard && [[CJPayKVContext kv_stringForKey:CJPayUnionPayIsUnAvailable] isEqualToString:@"1"]) {
            model.enable = NO;
            model.subTitle = CJPayLocalizedStr(@"无可绑定的银行卡");
            unionBindCardModel = model;
        } else if (model.showCombinePay && model.type == BDPayChannelTypeBalance && self.outDefaultConfig.isCombinePay && self.outDefaultConfig.combineType == BDPayChannelTypeIncomePay) {
            model.enable = NO;
            model.subTitle = CJPayLocalizedStr(@"暂不支持与业务收入组合支付");
            [invalidModels addObject:model];
        } else if (model.showCombinePay && model.type == BDPayChannelTypeIncomePay && self.outDefaultConfig.isCombinePay && self.outDefaultConfig.combineType == BDPayChannelTypeBalance) {
            model.enable = NO;
            model.subTitle = CJPayLocalizedStr(@"暂不支持与零钱组合支付");
            [invalidModels addObject:model];
        } else {
            // 如果余额，也有余额不足的情况，要把该方式提前放
            // 原有：除抖音支付进入不用将零钱余额不足放到最下面，其他都需要。新改动：抖音支付进入切卡页面也将零钱余额不足放到最下面
            if (channelConfig.type == BDPayChannelTypeBalance && ![channelConfig enable]) {
                NSMutableArray *newNotSufficientFundsIDs = [NSMutableArray arrayWithArray:self.notSufficientFundsIDs ?: @[]];
                [newNotSufficientFundsIDs btd_insertObject:channelConfig.cjIdentify atIndex:0];
                self.notSufficientFundsIDs = [newNotSufficientFundsIDs copy];
                
                model.enable = NO;
                [invalidMethods cj_setObject:model forKey:channelConfig.cjIdentify];
            } else {
                //绑卡方式存到bindCardArray中，选中的绑卡方式另存到isChosedModel
                if ([model.channelConfig.subPayType isEqualToString:@"new_bank_card"] && Check_ValidString(model.channelConfig.frontBankCode) && (!model.isConfirmed)) {
                    [bindCardArray btd_addObject:model];
                } else {
                    [array btd_addObject: model];
                }
            }
        }
    }
    [array addObjectsFromArray:bindCardArray];
    
    // 根据余额不足要求重新排序展示卡列表
    for (NSString *cjidentify in self.notSufficientFundsIDs) {
        id object = [invalidMethods cj_objectForKey:cjidentify];
        if (object) {
            [array addObject:object];
        }
    }
    if (limitBalanceModel != nil) {
        [array addObject:limitBalanceModel];
    }
    if (limitIncomeModel != nil) {
        [array addObject:limitIncomeModel];
    }
    if (invalidModels.count > 0) {
        [array addObjectsFromArray:invalidModels];
    }
    if (unionBindCardModel) {
        [array btd_addObject:unionBindCardModel];
    }
    CJPayZoneSplitInfoModel *zoneInfoModel = self.orderResponse.payInfo.bdPay.subPayTypeSumInfo.zoneSplitInfoModel;
    zoneInfoModel.isShowCombineTitle = self.outDefaultConfig.isCombinePay;
    return  [CJPayBizDeskUtil reorderDisableCardsWithMethodArray:array
                                              zoneSplitInfoModel:zoneInfoModel];
}

- (BOOL)p_isHaveDiscount {
    __block BOOL isHaveDiscount = NO;
    [[self p_getShouldShowConfigs] enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.voucherInfo) {
            isHaveDiscount = YES;
            *stop = YES;
        }
    }];
    return isHaveDiscount;
}

#pragma mark - CJPayMethodTableViewDelegate
- (void)didSelectAtIndex:(int)selectIndex {
    self.selectIndex = selectIndex;
    if (selectIndex >= 0 && selectIndex < _payMethodView.models.count) {
        CJPayChannelBizModel *model = [_payMethodView.models cj_objectAtIndex:selectIndex];
        CJPayDefaultChannelShowConfig *selectChannelConfig = model.channelConfig;
        
        NSMutableArray *activityInfos = [NSMutableArray array];
        NSDictionary *infoDict = [selectChannelConfig toActivityInfoTracker];
        if (infoDict.count > 0) {
            [activityInfos addObject:infoDict];
        }
        if (model.type == BDPayChannelTypeCreditPay) {
            [CJPayKVContext kv_setValue:@"1" forKey:CJPayTrackerCommonParamsCreditStage];
        }
        else {
            [CJPayKVContext kv_setValue:@"" forKey:CJPayTrackerCommonParamsCreditStage];
        }
        [self p_trackWithEventName:@"wallet_cashier_choose_method_click" params:@{
            @"activity_info": activityInfos,
            @"method": CJString([CJPayTypeInfo getTrackerMethodByChannelConfig:selectChannelConfig]),
            @"page_type": @(2),
            @"selected_byte_sub_pay" : [self p_subPayInfoTrackerWithShowConfig:selectChannelConfig index:selectIndex] ?: @{},
            @"prev_selected_title": CJString(self.currentSelectedBizModel.title),
            @"curr_selected_title": CJString(model.title),
            @"byte_sub_pay_list": [self p_payMethodInfoTrackList]
        }];
        
        if (!model.enable) {
            return;
        }
        if (model.type == BDPayChannelTypeAddBankCard) {
            CJ_DelayEnableView(self.payMethodView);
            if (self.delegate && [self.delegate respondsToSelector:@selector(bindCard:)]) {
                if (self.outDefaultConfig.isCombinePay) {
                    selectChannelConfig.isCombinePay = YES;
                    selectChannelConfig.combineType = self.outDefaultConfig.combineType;
                }
                [self.delegate bindCard:selectChannelConfig];
            }
            [self p_trackWithEventName:@"wallet_cashier_add_newcard_click" params:@{
                @"from" : @"收银台二级页底部",
                @"activity_info" : activityInfos,
                @"method" : CJString([CJPayTypeInfo getTrackerMethodByChannelConfig:selectChannelConfig]),
                @"addcard_info": CJString(model.title),
            }];
            return;
        }
        if ((model.type == BDPayChannelTypeBalance || model.type == BDPayChannelTypeIncomePay) && model.showCombinePay && !model.isCombinePayBackToHomePage) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(combinePayWithType:)]) {
                [self.delegate combinePayWithType:model.type];
            }
            return;
        }
    
        // 1. 点击添加新卡，直接跳到银行卡列表  2. 点击普通cell，如果是银行卡，且未激活直接跳到激活页面 3. 其他情况视为正确的卡数据，更新选项
        [self p_modifyResponseModelSelectIndexTo:selectIndex];
    }
}
- (void)p_modifyResponseModelSelectIndexTo:(NSInteger) selectIndex{
    if (selectIndex > self.payMethodView.models.count) {
        return;
    }
    CJPayChannelBizModel *bizModel = [_payMethodView.models cj_objectAtIndex:selectIndex];
    CJPayDefaultChannelShowConfig *selectChannelConfig = bizModel.channelConfig;
    if ([selectChannelConfig.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) {
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)selectChannelConfig.payChannel;
        CJPayBytePayCreditPayMethodModel *model = [payChannel.payTypeData.creditPayMethods cj_objectAtIndex:0];
        BOOL hasChoose = NO;
        for (CJPayBytePayCreditPayMethodModel *model in payChannel.payTypeData.creditPayMethods) {
            if (model.choose) {
                hasChoose = YES;
            }
        }
        if (hasChoose == NO && model) {
            model.choose = YES;
            self.creditPayInstallment = @"1";
        }
        payChannel.payTypeData.creditPayInstallment = self.creditPayInstallment;
        if (bizModel.type == BDPayChannelTypeCreditPay) {
            NSArray *activityInfos = [selectChannelConfig toActivityInfoTrackerForCreditPay:self.creditPayInstallment];
            [self p_trackWithEventName:@"wallet_cashier_doustage_click" params:@{
                @"activity_info": Check_ValidArray(activityInfos) ? activityInfos : @[],
                @"fxh_method": CJString(self.creditPayInstallment)
            }];
        }
    }
    self.outDefaultConfig = selectChannelConfig;
    [self p_updatePayMethodView];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(changePayMethodTo:)]) {
        [self.delegate changePayMethodTo:selectChannelConfig];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [super back]; // 这里用super调用，不走复写后的弹窗逻辑了
        });
    }
}

#pragma mark - getter & setter

- (CJPayNotSufficientFundsView *)notSufficientFundsView {
    if (!_notSufficientFundsView) {
        _notSufficientFundsView = [CJPayNotSufficientFundsView new];
    }
    return _notSufficientFundsView;
}

- (CJPayPaddingLabel *)voucherTipLabel {
    if (!_voucherTipLabel) {
        _voucherTipLabel = [CJPayPaddingLabel new];
        _voucherTipLabel.textInsets = UIEdgeInsetsMake(0, 16, 0, 0);
        _voucherTipLabel.font = [UIFont cj_fontOfSize:12];
        _voucherTipLabel.adjustsFontSizeToFitWidth = YES;
        _voucherTipLabel.textColor = [UIColor cj_ff6f28WithAlpha:1.0];
        _voucherTipLabel.backgroundColor = [UIColor cj_ff6f28WithAlpha:0.1];
    }
    return _voucherTipLabel;
}

- (void)setIconTips:(CJPaySubPayTypeIconTipModel *)iconTips {
    _iconTips = iconTips;
    self.notSufficientFundsView.iconImgView.hidden = !iconTips;
    if (iconTips) {
        self.notSufficientFundsView.hidden = NO;
        @CJWeakify(self)
        self.notSufficientFundsView.iconClickBlock = ^{
            @CJStrongify(self)
            CJPayInComePayAlertContentView *alertContentView = [[CJPayInComePayAlertContentView alloc] initWithIconTips:iconTips];
            CJPayDyTextPopUpModel *model = [CJPayDyTextPopUpModel new];
            model.type = CJPayTextPopUpTypeDefault;
            CJPayDyTextPopUpViewController *alertVC = [[CJPayDyTextPopUpViewController alloc] initWithPopUpModel:model contentView:alertContentView];
            [alertVC showOnTopVC:self];
        };
    }
    
    [self.notSufficientFundsView updateTitle:Check_ValidString(iconTips.title) ? iconTips.title : CJPayLocalizedStr(@"支付方式暂不可用，请更换支付方式")];
}

- (void)setShowNotSufficientFundsHeaderLabel:(BOOL)showNotSufficientFundsHeaderLabel {
    _showNotSufficientFundsHeaderLabel = showNotSufficientFundsHeaderLabel;
    self.notSufficientViewHeightConstraint.offset = self.showNotSufficientFundsHeaderLabel ? self.notSufficientFunsSize.height : 0;
    self.payMethodViewTopBaseNotSufficientViewConstraint.offset = self.showNotSufficientFundsHeaderLabel ? 0 : 8;
}

- (NSDictionary *)commonTrackerParams {
    return [self.processManager buildCommonTrackDic:@{}];
}

#pragma mark - tracker

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:self.commonTrackerParams];
    [mutableDic addEntriesFromDictionary:params];
    [CJTracker event:eventName params:mutableDic];
}

- (void)p_tracker
{
    NSMutableArray *channels = [NSMutableArray new];
    
    for (CJPayChannelBizModel *model in _payMethodView.models) {
        [channels addObject:CJString(model.title)];
    }
    NSString *bank_list = [channels componentsJoinedByString:@","];
    
    NSArray *showConfigs = [self p_getShouldShowConfigs];
    NSMutableArray *campaignInfos = [NSMutableArray array];
    NSMutableArray *methodLists = [NSMutableArray array];
    [showConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj toActivityInfoTracker].count > 0) {
            [campaignInfos addObject:[obj toActivityInfoTracker]];
        }
        if ([obj toActivityInfoTrackerForCreditPay].count > 0) {
            [campaignInfos addObjectsFromArray:[obj toActivityInfoTrackerForCreditPay]];
        }
        if ([obj toMethodInfoTracker].count > 0) {
            [methodLists addObject:[obj toMethodInfoTracker]];
        }
    }];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"bank_list" : CJString(bank_list),
        @"campaign_info" : campaignInfos,
        @"all_method_list": methodLists,
        @"byte_sub_pay_list": [self p_payMethodInfoTrackList]
    }];
    if (self.showNotSufficientFundsHeaderLabel) {
        [params cj_setObject:@"1" forKey:@"error_info"];
    }
    [params cj_setObject:self.orderResponse.payInfo.bdPay.subPayTypeSumInfo.subPayTypePageSubtitle forKey:@"byte_title"];
    [self p_trackWithEventName:@"wallet_cashier_method_page_imp" params:params];
}

- (NSArray *)p_payMethodInfoTrackList {
    NSArray *showConfigs = [self p_getShouldShowConfigs];
    NSMutableArray *subPayMethodLists = [NSMutableArray array];
    [showConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [subPayMethodLists btd_addObject:[self p_subPayInfoTrackerWithShowConfig:obj index:idx]];
    }];
    return [subPayMethodLists copy];
}

- (NSMutableDictionary *)p_subPayInfoTrackerWithShowConfig:(CJPayDefaultChannelShowConfig *)config index:(NSUInteger)index {
    NSMutableDictionary *dict = [[config toSubPayMethodInfoTrackerDic] mutableCopy];
    [dict cj_setObject:@(index) forKey:@"index"];
    return [dict copy];
}

@end
