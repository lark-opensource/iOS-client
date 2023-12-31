//
//  IESPrefetchDebugViewController.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/18.
//

#import "IESPrefetchDebugViewController.h"
#import "IESPrefetchManager.h"
#import "IESPrefetchDebugBizViewController.h"

@interface IESPrefetchDebugViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSString *> *allBiz;

@end

@implementation IESPrefetchDebugViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Prefetch DebugUI";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    self.allBiz = [[IESPrefetchManager sharedInstance] allBiz];
    [self setupTableView];
}

- (void)dismiss
{
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupTableView
{
    self.tableView = [[UITableView alloc] init];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 9.0, *)) {
        NSLayoutConstraint *leadingConstraint = [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor];
        NSLayoutConstraint *trailingConstraint = [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor];
        NSLayoutConstraint *topConstraint = nil;
        NSLayoutConstraint *bottomConstraint = nil;
        if (@available(iOS 11.0, *)) {
            topConstraint = [self.tableView.topAnchor constraintEqualToSystemSpacingBelowAnchor:self.view.safeAreaLayoutGuide.topAnchor multiplier:1.0];
            bottomConstraint = [self.view.safeAreaLayoutGuide.bottomAnchor constraintEqualToSystemSpacingBelowAnchor:self.tableView.bottomAnchor multiplier:1.0];
        } else {
            topConstraint = [self.tableView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:8];
            bottomConstraint = [self.bottomLayoutGuide.topAnchor constraintEqualToAnchor:self.tableView.bottomAnchor constant:8];
        }
        [self.view addConstraints:@[leadingConstraint, trailingConstraint, topConstraint, bottomConstraint]];
    } else {
        // Fallback on earlier versions
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.allBiz.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"staticCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"staticCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = self.allBiz[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *biz = self.allBiz[indexPath.row];
    IESPrefetchDebugBizViewController *vc = [[IESPrefetchDebugBizViewController alloc] initWithBiz:biz];
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Business";
}

@end
