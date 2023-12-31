//
//  CJPayFrontCardListViewController.m
//  CJPay
//
//  Created by wangxiaohong on 2020/3/12.
//

#import "CJPayFrontCardListViewController.h"
#import "CJPayBDMethodTableView.h"
#import "CJPayNotSufficientFundsView.h"
#import "CJPayBDTypeInfo.h"
#import "CJPayBindCardManager.h"
#import "CJPayMerchantInfo.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayMemBankInfoModel.h"
#import "CJPayLoadingButton.h"
#import "CJPayBDCreateOrderRequest.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPayChannelBizModel.h"
#import "CJPayAlertUtil.h"
#import "CJPayToast.h"
#import "CJPaySettingsManager.h"
#import "CJPayBalancePromotionModel.h"
#import "CJPayUIMacro.h"

@interface CJPayFrontCardListViewController()<CJCJPayBDMethodTableViewDelegate>

@property (nonatomic, strong) CJPayNotSufficientFundsView *notSufficientFundsView;
@property (nonatomic, strong) CJPayBDMethodTableView *payMethodView;
@property (nonatomic, strong) BDChooseCardCommonModel *commonModel;
@property (nonatomic, assign) BOOL showBottomAddCardBtn;
@property (nonatomic, strong) CJPayLoadingButton *bottomAddCardBtn;
@property (nonatomic, strong) UIView *bottomAddCardBtnBackView;

@end

@implementation CJPayFrontCardListViewController

+ (void)showVCWithCommonModel:(BDChooseCardCommonModel *)commonModel {
    CJPayFrontCardListViewController *cardListVC = [[CJPayFrontCardListViewController alloc] initWithCardCommonModel:commonModel];
        cardListVC.isSupportClickMaskBack = YES;
    [cardListVC useCloseBackBtn];
    
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:commonModel.fromVC];

    if (![topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        cardListVC.animationType = HalfVCEntranceTypeFromBottom;
        if (!CJ_Pad) {
            [cardListVC useCloseBackBtn];
        }
        [cardListVC presentWithNavigationControllerFrom:topVC useMask:NO completion:nil];
        return;
    }
    
    __block NSUInteger lastHalfScreenIndex = NSNotFound;
    [topVC.navigationController.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController * _Nonnull vc, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            lastHalfScreenIndex = idx;
            *stop = YES;
        }
    }];

    if (lastHalfScreenIndex < topVC.navigationController.viewControllers.count - 1) {
        NSMutableArray *vcStack = [topVC.navigationController.viewControllers mutableCopy];
        [cardListVC showMask:NO];
        cardListVC.animationType = HalfVCEntranceTypeFromRight;
        [vcStack insertObject:cardListVC atIndex:lastHalfScreenIndex];
        topVC.navigationController.viewControllers = [vcStack copy];
        [topVC.navigationController popToViewController:cardListVC animated:YES];
    } else {
        if (!CJ_Pad) {
            cardListVC.animationType = HalfVCEntranceTypeFromBottom;
            [cardListVC showMask:YES];
            [cardListVC useCloseBackBtn];
        }
        [topVC.navigationController pushViewController:cardListVC animated:YES];
    }
}

