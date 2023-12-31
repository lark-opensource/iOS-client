//
//  BDRuleEngineDebugParameterRegisterViewController.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/3/31.
//

#import "BDRuleEngineDebugParameterRegisterViewController.h"
#import "BDRuleEngineDebugConstant.h"
#import "BDRuleEngineDebugUtil.h"
#import "BDRuleParameterDefine.h"
#import "BDRLToolItem.h"
#import "BDRLInputCell.h"
#import "BDRLButtonCell.h"

#import "BDRuleParameterRegistry.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

static NSString *const BDRLInputCellReuseIdentifier = @"inputCell";
static NSString *const BDRLButtonCellReuseIdentifier = @"buttonCell";

static NSString *const ParameterKeyInputTitle = @"Key";
static NSString *const ParameterTypeInputTitle = @"Type";
static NSString *const ParameterOriginInputTitle = @"Origin";
static NSString *const ParameterValueInputTitle = @"Value";
static NSString *const ExecuteTitle = @"Register";

static NSString *const TypeActionSheetTitle = @"Select Type";
static NSString *const OriginActionSheetTitle = @"Select Origin";

@interface BDRuleEngineDebugParameterRegisterViewController ()<UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<BDRLToolItem *> *items;
@property (nonatomic, strong) NSMutableDictionary *inputCells;

@property (nonatomic, assign) BDRuleParameterType inputType;
@property (nonatomic, assign) BDRuleParameterOrigin originType;
@property (nonatomic, copy, readonly) NSString *inputTypeTitle;
@property (nonatomic, copy, readonly) NSString *originTypeTitle;
@property (nonatomic, strong, readonly) NSDictionary *inputTypeDict;
@property (nonatomic, strong, readonly) NSDictionary *originTypeDict;

@end

@implementation BDRuleEngineDebugParameterRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Parameter Register";
    self.view.backgroundColor = [UIColor whiteColor];
    [self loadItems];
    [self.view addSubview:self.tableView];
}

- (void)loadItems {
    self.inputType = BDRuleParameterTypeString;
    self.originType = BDRuleParameterOriginState;
    
    BDRLToolItem *keyInput = [BDRLToolItem new];
    keyInput.itemTitle = ParameterKeyInputTitle;
    keyInput.inputType = BDRLToolItemInputTypeString;
    keyInput.itemType = BDRLToolItemTypeInput;
    keyInput.rowCount = 1;
    
    BDRLToolItem *typeInput = [BDRLToolItem new];
    typeInput.itemTitle = ParameterTypeInputTitle;
    typeInput.inputType = BDRLToolItemInputTypeString;
    typeInput.itemType = BDRLToolItemTypeInput;
    typeInput.inputDisable = YES;
    typeInput.rowCount = 1;
    
    BDRLToolItem *originInput = [BDRLToolItem new];
    originInput.itemTitle = ParameterOriginInputTitle;
    originInput.inputType = BDRLToolItemInputTypeString;
    originInput.itemType = BDRLToolItemTypeInput;
    originInput.inputDisable = YES;
    originInput.rowCount = 1;
    
    BDRLToolItem *valueInput = [BDRLToolItem new];
    valueInput.itemTitle = ParameterValueInputTitle;
    valueInput.inputType = BDRLToolItemInputTypeString;
    valueInput.itemType = BDRLToolItemTypeInput;
    valueInput.rowCount = 3;
    
    BDRLToolItem *execute = [BDRLToolItem new];
    execute.itemTitle = ExecuteTitle;
    execute.itemType = BDRLToolItemTypeButton;
    execute.rowCount = 1;
    
    @weakify(self);
    execute.action = ^{
        @strongify(self);
        [self performParameterRegister];
    };
    
    typeInput.action = ^{
        @strongify(self);
        [self showSelectTypeActionSheet];
    };
    
    originInput.action = ^{
        @strongify(self);
        [self showSelectOriginActionSheet];
    };
    
    self.items = @[keyInput, typeInput, originInput, valueInput, execute];
}

