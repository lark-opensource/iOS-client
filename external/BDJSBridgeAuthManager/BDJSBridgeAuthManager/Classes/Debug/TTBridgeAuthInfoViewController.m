//
//  TTBridgeAuthInfoViewController.m
//  TTBridgeUnify
//
//  Created by liujinxing on 2020/8/13.
//

#import "TTBridgeAuthInfoViewController.h"
#import <objc/runtime.h>
#import <TTDebugCore/TTDebugSearchResultView.h>

#ifndef stringify
#define stringify(s) #s
#endif

#pragma mark - Categories

@implementation NSArray (BDPiperAuthDebug)

- (NSString *)readableString{
    NSMutableString * js = [NSMutableString stringWithString:@"\t(\n"];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [js appendFormat:@"\t\t%@\n",obj];
    }];
    [js appendString:@"\t)"];
    return js;
}

@end

@implementation NSDictionary (BDPiperAuthDebug)

- (NSString *)readableString{
    NSArray *includeMethod = [self objectForKey:@"included_methods"];
    NSArray *excludedMethods = [self objectForKey:@"excluded_methods"];
    NSString * js = [NSString stringWithFormat:@stringify(
        {\n
            \t"pattern":\t%@!\n
            \t"group":\t%@!\n
            \t"included_methods":\t%@!\n
            \t"excluded_methods":\t%@!\n
        }
    ),[self objectForKey:@"pattern"],[self objectForKey:@"group"], includeMethod.readableString, excludedMethods.readableString];
    return [js stringByReplacingOccurrencesOfString:@"!" withString:@","];
}

@end

#pragma mark - TTBridgeAuthCellItem

@implementation TTBridgeAuthCellItem : STTableViewCellItem

- (instancetype)initWithChannelName:(NSString *)channelName domainName:(NSString *)domainName target:(id)target action:(__nullable SEL)action{
    self = [super initWithTitle:domainName target:target action:action];
    if (self){
        _channelName = channelName;
        _domainName = domainName;
    }
    return self;
}

@end

#pragma mark - TTBridgeAuthInfoDetailViewController

@interface TTBridgeAuthInfoDetailViewController : UIViewController

@property(nonatomic, strong) STDebugTextView *textView;
@property(nonatomic, strong) NSMutableArray<NSDictionary *> *authInfos;
@property(nonatomic, copy) NSString *domain;

- (instancetype)initWithDomain:(NSString *)domain AuthInfo:(NSArray<NSDictionary *> *)authInfo;

@end

@implementation TTBridgeAuthInfoDetailViewController

- (instancetype)initWithDomain:(NSString *)domain AuthInfo:(NSArray<NSDictionary *> *)authInfo{
    self = [super init];
    if (self){
        _authInfos = [NSMutableArray arrayWithArray:authInfo];
        _domain = domain;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = self.domain;

    self.textView = [[STDebugTextView alloc] initWithFrame:self.view.bounds];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.authInfos enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull authInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.textView appendText:[authInfo readableString]];
    }];
    [self.view addSubview:self.textView];
}

@end

#pragma mark - TTBridgeAuthInfoViewController

@interface TTBridgeAuthInfoViewController () <UISearchBarDelegate>

@property (nonatomic, copy) NSString *accessKey;
@property(nonatomic, strong) UIView *tableViewHeaderView;
@property (nonatomic, strong) UISearchBar *domainSearchBar;
@property (nonatomic, strong) TTDebugSearchResultView *searchResultView;

@end

@implementation TTBridgeAuthInfoViewController

- (instancetype)initWithTitle:(NSString *)title JSON:(NSDictionary *) json accessKey:(NSString *)accessKey{
    self = [super init];
    if (self){
        _json = json;
        _accessKey = accessKey;
        self.title = title;
    }
    return self;
}

