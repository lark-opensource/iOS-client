//
//  CJPayDYChoosePayMethodViewController.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/18.
//

#import "CJPayDYChoosePayMethodViewController.h"
#import "CJPayBDMethodTableView.h"
#import "CJPayWebViewUtil.h"
#import "CJPayUIMacro.h"
#import "CJPayTracker.h"
#import "CJPayChannelModel.h"
#import "CJPayBindCardManager.h"
#import "CJPayNotSufficientFundsView.h"
#import "CJPayBindCardResultModel.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPayChannelBizModel.h"
#import "CJPayAlertUtil.h"

@interface CJPayDYChoosePayMethodViewController ()<CJCJPayBDMethodTableViewDelegate>

@property (nonatomic, strong) CJPayNotSufficientFundsView *notSufficientFundsView;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *outDefaultConfig;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *orderResponse;

@property (nonatomic, assign) BOOL isFromCombinedPay;
@property (nonatomic, copy) CJPayDYSelectPayMethodCompletion selectPayMethodCompletion;

@end

@implementation CJPayDYChoosePayMethodViewController

- (instancetype)initWithOrderResponse:(CJPayBDCreateOrderResponse *)response
                        defaultConfig:(CJPayDefaultChannelShowConfig *)config
                          combinedPay:(BOOL)isFromCombinedPay
            selectPayMethodCompletion:(nullable CJPayDYSelectPayMethodCompletion)completion {
    self = [super init];
    if (self) {
        self.orderResponse = response;
        self.outDefaultConfig = config;
        self.isSupportClickMaskBack = NO;
        self.selectPayMethodCompletion = completion;
        self.isFromCombinedPay = isFromCombinedPay;
    }
    return self;
}

- (void)back {
    [self.queen trackCashierWithEventName:@"wallet_cashier_choose_method_close"
                                   params:@{
                                            @"page_type": self.isFromCombinedPay ? @(3) : @(2)
                                          }];
    
    if (self.showNotSufficientFundsHeaderLabel) {
        [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"确定退出支付") content:nil leftButtonDesc:CJPayLocalizedStr(@"取消") rightButtonDesc:CJPayLocalizedStr(@"退出") leftActionBlock:nil rightActioBlock:^{
            if ([self.delegate respondsToSelector:@selector(closeDesk)]) {
                [self.delegate closeDesk];
            }
        } useVC:self];
    } else {
        [super back];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)p_setupUI
{
    if (self.isFromCombinedPay) {
        [self.navigationBar setTitle:CJPayLocalizedStr(@"选择与零钱组合的支付方式")];
    } else {
        [self.navigationBar setTitle:CJPayLocalizedStr(@"选择支付方式")];
    }
    NSUInteger topY = 0;
    if (self.showNotSufficientFundsHeaderLabel) {
        [self.contentView addSubview:self.notSufficientFundsView];
        CGSize notSufficientFunsSize = [self.notSufficientFundsView calSize];
        self.notSufficientFundsView.frame = CGRectMake(0, 0, notSufficientFunsSize.width, notSufficientFunsSize.height);
        topY = self.notSufficientFundsView.cj_bottom;
        if (@available(iOS 13.0, *)) {
            self.modalInPresentation = CJ_Pad;
        } else {
            // Fallback on earlier versions
        }
    }
    [self.contentView addSubview:self.payMethodView];
    CJPayMasReMaker(self.payMethodView, {
        make.top.equalTo(self.contentView).offset(topY);
        make.bottom.right.left.equalTo(self.contentView);
    });
    [self p_updatePayMethodView];
}

- (CJPayChannelBizModel *)p_createDiscountModelWithQuickPayCardModel:(CJPayQuickPayCardModel *)quickPayModel
{
    CJPayChannelBizModel *newCardBizModel = [CJPayChannelBizModel new];
    newCardBizModel.type = CJPayChannelTypeUnBindBankCard;
    newCardBizModel.title = [NSString stringWithFormat:@"%@%@", CJString(quickPayModel.frontBankCodeName), CJString(quickPayModel.cardTypeName)];
    newCardBizModel.iconUrl = quickPayModel.iconUrl;
    newCardBizModel.enable = YES;
    return newCardBizModel;
}

- (CJPayChannelBizModel *)p_createAddBankCardBizModel
{
    CJPayChannelBizModel *addBankCard = [CJPayChannelBizModel new];
    addBankCard.type = BDPayChannelTypeAddBankCard;
    addBankCard.isConfirmed = NO;
    addBankCard.title = CJPayLocalizedStr(@"添加新卡支付");
    addBankCard.iconUrl = @"";
    addBankCard.enable = YES;
    return addBankCard;
}

