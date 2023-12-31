//
//  ACCTagsItemPickerViewController.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/29.
//

#import "ACCTagsItemPickerViewController.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/UISearchBar+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/ACCLoadMoreFooter.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitBeauty/ACCNetworkReachabilityProtocol.h>

@interface ACCTagsItemPickerViewController ()<ACCTagsSearchBarDelegate, ACCEditTagsSearchEmptyViewDelegate>
@property (nonatomic, strong) UIView *normalView;
@property (nonatomic, strong) ACCEditTagsSearchEmptyView *emptyView;
@property (nonatomic, strong, readwrite) ACCTagsSearchBar *searchBar;
@property (nonatomic, strong, readwrite) UITableView *tableView;
@property (nonatomic, strong) UIView *currentView;
@property (nonatomic, assign) BOOL hasMoreData;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIView *errorView;
@property (nonatomic, strong) UIView *loadingView;

@property (nonatomic, strong) UIView <ACCLoadingViewProtocol> *loadingIndicator;
@end

@implementation ACCTagsItemPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSearchBarIfNeeded];
    self.hasMoreData = YES;
    self.currentKeyword = @"";
    self.loadStatus = ACCTagsItemPickerLoadStatusInitial;
    self.loadStatus = ACCTagsItemPickerLoadStatusLoading;
    [self fetchRecommendData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.searchBar resignFirstResponder];
    [self hideCancelButton];
}

#pragma mark - Data management

- (void)fetchRecommendData
{
}

- (void)searchWithKeyword:(NSString *)searchWithKeyword completion:(ACCTagSearchCompletion)completion
{
    
}

- (void)loadMoreWithKeyword:(NSString *)searchWithKeyword completion:(ACCTagSearchCompletion)completion
{
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[self cellIdentifier] forIndexPath:indexPath];
    if ([cell conformsToProtocol:@protocol(ACCTagsItemPickerTableViewCellProtocol)]) {
        NSArray *dataSource = [self.dataSource copy];
        if (indexPath.row < [dataSource count]) {
            id<ACCTagsItemPickerTableViewCellProtocol> tagsCell = (id<ACCTagsItemPickerTableViewCellProtocol>)cell;
            [tagsCell updateWithData:dataSource[indexPath.row]];
        }
    }
    [self configCell:cell];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self cellHeight];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];
    NSArray *dataSource = [self.dataSource copy];
    if (indexPath.row < [dataSource count]) {
        NSMutableDictionary *extraParams = [[self trackerParamsForItemAtIndexPath:indexPath] mutableCopy];
        NSString *event = [self isSearch] ? @"tag_search_word_click" :  @"tag_rec_content_click";
        if (![self isSearch]) {
            [extraParams setValue:@"suppose_rec" forKey:@"rec_type"];
        }
        if ([self needToTrackClickEvent]) {
            [ACCTracker() trackEvent:event
                              params:extraParams];
        }
        [extraParams setValue:[self tagTypeString] forKey:@"tag_type"];
        [extraParams setValue:[self tagSource] forKey:@"tag_source"];
        [self.delegate tagsItemPicker:self didSelectItem:[self tagModelForIndexPath:indexPath] referExtra:extraParams];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if ([self shouldShowCreateCustomTagFooter]) {
        return 63.f;
    }
    return 0.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (![self shouldShowCreateCustomTagFooter]) {
        return nil;
    }
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, 63.f)];
    UIView *topLine = [[UIView alloc] init];
    topLine.backgroundColor = ACCResourceColor(ACCColorConstLineInverse2);
    [footerView addSubview:topLine];
    ACCMasMaker(topLine, {
        make.top.equalTo(footerView);
        make.left.equalTo(footerView).offset(16.f);
        make.right.equalTo(footerView).offset(-16.f);
        make.height.equalTo(@1.f);
    });
    
    footerView.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] init];
    label.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnFooter)];
    [label addGestureRecognizer:tap];
    
    UIFont *textFont = [ACCFont() systemFontOfSize:15];
    NSMutableAttributedString *footerText = [[NSMutableAttributedString alloc] initWithString:@"没有想要的结果？你可"
                                                                                   attributes:@{NSFontAttributeName: textFont,
                                                                                                NSForegroundColorAttributeName : ACCResourceColor(ACCColorConstTextInverse3)
                                                                                   }];
    NSAttributedString *actionText = [[NSAttributedString alloc] initWithString:@"创建此自定义标记" attributes:@{
        NSFontAttributeName: textFont,
        NSForegroundColorAttributeName : ACCResourceColor(ACCColorPrimary),
    }];
    [footerText appendAttributedString:actionText];
    label.attributedText = footerText;
    
    [footerView addSubview:label];
    ACCMasMaker(label, {
        make.center.equalTo(footerView);
    });
    return footerView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate isCurrentTagPicker:self]) {
        [self trackCellDisplayAtIndexPath:indexPath];
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
        [self hideCancelButton];
    }
}

