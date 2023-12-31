//
//  BDRuleEngineDebugRunnerViewController.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/4/6.
//

#import "BDRuleEngineDebugRunnerViewController.h"

#import "BDRuleEngineDebugConstant.h"
#import "BDRuleEngineDebugUtil.h"
#import "BDRLToolItem.h"
#import "BDRLInputCell.h"
#import "BDRLButtonCell.h"
#import "BDRLTextCell.h"
#import "BDRLSwitchCell.h"
#import "BDRECommand.h"
#import "BDREInstruction.h"
#import "BDRuleEngineSettings.h"
#import "BDRuleParameterFetcher.h"
#import "BDREExprRunner.h"
#import "BDRuleQuickExecutor.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

static NSString *const BDRLInputCellReuseIdentifier    = @"inputCell";
static NSString *const BDRLButtonCellReuseIdentifier   = @"buttonCell";
static NSString *const BDRLTextCellReuseIdentifier     = @"textCell";
static NSString *const BDRLSwitcherCellReuseIdentifier = @"switcherCell";

static NSString *const ExpressionInputTitle   = @"表达式";
static NSString *const InstructionsInputTitle = @"指令队列";
static NSString *const ExtraDictInputTitle    = @"额外参数";


@interface BDRuleEngineDebugRunnerViewController ()<UITableViewDelegate, UITableViewDataSource, BDRLToolSwitchCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<BDRLToolItem *> *items;
@property (nonatomic, strong) NSMutableDictionary *inputCells;
@property (nonatomic, strong) BDRLTextCell *resultCell;
@property (nonatomic, assign) BOOL quickMode;

@end

@implementation BDRuleEngineDebugRunnerViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Runner Execute";
    self.view.backgroundColor = [UIColor whiteColor];
    [self loadItems];
    [self.view addSubview:self.tableView];
}

- (void)loadItems
{
    BDRLToolItem *expressionInput = [BDRLToolItem new];
    expressionInput.itemTitle = ExpressionInputTitle;
    expressionInput.inputType = BDRLToolItemInputTypeString;
    expressionInput.itemType = BDRLToolItemTypeInput;
    expressionInput.rowCount = 1;
    
    BDRLToolItem *parseExecute = [BDRLToolItem new];
    parseExecute.itemTitle = @"解析";
    parseExecute.itemType = BDRLToolItemTypeButton;
    parseExecute.rowCount = 1;
    @weakify(self);
    parseExecute.action = ^{
        @strongify(self);
        [self performParse];
    };
    
    BDRLToolItem *instructionItem = [BDRLToolItem new];
    instructionItem.itemTitle = InstructionsInputTitle;
    instructionItem.inputType = BDRLToolItemInputTypeArray;
    instructionItem.itemType = BDRLToolItemTypeInput;
    instructionItem.rowCount = 2;
    
    BDRLToolItem *extraDict = [BDRLToolItem new];
    extraDict.itemTitle = ExtraDictInputTitle;
    extraDict.inputType = BDRLToolItemInputTypeDictionary;
    extraDict.itemType = BDRLToolItemTypeInput;
    extraDict.rowCount = 2;
    
    BDRLToolItem *quickExecutor = [BDRLToolItem new];
    quickExecutor.itemTitle = @"快速模式";
    quickExecutor.itemType = BDRLToolItemTypeSwitch;
    quickExecutor.rowCount = 1;
    
    BDRLToolItem *celExecute = [BDRLToolItem new];
    celExecute.itemTitle = @"执行";
    celExecute.itemType = BDRLToolItemTypeButton;
    celExecute.rowCount = 1;
    celExecute.action = ^{
        @strongify(self);
        [self performRunnerExecute];
    };
    
    BDRLToolItem *result = [BDRLToolItem new];
    result.itemType = BDRLToolItemTypeText;
    result.rowCount = 2;
    
    self.items = @[expressionInput, parseExecute, instructionItem, extraDict, quickExecutor, celExecute, result];
}

- (void)performParse
{
    BDRLInputCell *expressionInput = [self.inputCells btd_objectForKey:ExpressionInputTitle default:nil];
    if (!expressionInput) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Error" message:@"未知错误" viewController:self];
        return;
    }
    
    NSString *expression = [self buildDataWithInput:expressionInput.inputText type:expressionInput.data.inputType];
    
    if (![expression isKindOfClass:[NSString class]] || expression.length == 0) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"请输入合法的执行表达式" viewController:self];
        return;
    }
    
    NSArray *commands = [[BDREExprRunner sharedRunner] commandsFromExpr:expression];
    
    if (!commands.count) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"无解析结果" viewController:self];
        return;
    }
    
    NSMutableArray *insts = [NSMutableArray arrayWithCapacity:commands.count];
    for (BDRECommand *command in commands) {
        NSDictionary *instDict = [[command instruction] jsonFormat];
        [insts btd_addObject:instDict];
    }
    
    if (!insts.count) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"指令生成失败" viewController:self];
        return;
    }
    
    BDRLInputCell *instructionsInput = [self.inputCells btd_objectForKey:InstructionsInputTitle default:nil];
    instructionsInput.inputText = [insts btd_jsonStringEncoded];
    [BDRuleEngineDebugUtil showAlertWithTitle:@"执行完成" message:@"" viewController:self];
}

