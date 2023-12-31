//
//  CJPayBytePayMethodView.m
//  Pods
//
//  Created by wangxiaohong on 2021/4/13.
//

#import "CJPayBytePayMethodView.h"

#import "CJPayUIMacro.h"
#import "CJPayChannelBizModel.h"
#import "CJPayBytePayMethodCell.h"
#import "CJPayBytePayMethodSecondaryCell.h"
#import "CJPayBytePayMethodCreditPayCell.h"
#import "CJPayByteSecondaryPayMethodCreditPayCell.h"
#import "CJPayByteMethodNewCustomerSecondaryCell.h"
#import "CJPayMethodBannerCell.h"
#import "CJPayMethodUnbindCardZoneCell.h"
#import "CJPayMethodSeparateLineCell.h"

@interface CJPayBytePayMethodView()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CJPayBytePayMethodSecondaryCell *secondaryCellView;
@property (nonatomic, strong) CJPayBytePayMethodCell *addCardCellView;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CJPayBytePayMethodCell *> *addCardCells;
@property (nonatomic, assign) NSInteger loadingIndex;

@end

@implementation CJPayBytePayMethodView

@synthesize models = _models;
@synthesize delegate = _delegate;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        self.addCardCells = [NSMutableDictionary new];
        self.loadingIndex = -1;
    }
    return self;
}

- (void)setModels:(NSArray *)models{
    _models = models;
    [self.tableView reloadData];
}

- (void)setupUI{
    [self.tableView registerClass:CJPayBytePayMethodCell.class forCellReuseIdentifier:CJPayBytePayMethodCell.description];
    [self.tableView registerClass:CJPayBytePayMethodSecondaryCell.class forCellReuseIdentifier:CJPayBytePayMethodSecondaryCell.description];
    [self.tableView registerClass:CJPayByteMethodNewCustomerSecondaryCell.class forCellReuseIdentifier:CJPayByteMethodNewCustomerSecondaryCell.description];
    [self.tableView registerClass:CJPayMethodUnbindCardZoneCell.class
           forCellReuseIdentifier:CJPayMethodUnbindCardZoneCell.description];
    [self.tableView registerClass:CJPayMethodSeparateLineCell.class forCellReuseIdentifier:CJPayMethodSeparateLineCell.description];
    [self addSubview:self.tableView];
    
    CJPayMasMaker(self.tableView, {
        make.edges.equalTo(self);
    })
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [UITableView new];
        _tableView.bounces = NO;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:CJPayBytePayMethodSecondaryCell.class]) {
        
        self.secondaryCellView = (CJPayBytePayMethodSecondaryCell *)cell;
    }
    
    if ([cell isKindOfClass:CJPayMethodBannerCell.class]) {
        @weakify(self);
        ((CJPayMethodBannerCell *)cell).clickBlock = ^(CJPayChannelType type) {
            @strongify(self);
            if ([self.delegate respondsToSelector:@selector(didClickBannerWithType:)]) {
                [self.delegate didClickBannerWithType:type];
            }
        };
        [cell.superview bringSubviewToFront:cell];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Class cellClass = [self getCellClass:[self.models objectAtIndex:indexPath.row]];

    UITableViewCell<CJPayMethodDataUpdateProtocol> *cell = (UITableViewCell<CJPayMethodDataUpdateProtocol> *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass(cellClass)];
    if (cell == nil) {
        cell = [[cellClass alloc] init];
    }
    @weakify(self);
    if ([cell isKindOfClass:[CJPayByteSecondaryPayMethodCreditPayCell class]]) {
        CJPayByteSecondaryPayMethodCreditPayCell *creditCell = (CJPayByteSecondaryPayMethodCreditPayCell *)cell;
        creditCell.clickBlock = ^(NSString *installment){
            @strongify(self);
            if ([self.delegate respondsToSelector:@selector(didChangeCreditPayInstallment:)]) {
                [self.delegate didChangeCreditPayInstallment:installment];
            }
        };
    }
    if ([cell isKindOfClass:[CJPayBytePayMethodCreditPayCell class]]) {
        CJPayBytePayMethodCreditPayCell *creditCell = (CJPayBytePayMethodCreditPayCell *)cell;
        creditCell.clickBlock = ^(NSString *installment){
            @strongify(self);
            if ([self.delegate respondsToSelector:@selector(didChangeCreditPayInstallment:)]) {
                [self.delegate didChangeCreditPayInstallment:installment];
            }
        };
    }
    if ([cell isKindOfClass:[CJPayByteMethodNewCustomerSecondaryCell class]]) {
        CJPayByteMethodNewCustomerSecondaryCell *tmpCell = (CJPayByteMethodNewCustomerSecondaryCell *)cell;
        tmpCell.subPayDelegate = self.delegate;
    }
    
    CJPayChannelBizModel *bizModel = [self.models objectAtIndex:indexPath.row];
    bizModel.isFromCombinePay = self.isFromCombinePay;
    [cell updateContent:bizModel];
    if (bizModel.type == BDPayChannelTypeAddBankCard && self.isChooseMethodSubPage) {
        NSString *str = [NSString stringWithFormat:@"%ld", indexPath.row];
        [self.addCardCells cj_setObject:cell forKey:str];
    }
    if (bizModel.type == CJPayChannelTypeQRCodePay && !self.isChooseMethodSubPage) {
        NSString *str = [NSString stringWithFormat:@"%ld", indexPath.row];
        [self.addCardCells cj_setObject:cell forKey:str];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.loadingIndex = indexPath.row;
    [self.delegate didSelectAtIndex:(int)indexPath.row];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectAtIndex:methodCell:)]) {
        [self.delegate didSelectAtIndex:(int)indexPath.row methodCell:[tableView cellForRowAtIndexPath:indexPath]];
    }
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
    if (model.isChooseMethodSubPage) {
        if ([model isDisplayCreditPayMetheds]) {
            return  CJPayBytePayMethodCreditPayCell.class;
        } else if (model.type == CJPayChannelTypeUnBindBankCardZone) {
            return CJPayMethodUnbindCardZoneCell.class;
        } else if (model.type == CJPayChannelTypeSeparateLine) {
            return CJPayMethodSeparateLineCell.class;
        } else {
            return CJPayBytePayMethodCell.class;
        }
    } else {
        switch (model.type) {
            case BDPayChannelTypeBankCard:
            case BDPayChannelTypeBalance:
            case BDPayChannelTypeIncomePay:
                return CJPayBytePayMethodSecondaryCell.class;
            case BDPayChannelTypeAddBankCard:
                return CJPayBytePayMethodSecondaryCell.class;
            case BDPayChannelTypeAddBankCardNewCustomer:
                return CJPayByteMethodNewCustomerSecondaryCell.class;
            case CJPayChannelTypeBannerCombinePay:
            case CJPayChannelTypeBannerVoucher:
                return CJPayMethodBannerCell.class;
            case BDPayChannelTypeCreditPay:
                return CJPayByteSecondaryPayMethodCreditPayCell.class;
            case CJPayChannelTypeQRCodePay:
                return NSClassFromString(CJPayMethodQRCodePayCell_Class); //解耦对cell的依赖
            default:
                return CJPayBytePayMethodCell.class;
        }
    }
}