#pragma mark - ACCTagSearchBarDelegate

- (void)searchBar:(ACCTagsSearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self reloadDataWithKeyword:searchText];
}

- (void)searchBarTextDidBeginEditing:(ACCTagsSearchBar *)searchBar
{
    [self showCancelButton];
    [ACCTracker() trackEvent:@"enter_tag_search" params:self.trackerParams];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self clearSearchCondition];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)showCancelButton
{
    [self.searchBar setShowsCancelButton:YES];
}

- (void)hideCancelButton
{
    [self.searchBar setShowsCancelButton:NO];
}

- (void)updateMJFooter
{
    if (self.needFooter) {
        if ([self.tableView.mj_footer isKindOfClass:[ACCLoadMoreFooter class]]) {
            ACCLoadMoreFooter *footer = (ACCLoadMoreFooter *)self.tableView.mj_footer;
            [footer setLoadMoreLabelTextColor:ACCResourceColor(ACCColorConstTextInverse4)];
            if ([self needNoMoreFooterText]) {
                footer.showNoMoreDataText = YES;
            } else {
                footer.showNoMoreDataText = NO;
            }
        }
    }
}

- (void)reloadDataWithKeyword:(NSString *)keyword
{
    ACCTagsItemPickerLoadStatus previousLoadStatus = self.loadStatus;
    if (previousLoadStatus == ACCTagsItemPickerLoadStatusSuccess && [keyword isEqualToString:self.currentKeyword]) {
        return ;
    }
    self.currentKeyword = keyword;
    if (previousLoadStatus == ACCTagsItemPickerLoadStatusError) {
        self.loadStatus = ACCTagsItemPickerLoadStatusLoading;
    }
    if (![self networkReachable]) {
        if (ACC_isEmptyString(keyword)) {
            [self restoreRecommendData];
        } else {
            self.loadStatus = ACCTagsItemPickerLoadStatusError;
        }
        return;
    }
    if (self.needFooter) {
        [self.tableView.mj_footer resetNoMoreData];
    }
    @weakify(self)
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    [self searchWithKeyword:keyword completion:^(NSArray * result, NSError * error, BOOL hasMoreData) {
        @strongify(self)
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
        NSMutableDictionary *params = [self.trackerParams mutableCopy];
        NSInteger duration = [@((endTime - startTime) * 1000) integerValue];
        [params setValue:[self tagTypeString] forKey:@"tag_type"];
        [params setValue:keyword forKey:@"search_keyword"];
        [params setValue:@(duration) forKey:@"duration"];
        BOOL isSuccess = YES;
        if (ACC_isEmptyArray(result) || error) {
            isSuccess = NO;
        }
        [params setValue:@(isSuccess) forKey:@"is_success"];
        if (!ACC_isEmptyString(keyword)) {
            [ACCTracker() trackEvent:@"tag_search_finish" params:params];
        }
        [self updateMJFooter];
        [self handleData:result error:error hasMore:hasMoreData];
    }];
}

- (void)reloadData
{
    [self reloadDataWithKeyword:self.currentKeyword];
}

#pragma mark - Setters & Getters

- (void)setLoadStatus:(ACCTagsItemPickerLoadStatus)loadStatus
{
    if (_loadStatus != loadStatus) {
        _loadStatus = loadStatus;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.currentView) {
                [self.currentView removeFromSuperview];
            }
            self.currentView = [self viewForLoadStatus:loadStatus];
            if (self.currentView) {
                [self.view addSubview:self.currentView];
                
                ACCMasReMaker(self.currentView, {
                    if (self.needSearchBar) {
                        make.top.equalTo(self.searchBar.mas_bottom).offset(20.f);
                    } else {
                        make.top.equalTo(self.view).offset(26.f);
                    }
                    make.left.right.equalTo(self.view);
                    make.bottom.equalTo(self.view).offset(-ACC_IPHONE_X_BOTTOM_OFFSET);
                });
            }
            [self.view layoutIfNeeded];
            
            if (loadStatus == ACCTagsItemPickerLoadStatusLoading) {
                [self.loadingIndicator startAnimating];
            } else {
                [self.loadingIndicator stopAnimating];
            }
        });
    }
}

