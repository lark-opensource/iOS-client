//
//  CJPayChoosePayMethodGroupView.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/22.
//

#import "CJPayChoosePayMethodGroupView.h"
#import "CJPayChooseDyPayMethodGroupModel.h"

#import "CJPayUIMacro.h"
#import "CJPayDyPayMethodNumAdjustCell.h"
#import "CJPayDyPayMethodCell.h"
#import "CJPayDyPayCreditMethodCell.h"
#import "CJPayBaseListDataSource.h"
#import "CJPayDyPayMethodCellViewModel.h"
#import "CJPayDyPayMethodAdjustCellViewModel.h"
#import "CJPayDyPayCreditMethodCellViewModel.h"

#import "CJPayDefaultChannelShowConfig.h"

@interface CJPayChoosePayMethodGroupView ()<UITableViewDelegate, UITableViewDataSource>
#pragma mark - model
@property (nonatomic, strong) CJPayChooseDyPayMethodGroupModel *viewModel; // 视图数据
@property (nonatomic, strong) CJPayBaseListDataSource *dataSource; // 支付方式列表数据

#pragma mark - views
@property (nonatomic, strong) UILabel *titleLabel; // 标题
@property (nonatomic, strong) UIView *titleZoneView; // 标题区域（带渐变背景色）
@property (nonatomic, strong) UITableView *payMethodsTableView; // 支付方式列表

#pragma mark - constraints
@property (nonatomic, strong) MASConstraint *payMethodViewBottomConstraint; //支付列表bottom约束
@property (nonatomic, strong) MASConstraint *methodTableViewHeightConstraint; //支付列表height约束
@property (nonatomic, strong) MASConstraint *extraDescLabelBottomConstraint; //描述文案bottom约束

#pragma mark - status
@property (nonatomic, assign) BOOL isPaymentToolsFold; // 支付方式列表是否处于折叠状态
@property (nonatomic, assign) BOOL isSetGradientBGColor; // 是否已设置过标题区域背景色
@property (nonatomic, assign) NSUInteger bindCardPaymentCount; // 绑卡支付方式总数量

@property (nonatomic, strong) CJPayDyPayMethodCellViewModel *selectAddCardCellVM;
@end


@implementation CJPayChoosePayMethodGroupView

- (instancetype)initWithPayMethodViewModel:(CJPayChooseDyPayMethodGroupModel *)model {
    self = [super init];
    if (self) {
        _viewModel = model;
        self.bindCardPaymentCount = [self p_getBindCardPaymentToolTotalCount:model];
        self.isPaymentToolsFold = YES;
        [self p_setupUI];
        [self p_reloadWithViewModel:model];
    }
    return self;
}

- (void)p_setupUI {
    self.backgroundColor = [UIColor whiteColor];
    
    [self addSubview:self.titleZoneView];
    [self.titleZoneView addSubview:self.titleLabel];
    [self addSubview:self.payMethodsTableView];
    [self.payMethodsTableView registerClass:CJPayDyPayMethodCell.class forCellReuseIdentifier:CJPayDyPayMethodCell.description];
    [self.payMethodsTableView registerClass:CJPayDyPayMethodNumAdjustCell.class forCellReuseIdentifier:CJPayDyPayMethodNumAdjustCell.description];
    
    CJPayMasMaker(self.titleZoneView, {
        make.top.left.equalTo(self).offset(1);
        make.right.equalTo(self).offset(-1);
        make.height.mas_equalTo(34);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self.titleZoneView).offset(12);
        make.right.lessThanOrEqualTo(self.titleZoneView).offset(-16);
    });
    
    CJPayMasMaker(self.payMethodsTableView, {
        make.top.equalTo(self.titleZoneView.mas_bottom);
        make.left.right.equalTo(self);
        self.methodTableViewHeightConstraint = make.height.mas_equalTo(1);
        self.payMethodViewBottomConstraint = make.bottom.equalTo(self);
    });
    [self.payMethodsTableView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.payMethodViewBottomConstraint activate];
    
}

// 根据model刷新视图
- (void)p_reloadWithViewModel:(CJPayChooseDyPayMethodGroupModel *)model {
    self.viewModel = model;
    [self p_updatePayMethodGroupViewContent];
    [self p_reloadMethodListDataSource:model];
}

- (void)p_updatePayMethodGroupViewContent {
    self.titleLabel.text = CJString(self.viewModel.methodGroupTitle);
}

