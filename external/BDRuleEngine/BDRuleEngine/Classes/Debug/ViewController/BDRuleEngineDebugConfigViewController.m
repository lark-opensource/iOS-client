//
//  BDRuleEngineDebugConfigViewController.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/6/6.
//

#import "BDRuleEngineDebugConfigViewController.h"
#import "BDRuleEngineMockConfigStore.h"
#import "BDRuleEngineDebugUtil.h"
#import "BDRuleEngineSettings+Mock.h"
#import "BDRuleEngineDebugConstant.h"
#import "BDRLToolItem.h"
#import "BDRLInputCell.h"
#import "BDRLButtonCell.h"
#import "BDRLSwitchCell.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

static NSString *const BDRLMockConfigTitle = @"Mock Enable";
static NSString *const BDRLConfigDictTitle = @"Settings";
static NSString *const ExecuteTitle = @"Save Config";

@interface BDRuleEngineDebugConfigViewController ()<UITableViewDelegate, UITableViewDataSource, BDRLToolSwitchCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) BDRLInputCell *configCell;
@property (nonatomic, strong) NSArray<BDRLToolItem *> *items;

@end

@implementation BDRuleEngineDebugConfigViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self __setupData];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Config Setting";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.tableView];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

- (void)__setupData
{
    BDRLToolItem *enableMockItem = [BDRLToolItem new];
    enableMockItem.itemTitle = BDRLMockConfigTitle;
    enableMockItem.itemType = BDRLToolItemTypeSwitch;
    enableMockItem.isOn = [BDRuleEngineMockConfigStore enableMock];
    enableMockItem.rowCount = 1;
    
    BDRLToolItem *configItem = [BDRLToolItem new];
    configItem.itemTitle = BDRLConfigDictTitle;
    configItem.inputType = BDRLToolItemInputTypeDictionary;
    configItem.itemType = BDRLToolItemTypeInput;
    configItem.rowCount = 3;
    
    BDRLToolItem *execute = [BDRLToolItem new];
    execute.itemTitle = ExecuteTitle;
    execute.itemType = BDRLToolItemTypeButton;
    execute.rowCount = 1;
    @weakify(self);
    execute.action = ^{
        @strongify(self);
        [self performSaveMockConfig];
    };
    
    self.items = @[enableMockItem, configItem, execute];
}

- (void)performSaveMockConfig
{
    if (!self.configCell) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Error" message:@"未知错误" viewController:self];
        return;
    }
    NSDictionary *value = [self.configCell.inputText btd_jsonDictionary];
    if (!value) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"请输入合法的配置" viewController:self];
        return;
    }
    [[BDRuleEngineMockConfigStore sharedStore] saveMockConfigValue:value];
    [self.configCell setInputText:[value btd_jsonStringPrettyEncoded]];
    [BDRuleEngineDebugUtil showAlertWithTitle:@"保存成功" message:@"若使用请开启Mock" viewController:self];
}

#pragma mark - tableView datasource & delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        BDRLToolItem *item = self.items[indexPath.row];
        !item.action ?: item.action();
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return BDDebugPerRowHeight * self.items[indexPath.row].rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BDRLToolItem *item = self.items[indexPath.row];
    if (item.itemType == BDRLToolItemTypeSwitch) {
        BDRLSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BDRLSwitchCell class]) forIndexPath:indexPath];
        cell.delegate = self;
        [cell configWithData:item];
        return cell;
    } else if (item.itemType == BDRLToolItemTypeButton) {
        BDRLButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BDRLButtonCell class]) forIndexPath:indexPath];
        [cell configWithData:item];
        return cell;
    } else if (item.itemType == BDRLToolItemTypeInput) {
        BDRLInputCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BDRLInputCell class]) forIndexPath:indexPath];
        [cell configWithData:item];
        if (item.itemTitle == BDRLConfigDictTitle) {
            [(BDRLInputCell *)cell setInputText:[[BDRuleEngineSettings config] btd_jsonStringPrettyEncoded] ?: @""];
            self.configCell = cell;
        }
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
        [_tableView registerClass:[BDRLButtonCell class] forCellReuseIdentifier:NSStringFromClass([BDRLButtonCell class])];
        [_tableView registerClass:[BDRLSwitchCell class] forCellReuseIdentifier:NSStringFromClass([BDRLSwitchCell class])];
        [_tableView registerClass:[BDRLInputCell class] forCellReuseIdentifier:NSStringFromClass([BDRLInputCell class])];
        _tableView.backgroundColor = [UIColor whiteColor];
        self.tableView.frame = self.view.bounds;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _tableView;
}

#pragma mark - BDRLToolSwitchCellDelegate
- (void)handleSwitchChange:(BOOL)isOn itemTitle:(NSString *)itemTitle
{
    if ([itemTitle isEqualToString:BDRLMockConfigTitle]) {
        [BDRuleEngineMockConfigStore setEnableMock:isOn];
        [self __setupData];
        [self.tableView reloadData];
    }
}

@end


