//
//  ACCSearchStickerViewController.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/13.
//

#import "ACCSearchStickerViewController.h"
#import <CreationKitInfra/ACCSearchBar.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "AWEInformationStickerCollectionViewCell.h"
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCLoadMoreFooter.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCLogHelper.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <EffectPlatformSDK/IESInfoStickerModel.h>
#import <EffectPlatformSDK/EffectPlatform+InfoSticker.h>
#import <EffectPlatformSDK/EffectPlatform+Additions.h>

static NSInteger const ACCSearchStickerPageCount = 30;
static CGFloat const ACCSearchStickerBasicPadding = 15.f;
static CGFloat const ACCSearchStickerBasicSpace = 7.5;

@interface ACCSearchStickerViewController ()<UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate>

@property (nonatomic, strong) ACCSearchBar *searchBar;
@property (nonatomic, strong) UIButton *dismissBtn;
@property (nonatomic, strong) UIButton *searchBtn;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, weak) UIView<ACCLoadingViewProtocol> *loadingView;

@property (nonatomic, strong) IESInfoStickerResponseModel *recommendModel;
@property (nonatomic, strong) IESInfoStickerResponseModel *searchModel;
@property (nonatomic, copy) NSArray<IESInfoStickerModel *> *recommendList;
@property (nonatomic, copy) NSArray<IESInfoStickerModel *> *searchList;

// AutoSearch
@property (nonatomic, assign) BOOL canAutoSearch;
@property (nonatomic, assign) BOOL isLoadingData;
@property (nonatomic, copy) NSString *searchedKeyword;
@property (nonatomic, strong) NSMutableDictionary *downloadingDict;

@end

@implementation ACCSearchStickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *dismissBtn = [[UIButton alloc] init];
    dismissBtn.titleLabel.font = [UIFont acc_systemFontOfSize:15.f weight:ACCFontWeightRegular];
    [dismissBtn setTitle:@"取消" forState:UIControlStateNormal];
    [dismissBtn addTarget:self action:@selector(p_dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dismissBtn];
    self.dismissBtn = dismissBtn;
    ACCMasMaker(dismissBtn, {
        make.top.equalTo(@(ACCSearchStickerBasicPadding));
        make.right.equalTo(@(-ACCSearchStickerBasicPadding));
        make.width.equalTo(@40.f);
        make.height.equalTo(@36.f);
    });
    
    UIButton *searchBtn = [[UIButton alloc] init];
    searchBtn.titleLabel.font = [UIFont acc_systemFontOfSize:15.f weight:ACCFontWeightRegular];
    [searchBtn setTitle:@"搜索" forState:UIControlStateNormal];
    [searchBtn addTarget:self action:@selector(searchBarSearchButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:searchBtn];
    self.searchBtn = searchBtn;
    ACCMasMaker(searchBtn, {
        make.top.equalTo(@(ACCSearchStickerBasicPadding));
        make.right.equalTo(@(-ACCSearchStickerBasicPadding));
        make.width.equalTo(@40.f);
        make.height.equalTo(@36.f);
    });
    searchBtn.hidden = YES;
    
    ACCSearchBar *searchBar = [[ACCSearchBar alloc] initWithFrame:CGRectZero colorStyle:ACCSearchBarColorStyleD];
    if (searchBar.ownSearchField) {
        searchBar.ownSearchField.textAlignment = NSTextAlignmentLeft;
    }
    searchBar.placeholder = @"搜索更多贴纸";
    searchBar.delegate = self;
    [self.view addSubview:searchBar];
    self.searchBar = searchBar;
    ACCMasMaker(searchBar, {
        make.left.equalTo(@(ACCSearchStickerBasicPadding));
        make.right.equalTo(dismissBtn.mas_left).equalTo(@(-ACCSearchStickerBasicPadding));
        make.top.equalTo(@(ACCSearchStickerBasicPadding));
        make.height.equalTo(@36.f);
    });
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];;
    layout.minimumLineSpacing = ACCSearchStickerBasicSpace;
    layout.minimumInteritemSpacing = ACCSearchStickerBasicSpace;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionInset = UIEdgeInsetsMake(0.f, ACCSearchStickerBasicPadding, 8.f, ACCSearchStickerBasicPadding);

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.alwaysBounceVertical = YES;
    [collectionView registerClass:[ACCSearchStickerCollectionViewCell class] forCellWithReuseIdentifier:[ACCSearchStickerCollectionViewCell identifier]];
    [collectionView registerClass:[ACCSearchStickerCollectionViewHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[ACCSearchStickerCollectionViewHeader identifier]];
    if ([collectionView respondsToSelector:@selector(contentInsetAdjustmentBehavior)]) {
        if (@available(iOS 11.0, *)) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    ACCMasMaker(collectionView, {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.top.equalTo(searchBar.mas_bottom).equalTo(@(ACCSearchStickerBasicPadding));
        make.bottom.equalTo(self.view);
    });
    collectionView.hidden = YES;
    
    @weakify(self);
    ACCLoadMoreFooter *footer = [ACCLoadMoreFooter footerWithRefreshingBlock:^{
        @strongify(self);
        if (!self.searchList.count) {
            [self fetchRecommendData:YES];
        } else {
            [self fetchSearchData:self.searchBar.text loadMore:YES];
        }
    }];
    [footer setLoadingViewBackgroundColor:[UIColor clearColor]];
    collectionView.mj_footer = footer;
    
    self.canAutoSearch = YES;
    self.downloadingDict = [[NSMutableDictionary alloc] init];
    [self fetchRecommendData:NO];
}

#pragma mark - Data
- (NSArray<IESInfoStickerModel *> *)models
{
    return self.searchList.count > 0 ? self.searchList : self.recommendList;
}

- (void)fetchRecommendData:(BOOL)loadMore
{
    if (!loadMore) {
        [self p_configLoading:YES];
    }
    NSDictionary *extraParams = @{
        @"image_uri" : self.uploadFramesURI ? : @"",
        @"creation_id" : self.creationId ? : @"",
        @"source" : @2
    };
    @weakify(self);
    [EffectPlatform fetchInfoStickerRecommendListWithType:@"lab"
                                                pageCount:ACCSearchStickerPageCount
                                                   cursor:loadMore ? self.recommendModel.cursor.integerValue : 0
                                                effectIDs:nil
                                          extraParameters:extraParams
                                               completion:^(NSError * _Nullable error, IESInfoStickerResponseModel * _Nullable model) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if (!error) {
                if (loadMore && self.recommendModel) {
                    [self.recommendModel appendAndUpdateDataWithResponseModel:model];
                } else {
                    self.recommendModel = model;
                }
                self.recommendList = [self p_filterStickerList:self.recommendModel.stickerList];
            } else {
                AWELogToolError(AWELogToolTagEdit, @"search recommend info sticker request error: %@", error);
            }
            // 当前没有搜索结果时，加载推荐数据
            if (!self.searchList.count) {
                [self p_reloadData:loadMore];
            }
        });
    }];
}