// 构造支付方式列表数据
- (void)p_reloadMethodListDataSource:(CJPayChooseDyPayMethodGroupModel *)model {
    NSArray<CJPayBaseListViewModel *> *viewModels = [NSArray new];
    if (model.methodGroupType == CJPayPayMethodTypePaymentTool) {
        viewModels = [self p_buildPaymentToolDataSource:model.methodList limitBindCardCount:model.displayNewBankCardCount];
    } else if (model.methodGroupType == CJPayPayMethodTypeFinanceChannel) {
        viewModels = [self p_buildFinanceChannelDataSource:model.methodList];
    }
  
    [self.dataSource.sectionsDataDic removeAllObjects];
    [self.dataSource.sectionsDataDic addEntriesFromDictionary:@{@(0): [viewModels mutableCopy]}];
    [self.payMethodsTableView reloadData];
    // 计算tableView的总高度，用于撑开外部scrollView
    self.methodTableViewHeightConstraint.offset = [self p_getTableViewHeightWithViewModels:viewModels];
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

// 构造”支付工具“类型的支付方式数据：[CJPayDefaultChannelShowConfig] -> [CJPayBaseListViewModel]
- (NSArray<CJPayBaseListViewModel *> *)p_buildPaymentToolDataSource:(NSArray<CJPayDefaultChannelShowConfig *> *)methodList limitBindCardCount:(NSInteger)bindCardLimitCount{
    
    NSMutableArray<CJPayBaseListViewModel *> *dataSource = [NSMutableArray new];
    
    @CJWeakify(self)
    __block BOOL hasAddDisablePayment = NO;
    __block BOOL hasAddAdjustCell = NO;
    __block NSInteger bindCardCount = 0;
    [methodList enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        
        // 创建普通支付方式cellViewModel
        CJPayDyPayMethodCellViewModel *payMethodCellViewModel = [CJPayDyPayMethodCellViewModel new];
        payMethodCellViewModel.showConfig = obj;
        @CJWeakify(payMethodCellViewModel)
        payMethodCellViewModel.didSelectedBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull showConfig) {
            @CJStrongify(self)
            @CJStrongify(payMethodCellViewModel)
            [self didSelectedCellViewModel:payMethodCellViewModel];
        };
        if (!obj.canUse && !hasAddDisablePayment) {
            hasAddDisablePayment = YES;
            payMethodCellViewModel.needAddTopLine = YES;
        }
        if (obj.type != BDPayChannelTypeAddBankCard) {
            [dataSource btd_addObject:payMethodCellViewModel];
            return;
        }

        CJPayDyPayMethodAdjustCellViewModel *adjustCellViewModel = [CJPayDyPayMethodAdjustCellViewModel new];
        adjustCellViewModel.isInFoldStatus = self.isPaymentToolsFold;
        adjustCellViewModel.addBankCardFoldDesc = self.viewModel.addBankCardFoldDesc;
        adjustCellViewModel.clickBlock = ^(BOOL isFold) {
            @CJStrongify(self)
            [self p_showPaymentToolsWithFoldStatus:isFold];
        };
        
        bindCardCount++;
        if (self.isPaymentToolsFold) { //支付列表折叠状态
            if (bindCardCount > bindCardLimitCount) {
                if (!hasAddAdjustCell) {
                    // 列表折叠时，展示“展开更多银行”cell的条件：当前绑卡展示数 > 限制展示数
                    hasAddAdjustCell = YES;
                    [dataSource btd_addObject:adjustCellViewModel];
                }
                return;
            }
            [dataSource btd_addObject:payMethodCellViewModel];
            
        } else { //支付列表展开状态
            [dataSource btd_addObject:payMethodCellViewModel];
            if (!hasAddAdjustCell && bindCardLimitCount < self.bindCardPaymentCount && bindCardCount == self.bindCardPaymentCount) {
                // 列表展开时，展示“收起更多银行”cell的条件：限制展示数 < 绑卡总条数 && 当前已是最后一个绑卡cell
                hasAddAdjustCell = YES;
                [dataSource btd_addObject:adjustCellViewModel];
            }
        }

    }];
    return [dataSource copy];
}

// 构造”资金渠道“类型的支付方式数据：[CJPayDefaultChannelShowConfig] -> [CJPayBaseListViewModel]
- (NSArray<CJPayBaseListViewModel *> *)p_buildFinanceChannelDataSource:(NSArray<CJPayDefaultChannelShowConfig *> *)methodList {
    
    NSMutableArray<CJPayBaseListViewModel *> *dataSource = [NSMutableArray new];
    // 创建资金渠道支付方式列表
    @CJWeakify(self)
    __block BOOL hasAddDisablePayment = NO;
    [methodList enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        // 创建普通支付方式cellViewModel
        CJPayDyPayMethodCellViewModel *payMethodCellViewModel;
        if (obj.type == BDPayChannelTypeCreditPay) {
            payMethodCellViewModel = [CJPayDyPayCreditMethodCellViewModel new];
        } else {
            payMethodCellViewModel = [CJPayDyPayMethodCellViewModel new];
        }
        payMethodCellViewModel.showConfig = obj;
        @CJWeakify(payMethodCellViewModel)
        payMethodCellViewModel.didSelectedBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull showConfig) {
            @CJStrongify(self)
            @CJStrongify(payMethodCellViewModel)
            [self didSelectedCellViewModel:payMethodCellViewModel];
        };
        
        if (!obj.canUse && !hasAddDisablePayment) {
            hasAddDisablePayment = YES;
            payMethodCellViewModel.needAddTopLine = YES;
        }
        [dataSource btd_addObject:payMethodCellViewModel];
    }];
    return [dataSource copy];
}

