//
//  BDRuleEngineDebugProviderListViewController.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 26.4.22.
//

#import "BDRuleEngineDebugProviderListViewController.h"
#import "BDRuleEngineDebugRawJsonViewController.h"
#import "BDRuleEngineDebugSceneListViewController.h"
#import "BDRLProviderListViewModel.h"
#import "BDRLToolItem.h"
#import "BDRLStrategyButtonCell.h"

@interface BDRuleEngineDebugProviderListViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) BDRLProviderListViewModel *viewModel;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation BDRuleEngineDebugProviderListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Strategy List";
    self.view.backgroundColor = [UIColor whiteColor];
    [self __setupData];
    [self.view addSubview:self.tableView];
}

#pragma mark - tableView datasource & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.viewModel count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= [self.viewModel count]) {
        return;
    }

    if (indexPath.section == [self.viewModel count] - 1) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        BDRuleEngineDebugSceneListViewController *nextViewController = [[BDRuleEngineDebugSceneListViewController alloc] initWithViewModel:[self.viewModel viewModelAtIndexPath:indexPath]];
        nextViewController.title = [self.viewModel titleAtIndexPath:indexPath];
        [self.navigationController pushViewController:nextViewController animated:YES];
        return;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    BDRuleEngineDebugRawJsonViewController *nextViewController = [[BDRuleEngineDebugRawJsonViewController alloc] initWithViewModel:[self.viewModel viewModelAtIndexPath:indexPath]];
    nextViewController.title = [self.viewModel titleAtIndexPath:indexPath];
    [self.navigationController pushViewController:nextViewController animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BDRLBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BDRLStrategyButtonCell class]) forIndexPath:indexPath];
    BDRLToolItem *item = [BDRLToolItem new];

    item.itemTitle = [self.viewModel titleAtIndexPath:indexPath];

    [cell configWithData:item];

    return cell;
}

#pragma mark - Private

- (void)__setupData
{
    _viewModel = [[BDRLProviderListViewModel alloc] init];
}

#pragma mark - UI Init

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        [_tableView registerClass:[BDRLStrategyButtonCell class] forCellReuseIdentifier:NSStringFromClass([BDRLStrategyButtonCell class])];
        self.tableView.frame = self.view.bounds;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _tableView;
}

@end
