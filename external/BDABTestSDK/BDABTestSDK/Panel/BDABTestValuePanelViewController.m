//
//  BDABTestValuePanelViewController.m
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "BDABTestValuePanelViewController.h"
#import "BDABTestExperimentDetailViewController.h"
#import "BDABTestPanelTableViewCell.h"

@interface BDABTestValuePanelViewController ()<UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, copy) NSArray<BDABTestBaseExperiment *> *datas;
@property (nonatomic, copy) NSArray<BDABTestBaseExperiment *> *results;

@end

@implementation BDABTestValuePanelViewController

- (instancetype)initWithSourceData:(NSArray<BDABTestBaseExperiment *> *)data
{
    if (self = [super init]) {
        self.datas = data;
    }
    return self;
}

- (void)viewDidLoad
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(cancelActionFired:)];
    self.tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    UISearchController *search = [[UISearchController alloc] initWithSearchResultsController:nil];
    search.searchResultsUpdater = self;
    search.dimsBackgroundDuringPresentation = NO;
    self.searchController = search;
    self.tableView.tableHeaderView = search.searchBar;
}

- (void)cancelActionFired:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active) {
        return self.results.count ;
    }
    return self.datas.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BDABTestPanelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (!cell) {
        cell = [[BDABTestPanelTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellID"];
    }
    BDABTestBaseExperiment *experiment;
    if (self.searchController.active ) {
        experiment = [self.results objectAtIndex:indexPath.row];
    } else {
        experiment = [self.datas objectAtIndex:indexPath.row];
    }
    cell.owner = experiment.owner ?: @"No Body";
    cell.key = experiment.key;
    cell.desc = experiment.desc;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BDABTestBaseExperiment *experiment;
    if (self.searchController.active ) {
        experiment = [self.results objectAtIndex:indexPath.row];
    } else {
        experiment = [self.datas objectAtIndex:indexPath.row];
    }
    BDABTestExperimentDetailViewController *vc = [[BDABTestExperimentDetailViewController alloc] initWithExperiment:experiment];
    [self.navigationController pushViewController:vc animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *inputStr = searchController.searchBar.text;
    if (self.results.count > 0) {
        self.results = nil;
    }
    NSMutableArray *tmpResult = [NSMutableArray array];
    for (BDABTestBaseExperiment *experiment in self.datas) {
        if ((experiment.key.length > 0 && [experiment.key.lowercaseString rangeOfString:inputStr.lowercaseString].location != NSNotFound) ||
            (experiment.owner.length > 0 && [experiment.owner.lowercaseString rangeOfString:inputStr.lowercaseString].location != NSNotFound)) {
            [tmpResult addObject:experiment];
        }
    }
    self.results = [tmpResult copy];
    [self.tableView reloadData];
}

@end
