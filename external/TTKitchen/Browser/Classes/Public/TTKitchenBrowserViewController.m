//
//  TTKitchenBrowserViewController.m
//  Article
//
//  Created by SongChai on 2017/8/21.
//

#import "TTKitchenBrowserViewController.h"
#import "TTKitchenInternal.h"
#import "TTKitchenAddition.h"
#import "TTKitchenEditorViewController.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTPostDataHttpRequestSerializer.h>
#import "TTKitchenSearchHistoryView.h"

static NSString *uploadKeyURL = @"https://cloudapi.bytedance.net/faas/services/tt4647ot87dv4anb98/invoke/keyMapper";

@interface TTKitchenBrowserViewController ()<UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, TTKitchenSearchHistoryViewDelegate>
@property (nonatomic, strong) UIView *tableViewHeaderView;
@property (nonatomic, strong) UISearchBar *kitchenSearchBar;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<TTKitchenModel *> *dataSource;
@property (nonatomic, strong) TTKitchenSearchHistoryView *searchHistoryView;//搜索历史

@end

@implementation TTKitchenBrowserViewController

+ (void)showInViewController:(UIViewController *)viewController {
    if (viewController == nil) {
        return;
    }
    
    TTKitchenBrowserViewController *debugViewController = [[TTKitchenBrowserViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:debugViewController];
    [viewController presentViewController:navigationController animated:YES completion:NULL];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIView *)tableViewHeaderView {
    if (_tableViewHeaderView == nil) {
        _tableViewHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _tableView.frame.size.width, 40)];
        self.kitchenSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, _tableViewHeaderView.frame.size.width, _tableViewHeaderView.frame.size.height)];
        self.kitchenSearchBar.placeholder = @"搜索";
        self.kitchenSearchBar.delegate = self;
        self.kitchenSearchBar.showsCancelButton = YES;
        [_tableViewHeaderView addSubview:self.kitchenSearchBar];
    }
    return _tableViewHeaderView;
}

- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:(UITableViewStylePlain)];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.estimatedRowHeight = 44;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _tableView.tableHeaderView = self.tableViewHeaderView;
    }
    return _tableView;
}

- (TTKitchenSearchHistoryView *)searchHistoryView {
    if (_searchHistoryView == nil) {
        _searchHistoryView = [[TTKitchenSearchHistoryView alloc] initWithFrame:CGRectMake(0, 40, self.view.frame.size.width, 0)];
        _searchHistoryView.delegate = self;
    }
    return _searchHistoryView;
}

- (void)configDataSources {
    NSArray<TTKitchenModel *> *array = [[TTKitchen allKitchenModels] copy];
    NSString *searchKey = [self.kitchenSearchBar.text stringByReplacingOccurrencesOfString:@"_" withString:@""];
    if ([searchKey length]) {
        array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TTKitchenModel *model, NSDictionary<NSString *,id> * _Nullable bindings) {
            NSString *summary = [model.summary stringByReplacingOccurrencesOfString:@"_" withString:@""];//去除下划线
            NSString *key = [model.key stringByReplacingOccurrencesOfString:@"_" withString:@""];
            NSString *text = [model.text stringByReplacingOccurrencesOfString:@"_" withString:@""];
            return ((summary && [summary rangeOfString:searchKey options:NSCaseInsensitiveSearch].location != NSNotFound) ||
                    (key && [key rangeOfString:searchKey options:NSCaseInsensitiveSearch].location != NSNotFound) ||
                    (text && [text rangeOfString:searchKey options:NSCaseInsensitiveSearch].location != NSNotFound)
                    );
            
        }]];
    }

    self.dataSource = array;
}

- (void)updateWhenSearchTextChanged {
    [self configDataSources];
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    self.title = @"Kitchen";
    [self configDataSources];
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    if (self == [self.navigationController.viewControllers firstObject]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(cancelActionFired:)];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStylePlain target:self action:@selector(more:)];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didKitchenChange) name:kTTKitchenEditorSuccessNotification object:nil];
}