#pragma mark - ACCEditTagsSearchEmptyViewDelegate

- (void)didTapOnEmptView:(ACCEditTagsSearchEmptyView *)emptyView
{
    [self.searchBar resignFirstResponder];
}

- (void)didTapOnActionButtonInEmptyView:(ACCEditTagsSearchEmptyView *)emptyView
{
    [self.searchBar resignFirstResponder];
    [self.delegate tagsItemPickerDidTapCreateCustomTagButton:self keyword:self.searchBar.textField.text];
}

#pragma mark - Private Helper

- (UIView *)viewForLoadStatus:(ACCTagsItemPickerLoadStatus)loadStatus
{
    if (loadStatus == ACCTagsItemPickerLoadStatusEmpty) {
        return self.emptyStateView;
    } else if (loadStatus == ACCTagsItemPickerLoadStatusError) {
        return self.errorView;
    } else if (loadStatus == ACCTagsItemPickerLoadStatusLoading) {
        return self.loadingView;
    } else {
        return self.normalView;
    }
}

- (void)setupSearchBarIfNeeded
{
    if (self.needSearchBar) {
        UIView *leftView = [self searchBarLeftView];
        self.searchBar = [[ACCTagsSearchBar alloc] initWithLeftView:leftView leftViewWidth:leftView.frame.size.width];
        self.searchBar.delegate = self;
        
        NSDictionary *placeHolderAttributes = @{
            NSFontAttributeName : [ACCFont() systemFontOfSize:15.f],
            NSForegroundColorAttributeName : ACCResourceColor(ACCColorConstTextInverse5)};
        self.searchBar.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:[self searchBarPlaceHolder] attributes:placeHolderAttributes];
        [self.view addSubview:self.searchBar];
        
        ACCMasMaker(self.searchBar, {
            make.top.equalTo(self.view).offset(20.f);
            make.left.equalTo(self.view);
            make.right.equalTo(self.view);
            make.height.equalTo(@([self.searchBar searchBarHeight]));
        });
    }
}

- (void)handleLoadFinishWithMoreData:(BOOL)hasMore
{
    self.hasMoreData = hasMore;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMJFooter];
        if (self.needFooter) {
            if (hasMore) {
                [self.tableView.mj_footer endRefreshing];
            } else {
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
        }
        [self.tableView reloadData];
    });
}

- (void)handleTapOnFooter
{
    [self.searchBar resignFirstResponder];
    [self.delegate tagsItemPickerDidTapCreateCustomTagButton:self keyword:self.searchBar.textField.text];
}

- (BOOL)shouldShowCreateCustomTagFooter
{
    return self.needCreateCustomTagFooter && !self.hasMoreData && !ACC_isEmptyString(self.currentKeyword);
}

- (void)scrollToItem:(NSString *)item
{
    NSInteger index = [self indexOfItem:item];
    if (index >= 0 && index < [self.dataSource count]) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (BOOL)networkReachable
{
    id<ACCNetworkReachabilityProtocol> reachabilityManager = IESAutoInline(ACCBaseServiceProvider(), ACCNetworkReachabilityProtocol);
    return reachabilityManager.isReachable;
}

- (BOOL)isSearch
{
    return !ACC_isEmptyString(self.currentKeyword);
}

- (NSDictionary *)trackerParamsForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *params = [[self itemTrackerParamsForItemAtIndexPath:indexPath] mutableCopy];
    [params addEntriesFromDictionary:self.trackerParams];
    if ([self isSearch]) {
        [params setValue:self.currentKeyword forKey:@"search_keyword"];
    }
    return params;
}

- (void)handleTapOnErrorView
{
    [self hideCancelButton];
    [self.searchBar resignFirstResponder];
}

- (void)clearSearchCondition
{
    if (ACC_isEmptyString(self.searchBar.textField.text)) {
        return ;
    }
    self.searchBar.textField.text = @"";
    if (self.needFooter) {
        [self.tableView.mj_footer resetNoMoreData];
    }
    [self reloadDataWithKeyword:@""];
    [self hideCancelButton];
    [self.searchBar resignFirstResponder];
}

#pragma mark - Subclassing

- (void)handleData:(NSArray *)data error:(NSError *)error hasMore:(BOOL)hasMore
{
    if (error || (ACC_isEmptyArray(data) && ![self networkReachable] && [self needNetworkRequest])) {
        self.loadStatus = ACCTagsItemPickerLoadStatusError;
    } else if (ACC_isEmptyArray(data)) {
        self.loadStatus = ACCTagsItemPickerLoadStatusEmpty;
    } else {
        self.loadStatus = ACCTagsItemPickerLoadStatusSuccess;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleLoadFinishWithMoreData:hasMore];
            self.tableView.contentOffset = CGPointMake(0, -self.tableView.contentInset.top);
        });
    }
}