- (void)loadDataSource{
    NSMutableArray *dataSource = [NSMutableArray array];
    NSArray<NSDictionary *> *array = [self.json valueForKeyPath:[NSString stringWithFormat:@"data.packages.%@",self.accessKey]];
    NSMutableDictionary<NSString *, NSMutableDictionary *> *channels = NSMutableDictionary.new;
    
    [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull channel, NSUInteger idx, BOOL * _Nonnull stop) {
        [channels setValue:[NSMutableDictionary dictionaryWithDictionary:channel] forKey: channel[@"channel"]];
        NSMutableArray <TTBridgeAuthCellItem *> *itemArray = NSMutableArray.new;
        NSDictionary <NSString *, NSArray<NSDictionary *> *> *content = [channel objectForKey:@"content"];
        [content enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull domain, NSArray<NSDictionary *> * _Nonnull rules, BOOL * _Nonnull stop) {
            TTBridgeAuthCellItem * cellItem = [[TTBridgeAuthCellItem alloc]initWithChannelName:channel[@"channel"] domainName:domain target:self action:@selector(showDomainAuthRules:)];
            [itemArray addObject:cellItem];
        }];
        NSString *sectionTitle = [channel[@"channel"] stringByAppendingFormat:@" (%lu items)",(unsigned long)[itemArray count]];
        STTableViewSectionItem *sectionItem = [[STTableViewSectionItem alloc]initWithSectionTitle:sectionTitle items:itemArray];
        [dataSource addObject:sectionItem];
    }];
    self.channels = channels;
    self.dataSource = dataSource;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadDataSource];
    self.tableView.tableHeaderView = self.tableViewHeaderView;
    CGFloat y = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height + self.domainSearchBar.frame.size.height + self.tableViewHeaderView.frame.size.height;
    self.searchResultView = [[TTDebugSearchResultView alloc] initWithFrame:CGRectMake(0, y, self.tableView.frame.size.width, self.tableView.frame.size.height)];
    self.searchResultView.backgroundColor = [UIColor whiteColor];
    self.searchResultView.hidden = YES;
    self.searchResultView.tableView.hidden = YES;
    [self.view addSubview:self.searchResultView];
}

- (void)showDomainAuthRules:(TTBridgeAuthCellItem *)item {
    NSArray<NSDictionary *> *authInfos = [self.channels valueForKeyPath:
                                          [NSString stringWithFormat:@"%@.content.%@",item.channelName,item.domainName]];
    TTBridgeAuthInfoDetailViewController *domainViewController = [[TTBridgeAuthInfoDetailViewController alloc]initWithDomain:item.title AuthInfo:authInfos];
    [self.navigationController pushViewController:domainViewController animated:YES];
}
    
- (UIView *)tableViewHeaderView {
    if (_tableViewHeaderView == nil) {
        _tableViewHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
        self.domainSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, _tableViewHeaderView.frame.size.width, _tableViewHeaderView.frame.size.height)];
        self.domainSearchBar.placeholder = @"Search";
        self.domainSearchBar.delegate = self;
        self.domainSearchBar.showsCancelButton = YES;
        [_tableViewHeaderView addSubview:self.domainSearchBar];
    }
    return _tableViewHeaderView;
}

#pragma mark - UISearchBar Delegate

- (void)updateWhenSearchTextChanged {
    NSArray *data = [self.dataSource copy];
    NSMutableArray *filterData = [NSMutableArray new];
    NSString *text = self.domainSearchBar.text;
    if (text.length > 0) {
        self.searchResultView.hidden = NO;
        self.searchResultView.tableView.hidden = NO;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [data enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                STTableViewSectionItem *sectionItem = [obj isKindOfClass:[STTableViewSectionItem class]] ? obj : nil;
                for (STTableViewCellItem *cellItem in sectionItem.items) {
                    if ([cellItem.title rangeOfString:text options:NSCaseInsensitiveSearch].length > 0) {
                        [filterData addObject:cellItem];
                    }
                }
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.searchResultView.searchResultDataSource = [filterData copy];
                [self.searchResultView.tableView reloadData];
            });
        });
    } else {
        self.searchResultView.hidden = YES;
        self.searchResultView.tableView.hidden = YES;
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self updateWhenSearchTextChanged];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = YES;
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    if([searchBar.text isEqualToString:@""]) {
        searchBar.showsCancelButton = NO;
        self.searchResultView.hidden = YES;
        self.searchResultView.tableView.hidden = YES;
    } else {
        searchBar.showsCancelButton = YES;
    }
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchBarResignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = nil;
    [self updateWhenSearchTextChanged];
    [self searchBarResignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchResultView.hidden = YES;
    self.searchResultView.tableView.hidden = YES;
}

- (void)searchBarResignFirstResponder {
    self.domainSearchBar.showsCancelButton = NO;
    [self.domainSearchBar resignFirstResponder];
    self.searchResultView.hidden = YES;
    self.searchResultView.tableView.hidden = YES;
}
@end