- (Class)getCellClassByShowConfig:(CJPayDefaultChannelShowConfig *)config {
    if (config.isChooseMethodSubPage) {
        if ([config isDisplayCreditPayMetheds]) {
            return CJPayBytePayMethodCreditPayCell.class;
        } else {
            return CJPayBytePayMethodCell.class;
        }
    } else {
        switch (config.type) {
            case BDPayChannelTypeBankCard:
            case BDPayChannelTypeBalance:
            case BDPayChannelTypeIncomePay:
                return CJPayBytePayMethodSecondaryCell.class;
            case BDPayChannelTypeAddBankCard:
                return CJPayBytePayMethodSecondaryCell.class;
            case CJPayChannelTypeBannerCombinePay:
            case CJPayChannelTypeBannerVoucher:
                return CJPayMethodBannerCell.class;
            case BDPayChannelTypeCreditPay:
                return CJPayByteSecondaryPayMethodCreditPayCell.class;
            default:
                return CJPayBytePayMethodCell.class;
        }
    }
}

#pragma mark - CJPayMethodTableViewProtocol
- (void)startLoading
{
    if (self.isChooseMethodSubPage) {
        id cell = [self.addCardCells cj_objectForKey:[NSString stringWithFormat:@"%ld", self.loadingIndex]];
        if ([cell isKindOfClass:CJPayBytePayMethodCell.class]) {
            self.addCardCellView = cell;
            @CJStartLoading(self.addCardCellView)
        }
    } else if (self.secondaryCellView) {
        @CJStartLoading(self.secondaryCellView)
    } else {
        id cell = [self.addCardCells cj_objectForKey:[NSString stringWithFormat:@"%ld", self.loadingIndex]];
        if ([cell isKindOfClass:CJPayBytePayMethodCell.class]) {
            self.addCardCellView = cell;
            @CJStartLoading(self.addCardCellView)
        }
    }
}

- (void)stopLoading
{
    if (self.isChooseMethodSubPage && self.addCardCellView != nil) {
        @CJStopLoading(self.addCardCellView)
        self.addCardCellView = nil;
    } else if(self.secondaryCellView) {
        @CJStopLoading(self.secondaryCellView)
    } else if (self.addCardCellView){
        @CJStopLoading(self.addCardCellView)
    }
}

- (void)scrollToTop {
    NSInteger cellCount = self.models.count;
    if (cellCount <= 0) {
        return;
    }
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

@end