- (void)didKitchenChange {
    [self.tableView reloadData];
}

- (void)cancelActionFired:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)more:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"清理日志" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [TTKitchen cleanCacheLog];
    }]];
    
    __weak TTKitchenBrowserViewController *weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"恢复默认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [TTKitchen removeAllKitchen];
        [weakSelf.tableView reloadData];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Upload Client Keys" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSArray *allKeys = [[TTKitchenManager sharedInstance] allKitchenKeys];
        
        [[TTNetworkManager shareInstance] requestForJSONWithURL:uploadKeyURL
                                                         params:@{@"allKeys": allKeys}
                                                         method:@"POST"
                                               needCommonParams:YES
                                              requestSerializer:TTPostDataHttpRequestSerializer.class
                                             responseSerializer:nil
                                                     autoResume:YES callback:^(NSError *error, id jsonObj) {
            //
        }];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TTKitchenModel *model = [self.dataSource objectAtIndex:indexPath.row];
    if (model) {
        if (model.type == TTKitchenModelTypeBOOL) {
            [model switchAction];
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            TTKitchenEditorViewController *editorViewController = [[TTKitchenEditorViewController alloc] initWithKitchenModel:model];
            [self.navigationController pushViewController:editorViewController animated:YES];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.searchHistoryView removeSearchHistoryViewFromSuperview];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TTKitchenModel *model = [self.dataSource objectAtIndex:indexPath.row];
    
    NSString *cellIndentifier = model.type == TTKitchenModelTypeBOOL? @"SwitchCell": @"DetailCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
    
    if (!cell) {
        UITableViewCellStyle style = UITableViewCellStyleSubtitle;
        cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIndentifier];
    }
    cell.textLabel.text = model.key;
    cell.textLabel.numberOfLines = 0;
    if (model.type == TTKitchenModelTypeBOOL) {
        cell.detailTextLabel.text = model.summary;
        int switchTag = 13322;
        UISwitch *switchView = [cell.contentView viewWithTag:switchTag];
        if (!switchView) {
            switchView = [[UISwitch alloc] init];
            switchView.frame = CGRectMake(tableView.frame.size.width - switchView.frame.size.width - 10,
                                          (44 - switchView.frame.size.height)/2,
                                          switchView.frame.size.width,
                                          switchView.frame.size.height);
            switchView.tag = switchTag;
            cell.accessoryView = switchView;
            switchView.userInteractionEnabled = NO;
        }
        switchView.on = [model isSwitchOpen];
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", model.summary, model.text];
    }
    
    return cell;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self updateWhenSearchTextChanged];
    [self.searchHistoryView removeSearchHistoryViewFromSuperview];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchBarResignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.maskView.hidden = NO;
    [self.searchHistoryView showInView:self.tableView];
}

- (void)searchHistoryView:(TTKitchenSearchHistoryView *)historyView didClickHistoryButton:(NSString *)searchKey {
    self.kitchenSearchBar.text = searchKey;
    [self.searchHistoryView removeSearchHistoryViewFromSuperview];
    [self configDataSources];
    [self.tableView reloadData];
}

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:CGRectMake(0, self.tableViewHeaderView.frame.size.height, self.tableView.frame.size.width, self.tableView.frame.size.height - self.tableViewHeaderView.frame.size.height)];
        _maskView.hidden = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(maskViewTaped:)];
        [_maskView addGestureRecognizer:tapGesture];
        [self.tableView addSubview:_maskView];
    }
    return _maskView;
}

- (void)maskViewTaped:(UIGestureRecognizer *)sender {
    [self searchBarResignFirstResponder];
}

- (void)searchBarResignFirstResponder {
    [self.searchHistoryView saveSearchKeyword:self.kitchenSearchBar.text];
    [self.searchHistoryView removeSearchHistoryViewFromSuperview];
    [self.kitchenSearchBar resignFirstResponder];
    self.maskView.hidden = YES;
}

@end