- (void)fetchSearchData:(NSString *)keyword loadMore:(BOOL)loadMore
{
    if (!keyword.length) {
        return;
    }
    if (!loadMore) {
        [self p_configLoading:YES];
    }
    
    [self.delegate searchTrackEvent:@"infosticker_search_sug" extraParams:@{
        @"sug_keyword" : self.searchedKeyword ? : @""
    }];
    
    NSDictionary *extraParams = @{
        @"image_uri" : self.uploadFramesURI ? : @"",
        @"creation_id" : self.creationId ? : @""
    };
    @weakify(self);
    [EffectPlatform fetchInfoStickerSearchListWithKeyWord:keyword
                                                     type:@"lab"
                                                pageCount:ACCSearchStickerPageCount
                                                   cursor:loadMore ? self.searchModel.cursor.integerValue : 0
                                                effectIDs:nil
                                          extraParameters:extraParams
                                               completion:^(NSError * _Nullable error, IESInfoStickerResponseModel * _Nullable model) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if ([keyword isEqualToString:self.searchedKeyword]) {
                // 更新数据
                if (!error) {
                    if (loadMore && self.searchModel) {
                        [self.searchModel appendAndUpdateDataWithResponseModel:model];
                    } else {
                        self.searchModel = model;
                        if (!model.stickerList.count) {
                            [self.delegate searchTrackEvent:@"infosticker_search_failed" extraParams:@{
                                @"search_keyword" : keyword ? : @""
                            }];
                        }
                    }
                    self.searchList = [self p_filterStickerList:self.searchModel.stickerList];
                } else {
                    [self.delegate searchTrackEvent:@"infosticker_search_failed" extraParams:@{
                        @"search_keyword" : keyword ? : @""
                    }];
                    AWELogToolError(AWELogToolTagEdit, @"search info sticker request error: %@", error);
                }
                // 加载数据
                [self p_reloadData:loadMore];
            }
        });
    }];
}

