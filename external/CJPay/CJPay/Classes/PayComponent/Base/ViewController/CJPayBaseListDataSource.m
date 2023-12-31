//
//  CJPayBaseListDataSource.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/18.
//

#import "CJPayBaseListDataSource.h"
#import "CJPayBaseListViewModel.h"
#import "CJPayUIMacro.h"

@implementation CJPayBaseListDataSource

- (NSMutableDictionary<NSNumber *,NSMutableArray<CJPayBaseListViewModel *> *> *)sectionsDataDic {
    if (!_sectionsDataDic) {
        _sectionsDataDic = [[NSMutableDictionary alloc] init];
    }
    return _sectionsDataDic;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sectionsDataDic count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *models = [self viewModelsAtSection:section];
    if (models) {
        return models.count;
    } else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self viewHeightAtIndexPath:indexPath];
}

- (CGFloat)viewHeightAtIndexPath:(NSIndexPath *)indexPath {
    CJPayBaseListViewModel *viewModel = [self viewModelAtIndexPath:indexPath];
    if (viewModel) {
        return [viewModel getViewHeight] + [viewModel getTopMarginHeight] + [viewModel getBottomMarginHeight];
    } else {
        return 0.0f;
    }
}

- (CJPayBaseListViewModel *)viewModelAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *models = [[self viewModelsAtSection: indexPath.section] copy];
    CJPayBaseListViewModel *model = [models cj_objectAtIndex:indexPath.row];
    return model;
}

- (NSMutableArray *)viewModelsAtSection:(NSInteger )section {
    NSMutableArray *models = [self.sectionsDataDic objectForKey:[NSNumber numberWithInteger:section]];
    return models;
}

@end
