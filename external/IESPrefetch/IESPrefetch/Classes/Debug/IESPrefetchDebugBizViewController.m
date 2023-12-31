//
//  IESPrefetchDebugBizViewController.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/19.
//

#import "IESPrefetchDebugBizViewController.h"
#import "IESPrefetchLoaderPrivateProtocol.h"
#import "IESPrefetchManager.h"
#import "IESPrefetchCacheModel+RequestModel.h"
#import "IESPrefetchDebugTemplateViewController.h"

@interface IESPrefetchDebugBizViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSString *biz;
@property (nonatomic, strong) id<IESPrefetchLoaderPrivateProtocol> loader;
@property (nonatomic, copy) NSArray<IESPrefetchCacheModel *> *caches;
@property (nonatomic, copy) NSArray<NSString *> *projects;

@end

@implementation IESPrefetchDebugBizViewController

- (instancetype)initWithBiz:(NSString *)biz
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        _biz = biz;
        _loader = (id<IESPrefetchLoaderPrivateProtocol>)[[IESPrefetchManager sharedInstance] loaderForBusiness:biz];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = [NSString stringWithFormat:@"Prefetch-%@", self.biz];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupTableView];
    [self loadCaches];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadProjects];
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

- (void)loadCaches
{
    IESPrefetchCacheProvider *cacheProvider = [self.loader cacheProvider];
    self.caches = [cacheProvider allCaches];
}

- (void)loadProjects
{
    self.projects = [self.loader allProjects];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1) {
        return self.projects.count;
    } else if (section == 2) {
        return self.caches.count;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"staticCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"staticCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (indexPath.section == 1) {
        NSString *project = self.projects[indexPath.row];
        cell.textLabel.text = project;
    } else if (indexPath.section == 2) {
        IESPrefetchCacheModel *cache = self.caches[indexPath.row];
        cell.textLabel.text = cache.requestDescription;
        cell.textLabel.numberOfLines = 0;
    } else {
        cell.textLabel.text = @"New Load Config";
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Add New";
    } else if (section == 1) {
        return [NSString stringWithFormat:@"Projects(%@)", @(self.projects.count)];
    }
    return [NSString stringWithFormat:@"Caches(%@)", @(self.caches.count)];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        NSString *project = self.projects[indexPath.row];
        IESPrefetchDebugTemplateViewController *vc = [[IESPrefetchDebugTemplateViewController alloc] initWithBusiness:self.biz];
        vc.configTemplate = [self.loader templateForProject:project];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (indexPath.section == 2) {
        IESPrefetchCacheModel *cache = self.caches[indexPath.row];
        NSMutableString *content = [[NSMutableString alloc] init];
        [content appendFormat:@"request: %@", cache.requestDescription];
        [content appendString:@"\r\n=======expire=======\r\n"];
        NSTimeInterval expiredTime = cache.timeInterval + cache.expires;
        NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:expiredTime];
        [content appendFormat:@"expire: %@s --expire time: %@", @(cache.expires), date];
        [content appendString:@"\r\n=======content=======\r\n"];
        [content appendFormat:@"%@", [cache.data description]];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cache" message:content.description preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        IESPrefetchDebugTemplateViewController *vc = [[IESPrefetchDebugTemplateViewController alloc] initWithBusiness:self.biz];
        vc.editable = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
