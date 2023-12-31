//
//  CJPayBDMethodTableView.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/18.
//

#import "CJPayBDMethodTableView.h"
#import "CJPayUIMacro.h"
#import "CJPayMethodAddCardCellView.h"
#import "CJPayFrontBankCardListCell.h"
#import "CJPayMethodCell.h"
#import "CJPayFrontMethodAddCardCell.h"
#import "CJPayChannelBizModel.h"

@interface CJPayBDMethodTableView() <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, weak, nullable) CJPayMethodAddCardCellView *addBankCardCell;

@end

@implementation CJPayBDMethodTableView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setModels:(NSArray *)models{
    _models = models;
    [self.tableView reloadData];
}

- (void)setupUI{
    self.tableView = [UITableView new];
    self.tableView.bounces = YES;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
//    UIView *headerView = [[UIView alloc] init];
//    self.tableView.tableHeaderView = headerView;
//
    self.tableView.sectionHeaderHeight = 6;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:CJPayMethodAddCardCellView.class forCellReuseIdentifier:CJPayMethodAddCardCellView.description];
    [self.tableView registerClass:CJPayMethodCell.class forCellReuseIdentifier:CJPayMethodCell.description];
    [self.tableView registerClass:CJPayFrontBankCardListCell.class forCellReuseIdentifier:CJPayFrontBankCardListCell.description];
    [self addSubview:self.tableView];
    CJPayMasMaker(self.tableView, {
        make.edges.equalTo(self);
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Class cellClass = [self getCellClass:[self.models objectAtIndex:indexPath.row]];
    UITableViewCell<CJPayMethodDataUpdateProtocol> *cell = (UITableViewCell<CJPayMethodDataUpdateProtocol> *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass(cellClass)];
    if (cell == nil) {
        cell = [[cellClass alloc] init];
    }
    [cell updateContent:(CJPayChannelBizModel *)[self.models objectAtIndex:indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate didSelectAtIndex:(int)indexPath.row];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.models.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [self calculBankCardModelHeight:[self.models objectAtIndex:indexPath.row]];
}

- (CGFloat)calculBankCardModelHeight:(CJPayChannelBizModel *)model {
    Class cellClass = [self getCellClass:model];
    if ([cellClass conformsToProtocol:@protocol(CJPayMethodDataUpdateProtocol)]) {
        id cellHeight = [cellClass performSelector:@selector(calHeight:) withObject:model];
        if ([cellHeight isKindOfClass:NSNumber.class]) {
            return ((NSNumber *)cellHeight).floatValue;
        }
    }
    return CGFLOAT_MIN;
}

- (Class)getCellClass:(CJPayChannelBizModel *)model {
    switch (model.type) {
        case BDPayChannelTypeAddBankCard:
            return CJPayMethodAddCardCellView.class;
        case BDPayChannelTypeFrontAddBankCard:
            return CJPayFrontMethodAddCardCell.class;
        case CJPayChannelTypeFrontCardList:
            return CJPayFrontBankCardListCell.class;
        default:
            return CJPayMethodCell.class;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:CJPayMethodAddCardCellView.class]) {
        self.addBankCardCell = (CJPayMethodAddCardCellView *)cell;
    }
}

- (UITableViewCell<CJPayBaseLoadingProtocol> *)p_getLoadingCell {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (![cell conformsToProtocol:@protocol(CJPayBaseLoadingProtocol)]) {
        return nil;
    }
    UITableViewCell<CJPayBaseLoadingProtocol> *loadingCell = (UITableViewCell<CJPayBaseLoadingProtocol>*)cell;
    return loadingCell;
}

- (void)startLoadingAnimationOnAddBankCardCell
{
    @CJStartLoading(self.addBankCardCell)
}

- (void)stopLoadingAnimationOnAddBankCardCell
{
    @CJStopLoading(self.addBankCardCell)
}

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    UITableViewCell<CJPayBaseLoadingProtocol> *cell = [self p_getLoadingCell];
    if (cell && [cell respondsToSelector:@selector(startLoading)]) {
        [cell startLoading];
    }
}

- (void)stopLoading {
    UITableViewCell<CJPayBaseLoadingProtocol> *cell = [self p_getLoadingCell];
    if (cell && [cell respondsToSelector:@selector(stopLoading)]) {
        [cell stopLoading];
    }
}

@end