#pragma mark - ScrollView
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.isLoadingData) {
        if (!self.useAutoSearch) {
            self.dismissBtn.hidden = NO;
            self.searchBtn.hidden = YES;
        }
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark - UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake((ACC_SCREEN_WIDTH - 2*ACCSearchStickerBasicPadding - 3*ACCSearchStickerBasicSpace) / 4, (ACC_SCREEN_WIDTH - 2*ACCSearchStickerBasicPadding - 3*ACCSearchStickerBasicSpace) / 4);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (self.models.count <= 0 || (self.searchList.count <= 0 && self.searchedKeyword.length > 0)) {
        return CGSizeMake(ACC_SCREEN_WIDTH, 63.f);
    }
    return CGSizeMake(CGFLOAT_MIN, CGFLOAT_MIN);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    ACCSearchStickerCollectionViewHeader *headerView = (ACCSearchStickerCollectionViewHeader *)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:[ACCSearchStickerCollectionViewHeader identifier] forIndexPath:indexPath];
    headerView.didClickBlock = nil;
    if (self.models.count <= 0) {
        [headerView updateWithTitle:@"网络不给力，请点击重试"];
        @weakify(self);
        headerView.didClickBlock = ^{
            @strongify(self);
            [self p_refetchData];
        };
    } else if (self.searchList.count <= 0 && self.searchedKeyword.length > 0) {
        [headerView updateWithTitle:@"没有搜索到结果，你可以试试以下贴纸"];
    } else {
        [headerView updateWithTitle:@""];
    }
    return headerView;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    IESInfoStickerModel *model = [self.models acc_objectAtIndex:indexPath.row];
    ACCSearchStickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[ACCSearchStickerCollectionViewCell identifier] forIndexPath:indexPath];
    if (!cell) {
        cell = [[ACCSearchStickerCollectionViewCell alloc] init];
    }
    [cell setupUI];
    
    NSMutableArray *images = [NSMutableArray array];
    if (model.dataSource == IESInfoStickerModelSourceLoki) {
        images = [model.iconDownloadURLs mutableCopy];
    } else {
        if (model.sticker.url) {
            [images acc_addObject:model.sticker.url];
        }
        if (model.thumbnailSticker.url) {
            [images acc_addObject:model.thumbnailSticker.url];
        }
    }

    cell.stickerId = model.stickerIdentifier;
    // 重置下载状态
    if (model.stickerIdentifier) {
        cell.downloadStatus = [self.downloadingDict acc_boolValueForKey:model.stickerIdentifier] ? AWEInfoStickerDownloadStatusDownloading : AWEInfoStickerDownloadStatusUndownloaded;
    }
    [cell configCellWithImage:[images copy]];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    IESInfoStickerModel *model = [self.models acc_objectAtIndex:indexPath.row];
    [self.delegate searchTrackEvent:@"prop_show" extraParams:[self p_stickerTrackParams:model index:indexPath.row+1]];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    ACCSearchStickerCollectionViewCell *cell = (ACCSearchStickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    IESInfoStickerModel *model = [self.models acc_objectAtIndex:index];
    if (!model.downloaded && model.stickerIdentifier) {
        cell.downloadStatus = AWEInfoStickerDownloadStatusDownloading;
        [self.downloadingDict btd_setObject:@(YES) forKey:model.stickerIdentifier];
    }
    @weakify(self);
    [self.delegate searchStickerCollectionViewController:self didSelectSticker:model indexPath:indexPath downloadProgressBlock:^(CGFloat progress) {
        if ([model.stickerIdentifier isEqualToString:cell.stickerId]) {
            [cell updateDownloadProgress:progress];
        }
    } downloadedBlock:^(BOOL success){
        @strongify(self);
        if ([model.stickerIdentifier isEqualToString:cell.stickerId]) {
            cell.downloadStatus = AWEInfoStickerDownloadStatusDownloaded;
        }
        if (model.stickerIdentifier) {
            [self.downloadingDict removeObjectForKey:model.stickerIdentifier];
        }
        if (!success) {
            [ACCToast() show:@"下载失败" onView:self.view];
        }
    }];
    [self.delegate searchTrackEvent:@"prop_click" extraParams:[self p_stickerTrackParams:model index:index+1]];
}

#pragma mark - UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if (!self.useAutoSearch) {
        BOOL isEmpty = searchBar.text.length <= 0;
        self.dismissBtn.hidden = !isEmpty;
        self.searchBtn.hidden = isEmpty;
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    BOOL isEmpty = searchBar.text.length <= 0;
    if (isEmpty) {
        [self p_searchTextBecomeEmpty];
    }
    if (!self.useAutoSearch) {
        self.dismissBtn.hidden = !isEmpty;
        self.searchBtn.hidden = isEmpty;
    } else {
        [self p_autoSearch];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (!self.useAutoSearch) {
        self.dismissBtn.hidden = NO;
        self.searchBtn.hidden = YES;
    }
    [self p_manullySearch];
}

