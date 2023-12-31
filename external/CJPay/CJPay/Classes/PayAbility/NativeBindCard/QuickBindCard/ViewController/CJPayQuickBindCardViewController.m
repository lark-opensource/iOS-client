//
//  CJPayQuickBindCardViewController.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/12.
//

#import "CJPayQuickBindCardViewController.h"
#import "CJPayQuickBindCardTableViewCell.h"
#import "CJPayQuickBindCardHeaderView.h"
#import "CJPayQuickBindCardTipsViewModel.h"
#import "CJPayQuickBindCardQuickFrontHeaderViewModel.h"
#import "CJPayQuickBindCardViewModel.h"
#import "CJPayQuickBindCardAbbreviationViewModel.h"
#import "CJPayBindCardManager.h"
#import "CJPayUserInfo.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayKVContext.h"
#import "CJPayBindCardShareDataKeysDefine.h"
#import "CJPayNavigationBarView.h"

@interface CJPayQuickBindCardViewController ()

@property (nonatomic, strong) CJPayBindCardVCLoadModel *vcLoadModel;
@property (nonatomic, assign, readwrite) CGFloat curContentHeight;

#pragma mark - model
@property (nonatomic, strong) CJPayBaseListViewModel *tableHeaderViewModel;

@end

@implementation CJPayQuickBindCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CJPayStyleBaseListCellView *)tableViewHeader {
    return (CJPayStyleBaseListCellView *)self.tableHeaderViewModel.cell;
}

- (void)reloadWithModel:(CJPayBindCardVCLoadModel *)vcLoadModel {
    if (vcLoadModel.banksList.count == 0) {
        return;
    }
    
    self.vcLoadModel = vcLoadModel;
    
    NSMutableArray<CJPayBaseListViewModel *> *viewModels = [[self getViewModelsWithLoadModel:vcLoadModel] mutableCopy];
    
    [self.dataSource.sectionsDataDic removeAllObjects];
    [self.dataSource.sectionsDataDic addEntriesFromDictionary:@{@(0): viewModels}];
    [self.tableView reloadData];
    
    CJ_CALL_BLOCK(self.contentHeightDidChangeBlock, [self getTableViewHeightWithViewModels:viewModels]);
}

- (NSArray<CJPayBaseListViewModel *> *)getViewModelsWithLoadModel:(CJPayBindCardVCLoadModel *)vcLoadModel {
    NSMutableArray *viewModels = [NSMutableArray array];
    
    if (!CJOptionsHasValue(self.vcStyle, CJPayBindCardStyleDeepFold)) {
        [viewModels addObject:[self p_getHeaderViewModelWithVCLoadModel:vcLoadModel]];
        [viewModels addObjectsFromArray:[self p_getBindCardModel:vcLoadModel.banksList]];
    }
    
    // BDPayQuickBindCardStyleV2Fold | BDPayQuickBindCardStyleV2DeepFold
    if (CJOptionsHasValue(self.vcStyle, CJPayBindCardStyleFold | CJPayBindCardStyleDeepFold) ) {
        CJPayQuickBindCardAbbreviationViewModel *abbreviationViewModel = [CJPayQuickBindCardAbbreviationViewModel new];
        abbreviationViewModel.bindCardBankCount = [vcLoadModel.banksList count];
        abbreviationViewModel.bindCardVCModel = self.bindCardVCModel;
        abbreviationViewModel.banksLength = vcLoadModel.banksLength;
        [viewModels btd_addObject:abbreviationViewModel];
    // BDPayQuickBindCardStyleV1 | BDPayQuickBindCardStyleV2Unfold
    } else if (CJOptionsHasValue(self.vcStyle, CJPayBindCardStyleUnfold)) {
        CJPayQuickBindCardTipsViewModel *tipsViewModel = [[CJPayQuickBindCardTipsViewModel alloc] initWithViewController:self];
        tipsViewModel.viewStyle = self.vcStyle;
        if (CJOptionsHasValue(self.vcStyle, CJPayBindCardStyleUnfold)) {
            @CJWeakify(self);
            tipsViewModel.didClickBlock = ^{
                @CJStrongify(self);
                CJ_CALL_BLOCK(self.didSelectedTipsBlock);
            };
        }
        [viewModels addObject:tipsViewModel];

        if (vcLoadModel.isShowBottomLabel) {
            CJPayQuickBindCardFooterViewModel *vm = [CJPayQuickBindCardFooterViewModel new];
            [viewModels addObject:vm];
        }
    }
    
    return [viewModels copy];
}

