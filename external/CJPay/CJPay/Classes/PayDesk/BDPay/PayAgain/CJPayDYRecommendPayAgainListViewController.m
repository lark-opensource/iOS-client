//
//  CJPayDYRecommendPayAgainListViewController.m
//  Pods
//
//  Created by wangxiaohong on 2022/3/24.
//

#import "CJPayDYRecommendPayAgainListViewController.h"

#import "CJPayBDMethodTableView.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayChannelBizModel.h"

@interface CJPayDYRecommendPayAgainListViewController ()<CJCJPayBDMethodTableViewDelegate>

@property (nonatomic, strong) CJPayBDMethodTableView *payMethodView;

@end

@implementation CJPayDYRecommendPayAgainListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    
    [self p_trackerWithEventName:@"wallet_cashier_method_page_imp" params:@{}];
}

- (void)p_setupUI
{
    [self.navigationBar setTitle:CJPayLocalizedStr(@"选择支付方式")];
    [self.contentView addSubview:self.payMethodView];
    CJPayMasReMaker(self.payMethodView, {
        make.edges.equalTo(self.contentView);
        make.bottom.right.left.equalTo(self.contentView);
    });
    [self p_updatePayMethodView];
}

- (NSArray *)p_buildPayMethodModels {
    
    //展示顺序 可用卡 - 营销活动卡 - 添加新卡 - 余额不足卡(如果余额支付余额不足需要提前) - 不可用普通卡
    NSMutableArray *availableModels = [NSMutableArray array];
    NSMutableArray *disableModels = [NSMutableArray array];
    NSMutableArray *unAvailableModels = [NSMutableArray array];
    CJPayChannelBizModel *balanceNotSufficientModel;
    
    for (CJPayDefaultChannelShowConfig *channelConfig in [self.createResponse.payTypeInfo allPayChannels]) {
        CJPayChannelBizModel *model = [channelConfig toBizModel];
        model.hasConfirmBtnWhenUnConfirm = NO;
        model.isDYRecommendPayAgain = YES;
        if ([channelConfig.cjIdentify isEqualToString:self.outerRecommendShowConfig.cjIdentify]) { //置顶外部推荐的支付方式
            [availableModels btd_insertObject:model atIndex:0];
        } else if ([self.payDisabledFundID2ReasonMap.allKeys containsObject:channelConfig.cjIdentify]) { //银行卡余额不足
            model.enable = NO;
            model.reasonStr = [self.payDisabledFundID2ReasonMap cj_stringValueForKey:channelConfig.cjIdentify];
            [disableModels btd_addObject:model];
        } else if (channelConfig.type == BDPayChannelTypeBalance && ![channelConfig enable]) {
            model.enable = NO;
            balanceNotSufficientModel = model;
        } else { //普通卡
            if ([model enable]) {
                [availableModels btd_addObject:model];
            } else {
                [unAvailableModels btd_addObject:model];
            }
        }
    }
    
    NSMutableArray *resultModels = [NSMutableArray arrayWithArray:availableModels];
    
    if ([self.createResponse.payTypeInfo.quickPay.status isEqualToString:@"1"]) {
        [resultModels btd_addObject:[self p_createAddBankCardBizModel]];
    }
    
    if (balanceNotSufficientModel) {  //如果余额，也有余额不足的情况，要把该方式提前放
        [resultModels btd_addObject:balanceNotSufficientModel];
    }
    [resultModels addObjectsFromArray:disableModels];
    
    [resultModels addObjectsFromArray:unAvailableModels];
    
    return resultModels;
}

- (CJPayChannelBizModel *)p_createAddBankCardBizModel
{
    CJPayDefaultChannelShowConfig *addCardShowConfig = [CJPayDefaultChannelShowConfig new];
    addCardShowConfig.title = CJPayLocalizedStr(@"添加新卡支付");
    addCardShowConfig.type = BDPayChannelTypeAddBankCard;
    addCardShowConfig.iconUrl = @"";
    addCardShowConfig.status = @"1";
    
    CJPayChannelBizModel *addBankCard = [addCardShowConfig toBizModel];
    addBankCard.isDYRecommendPayAgain = YES;
    return addBankCard;
}


- (void)p_updatePayMethodView {
    self.payMethodView.models = [self p_buildPayMethodModels];
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    if (!self.delegate || ![self.delegate respondsToSelector:@selector(trackWithEventName:params:)]) {
        return;
    }
    [self.delegate trackWithEventName:eventName params:params];
}

#pragma mark - CJCJPayBDMethodTableViewDelegate

- (void)didSelectAtIndex:(int)selectIndex {
    if (selectIndex < 0 || selectIndex >= self.payMethodView.models.count) {
        return;
    }
    id selectedModel = [_payMethodView.models cj_objectAtIndex:selectIndex];
    if (![selectedModel isKindOfClass:CJPayChannelBizModel.class]) {
        return;
    }
    CJPayChannelBizModel *model = (CJPayChannelBizModel *)selectedModel;
    if (!model.enable) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(didClickPayMethod:)]) {
        [self.delegate didClickPayMethod:model.channelConfig];
        [self p_trackerWithEventName:@"wallet_cashier_confirm_click" params:@{}];
        if (model.type == BDPayChannelTypeAddBankCard) {
            [self p_trackerWithEventName:@"wallet_cashier_add_newcard_click" params:@{}];
        }
    }
}

#pragma mark - Lazy Views

- (CJPayBDMethodTableView *)payMethodView
{
    if (!_payMethodView) {
        _payMethodView = [[CJPayBDMethodTableView alloc] init];
        _payMethodView.delegate = self;
    }
    return _payMethodView;
}

@end