- (instancetype)initWithCardCommonModel:(BDChooseCardCommonModel *)cardCommonModel
{
    self = [super init];
    if (self) {
        self.isSupportClickMaskBack = NO;
        [self showMask:YES];
        _commonModel = cardCommonModel;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isSupportClickMaskBack = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.showBottomAddCardBtn = YES;
    for (CJPayDefaultChannelShowConfig * channel in [self.commonModel.orderResponse.payTypeInfo allPayChannels]) {
        if (channel.enable) {
            self.showBottomAddCardBtn = NO;
            break;
        }
    }
    [self p_setupUI];
    [self p_updatePayMethodView];
    
    [self p_tracker];
}

- (void)p_tracker
{
    if (self.commonModel.comeFromSceneType == CJPayComeFromSceneTypeBalanceWithdraw) {
        [self p_trackerWithEventName:@"wallet_tixian_cardselect_imp" params:@{}];
    }
}

- (void)p_setupUI
{
    if (self.commonModel.comeFromSceneType == CJPayComeFromSceneTypeBalanceWithdraw){
        [self.navigationBar setTitle:CJPayLocalizedStr(@"选择到账银行卡")];
    }else{
        [self.navigationBar setTitle:CJPayLocalizedStr(@"选择充值方式")];
    }
    
    NSUInteger topY = 0;
    if (self.commonModel.notSufficientFundsIDs.count > 0 && self.commonModel.hasSfficientBlockBack) {
        [self.contentView addSubview:self.notSufficientFundsView];
        CGSize notSufficientFunsSize = [self.notSufficientFundsView calSize];
        CJPayMasMaker(self.notSufficientFundsView, {
            make.left.top.width.equalTo(self.contentView);
            make.height.equalTo(@(notSufficientFunsSize.height));
        });
        topY = notSufficientFunsSize.height;
        if (@available(iOS 13.0, *)) {
            self.modalInPresentation = CJ_Pad;
        } else {
            // Fallback on earlier versions
        }
    }
    [self.contentView addSubview:self.payMethodView];
    CJPayMasMaker(self.payMethodView, {
        make.left.right.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(topY);
        CGFloat offsetBottom = CJ_IPhoneX ? 34 : 0;
        if (self.showBottomAddCardBtn) {
            offsetBottom += 72;
        }
        make.bottom.equalTo(self.contentView).offset(-offsetBottom);
    });
    
    if (self.showBottomAddCardBtn) {
        [self.contentView addSubview:self.bottomAddCardBtnBackView];
        CJPayMasMaker(self.bottomAddCardBtnBackView, {
            make.left.right.bottom.equalTo(self.contentView);
            make.height.mas_equalTo(72 + (CJ_IPhoneX ? 34 : 0));
        });
        [self.bottomAddCardBtnBackView addSubview:self.bottomAddCardBtn];
        CJPayMasMaker(self.bottomAddCardBtn, {
            make.left.equalTo(self.bottomAddCardBtnBackView).offset(16);
            make.right.equalTo(self.bottomAddCardBtnBackView).offset(-16);
            make.top.equalTo(self.bottomAddCardBtnBackView).offset(12);
            make.height.mas_equalTo(48);
        });
    }
}

- (void)p_updatePayMethodView {
    self.payMethodView.models = [self p_buildPayMethodModels];
}

- (NSArray *)p_buildPayMethodModels {
    //展示顺序 可用卡 - 添加新卡 - 余额不足卡 - 不可用卡
    NSMutableArray *availableModels = [NSMutableArray array];
    NSMutableArray *notSufficientModels = [NSMutableArray array];
    NSMutableArray *unAvailableModels = [NSMutableArray array];
    
    for (CJPayQuickPayCardModel *card in self.commonModel.orderResponse.payTypeInfo.quickPay.cards) {
        card.comeFromSceneType = self.commonModel.comeFromSceneType;
        CJPayDefaultChannelShowConfig *showConfig = [card buildShowConfig].firstObject;
        showConfig.isSelected = [showConfig isEqual:self.commonModel.defaultConfig];
        showConfig.comeFromSceneType = self.commonModel.comeFromSceneType;
        CJPayChannelBizModel *bizModel = [showConfig toBizModel];
        bizModel.type = CJPayChannelTypeFrontCardList;
        bizModel.hasConfirmBtnWhenUnConfirm = NO;
        if ([self.commonModel.notSufficientFundsIDs containsObject:showConfig.cjIdentify]) {
            bizModel.enable = NO;
            if (!Check_ValidString(bizModel.reasonStr)) {
                bizModel.reasonStr = CJPayLocalizedStr(@"银行卡可用余额不足");
            }
            [notSufficientModels addObject:bizModel];
        } else {
            if ([bizModel enable]) {
                [availableModels addObject:bizModel];
            } else {
                [unAvailableModels addObject:bizModel];
            }
        }
    }
    
    NSMutableArray *resultModels = [NSMutableArray arrayWithArray:availableModels];
    
    if ([self.commonModel.orderResponse.payTypeInfo.quickPay.status isEqualToString:@"1"] && !self.showBottomAddCardBtn) {
        [resultModels addObject:[self p_createAddBankCardBizModel]];
    }
    
    [resultModels addObjectsFromArray:notSufficientModels];
    [resultModels addObjectsFromArray:unAvailableModels];
    
    return resultModels;
}

- (CJPayChannelBizModel *)p_createAddBankCardBizModel
{
    CJPayChannelBizModel *addBankCard = [CJPayChannelBizModel new];
    addBankCard.type = BDPayChannelTypeFrontAddBankCard;
    addBankCard.isConfirmed = NO;
    if (self.commonModel.comeFromSceneType == CJPayComeFromSceneTypeBalanceWithdraw){
        addBankCard.title = CJPayLocalizedStr(@"添加新卡提现");
    } else if (self.commonModel.comeFromSceneType == CJPayComeFromSceneTypeBalanceRecharge){
        addBankCard.title = CJPayLocalizedStr(@"添加新卡充值");
    } else {
        addBankCard.title = CJPayLocalizedStr(@"添加新卡");
    }
    
    addBankCard.iconUrl = @"";
    addBankCard.enable = YES;
    addBankCard.rightDiscountStr = CJString(self.commonModel.orderResponse.balancePromotionModel.promotionDescription);
    return addBankCard;
}

#pragma mark - CJCJPayBDMethodTableViewDelegate
// 绑卡
- (void)p_bindCard:(void(^)(void))finishLoadingBlock {
    if ([self.commonModel.orderResponse.payTypeInfo.quickPay.enableBindCard isEqualToString:@"0"]) { // 绑定银行卡不可用，弹出服务端配置的文案
        NSString *toastContent = self.commonModel.orderResponse.payTypeInfo.quickPay.enableBindCardMsg;
        if (toastContent == nil || toastContent.length < 1) {
            toastContent = CJPayLocalizedStr(@"添加银行卡已达上限");
        }
        [CJToast toastText:toastContent inWindow:self.cj_window];
        return;
    }
    
    CJ_CALL_BLOCK(self.commonModel.bindCardBlock, finishLoadingBlock);
}

- (void)didSelectAtIndex:(int)selectIndex {
    if (self.commonModel.comeFromSceneType == CJPayComeFromSceneTypeBalanceWithdraw) {
        [self p_trackerWithEventName:@"wallet_tixian_cardselect_click" params:@{}];
    }
    
    if (selectIndex > self.payMethodView.models.count) {
        return;
    }
    
    CJPayChannelBizModel *model = [_payMethodView.models cj_objectAtIndex:selectIndex];
    if (!model.enable) {
        return;
    }
    
    if (model.type == BDPayChannelTypeFrontAddBankCard) {
        CJ_DelayEnableView(self.view);
        @CJWeakify(self)
        if (self.commonModel.comeFromSceneType == CJPayComeFromSceneTypeBalanceWithdraw) {
            [self p_trackerWithEventName:@"wallet_tixian_cardselect_addbcard" params:@{@"from": @"收银台二级页底部"}];
        } else if (self.commonModel.comeFromSceneType == CJPayComeFromSceneTypeBalanceRecharge) {
            [self p_trackerWithEventName:@"wallet_change_cashier_add_newcard_click" params:@{@"from": @"收银台二级页底部"}];
        }
        [self.payMethodView startLoadingAnimationOnAddBankCardCell];
        [self p_bindCard:^{
            [weak_self.payMethodView stopLoadingAnimationOnAddBankCardCell];
        }];
    } else if (model.type == CJPayChannelTypeFrontCardList) {
        [self p_modifySelectedModel:model];
        CJ_DelayEnableView(self.payMethodView);
    }
}

- (void)back
{
    [self p_trackerWithEventName:@"wallet_tixian_cardselect_close" params:@{}];
    if (self.commonModel.notSufficientFundsIDs.count > 0 && self.commonModel.hasSfficientBlockBack) {
        [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"确定退出支付") content:nil leftButtonDesc:CJPayLocalizedStr(@"取消") rightButtonDesc:CJPayLocalizedStr(@"退出") leftActionBlock:nil rightActioBlock:^{
            CJ_CALL_BLOCK(self.commonModel.backToMainVCBlock);
        } useVC:self];
    } else {
        @CJWeakify(self);
        [super closeWithAnimation:YES comletion:^(BOOL isFinish) {
            @CJStrongify(self);
            CJPayChooseCardResultModel *model = [CJPayChooseCardResultModel new];
            model.isCancel = YES;
            model.isNewCard = NO;
            CJ_CALL_BLOCK(self.commonModel.chooseCardCompletion, model);
        }];
    }
}