- (void)performRunnerExecute
{
    BDRLInputCell *expressionInput = [self.inputCells btd_objectForKey:ExpressionInputTitle default:nil];
    BDRLInputCell *paramsInput = [self.inputCells btd_objectForKey:ExtraDictInputTitle default:nil];
    BDRLInputCell *instructionsInput = [self.inputCells btd_objectForKey:InstructionsInputTitle default:nil];
    
    if (!expressionInput || !paramsInput || !instructionsInput) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Error" message:@"未知错误" viewController:self];
        return;
    }
    
    NSString *expression = [self buildDataWithInput:expressionInput.inputText type:expressionInput.data.inputType];
    NSDictionary *params = [self buildDataWithInput:paramsInput.inputText type:paramsInput.data.inputType];
    
    if (paramsInput.inputText.length && ![params isKindOfClass:[NSDictionary class]]) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"请输入合法的额外参数" viewController:self];
        return;
    }
    
    BDRuleParameterFetcher *fetcher = [[BDRuleParameterFetcher alloc] initWithExtraParameters: params];
    NSArray *instructions = [self buildDataWithInput:instructionsInput.inputText type:instructionsInput.data.inputType];
    NSArray *commands = [BDREInstruction commandsWithJsonArray:instructions];
    
    if (!expression.length && !commands.count) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"请输入合法的表达式或指令队列" viewController:self];
        return;
    }
    NSDictionary *mergedResult = nil;
    if (self.quickMode) {
        BDRuleQuickExecutor *quickExecutor = [self quickExecutor];
        if (!quickExecutor) {
            return;
        }
        NSError *error;
        BOOL res = [quickExecutor evaluateWithEnv:fetcher error:&error];
        mergedResult = @{
            @"result" : @(res),
            @"error"  : error ?: @""
        };
    } else {
        BDREExprResponse *response = [[BDREExprRunner sharedRunner] execute:expression preCommands:commands withEnv:fetcher uuid:nil];
        if (!response) {
            [BDRuleEngineDebugUtil showAlertWithTitle:@"执行失败" message:@"错误原因: 未知" viewController:self];
            return;
        }
        mergedResult = @{
            @"response" : [response jsonFormat],
            @"usedParameters" : fetcher.usedParameters ?: @""
        };
    }
    if (self.resultCell) {
        [self.resultCell setText:[mergedResult btd_jsonStringEncoded]];
    }
    [BDRuleEngineDebugUtil showAlertWithTitle:@"执行完成" message:@"" viewController:self];
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

# pragma mark - BDRLToolSwitchCellDelegate
- (void)handleCellSwitchChange:(BDRLSwitchCell *)cell
{
    BOOL isOn = cell.switchCtrl.isOn;
    // 关闭
    if (!isOn) {
        self.quickMode = NO;
        return;
    }
    // 开启 进行校验
    if (![self quickExecutor]) {
        self.quickMode = NO;
        [cell.switchCtrl setOn:NO];
        return;
    }
    // 生效
    self.quickMode = YES;
}

- (BDRuleQuickExecutor *)quickExecutor
{
    if (![BDRuleEngineSettings enableQuickExecutor]) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"无法使用快速模式" message:@"下发配置为关闭" viewController:self];
        return nil;
    }
    BDRLInputCell *expressionInput = [self.inputCells btd_objectForKey:ExpressionInputTitle default:nil];
    BDRLInputCell *instructionsInput = [self.inputCells btd_objectForKey:InstructionsInputTitle default:nil];
    
    NSArray *instructions = [self buildDataWithInput:instructionsInput.inputText type:instructionsInput.data.inputType];
    NSArray *commands = [BDREInstruction commandsWithJsonArray:instructions];
    
    if (!commands.count) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"无法使用快速模式" message:@"指令队列为空" viewController:self];
        return nil;
    }
    NSString *expression = [self buildDataWithInput:expressionInput.inputText type:expressionInput.data.inputType];
    
    BDRuleQuickExecutor *executor = [BDRuleQuickExecutorFactory createExecutorWithCommands:commands cel:expression];
    if (!executor) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"无法使用快速模式" message:@"表达式不符合规定形式" viewController:self];
    }
    return executor;
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
        } else if (item.itemType == BDRLToolItemTypeSwitch) {
            identifier = BDRLSwitcherCellReuseIdentifier;
        }
        if (identifier) {
            BDRLBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (item.itemType == BDRLToolItemTypeInput) {
                [self.inputCells btd_setObject:cell forKey:item.itemTitle];
            }
            if (item.itemType == BDRLToolItemTypeText) {
                self.resultCell = (BDRLTextCell *)cell;
            }
            if (item.itemType == BDRLToolItemTypeSwitch) {
                ((BDRLSwitchCell *)cell).delegate = self;
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

#pragma mark - Init

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
        [_tableView registerClass:[BDRLSwitchCell class] forCellReuseIdentifier:BDRLSwitcherCellReuseIdentifier];
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
