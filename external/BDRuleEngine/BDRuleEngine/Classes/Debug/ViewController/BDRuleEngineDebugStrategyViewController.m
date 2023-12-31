//
//  BDRuleEngineDebugStrategyViewController.m
//  BDRuleEngine
//
//  Created by WangKun on 2022/1/4.
//

#import "BDRuleEngineDebugStrategyViewController.h"
#import "BDStrategyCenter+Debug.h"
#import "BDStrategyProvider.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDRuleEngineStrategyCell: UITableViewCell
@property (nonatomic, strong) UITextView *textView;
@end


@implementation BDRuleEngineStrategyCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:[self textView]];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textView.frame = CGRectMake(20, 0, self.contentView.bounds.size.width - 20, self.contentView.bounds.size.height);
}

- (UITextView *)textView
{
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.editable = NO;
    }
    return _textView;
}

@end

@interface BDRuleEngineDebugStrategyViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, copy) NSArray<id<BDStrategyProvider>> *providers;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation BDRuleEngineDebugStrategyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Strategies";
    self.view.backgroundColor = [UIColor whiteColor];
    self.providers = [BDStrategyCenter providers];
    [self.view addSubview:self.tableView];
    // Do any additional setup after loading the view.
}


#pragma mark - tableView datasource & delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _providers.count + 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section < _providers.count) {
        return NSStringFromClass([_providers[section] class]);
    }
    return @"merged";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 300;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BDRuleEngineStrategyCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BDRuleEngineStrategyCell class]) forIndexPath:indexPath];
    if (indexPath.section < _providers.count) {
        NSString *json = [[_providers[indexPath.section] strategies] btd_jsonStringPrettyEncoded];
        cell.textView.text = json;
    } else {
        cell.textView.text = [[BDStrategyCenter mergedStrategies] btd_jsonStringPrettyEncoded];
    }
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
        [_tableView registerClass:[BDRuleEngineStrategyCell class] forCellReuseIdentifier:NSStringFromClass([BDRuleEngineStrategyCell class])];
        self.tableView.frame = self.view.bounds;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _tableView;
}


@end