- (void)p_modifySelectedModel:(CJPayChannelBizModel *)model {
    CJPayDefaultChannelShowConfig *selectChannelConfig = model.channelConfig;
    self.commonModel.defaultConfig = selectChannelConfig;
    [self p_updatePayMethodView];
    CJPayChooseCardResultModel *resultModel = [CJPayChooseCardResultModel new];
    resultModel.isCancel = NO;
    resultModel.isNewCard = NO;
    resultModel.config = selectChannelConfig;
    CJ_CALL_BLOCK(self.commonModel.chooseCardCompletion, resultModel);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [super back];
    });
}

- (void)bindCardClick {
    @CJStartLoading(self.bottomAddCardBtn)
    @CJWeakify(self)
    [self p_bindCard:^{
        @CJStopLoading(weak_self.bottomAddCardBtn)
    }];
    
    if (self.commonModel.comeFromSceneType == CJPayComeFromSceneTypeBalanceWithdraw) {
        [self p_trackerWithEventName:@"wallet_tixian_cardselect_addbcard" params:@{@"from": @"收银台二级页底部"}];
    } else if (self.commonModel.comeFromSceneType == CJPayComeFromSceneTypeBalanceRecharge) {
        [self p_trackerWithEventName:@"wallet_change_cashier_add_newcard_click" params:@{@"from": @"收银台二级页底部"}];
    }
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params
{
    NSMutableDictionary *baseParams = [self.commonModel.trackerParams mutableCopy];
    [baseParams addEntriesFromDictionary:@{
        @"card_number": @([self p_buildPayMethodModels].count - 1),
        @"if_quickpay" : [self p_buildPayMethodModels].count > 1 ? @"1" : @"0",
    }];
    [baseParams addEntriesFromDictionary:params];
    [CJTracker event:eventName params:[baseParams copy]];
}

#pragma mark - lazy View

- (CJPayLoadingButton *)bottomAddCardBtn {
    if (!_bottomAddCardBtn) {
        _bottomAddCardBtn = [CJPayLoadingButton new];
        _bottomAddCardBtn.disablesInteractionWhenLoading = NO;
        if (self.commonModel.comeFromSceneType == CJPayComeFromSceneTypeBalanceWithdraw){
            [_bottomAddCardBtn setTitle:CJPayLocalizedStr(@"添加新卡提现") forState:UIControlStateNormal];
        }else{
            [_bottomAddCardBtn setTitle:CJPayLocalizedStr(@"添加新卡") forState:UIControlStateNormal];
        }
        [_bottomAddCardBtn addTarget:self action:@selector(bindCardClick) forControlEvents:UIControlEventTouchUpInside];
        _bottomAddCardBtn.cjEventInterval = 1;
        [_bottomAddCardBtn cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        _bottomAddCardBtn.layer.cornerRadius = 5;
        _bottomAddCardBtn.clipsToBounds = YES;
    }
    return _bottomAddCardBtn;
}

- (UIView *)bottomAddCardBtnBackView {
    if (!_bottomAddCardBtnBackView) {
        _bottomAddCardBtnBackView = [UIView new];
        _bottomAddCardBtnBackView.backgroundColor = UIColor.whiteColor;
    }
    return _bottomAddCardBtnBackView;
}

- (CJPayBDMethodTableView *)payMethodView
{
    if (!_payMethodView) {
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