- (void)performParameterRegister
{
    BDRLInputCell *keyInput = self.inputCells[ParameterKeyInputTitle];
    BDRLInputCell *valueInput = self.inputCells[ParameterValueInputTitle];
    if (!keyInput || !valueInput) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Error" message:@"未知错误" viewController:self];
        return;
    }
    
    NSString *key = keyInput.inputText;
    
    if (![key isKindOfClass:[NSString class]] || key.length == 0) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"请输入合法的Key" viewController:self];
        return;
    }
    
    NSArray<BDRuleParameterBuilderModel *> *paramModels = [BDRuleParameterRegistry allParameters];
    
    for (BDRuleParameterBuilderModel *model in paramModels) {
        if ([model.key isEqualToString:key]) {
            [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"该Key已经被注册" viewController:self];
            return;
        }
    }
    
    if (valueInput.inputText.length == 0 && self.inputType != BDRuleParameterTypeString) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"请输入Value" viewController:self];
        return;
    }
    
    id value = [self buildDataWithInput:valueInput.inputText type:self.inputType];
    if (!value) {
        [BDRuleEngineDebugUtil showAlertWithTitle:@"Warning" message:@"输入Value与类型不匹配" viewController:self];
        return;
    }
    
    if (self.originType == BDRuleParameterOriginState) {
        [BDRuleParameterRegistry registerParameterWithKey:key type:self.inputType builder:^id _Nonnull(id<BDRuleParameterBuilderProtocol> fetcher) {
            return value;
        }];
    } else if (self.originType == BDRuleParameterOriginConst) {
        [BDRuleParameterRegistry registerConstParameterWithKey:key type:self.inputType builder:^id _Nonnull(id<BDRuleParameterBuilderProtocol> fetcher) {
            return value;
        }];
    }
   
    [BDRuleEngineDebugUtil showAlertWithTitle:@"注册成功" message:@"可在Parameters中查看结果" viewController:self];
}

- (id)buildDataWithInput:(NSString *)input type:(BDRuleParameterType)type
{
    if (!input) {
        return nil;
    }
    switch (type) {
        case BDRuleParameterTypeNumberOrBool:
            return [input btd_numberValue];
        case BDRuleParameterTypeString:
            return input;
        case BDRuleParameterTypeArray:
            return [input btd_jsonArray];
        case BDRuleParameterTypeDictionary:
            return [input btd_jsonDictionary];
        case BDRuleParameterTypeUnknown:
            return nil;
    }
}

- (void)showSelectOriginActionSheet
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                      initWithTitle:OriginActionSheetTitle
                                      delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                      otherButtonTitles:@"State", @"Const", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showInView:self.view];
}

- (void)showSelectTypeActionSheet
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                      initWithTitle:TypeActionSheetTitle
                                      delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                      otherButtonTitles:@"String", @"Number/Bool",  @"Array" , @"Dictionary" ,nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showInView:self.view];
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
        }
        if (identifier) {
            BDRLBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (item.itemType == BDRLToolItemTypeInput) {
                self.inputCells[item.itemTitle] = cell;
                if (item.itemTitle == ParameterTypeInputTitle) {
                    [(BDRLInputCell *)cell setInputText:self.inputTypeTitle];
                }
                if (item.itemTitle == ParameterOriginInputTitle) {
                    [(BDRLInputCell *)cell setInputText:self.originTypeTitle];
                }
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
    !item.action ?: item.action();
    return;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (buttonIndex == [actionSheet cancelButtonIndex]) {
        return;
    }
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (actionSheet.title == TypeActionSheetTitle) {
        NSNumber *typeNumber = [self.inputTypeDict btd_numberValueForKey:title];
        self.inputType = [typeNumber integerValue];
        BDRLInputCell *typeCell = [self.inputCells btd_objectForKey:ParameterTypeInputTitle default:nil];
        typeCell.inputText = title;
    } else if (actionSheet.title == OriginActionSheetTitle) {
        NSNumber *typeNumber = [self.originTypeDict btd_numberValueForKey:title];
        self.originType = [typeNumber integerValue];
        BDRLInputCell *typeCell = [self.inputCells btd_objectForKey:ParameterOriginInputTitle default:nil];
        typeCell.inputText = title;
    }
}


#pragma mark - Lazy Load
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

- (NSString *)inputTypeTitle
{
    switch (self.inputType) {
        case BDRuleParameterTypeNumberOrBool:
            return @"Number/Bool";
        case BDRuleParameterTypeString:
            return @"String";
        case BDRuleParameterTypeArray:
            return @"Array";
        case BDRuleParameterTypeDictionary:
            return @"Dictionary";
        case BDRuleParameterTypeUnknown:
            return @"Unknown";
    }
}

- (NSString *)originTypeTitle
{
    switch (self.originType) {
        case BDRuleParameterOriginConst:
            return @"Const";
        case BDRuleParameterOriginState:
            return @"State";
    }
}

- (NSDictionary *)inputTypeDict
{
    return @{
        @"Number/Bool": @(BDRuleParameterTypeNumberOrBool),
        @"String": @(BDRuleParameterTypeString),
        @"Array": @(BDRuleParameterTypeArray),
        @"Dictionary" : @(BDRuleParameterTypeDictionary),
        @"Unknown" : @(BDRuleParameterTypeUnknown)
    };
}

- (NSDictionary *)originTypeDict
{
    return @{
        @"State": @(BDRuleParameterOriginState),
        @"Const": @(BDRuleParameterOriginConst)
    };
}

@end
