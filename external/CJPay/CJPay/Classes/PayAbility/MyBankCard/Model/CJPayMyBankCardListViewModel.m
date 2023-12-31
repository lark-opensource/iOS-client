//
//  CJPayMyBankCardListViewModel.m
//  Pods
//
//  Created by wangxiaohong on 2020/12/30.
//

#import "CJPayMyBankCardListViewModel.h"

#import "CJPayMyBankCardListView.h"
#import "CJPayBankCardModel.h"
#import "CJPayUIMacro.h"
#import "CJPayBankCardItemCell.h"
#import "CJPayBaseListDataSource.h"
#import "CJPayBankCardItemViewModel.h"

@interface CJPayMyBankCardListViewModel()

@property (nonatomic, copy) NSArray *smallBankCardListViewModels;

@end

@implementation CJPayMyBankCardListViewModel

- (Class)getViewClass {
    return [CJPayMyBankCardListView class];
}

- (CGFloat)getViewHeight {
    __block CGFloat height = 52; //标题高度
    [self.smallBankCardListViewModels enumerateObjectsUsingBlock:^(CJPayBaseListViewModel  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        height += [obj getViewHeight];
    }];
    return height;
}

- (void)setBankCardListViewModels:(NSArray<CJPayBaseListViewModel *> *)bankCardListViewModels {
    _bankCardListViewModels = bankCardListViewModels;
    self.smallBankCardListViewModels = [self p_adapterViewModels:bankCardListViewModels];
}

- (NSArray *)p_adapterViewModels:(NSArray *)bankCardListViewModels {
    NSMutableArray *newListViewModels = [NSMutableArray array];
    [bankCardListViewModels enumerateObjectsUsingBlock:^(CJPayBaseListViewModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayBankCardItemViewModel.class]) {
            ((CJPayBankCardItemViewModel *)obj).isSmallStyle = YES;
            if (idx < 3) {
                [newListViewModels addObject:obj];
            }
        } else {
            [newListViewModels addObject:obj];
        }
    }];
    return newListViewModels;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CJPayBaseListViewModel *viewModel = [self.smallBankCardListViewModels cj_objectAtIndex:indexPath.row];
    CJPayBaseListCellView *listCell = viewModel.cell;
    if (listCell) {
        CJ_DelayEnableView(self.cell);
        [listCell didSelect];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CJPayBaseListViewModel *cardListViewModel = [self.smallBankCardListViewModels cj_objectAtIndex:indexPath.row];
    return [cardListViewModel getViewHeight];
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

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bankCardListViewModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.smallBankCardListViewModels.count) {
        return [[CJPayBaseListCellView alloc] init];
    }
    
    CJPayBaseListViewModel *viewModel = [self.smallBankCardListViewModels cj_objectAtIndex:indexPath.row];
    
    if (viewModel) {
        Class cellClass = [viewModel getViewClass];
        NSString *reuseIdentifier = NSStringFromClass(cellClass);
        CJPayBaseListCellView *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        
        if (!cell) {
            cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        }
        
        [cell bindViewModel:viewModel];
        return cell;
    }
    return [[CJPayBaseListCellView alloc]init];
}

@end