- (ACCEditTagsSearchEmptyView *)emptyView
{
    if (!_emptyView) {
        _emptyView = [[ACCEditTagsSearchEmptyView alloc] init];
        _emptyView.delegate = self;
        [_emptyView updateWithText:[self emptyResultText]];
    }
    return _emptyView;
}

- (UIView *)normalView
{
    if (!_normalView) {
        _normalView = [[UIView alloc] init];
        _normalView.backgroundColor = [UIColor clearColor];
        
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self headerHeight])];
        headerView.backgroundColor = [UIColor clearColor];
        self.headerView = headerView;
        UILabel *label = [[UILabel alloc] init];
        label.font = [ACCFont() systemFontOfSize:13.f weight:ACCFontWeightMedium];
        label.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        label.text = [self headerText];
        self.headerLabel = label;
        [headerView addSubview:label];
        [_normalView addSubview:headerView];
        [self updateHeaderView];
        
        [_normalView addSubview:[self bottomView]];
        ACCMasMaker([self bottomView], {
            make.left.right.bottom.equalTo(_normalView);
            make.height.equalTo(@([self bottomViewHeight]));
        })
        
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, 0.01)];
        self.tableView.sectionHeaderHeight = 0.f;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self.tableView registerClass:[self cellClass] forCellReuseIdentifier:[self cellIdentifier]];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        [_normalView addSubview:self.tableView];
        ACCMasMaker(self.tableView, {
            make.top.equalTo(self.headerView.mas_bottom);
            make.left.right.equalTo(_normalView);
            make.bottom.equalTo(self.bottomView.mas_top);
        });
        
        if (self.needFooter) {
            @weakify(self)
            ACCLoadMoreFooter *footer = [ACCLoadMoreFooter footerWithRefreshingBlock:^{
                @strongify(self);
                [self loadMoreWithKeyword:self.currentKeyword completion:^(NSArray *result, NSError *error, BOOL hasMore) {
                    @strongify(self)
                    [self handleLoadFinishWithMoreData:hasMore];
                }];
            }];
            self.tableView.mj_footer = footer;
            footer.showNoMoreDataText = NO;
        }
    }
    return _normalView;
}

- (UIView *)errorView
{
    if (!_errorView) {
        _errorView = [[UIView alloc] init];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnErrorView)];
        [_errorView addGestureRecognizer:tap];
        UILabel *descriptionLabel = [[UILabel alloc] init];
        descriptionLabel.textColor = ACCResourceColor(ACCColorConstTextInverse3);
        descriptionLabel.font = [ACCFont() systemFontOfSize:15.f];
        descriptionLabel.text = @"稍后再试";
        [_errorView addSubview:descriptionLabel];
        ACCMasMaker(descriptionLabel, {
            make.centerX.equalTo(_errorView);
            make.top.equalTo(_errorView).offset(100.f);
        });
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        titleLabel.font = [ACCFont() systemFontOfSize:17.f weight:ACCFontWeightMedium];
        titleLabel.text = @"当前网络异常";
        [_errorView addSubview:titleLabel];
        ACCMasMaker(titleLabel, {
            make.centerX.equalTo(_errorView);
            make.bottom.equalTo(descriptionLabel.mas_top).offset(-8.f);
        });
        
        UIButton *retryButton = [[UIButton alloc] init];
        retryButton.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
        retryButton.layer.cornerRadius = 4.f;
        retryButton.layer.masksToBounds = YES;
        NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:@"点击重试"
                                                                        attributes:@{
                                                                            NSFontAttributeName: [ACCFont() systemFontOfSize:15.f weight:ACCFontWeightMedium],
                                                                            NSForegroundColorAttributeName : ACCResourceColor(ACCColorConstTextInverse)
                                                                        }];
        
        [retryButton setAttributedTitle:attrTitle forState:UIControlStateNormal];
        
        NSAttributedString *selectedTitle = [[NSAttributedString alloc] initWithString:@"点击重试"
                                                                        attributes:@{
                                                                            NSFontAttributeName: [ACCFont() systemFontOfSize:15.f weight:ACCFontWeightMedium],
                                                                            NSForegroundColorAttributeName : ACCResourceColor(ACCColorConstTextInverse4)
                                                                        }];
        [retryButton setAttributedTitle:selectedTitle forState:UIControlStateSelected];
        [retryButton addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventTouchUpInside];
        [_errorView addSubview:retryButton];
        ACCMasMaker(retryButton, {
            make.top.equalTo(descriptionLabel.mas_bottom).offset(30.f);
            make.centerX.equalTo(_errorView);
            make.width.equalTo(@150.f);
            make.height.equalTo(@44.f);
        })
    }
    return _errorView;
}

