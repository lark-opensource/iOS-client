//
//  CJPayCommonListViewController.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/18.
//

#import "CJPayCommonListViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseListViewModel.h"
#import "CJPayBaseListCellView.h"

@interface CJPayCommonListViewController ()<UITableViewDelegate,UITableViewDataSource,CJPayBaseListEventHandleProtocol>

@end

@implementation CJPayCommonListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 解决安全边距导致列表顶部空白的问题
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    [self.view addSubview:self.tableView];
    CJPayMasMaker(self.tableView, {
        make.centerX.width.bottom.equalTo(self.view);
        make.top.equalTo(self.view).offset([self navigationHeight]);
    });
}

- (void)reloadTableViewData {
    [self.tableView reloadData];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.backgroundColor = UIColor.whiteColor;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.scrollEnabled = YES;
    }
    return _tableView;
}

- (CJPayBaseListDataSource *)dataSource {
    if (!_dataSource) {
        _dataSource = [CJPayBaseListDataSource new];
    }
    return _dataSource;
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
        viewModel.viewController = self;
        Class cellClass = [viewModel getViewClass];
        NSString *reuseIdentifier = NSStringFromClass(cellClass);
        CJPayBaseListCellView *cell = [tableView dequeueReusableCellWithIdentifier: reuseIdentifier];
        if (!cell) {
            cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        }

        cell.eventHandler = self;
        [cell bindViewModel:viewModel];
        return cell;
    }
    return [[CJPayBaseListCellView alloc]init];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CJPayBaseListViewModel *viewModel = [self.dataSource viewModelAtIndexPath:indexPath];
    CJPayBaseListCellView *cell = viewModel.cell;
    if (cell) {
        CJ_DelayEnableView(self.view);
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

#pragma mark - CJPayBaseListEventHandleProtocol
- (void)handleWithEventName:(NSString *)eventName data:(id)data {
    
}

@end