- (NSArray *)p_buildPayMethodModels {
    
    //展示顺序 可用卡 - 营销活动卡 - 添加新卡 - 余额不足卡(如果余额支付余额不足需要提前) - 不可用普通卡
    NSMutableArray *availableModels = [NSMutableArray array];
    NSMutableArray *notSufficientModels = [NSMutableArray array];
    NSMutableArray *unAvailableModels = [NSMutableArray array];
    CJPayChannelBizModel *balanceNotSufficientModel;
    
    for (CJPayDefaultChannelShowConfig *channelConfig in [self.orderResponse.payTypeInfo allPayChannels]) {
        if (self.isFromCombinedPay && channelConfig.type == BDPayChannelTypeBalance) {
            continue;
        }
        if ([channelConfig isEqual:self.outDefaultConfig]) {
            channelConfig.isSelected = YES;
        } else {
            channelConfig.isSelected = NO;
        }
        CJPayChannelBizModel *model = [channelConfig toBizModel];
        model.hasConfirmBtnWhenUnConfirm = NO;
        if ([self.notSufficientFundsIDs containsObject:channelConfig.cjIdentify]) { //银行卡余额不足
            model.enable = NO;
            model.reasonStr = CJPayLocalizedStr(@"银行卡可用余额不足");
            [notSufficientModels addObject:model];
        } else if (channelConfig.type == BDPayChannelTypeBalance && (![channelConfig enable] || (channelConfig.showCombinePay && self.showNotSufficientFundsHeaderLabel && [channelConfig enable]))){
            // 二次支付不展示组合支付能力
            model.enable = NO;
            balanceNotSufficientModel = model;
        } else { //普通卡
            if ([model enable]) {
                [availableModels addObject:model];
            } else {
                [unAvailableModels addObject:model];
            }
        }
    }
    
    NSMutableArray *resultModels = [NSMutableArray arrayWithArray:availableModels];
    
    // 未绑定卡的营销活动model列表在此插入
    [self.orderResponse.payTypeInfo.quickPay.discountBanks enumerateObjectsUsingBlock:^(CJPayQuickPayCardModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [resultModels addObject:[self p_createDiscountModelWithQuickPayCardModel:obj]];
    }];
    
    if ([self.orderResponse.payTypeInfo.quickPay.status isEqualToString:@"1"]) {
        [resultModels addObject:[self p_createAddBankCardBizModel]];
    }
    
    if (balanceNotSufficientModel) {  //如果余额，也有余额不足的情况，要把该方式提前放
        [resultModels addObject:balanceNotSufficientModel];
    }
    [resultModels addObjectsFromArray:notSufficientModels];
    
    [resultModels addObjectsFromArray:unAvailableModels];
    
    return resultModels;
}

- (void)p_updatePayMethodView {
    self.payMethodView.models = [self p_buildPayMethodModels];
}

// 绑卡并支付
- (void)p_bindCardAndPay {
    
    if ([self.orderResponse.payTypeInfo.quickPay.enableBindCard isEqualToString:@"0"]) { // 绑定银行卡不可用，弹出服务端配置的文案
        NSString *toastContent = self.orderResponse.payTypeInfo.quickPay.enableBindCardMsg;
        if (toastContent == nil || toastContent.length < 1) {
            toastContent = CJPayLocalizedStr(@"添加银行卡已达上限");
        }
        [CJToast toastText:toastContent inWindow:self.cj_window];
        return;
    }
    [self p_nativeBindCardAndPay];
}

// native绑卡并支付流程
- (void)p_nativeBindCardAndPay {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bindCardAndPay)]) {
        [self.delegate bindCardAndPay];
    }
}

- (void)p_modifyResponseModelSelectIndexTo:(int) selectIndex{
    if (selectIndex > self.payMethodView.models.count) {
        return;
    }
    CJPayChannelBizModel *bizModel = [_payMethodView.models cj_objectAtIndex:selectIndex];
    CJPayDefaultChannelShowConfig *selectChannelConfig = bizModel.channelConfig;
    self.outDefaultConfig = selectChannelConfig;
    [self p_updatePayMethodView];
    
    if (self.selectPayMethodCompletion) { //需要自己处理回退逻辑
        self.selectPayMethodCompletion(selectChannelConfig);
    } else if (self.delegate && [self.delegate respondsToSelector:@selector(changePayMethodTo:)]) {
        [self.delegate changePayMethodTo:selectChannelConfig];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [super back]; // 这里用super调用，不走复写后的弹窗逻辑了
        });
    }
}

#pragma mark - CJCJPayBDMethodTableViewDelegate

- (void)didSelectAtIndex:(int)selectIndex{
    [self.queen trackCashierWithEventName:@"wallet_cashier_choose_method_click"
                                   params:@{
                                            @"page_type": self.isFromCombinedPay ? @(3) : @(2)
                                          }];
    
    if (selectIndex >= 0 && selectIndex < _payMethodView.models.count) {
        CJPayChannelBizModel *model = [_payMethodView.models cj_objectAtIndex:selectIndex];
        
        if (!model.enable) {
            return;
        }
        
        if (self.isFromCombinedPay) {
            [self p_modifyResponseModelSelectIndexTo:selectIndex];
            return;
        }
        
        // 1. 点击添加新卡，直接跳到银行卡列表 2. 其他情况视为正确的卡数据，更新选项
        if (model.type == BDPayChannelTypeAddBankCard || model.type == CJPayChannelTypeUnBindBankCard) {
            // 绑卡并支付
            [self p_bindCardAndPay];
        } else {
            [self p_modifyResponseModelSelectIndexTo:selectIndex];
        }
    }
}

#pragma mark - lazy View

- (CJPayBDMethodTableView *)payMethodView
{
    if (!_payMethodView) {
        CGFloat tableHeight = self.contentView.cj_height;
        if (CJ_IPhoneX) {
            tableHeight -= 34;
        }
        _payMethodView = [[CJPayBDMethodTableView alloc] init];
        _payMethodView.delegate = self;
    }
    return _payMethodView;
}

- (CJPayNotSufficientFundsView *)notSufficientFundsView {
    if (!_notSufficientFundsView) {
        _notSufficientFundsView = [CJPayNotSufficientFundsView new];
    }
    return _notSufficientFundsView;
}

@end
