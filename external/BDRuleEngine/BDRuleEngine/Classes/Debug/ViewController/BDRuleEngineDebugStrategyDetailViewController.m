//
//  BDRuleEngineDebugStrategyDetailViewController.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 27.4.22.
//

#import "BDRuleEngineDebugStrategyDetailViewController.h"
#import "BDRLStrategyDetailViewModel.h"

@interface BDRuleEnginePolicyCell: UITableViewCell
@property (nonatomic, strong) UITextView *textView;
@end

@implementation BDRuleEnginePolicyCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:[self textView]];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textView.frame = CGRectMake(15, 10, self.contentView.frame.size.width - 30, self.contentView.frame.size.height - 20);
}

- (UITextView *)textView
{
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.textAlignment = NSTextAlignmentLeft;
        _textView.font = [UIFont systemFontOfSize:14];
        _textView.editable = NO;
        _textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        _textView.layer.borderWidth = 0.8;
        _textView.layer.cornerRadius = 5.0;
        _textView.layer.masksToBounds = YES;
    }
    return _textView;
}

@end

@interface BDRuleEngineDebugStrategyDetailViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) BDRLStrategyDetailViewModel *viewModel;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation BDRuleEngineDebugStrategyDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
}

#pragma mark - tableView datasource & delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.viewModel count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section > 0) return nil;
    UITextView *textView = [[UITextView alloc] init];
    textView.text = [NSString stringWithFormat:@"   %@\n   %@\n   规则列表:", [self.viewModel strategyTitle], [self.viewModel strategyCel]];
    textView.textAlignment = NSTextAlignmentLeft;
    textView.textColor = [UIColor grayColor];
    textView.font = [UIFont boldSystemFontOfSize:14];
    textView.editable = NO;

    return textView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BDRuleEnginePolicyCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BDRuleEnginePolicyCell class]) forIndexPath:indexPath];

    cell.textView.text = [NSString stringWithFormat:@"%@\n%@\n%@", [self.viewModel policyTitleAtIndexPath:indexPath], [self.viewModel policyConfAtIndexPath:indexPath], [self.viewModel policyCelAtIndexPath:indexPath]];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.view.frame.size.height * 0.2;
}

#pragma mark - Init

- (instancetype)initWithViewModel:(BDRLStrategyViewModel *)viewModel
{
    if (self = [super init]) {
        if ([viewModel isKindOfClass:[BDRLStrategyDetailViewModel class]]) {
            _viewModel = (BDRLStrategyDetailViewModel *)viewModel;
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
        [_tableView registerClass:[BDRuleEnginePolicyCell class] forCellReuseIdentifier:NSStringFromClass([BDRuleEnginePolicyCell class])];
        self.tableView.frame = self.view.bounds;
//        self.tableView.sectionHeaderTopPadding = 0;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _tableView;
}

@end