- (CGFloat)getTableViewHeightWithViewModels:(NSArray<CJPayBaseListViewModel *> *)viewModels {
    __block CGFloat offset = 0.f;
    [viewModels enumerateObjectsUsingBlock:^(CJPayBaseListViewModel *  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        offset += [model getViewHeight];
    }];
    return offset;
}

- (CJPayBaseListViewModel *)p_getHeaderViewModelWithVCLoadModel:(CJPayBindCardVCLoadModel *)vcLoadModel {
    if (CJOptionsHasValue(self.vcStyle, CJPayBindCardStyleFold | CJPayBindCardStyleUnfold)) {
        CJPayQuickBindCardQuickFrontHeaderViewModel *headerViewModel = [CJPayQuickBindCardQuickFrontHeaderViewModel new];
        headerViewModel.title = CJString(vcLoadModel.title);
        headerViewModel.subTitle = CJString(vcLoadModel.subTitle);
        self.tableHeaderViewModel = headerViewModel;
        return headerViewModel;
    } else {
        CJPayQuickBindCardHeaderViewModel *headerViewModel = [[CJPayQuickBindCardHeaderViewModel alloc] initWithViewController:self];
        headerViewModel.title = CJString(vcLoadModel.title);;
        headerViewModel.subTitle = CJString(vcLoadModel.subTitle);
        self.tableHeaderViewModel = headerViewModel;
        return headerViewModel;
    }
}

- (NSArray<CJPayBaseListViewModel *> *)p_getBindCardModel:(NSArray<CJPayQuickBindCardModel *> *)banksList {
    NSMutableArray *viewModels = [NSMutableArray array];
    __block NSInteger bankCount = 0;
    @CJWeakify(self)
    [banksList enumerateObjectsUsingBlock:^(CJPayQuickBindCardModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        CJPayQuickBindCardViewModel *bindCardViewModel = [CJPayQuickBindCardViewModel new];
        bindCardViewModel.bindCardModel = obj;
        @CJWeakify(bindCardViewModel);
        bindCardViewModel.didSelectedBlock = ^(CJPayQuickBindCardModel * _Nonnull bindCardModel) {
            @CJStrongify(self)
            @CJStrongify(bindCardViewModel)
            CJ_DelayEnableView(self.view);
            NSDictionary *dict = @{
                CJPayBindCardShareDataKeyIsQuickBindCard: @(YES),
                CJPayBindCardShareDataKeyQuickBindCardModel : [bindCardModel toDictionary] ?: @{},
            };
            [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:dict completion:^(NSArray * _Nonnull modifyedKeysArray) {
                            
            }];
            bindCardViewModel.bindCardModel = bindCardModel;
            CJ_CALL_BLOCK(self.didSelectedBlock, bindCardViewModel);
        };
        bindCardViewModel.viewStyle = self.bindCardVCModel.vcStyle;
        if (!obj.isUnionBindCard || ![[CJPayKVContext kv_stringForKey:CJPayUnionPayIsUnAvailable] isEqualToString:@"1"]) {
            [viewModels btd_addObject:bindCardViewModel];
        }
        
        if (CJOptionsHasValue(self.vcStyle, CJPayBindCardStyleFold)) {
            bankCount++;
            BOOL isBankCountLimit = (bankCount == self.vcLoadModel.banksLength);
            bindCardViewModel.isBottomLineExtend = isBankCountLimit;
            *stop = isBankCountLimit;
        }
    }];
    
    return [viewModels copy];
}

- (void)p_setupUI
{
    self.navigationBar.hidden = YES;
    self.tableView.bounces = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.scrollEnabled = NO;
    [self.view addSubview:self.tableView];
    // remake
    CJPayMasReMaker(self.tableView, {
        make.top.bottom.equalTo(self.view);
        make.left.equalTo(self.view).offset(24);
        make.right.equalTo(self.view).offset(-24);
    });
//    self.isNeedDataSecurity = YES;
}

@end