#pragma mark - Actions
// 每次数据变更后调用
- (void)p_reloadData:(BOOL)loadMore
{
    self.isLoadingData = YES;
    BOOL hasSearchData = self.searchList.count > 0;
    BOOL hasRecommendData = self.recommendList.count > 0;
    if (hasSearchData) {
        if (self.searchModel.hasMore) {
            [self.collectionView.mj_footer endRefreshing];
            [self.collectionView.mj_footer resetNoMoreData];
        } else {
            [self.collectionView.mj_footer endRefreshingWithNoMoreData];
        }
    } else if (hasRecommendData) {
        if (self.recommendModel.hasMore) {
            [self.collectionView.mj_footer endRefreshing];
            [self.collectionView.mj_footer resetNoMoreData];
        } else {
            [self.collectionView.mj_footer endRefreshingWithNoMoreData];
        }
    }
    
    [self.collectionView reloadData];
    if (!loadMore) {
        [self p_configLoading:NO];
        [self.collectionView setContentOffset:CGPointZero animated:NO];
    }
    self.isLoadingData = NO;
}

- (void)p_refetchData
{
    if (self.searchBar.text.length > 0) {
        self.searchedKeyword = self.searchBar.text;
        [self fetchSearchData:self.searchedKeyword loadMore:NO];
    } else {
        self.collectionView.hidden = YES;
        [self fetchRecommendData:NO];
    }
}

// 返回贴纸面板
- (void)p_dismiss
{
    [self.delegate searchStickerCollectionViewControllerWillExit];
}

// 手动搜索
- (void)p_manullySearch
{
    [self.searchBar resignFirstResponder];
    if (![self.searchedKeyword isEqualToString:self.searchBar.text] || self.models.count <= 0) {
        self.searchedKeyword = self.searchBar.text;
        [self fetchSearchData:self.searchBar.text loadMore:NO];
    }
}

// 自动搜索，最小时间间隔0.5s
- (void)p_autoSearch
{
    if ([self.searchedKeyword isEqualToString:self.searchBar.text] || !self.canAutoSearch) {
        return;
    }
    self.canAutoSearch = NO;
    self.searchedKeyword = self.searchBar.text;
    [self fetchSearchData:self.searchBar.text loadMore:NO];
    
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        self.canAutoSearch = YES;
        if (![self.searchedKeyword isEqualToString:self.searchBar.text]) {
            self.searchedKeyword = self.searchBar.text;
            [self fetchSearchData:self.searchBar.text loadMore:NO];
        }
    });
}

// 搜索输入清空
- (void)p_searchTextBecomeEmpty
{
    self.searchModel = nil;
    self.searchedKeyword = nil;
    [self p_reloadData:NO];
}

// Loading图标控制
- (void)p_configLoading:(BOOL)show
{
    [self.loadingView dismiss];
    if (show) {
        self.loadingView = [ACCLoading() showLoadingOnView:self.view];
    } else {
        self.collectionView.hidden = NO;
    }
}

// 过滤
- (NSArray<IESInfoStickerModel *> *)p_filterStickerList:(NSArray<IESInfoStickerModel *> *)list
{
    NSMutableArray<IESInfoStickerModel *> *result = [[NSMutableArray alloc] init];
    [list enumerateObjectsUsingBlock:^(IESInfoStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self p_shouldFilter:obj tags:self.filterTags]) {
            [result addObject:obj];
        }
    }];
    return [result copy];
}

- (BOOL)p_shouldFilter:(IESInfoStickerModel *)sticker tags:(NSArray<NSString *> *)tags
{
    __block BOOL shouldFilter = NO;
    [sticker.tags enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *lowerStr = obj.lowercaseString;
        if ([tags containsObject:lowerStr] || [lowerStr isEqualToString:@"searchsticker"]) {
            shouldFilter = YES;
            *stop = YES;
        }
    }];
    return shouldFilter;
}

- (NSDictionary *)p_stickerTrackParams:(IESInfoStickerModel *)model index:(NSInteger)index
{
    return @{
        @"prop_id" : model.stickerIdentifier ? : @"",
        @"enter_method" : @"click_main_panel",
        @"category_name" : @"sticker",
        @"tab_id" : @"search",
        @"after_search" : @(1),
        @"impr_position" : @(index),
        @"search_keyword" : self.searchedKeyword ? : @"",
        @"is_first_search" : ACC_isEmptyString(self.searchedKeyword) ? @1 : @0,
        @"is_giphy" : @(1),
        @"image_uri" : self.uploadFramesURI ? : @"",
        @"staus" : self.enterStatus ? : @""
    };
}
@end
