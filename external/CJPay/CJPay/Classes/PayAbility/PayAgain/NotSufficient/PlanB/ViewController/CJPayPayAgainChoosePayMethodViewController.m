//
//  CJPayPayAgainChoosePayMethodViewController.m
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import "CJPayPayAgainChoosePayMethodViewController.h"

#import "CJPayBytePayMethodView.h"
#import "CJPaySDKMacro.h"
#import "CJPayIntegratedChannelModel.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayUIMacro.h"

@interface CJPayPayAgainChoosePayMethodViewController ()<CJPayMethodTableViewDelegate>

@property (nonatomic, strong) CJPayBytePayMethodView *payMethodView;
@property (nonatomic, strong) CJPayIntegratedChannelModel *cardListModel;

@property (nonatomic, strong) UITableViewCell *currentSelectedCell;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *currentChannelShowConfig;
@property (nonatomic, assign, readwrite) BOOL isCombinePay;
@property (nonatomic, assign) CJPayChannelType combineType;

@end

@implementation CJPayPayAgainChoosePayMethodViewController

- (instancetype)initWithEcommerceViewModel:(CJPayPayAgainViewModel *)viewModel {
    self = [super init];
    if (self) {
        _cardListModel = viewModel.cardListModel;
        _payDisabledFundID2ReasonMap = viewModel.payDisabledFundID2ReasonMap;
        _isCombinePay = viewModel.currentShowConfig.isCombinePay;
        if (_isCombinePay) {
            _combineType = viewModel.currentShowConfig.combineType;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    
    self.payMethodView.delegate = self;
    
    self.payMethodView.models = [self p_buildModels];
    self.payMethodView.isFromCombinePay = self.isCombinePay;
    
    [self p_tracker];
}

- (void)p_tracker {
    NSMutableArray *campaignInfos = [NSMutableArray array];
    NSMutableArray *methodList = [NSMutableArray array];
    
    for (CJPayChannelBizModel *bizModel in  [self p_buildModels]) {
        CJPayDefaultChannelShowConfig *config = bizModel.channelConfig;
        NSDictionary *campaignInfo = [config toActivityInfoTracker];
        if (self.isCombinePay) {
            campaignInfo = [config toCombinePayActivityInfoTracker];
        }
        if (campaignInfo.count > 0) {
            [campaignInfos addObject:campaignInfo];
        }
        NSDictionary *method = [bizModel toMethodInfoTracker];
        if (method.count > 0) {
            [methodList addObject:method];
        }
    }
    
    [self p_trackerWithEventName:@"wallet_cashier_method_page_imp" params:@{
        @"campaign_info" : campaignInfos ?: @[],
        @"all_method_list" : methodList ?: @[]
    }];
}

- (NSArray<CJPayChannelBizModel *> *)p_buildModels {
    
    NSMutableArray *bizModels = [NSMutableArray new];
    NSMutableDictionary *invalidMethods = [NSMutableDictionary new];
    NSMutableArray<CJPayChannelBizModel *> *disableModels = [NSMutableArray array];
    
    NSArray *showConfigArray = [self.cardListModel buildConfigsWithIdentify:@""];
    for (CJPayDefaultChannelShowConfig *showConfig in showConfigArray) {
        showConfig.isCombinePay = self.isCombinePay;
        showConfig.combineType = self.combineType;
        
        CJPayChannelBizModel *bizModel = [showConfig toBizModel];
        bizModel.isChooseMethodSubPage = YES;
        bizModel.isEcommercePay = YES;
        if ([self.payDisabledFundID2ReasonMap.allKeys containsObject:showConfig.cjIdentify]) {
            bizModel.enable = NO;
            bizModel.isConfirmed = NO;
            if (!Check_ValidString(bizModel.reasonStr)) {
                bizModel.reasonStr = [self.payDisabledFundID2ReasonMap cj_stringValueForKey:showConfig.cjIdentify];
                bizModel.subTitle = [self.payDisabledFundID2ReasonMap cj_stringValueForKey:showConfig.cjIdentify];
            }
            [invalidMethods cj_setObject:bizModel forKey:showConfig.cjIdentify];
        } else if (self.isCombinePay && bizModel.enable == YES && (bizModel.type == BDPayChannelTypeBalance || bizModel.type == BDPayChannelTypeIncomePay)) {
            bizModel.enable = NO;
            [disableModels addObject:bizModel];
        } else {
            [bizModels btd_addObject:bizModel];
        }
    }
    // 根据余额不足要求重新排序展示卡列表
    for (NSString *cjidentify in self.payDisabledFundID2ReasonMap.allKeys) {
        id object = [invalidMethods cj_objectForKey:cjidentify];
        if (object) {
            [bizModels addObject:object];
        }
    }
    
    if (disableModels.count > 0) {
        [bizModels addObjectsFromArray:disableModels];
    }
    
    return [bizModels copy];
}

- (void)p_setupUI {
    NSString *navTitle = @"";
    if (self.isSkipPwd) {
        navTitle = CJPayLocalizedStr(@"选择免密支付方式");
    } else if (self.isCombinePay) {
        if (self.showStyle == CJPaySecondPayRecSimpleStyle) {
            navTitle = CJPayLocalizedStr(@"选择以下组合支付方式，立即支付");
        } else {
            navTitle = CJPayLocalizedStr(@"选择组合支付方式");
        }
    } else {
        if (self.showStyle == CJPaySecondPayRecSimpleStyle) {
            navTitle = CJPayLocalizedStr(@"选择以下支付方式，立即支付");
        } else {
            navTitle = CJPayLocalizedStr(@"选择支付方式");
        }
    }
    [self.navigationBar setTitle:navTitle];
   
    self.isSupportClickMaskBack = NO;
    
    [self.contentView addSubview:self.payMethodView];
    
    CJPayMasMaker(self.payMethodView, {
        make.edges.equalTo(self.contentView);
    });
    
    if (@available(iOS 13.0, *)) {
        self.modalInPresentation = CJ_Pad;
    } else {
        // Fallback on earlier versions
    }
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    if (self.delegate && [self.delegate respondsToSelector:@selector(trackerWithEventName:params:)]) {
        [self.delegate trackerWithEventName:CJString(eventName) params:params];
    }
}

- (void)didSelectAtIndex:(int)selectIndex {
    // 防止crash
}

- (void)didSelectAtIndex:(int)selectIndex methodCell:(UITableViewCell *)cell {
    if (selectIndex < 0 || selectIndex >= self.payMethodView.models.count) {
        return;
    }
    CJPayChannelBizModel *model = [_payMethodView.models cj_objectAtIndex:selectIndex];
    
    if (!model.enable) {
        return;
    }
    
    self.currentChannelShowConfig = model.channelConfig;
    self.currentSelectedCell = cell;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didClickMethodCell:channelBizModel:)]) {
        [self.delegate didClickMethodCell:cell channelBizModel:model];
    }
}

- (void)didChangeCreditPayInstallment:(NSString *)installment {
    if (Check_ValidString(installment) && [self.delegate respondsToSelector:@selector(didChangeCreditPayInstallment:)]) {
        [self.delegate didChangeCreditPayInstallment:installment];
    }
}

- (CJPayBytePayMethodView *)payMethodView {
    if (!_payMethodView) {
        _payMethodView = [CJPayBytePayMethodView new];
        _payMethodView.isChooseMethodSubPage = YES;
    }
    return _payMethodView;
}

@end
