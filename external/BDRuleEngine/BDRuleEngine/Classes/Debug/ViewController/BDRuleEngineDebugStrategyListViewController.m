//
//  BDRuleEngineDebugStrategyListViewController.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 27.4.22.
//

#import "BDRuleEngineDebugStrategyListViewController.h"
#import "BDRuleEngineDebugStrategyDetailViewController.h"
#import "BDRLStrategyListViewModel.h"
#import "BDRLToolItem.h"
#import "BDRLMoreCell.h"

@interface BDRuleEngineDebugStrategyListViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) BDRLStrategyListViewModel *viewModel;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation BDRuleEngineDebugStrategyListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"策略列表";
    self.view.backgroundColor = [UIColor whiteColor];
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section > 1) {
        BDRuleEngineDebugStrategyDetailViewController *nextViewController = [[BDRuleEngineDebugStrategyDetailViewController alloc] initWithViewModel:[self.viewModel viewModelAtIndexPath:indexPath]];
        nextViewController.title = [self.viewModel titleAtIndexPath:indexPath];
        [self.navigationController pushViewController:nextViewController animated:YES];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BDRLBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BDRLMoreCell class]) forIndexPath:indexPath];
    BDRLToolItem *item = [BDRLToolItem new];

    item.itemTitle = [self.viewModel titleAtIndexPath:indexPath];

    [cell configWithData:item];

    if (indexPath.section > 1) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

#pragma mark - Init

- (instancetype)initWithViewModel:(BDRLStrategyViewModel *)viewModel
{
    if (self = [super init]) {
        if ([viewModel isKindOfClass:[BDRLStrategyListViewModel class]]) {
            _viewModel = (BDRLStrategyListViewModel *)viewModel;
        }
    }
    return self;
}

#pragma mark - UI Init

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        [_tableView registerClass:[BDRLMoreCell class] forCellReuseIdentifier:NSStringFromClass([BDRLMoreCell class])];
        self.tableView.frame = self.view.bounds;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _tableView;
}


@end
