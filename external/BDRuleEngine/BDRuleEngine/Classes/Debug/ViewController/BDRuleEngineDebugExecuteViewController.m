//
//  BDRuleEngineDebugExecuteViewController.m
//  Indexer
//
//  Created by Chengmin Zhang on 2022/3/29.
//

#import "BDRuleEngineDebugExecuteViewController.h"
#import "BDRuleEngineDebugConstant.h"
#import "BDRuleEngineDebugUtil.h"
#import "BDRLToolItem.h"
#import "BDRLInputCell.h"
#import "BDRLButtonCell.h"
#import "BDRLTextCell.h"
#import "BDStrategyCenter.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>

static NSString *const BDRLInputCellReuseIdentifier = @"inputCell";
static NSString *const BDRLButtonCellReuseIdentifier = @"buttonCell";
static NSString *const BDRLTextCellReuseIdentifier = @"textCell";

static NSString *const SourceInputTitle = @"场景来源";
static NSString *const ParamInputTitle = @"业务参数";
static NSString *const StrategyInputTitle = @"策略列表";

@interface BDRuleEngineDebugExecuteViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<BDRLToolItem *> *items;
@property (nonatomic, strong) NSMutableDictionary *inputCells;
@property (nonatomic, strong) BDRLInputCell *strategiesCell;
@property (nonatomic, strong) BDRLTextCell *resultCell;

@end

@implementation BDRuleEngineDebugExecuteViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Strategy Center";
    self.view.backgroundColor = [UIColor whiteColor];
    [self loadItems];
    [self.view addSubview:self.tableView];
}

- (void)loadItems
{
    BDRLToolItem *sourceInput = [BDRLToolItem new];
    sourceInput.itemTitle = SourceInputTitle;
    sourceInput.inputType = BDRLToolItemInputTypeString;
    sourceInput.itemType = BDRLToolItemTypeInput;
    sourceInput.rowCount = 1;
    
    BDRLToolItem *paramsInput = [BDRLToolItem new];
    paramsInput.itemTitle = ParamInputTitle;
    paramsInput.inputType = BDRLToolItemInputTypeDictionary;
    paramsInput.itemType = BDRLToolItemTypeInput;
    paramsInput.rowCount = 3;
    
    BDRLToolItem *selectStrategy = [BDRLToolItem new];
    selectStrategy.itemTitle = @"策略获取";
    selectStrategy.itemType = BDRLToolItemTypeButton;
    selectStrategy.rowCount = 1;
    
    BDRLToolItem *strategyInput = [BDRLToolItem new];
    strategyInput.itemTitle = StrategyInputTitle;
    strategyInput.inputType = BDRLToolItemInputTypeArray;
    strategyInput.itemType = BDRLToolItemTypeInput;
    strategyInput.rowCount = 2;
    
    BDRLToolItem *strategyExecute = [BDRLToolItem new];
    strategyExecute.itemTitle = @"策略执行";
    strategyExecute.itemType = BDRLToolItemTypeButton;
    strategyExecute.rowCount = 1;
    
    BDRLToolItem *result = [BDRLToolItem new];
    result.itemType = BDRLToolItemTypeText;
    result.rowCount = 2;
    
    @weakify(self);
    selectStrategy.action = ^{
        @strongify(self);
        [self performSelectStrategy];
    };
    strategyExecute.action = ^{
        @strongify(self);
        [self performExecuteStrategy];
    };
    
    self.items = @[sourceInput, paramsInput, selectStrategy, strategyInput, strategyExecute, result];
}

- (void)performSelectStrategy
{
    BDRLInputCell *sourceInput = self.inputCells[SourceInputTitle];
    BDRLInputCell *paramsInput = self.inputCells[ParamInputTitle];
    if (!sourceInput || !paramsInput) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Error" message:@"未知错误" viewController:self];
        return;
    }
    NSString *source = [self buildDataWithInput:sourceInput.inputText type:sourceInput.data.inputType];
    NSDictionary *params = [self buildDataWithInput:paramsInput.inputText type:paramsInput.data.inputType];
    
    if (![source isKindOfClass:[NSString class]] || source.length == 0) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"请输入合法的场景来源" viewController:self];
        return;
    }
    
    if (![params isKindOfClass:[NSDictionary class]]) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"请输入合法的业务参数" viewController:self];
        return;
    }
    
    BDStrategyResultModel *result = [BDStrategyCenter generateStrategiesInSource:source params:params];
    
    if (!result) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"执行失败" message:@"错误原因: 未知" viewController:self];
        return;
    }
    
    if (result.engineError) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"执行失败" message: [NSString stringWithFormat:@"错误代码: %ld", (long)result.engineError.code] viewController:self];
        return;
    }
    
    if (self.strategiesCell) {
        self.strategiesCell.inputText = [result.strategyNames btd_safeJsonStringEncoded];
    }
    if (self.resultCell) {
        [self.resultCell setText:[result description]];
    }
    [BDRuleEngineDebugUtil showAlertWithTitle:@"执行成功" message:@"结果已自动填入策略列表" viewController:self];
}