// 选中支付方式，回调
- (void)didSelectedCellViewModel:(CJPayDyPayMethodCellViewModel *)cellVM {
    if (!cellVM.showConfig.canUse) {
        return;
    }
    self.selectAddCardCellVM = cellVM;
    CJ_CALL_BLOCK(self.didSelectedBlock, cellVM.showConfig, cellVM.cell);
}

// 刷新当前groupView的支付方式选中态
- (void)updatePayMethodViewBySelectConfig:(CJPayDefaultChannelShowConfig *)selectConfig {
    
    NSArray<CJPayBaseListViewModel *> *dataSource = [self.dataSource.sectionsDataDic objectForKey:[NSNumber numberWithInteger:0]];
    [dataSource enumerateObjectsUsingBlock:^(CJPayBaseListViewModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayDyPayMethodCellViewModel.class]) {
            CJPayDyPayMethodCellViewModel *methodVM = (CJPayDyPayMethodCellViewModel *)obj;
            methodVM.showConfig.isSelected = [methodVM.showConfig isEqual:selectConfig];
        }
    }];
    [self.payMethodsTableView reloadData];

}

// 更改支付方式列表折叠态
- (void)p_showPaymentToolsWithFoldStatus:(BOOL)isFold {
    self.isPaymentToolsFold = !isFold;
    [self p_reloadMethodListDataSource:self.viewModel];
}

// 计算支付方式中绑卡方式的总数量
- (NSUInteger)p_getBindCardPaymentToolTotalCount:(CJPayChooseDyPayMethodGroupModel *)model {
    if (model.methodGroupType != CJPayPayMethodTypePaymentTool) {
        return 0;
    }
    NSPredicate *bindCardTypePredicate = [NSPredicate predicateWithFormat:@"type=%lu", BDPayChannelTypeAddBankCard];
    NSArray *bindCardArray = [model.methodList filteredArrayUsingPredicate:bindCardTypePredicate];
    return bindCardArray.count;
}

// 计算支付方式列表总高度
- (CGFloat)p_getTableViewHeightWithViewModels:(NSArray<CJPayBaseListViewModel *> *)viewModels {
    __block CGFloat offset = 0.f;
    [viewModels enumerateObjectsUsingBlock:^(CJPayBaseListViewModel *  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        offset += [model getViewHeight] + [model getTopMarginHeight] + [model getBottomMarginHeight];
    }];
    return offset;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.dataSource numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CJPayBaseListViewModel *viewModel = [self.dataSource viewModelAtIndexPath:indexPath];
    if (viewModel) {
        Class cellClass = [viewModel getViewClass];
        NSString *reuseIdentifier = NSStringFromClass(cellClass);
        CJPayBaseListCellView *cell = [tableView dequeueReusableCellWithIdentifier: reuseIdentifier];
        if (!cell) {
            cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        }
        [cell bindViewModel:viewModel];
        return cell;
    }
    return [[CJPayBaseListCellView alloc] init];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CJPayBaseListViewModel *viewModel = [self.dataSource viewModelAtIndexPath:indexPath];
    CJPayBaseListCellView *cell = viewModel.cell;
    if (cell) {
        CJ_DelayEnableView(self);
        [cell didSelect];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSource tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CJ_CALL_BLOCK(self.cellWillDisplayBlock, (CJPayBaseListCellView *)cell, [self.dataSource viewModelAtIndexPath:indexPath]);
}

#pragma mark - loading delegate
- (void)startLoading {
    [self.selectAddCardCellVM startLoading];
}

- (void)stopLoading {
    [self.selectAddCardCellVM stopLoading];
}

#pragma mark - lazy init
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:13];
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
    }
    return _titleLabel;
}

- (UIView *)titleZoneView {
    if (!_titleZoneView) {
        _titleZoneView = [UIView new];
        _titleZoneView.backgroundColor = [UIColor clearColor];
        _titleZoneView.clipsToBounds = YES;
    }
    return _titleZoneView;
}

- (UITableView *)payMethodsTableView {
    if (!_payMethodsTableView) {
        _payMethodsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _payMethodsTableView.delegate = self;
        _payMethodsTableView.bounces = NO;
        _payMethodsTableView.dataSource = self;
        _payMethodsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _payMethodsTableView.showsVerticalScrollIndicator = NO;
        _payMethodsTableView.scrollEnabled = NO;
        _payMethodsTableView.backgroundColor = [UIColor whiteColor];
    }
    return _payMethodsTableView;
}

- (CJPayBaseListDataSource *)dataSource {
    if (!_dataSource) {
        _dataSource = [CJPayBaseListDataSource new];
    }
    return _dataSource;
}
@end
