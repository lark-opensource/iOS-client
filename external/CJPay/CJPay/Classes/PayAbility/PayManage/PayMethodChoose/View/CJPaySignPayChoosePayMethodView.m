//
//  CJPaySignPayChoosePayMethodView.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/1.
//

#import "CJPaySignPayChoosePayMethodView.h"
#import "CJPaySignPayChoosePayMethodModel.h"
#import "CJPayBaseListDataSource.h"
#import "CJPayDyPayMethodCell.h"
#import "CJPayDyPayMethodNumAdjustCell.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayDyPayMethodCellViewModel.h"
#import "CJPayDyPayMethodAdjustCellViewModel.h"

#import "CJPayUIMacro.h"

@interface CJPaySignPayChoosePayMethodView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) CJPaySignPayChoosePayMethodModel *viewModel; // 视图数据
@property (nonatomic, strong) CJPayBaseListDataSource *dataSource; // 支付方式列表数据

@property (nonatomic ,strong) UILabel *groupTitleLabel; // 分组标题
@property (nonatomic, strong) UITableView *payMethodsTableView; // 支付方式列表

@property (nonatomic, strong) MASConstraint *payMethodViewBottomConstraint; //支付列表bottom约束
@property (nonatomic, strong) MASConstraint *methodTableViewHeightConstraint; //支付列表height约束
@property (nonatomic, strong) MASConstraint *extraDescLabelBottomConstraint; //描述文案bottom约束

@property (nonatomic, assign) BOOL isPaymentToolsFold; // 支付方式列表是否处于折叠状态
@property (nonatomic, assign) NSUInteger bindCardPaymentCount; // 绑卡支付方式总数量

@property (nonatomic, strong) CJPayDyPayMethodCellViewModel *selectAddCardCellVM;

@end

@implementation CJPaySignPayChoosePayMethodView

- (instancetype)initWithPayMethodViewModel:(CJPaySignPayChoosePayMethodModel *)model {
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

    if (Check_ValidString(self.viewModel.groupTitle)) {
        [self addSubview:self.groupTitleLabel];
        CJPayMasMaker(self.groupTitleLabel, {
            make.top.mas_equalTo(self);
            make.left.mas_equalTo(self).mas_offset(20);
            make.right.mas_equalTo(self).mas_offset(-20);
            make.height.mas_equalTo(42);
        });
    }
    
    [self addSubview:self.payMethodsTableView];
    [self.payMethodsTableView registerClass:CJPayDyPayMethodCell.class forCellReuseIdentifier:CJPayDyPayMethodCell.description];
    [self.payMethodsTableView registerClass:CJPayDyPayMethodNumAdjustCell.class forCellReuseIdentifier:CJPayDyPayMethodNumAdjustCell.description];
    
    CJPayMasMaker(self.payMethodsTableView, {
        make.top.mas_equalTo(Check_ValidString(self.viewModel.groupTitle) ? self.groupTitleLabel.mas_bottom : self);
        make.left.right.equalTo(self);
        self.methodTableViewHeightConstraint = make.height;
        self.payMethodViewBottomConstraint = make.bottom.equalTo(self).offset(-16);
    });
    [self.payMethodsTableView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.payMethodViewBottomConstraint activate];
}

// 根据model刷新视图
- (void)p_reloadWithViewModel:(CJPaySignPayChoosePayMethodModel *)model {
    self.viewModel = model;
    [self p_reloadMethodListDataSource:model];
}

// 构造支付方式列表数据
- (void)p_reloadMethodListDataSource:(CJPaySignPayChoosePayMethodModel *)model {
    NSArray<CJPayBaseListViewModel *> *viewModels = [NSArray new];
    viewModels = [self p_buildDataSource:model.methodList limitBindCardCount:model.displayNewBankCardCount];
  
    [self.dataSource.sectionsDataDic removeAllObjects];
    [self.dataSource.sectionsDataDic addEntriesFromDictionary:@{@(0): [viewModels mutableCopy]}];
    [self.payMethodsTableView reloadData];
    // 计算tableView的总高度，用于撑开外部scrollView
    self.methodTableViewHeightConstraint.offset = [self p_getTableViewHeightWithViewModels:viewModels];
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

// 构造支付方式数据：[CJPayDefaultChannelShowConfig] -> [CJPayBaseListViewModel]
- (NSArray<CJPayBaseListViewModel *> *)p_buildDataSource:(NSArray<CJPayDefaultChannelShowConfig *> *)methodList limitBindCardCount:(NSInteger)bindCardLimitCount{
    
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
        payMethodCellViewModel.isDeduct = YES;
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
    NSArray<CJPayBaseListViewModel *> *dataSource = [self.dataSource.sectionsDataDic btd_arrayValueForKey:[NSNumber numberWithInteger:0]];
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
- (NSUInteger)p_getBindCardPaymentToolTotalCount:(CJPaySignPayChoosePayMethodModel *)model {
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

#pragma mark - loading delegate
- (void)startLoading {
    [self.selectAddCardCellVM startLoading];
}

- (void)stopLoading {
    [self.selectAddCardCellVM stopLoading];
}

#pragma mark - lazy init

- (UILabel *)groupTitleLabel {
    if (!_groupTitleLabel) {
        _groupTitleLabel = [UILabel new];
        _groupTitleLabel.text = self.viewModel.groupTitle;
        _groupTitleLabel.font = [UIFont cj_fontOfSize:13];
        _groupTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
    }
    return _groupTitleLabel;
}

- (UITableView *)payMethodsTableView {
    if (!_payMethodsTableView) {
        _payMethodsTableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStyleGrouped];
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
