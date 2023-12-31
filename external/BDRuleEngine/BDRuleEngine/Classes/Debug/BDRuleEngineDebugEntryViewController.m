//
//  BDRuleEngineDebugEntryViewController.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/13.
//

#import "BDRuleEngineDebugEntryViewController.h"
#import "BDRuleEngineMockParametersStore.h"
#import "BDRuleEngineDebugParameterViewController.h"
#import "BDRuleEngineDebugExecuteViewController.h"
#import "BDRuleEngineDebugParameterRegisterViewController.h"
#import "BDRuleEngineDebugRunnerViewController.h"
#import "BDRuleEngineDebugProviderListViewController.h"
#import "BDRuleEngineDebugConfigViewController.h"
#import "BDRuleEngineDebugConstant.h"
#import "BDRLToolItem.h"
#import "BDRLSwitchCell.h"
#import "BDRLMoreCell.h"
#import "BDStrategyCenter.h"
#import "BDREExprRunner.h"
#import "BDREExprEnv.h"

static NSString *const BDRLMoreCellReuseIdentifier = @"moreCell";
static NSString *const BDRLSwitchCellReuseIdentifier = @"switchCell";

static NSString *const BDRLConfigTitle = @"Config Setting";
static NSString *const BDRLParametersTitle = @"Parameter List";
static NSString *const BDRLParameterRegisterTitle = @"Parameter Register";
static NSString *const BDRLExecuteTitle = @"Strategy Center";
static NSString *const BDRLRunnerTitle = @"Runner Execute";
static NSString *const BDRLProviderTitle = @"Strategy List";

@interface BDRuleEngineDebugEntryViewController()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSMutableArray <BDRLToolItem *> *itemArray;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation BDRuleEngineDebugEntryViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.itemArray = [self __setupData];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    self.title = @"RuleEngine Debug Tool";
}

#pragma mark - Private

- (NSMutableArray <BDRLToolItem *> *)__setupData
{
    NSMutableArray *mutableItems = [NSMutableArray array];
    
    BDRLToolItem *configItem = [BDRLToolItem new];
    configItem.itemTitle = BDRLConfigTitle;
    configItem.itemType = BDRLToolItemTypeMore;
    configItem.nextViewControllerClass = [BDRuleEngineDebugConfigViewController class];
    [mutableItems addObject:configItem];

    BDRLToolItem *parametersItem = [BDRLToolItem new];
    parametersItem.itemTitle = BDRLParametersTitle;
    parametersItem.itemType = BDRLToolItemTypeMore;
    parametersItem.nextViewControllerClass = [BDRuleEngineDebugParameterViewController class];
    [mutableItems addObject:parametersItem];
    
    BDRLToolItem *parametersRegiterItem = [BDRLToolItem new];
    parametersRegiterItem.itemTitle = BDRLParameterRegisterTitle;
    parametersRegiterItem.itemType = BDRLToolItemTypeMore;
    parametersRegiterItem.nextViewControllerClass = [BDRuleEngineDebugParameterRegisterViewController class];
    [mutableItems addObject:parametersRegiterItem];

    BDRLToolItem *strategyProvidersItem = [BDRLToolItem new];
    strategyProvidersItem.itemTitle = BDRLProviderTitle;
    strategyProvidersItem.itemType = BDRLToolItemTypeMore;
    strategyProvidersItem.nextViewControllerClass = [BDRuleEngineDebugProviderListViewController class];
    [mutableItems addObject:strategyProvidersItem];
    
    BDRLToolItem *executeItem = [BDRLToolItem new];
    executeItem.itemTitle = BDRLExecuteTitle;
    executeItem.itemType = BDRLToolItemTypeMore;
    executeItem.nextViewControllerClass = [BDRuleEngineDebugExecuteViewController class];
    [mutableItems addObject:executeItem];
    
    BDRLToolItem *runnerItem = [BDRLToolItem new];
    runnerItem.itemTitle = BDRLRunnerTitle;
    runnerItem.itemType = BDRLToolItemTypeMore;
    runnerItem.nextViewControllerClass = [BDRuleEngineDebugRunnerViewController class];
    [mutableItems addObject:runnerItem];
    
    return mutableItems;
}

- (void)addItem:(BDRLToolItem *)item
{
    [self.itemArray addObject:item];
}

#pragma mark - tableView datasource & delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.itemArray.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= self.itemArray.count) {
        return;
    }
    BDRLToolItem *item = self.itemArray[indexPath.row];
    switch (item.itemType) {
        case BDRLToolItemTypeMore:
        {
            if (item.nextViewControllerClass == nil) {
                item.nextViewControllerClass = [UIViewController class];
            }
            if ([item.itemTitle isEqualToString:BDRLProviderTitle]) {
                BDRuleEngineDebugProviderListViewController *vc = [item.nextViewControllerClass new];
                vc.title = item.itemTitle;
                [self.navigationController pushViewController:vc animated:YES];
            }
            else {
                [self.navigationController pushViewController:[item.nextViewControllerClass new] animated:YES];
            }
        }
            break;
        case BDRLToolItemTypeAction:
        {
            if (item.action != nil) {
                item.action();
            }
        }
            break;
        default:
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= self.itemArray.count) {
        return [UITableViewCell new];
    }
    
    BDRLToolItem *item = self.itemArray[indexPath.row];
    
    BDRLBaseCell *cell;
    
    switch (item.itemType) {
        case BDRLToolItemTypeMore:
        case BDRLToolItemTypeAction:
        default:
            cell = [tableView dequeueReusableCellWithIdentifier:BDRLMoreCellReuseIdentifier];
            break;
    }
    
    [cell configWithData:item];
    
    return cell;
}

#pragma mark - UI Init

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        [_tableView registerClass:[BDRLMoreCell class] forCellReuseIdentifier:BDRLMoreCellReuseIdentifier];
        self.tableView.frame = self.view.bounds;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _tableView;
}

@end
