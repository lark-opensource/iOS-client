//
//  BDRuleEngineDebugRawJsonViewController.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 26.4.22.
//

#import "BDRuleEngineDebugRawJsonViewController.h"
#import "BDRLRawJsonViewModel.h"

@interface BDRuleEngineRawJsonCell: UITableViewCell
@property (nonatomic, strong) UITextView *textView;
@end

@implementation BDRuleEngineRawJsonCell

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

@interface BDRuleEngineDebugRawJsonViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) BDRLRawJsonViewModel *viewModel;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation BDRuleEngineDebugRawJsonViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
}

#pragma mark - tableView datasource & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.viewModel count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.view.frame.size.height * 0.85;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BDRuleEngineRawJsonCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BDRuleEngineRawJsonCell class]) forIndexPath:indexPath];

//    item.nextViewControllerClass = [BDRuleEngineDebugLevelStrategyViewController class];
    cell.textView.text = [self.viewModel jsonFormat];

    return cell;
}

#pragma mark - Init

- (instancetype)initWithViewModel:(BDRLStrategyViewModel *)viewModel
{
    if (self = [super init]) {
        if ([viewModel isKindOfClass:[BDRLRawJsonViewModel class]]) {
            _viewModel = (BDRLRawJsonViewModel *)viewModel;
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
        [_tableView registerClass:[BDRuleEngineRawJsonCell class] forCellReuseIdentifier:NSStringFromClass([BDRuleEngineRawJsonCell class])];
        self.tableView.frame = self.view.bounds;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _tableView;
}

@end