- (BOOL)needSearchBar
{
    return YES;
}

- (NSString *)searchBarPlaceHolder
{
    return @"搜索";
}

- (ACCEditTagType)type
{
    return ACCEditTagTypeNone;
}

- (NSString *)cellIdentifier
{
    return @"";
}

- (CGFloat)cellHeight
{
    return 0.f;
}

- (Class)cellClass
{
    return [UITableViewCell class];
}

- (NSArray *)dataSource
{
    return [NSArray array];
}

- (NSString *)headerText
{
    return @"";
}

- (NSString *)emptyResultText
{
    return @"";
}

- (void)configCell:(UITableViewCell *)cell
{
}

- (UIView *)emptyStateView
{
    return self.emptyView;
}

- (BOOL)needFooter
{
    return YES;
}

- (CGFloat)headerHeight
{
    return 0.f;
}

- (UIView *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
    }
    return _bottomView;
}

- (CGFloat)bottomViewHeight
{
    return 0.f;
}

- (AWEInteractionEditTagStickerModel *)tagModelForIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (BOOL)needCreateCustomTagFooter
{
    return YES;
}

- (NSInteger)indexOfItem:(NSString *)item
{
    return -1;
}

- (NSString *)itemTitle
{
    return @"";
}

- (NSString *)tagTypeString
{
    return @"";
}

- (NSString *)tagSource
{
    NSString *tagSource = @"";
    if ([self isSearch]) {
        tagSource = @"tag_rec";
    } else {
        tagSource = @"tag_suppose";
    }
    return tagSource;
}

- (NSDictionary *)itemTrackerParamsForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return @{};
}

- (void)trackCellDisplayAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = [[self dataSource] copy];
    if (indexPath.row <= [dataSource count]) {
        NSMutableDictionary *params = [[self trackerParamsForItemAtIndexPath:indexPath] mutableCopy];
        NSString *event = [self isSearch] ? @"tag_search_word_show" :  @"tag_rec_content_show";
        if (![self isSearch]) {
            [params setValue:@"suppose_rec" forKey:@"rec_type"];
        }
        [ACCTracker() trackEvent:event params:params];
    }
}

- (void)setTrackerParams:(NSDictionary *)trackerParams
{
    NSMutableDictionary *params = [trackerParams mutableCopy];
    [params setValue:[self tagTypeString] forKey:@"tag_type"];
    _trackerParams = [params copy];
}

- (void)restoreRecommendData
{
    
}

- (BOOL)needNetworkRequest
{
    return YES;
}

- (UIView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [[UIView alloc] init];
        _loadingView.backgroundColor = [UIColor clearColor];
        self.loadingIndicator = [ACCLoading() loadingView];
        [_loadingView addSubview:self.loadingIndicator];
        ACCMasMaker(self.loadingIndicator, {
            make.center.equalTo(_loadingView);
            make.width.height.equalTo(@80);
        });
    }
    return _loadingView;
}

- (BOOL)needNoMoreFooterText
{
    return ACC_isEmptyString(self.currentKeyword);
}

- (BOOL)needToTrackClickEvent
{
    return YES;
}

- (void)updateHeaderView
{
    self.headerLabel.text = [self headerText];
    if (ACC_isEmptyString([self headerText])) {
        ACCMasReMaker(self.headerLabel, {
            make.left.equalTo(self.headerView).offset(16.f);
            make.top.equalTo(self.headerView);
            make.height.equalTo(@0);
        });
        ACCMasReMaker(self.headerView, {
            make.top.left.right.equalTo(_normalView);
            make.height.equalTo(@([self headerHeight]));
        });
    } else {
        ACCMasReMaker(self.headerLabel, {
            make.left.equalTo(self.headerView).offset(16.f);
            make.top.equalTo(self.headerView);
        });
        ACCMasReMaker(self.headerView, {
            make.top.left.right.equalTo(self.normalView);
            make.height.equalTo(@([self headerHeight]));
        });
    }
}

- (UIView *)searchBarLeftView
{
    return nil;
}

@end