- (void)performExecuteStrategy
{
    BDRLInputCell *sourceInput = self.inputCells[SourceInputTitle];
    BDRLInputCell *paramsInput = self.inputCells[ParamInputTitle];
    BDRLInputCell *strategiesInput = self.inputCells[StrategyInputTitle];
    if (!sourceInput || !paramsInput || !strategiesInput) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Error" message:@"未知错误" viewController:self];
        return;
    }
    NSString *source = [self buildDataWithInput:sourceInput.inputText type:sourceInput.data.inputType];
    NSDictionary *params = [self buildDataWithInput:paramsInput.inputText type:paramsInput.data.inputType];
    NSArray *strategies = [self buildDataWithInput:strategiesInput.inputText type:strategiesInput.data.inputType];
    if (![params isKindOfClass:[NSDictionary class]]) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"请输入合法的业务参数" viewController:self];
        return;
    }
    
    if (strategiesInput.inputText.length) {
        if ([strategies isKindOfClass:[NSArray class]]) {
            for (id item in strategies) {
                if (![item isKindOfClass:[NSString class]]) {
                    [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"请输入合法的策略名称" viewController:self];
                    return;
                }
            }
        } else {
            [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"请输入合法的策略列表" viewController:self];
            return;
        }
    }
    
    BDRuleResultModel *result = nil;
    if ([source isKindOfClass:[NSString class]] && source.length) {
        if ([strategies isKindOfClass:[NSArray class]]) {
            result = [BDStrategyCenter validateParams:params source:source strategyNames:strategies];
        } else {
            result = [BDStrategyCenter validateParams:params source:source];
        }
    } else {
        result = [BDStrategyCenter validateParams:params];
    }
    
    if (result.engineError) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"执行失败" message: [NSString stringWithFormat:@"错误代码: %ld", (long)result.engineError.code] viewController:self];
        return;
    }
    
    if (self.resultCell) {
        [self.resultCell setText:[result description]];
    }
    [BDRuleEngineDebugUtil showAlertWithTitle:@"执行成功" message:[NSString stringWithFormat:@"共计命中%ld个规则", (long)result.values.count] viewController:self];
}

- (id)buildDataWithInput:(NSString *)input type:(BDRLToolItemInputType)type
{
    if (!input) {
        return nil;
    }
    if (type == BDRLToolItemInputTypeString) {
        return input;
    }
    if (type == BDRLToolItemInputTypeArray) {
        return [input btd_jsonArray];
    }
    if (type == BDRLToolItemInputTypeDictionary) {
        return [input btd_jsonDictionary];
    }
    return nil;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    if (row < self.items.count) {
        return self.items[row].rowCount * BDDebugPerRowHeight;
    }
    return BDDebugPerRowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    if (row < self.items.count) {
        BDRLToolItem *item = self.items[row];
        NSString *identifier = nil;
        if (item.itemType == BDRLToolItemTypeInput) {
            identifier = BDRLInputCellReuseIdentifier;
        } else if (item.itemType == BDRLToolItemTypeButton) {
            identifier = BDRLButtonCellReuseIdentifier;
        } else if (item.itemType == BDRLToolItemTypeText) {
            identifier = BDRLTextCellReuseIdentifier;
        }
        if (identifier) {
            BDRLBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (item.itemType == BDRLToolItemTypeInput) {
                self.inputCells[item.itemTitle] = cell;
            }
            if ([item.itemTitle isEqualToString:StrategyInputTitle]) {
                self.strategiesCell = (BDRLInputCell *)cell;
            }
            if (item.itemType == BDRLToolItemTypeText) {
                self.resultCell = (BDRLTextCell *)cell;
            }
            [cell configWithData:self.items[row]];
            return cell;
        }
    }
    return [BDRLBaseCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= self.items.count) {
        return;
    }
    BDRLToolItem *item = self.items[indexPath.row];
    switch (item.itemType) {
        case BDRLToolItemTypeButton:
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

#pragma mark - UI Init

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        // register cell class here
        [_tableView registerClass:[BDRLInputCell class] forCellReuseIdentifier:BDRLInputCellReuseIdentifier];
        [_tableView registerClass:[BDRLButtonCell class] forCellReuseIdentifier:BDRLButtonCellReuseIdentifier];
        [_tableView registerClass:[BDRLTextCell class] forCellReuseIdentifier:BDRLTextCellReuseIdentifier];
        self.tableView.frame = self.view.bounds;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _tableView;
}

- (NSMutableDictionary *)inputCells
{
    if (!_inputCells) {
        _inputCells = [NSMutableDictionary dictionary];
    }
    return _inputCells;
}

@end
