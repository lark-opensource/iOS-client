//
//  BDRuleEngineDebugParameterViewController.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/13.
//

#import "BDRuleEngineDebugParameterViewController.h"
#import "BDRuleEngineMockParametersStore.h"
#import "BDRuleEngineDebugUtil.h"
#import "BDRuleParameterRegistry.h"
#import "BDRLParameterCell.h"
#import "BDRLToolItem.h"
#import "BDRLButtonCell.h"
#import "BDRLSwitchCell.h"

#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>

static NSString *const BDRLMockParametersTitle = @"Mock Enable";

@interface BDRuleEngineDebugParameterViewController()<UITableViewDelegate, UITableViewDataSource, BDRLToolParameterDelegate, BDRLToolSwitchCellDelegate>

@property (nonatomic, copy) NSArray<BDRuleParameterBuilderModel *> *stateItems;
@property (nonatomic, copy) NSArray<BDRuleParameterBuilderModel *> *constItems;

@property (nonatomic, strong) NSArray <BDRLToolItem *> *configItems;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation BDRuleEngineDebugParameterViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self __setupData];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Parameter List";
    [self.view addSubview:self.tableView];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

- (void)__setupData
{
    self.stateItems = [BDRuleParameterRegistry stateParameters];
    self.constItems = [BDRuleParameterRegistry constParameters];
    
    BDRLToolItem *resetMockItem = [BDRLToolItem new];
    resetMockItem.itemTitle = @"Mock Reset";
    resetMockItem.itemType = BDRLToolItemTypeButton;
    @weakify(self);
    resetMockItem.action = ^{
        @strongify(self);
        [[BDRuleEngineMockParametersStore sharedStore] resetMock];
        [self __setupData];
        [self.tableView reloadData];
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Success"message:@"Mock已重置" viewController:self];
    };
    
    BDRLToolItem *enableMockItem = [BDRLToolItem new];
    enableMockItem.itemTitle = BDRLMockParametersTitle;
    enableMockItem.itemType = BDRLToolItemTypeSwitch;
    enableMockItem.isOn = [BDRuleEngineMockParametersStore enableMock];
    
    self.configItems = @[enableMockItem, resetMockItem];
}

#pragma mark - tableView datasource & delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return @"State";
    } else if (section == 2) {
        return @"Const";
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.configItems.count;
    } else if (section == 1) {
        return self.stateItems.count;
    } else if (section == 2){
        return self.constItems.count;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        BDRLToolItem *item = self.configItems[indexPath.row];
        !item.action ?: item.action();
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 50;
    }
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        BDRLToolItem *item = self.configItems[indexPath.row];
        if (item.itemType == BDRLToolItemTypeSwitch) {
            BDRLSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BDRLSwitchCell class]) forIndexPath:indexPath];
            cell.delegate = self;
            [cell configWithData:item];
            return cell;
        } else if (item.itemType == BDRLToolItemTypeButton) {
            BDRLButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BDRLButtonCell class]) forIndexPath:indexPath];
            [cell configWithData:item];
            return cell;
        }
    } else {
        NSArray *items = @[];
        if (indexPath.section == 1) {
            items = self.stateItems;
        } else if (indexPath.section == 2) {
            items = self.constItems;
        }
        if (indexPath.row >= items.count) {
            return [UITableViewCell new];
        }
        BDRuleParameterBuilderModel *item = items[indexPath.row];
        BDRLParameterCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BDRLParameterCell class]) forIndexPath:indexPath];
        cell.delegate = self;
        [cell configWithData:item];
        return cell;
    }
    return [UITableViewCell new];
}

#pragma mark - UI Init

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        [_tableView registerClass:[BDRLParameterCell class] forCellReuseIdentifier:NSStringFromClass([BDRLParameterCell class])];
        [_tableView registerClass:[BDRLButtonCell class] forCellReuseIdentifier:NSStringFromClass([BDRLButtonCell class])];
        [_tableView registerClass:[BDRLSwitchCell class] forCellReuseIdentifier:NSStringFromClass([BDRLSwitchCell class])];
        self.tableView.frame = self.view.bounds;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _tableView;
}

#pragma mark -- BDRLToolParameterDelegate
- (void)handleParameterValueChanged:(BDRuleParameterBuilderModel *)parameter value:(NSString *)value
{
    if (!value) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Error"message:@"未知错误" viewController:self];
        return;
    }
    id convertedValue = nil;
    if (parameter.type == BDRuleParameterTypeNumberOrBool) {
        if (![value btd_numberValue]) {
            [BDRuleEngineDebugUtil showAlertWithTitle:@"Error"message:@"请输入数字或布尔变量" viewController:self];
            return;
        }
        convertedValue = [value btd_numberValue];
    } else if (parameter.type == BDRuleParameterTypeString) {
        convertedValue = value;
    } else {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Error"message:@"暂不支持该类型变量" viewController:self];
        return;
    }
    [[BDRuleEngineMockParametersStore sharedStore] saveMockValue:convertedValue forKey:parameter.key];
    [BDRuleEngineDebugUtil showAlertWithTitle:@"Success"message:@"设置成功" viewController:self];
}

#pragma mark - BDRLToolSwitchCellDelegate
- (void)handleSwitchChange:(BOOL)isOn itemTitle:(NSString *)itemTitle
{
    if ([itemTitle isEqualToString:BDRLMockParametersTitle]) {
        [BDRuleEngineMockParametersStore setEnableMock:isOn];
        [self __setupData];
        [self.tableView reloadData];
    }
}

@end
