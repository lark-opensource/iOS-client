//
//  ACCMVTemplatesContentProvider.m
//  CameraClient
//
//  Created by long.chen on 2020/3/2.
//

#import "ACCMVTemplatesContentProvider.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCMVTemplateCollectionViewCell.h"
#import <CreationKitInfra/ACCResponder.h>
#import "ACCMVTemplatesDetailTableViewController.h"
#import "ACCFavoriteMVTemplatesDataController.h"
#import "ACCClassicalMVTemplatesDataController.h"
#import "ACCCategoryMVTemplatesDataController.h"
#import "ACCMVTemplatesTransitionDelegate.h"
#import "ACCMVCategoryModel.h"
#import "ACCMVTemplatesPreloadDataManager.h"
#import "ACCMVTemplateInteractionViewController.h"
#import "UIViewController+ACCUIKitEmptyPage.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import "AWEMVTemplateModel.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import <CreationKitArch/ACCRepoContextModel.h>


static NSUInteger const kColumnCount = 2;
static CGFloat const kPadding = 8.f;
static CGFloat const kminimumColumnSpacing = 7.f;
static CGFloat const kminimumItemSpacing = 8.f;

@interface ACCMVTemplatesContentProvider ()

@property (nonatomic, strong) id<ACCMVTemplatesDataControllerProtocol> dataController;
@property (nonatomic, assign) BOOL usedProloadData;
@property (nonatomic, strong) ACCMVTemplatesTransitionDelegate *transitionDelegate;

@property (nonatomic, assign) BOOL hasFetchLandingTab;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *needRemoveIndexs;

@end

@implementation ACCMVTemplatesContentProvider

@synthesize viewController, hasMore, columnCount, minimumColumnSpacing, minimumInteritemSpacing, sectionInset;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(p_handleDidFavoriteMVTemplate:)
                                                     name:ACCMVTemplateDidFavoriteNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(p_handleDidUnFavoriteMVTemplate:)
                                                     name:ACCMVTemplateDidUnFavoriteNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - Public

- (UIView *)acc_zoomTransitionStartViewForItemOffset:(NSInteger)itemOffset
{
    return [self.viewController transitionCollectionCellForItemOffset:itemOffset];
}

#pragma mark - ACCWaterfallContentProviderProtocol

- (void)handleOnViewDidAppear
{
    NSMutableArray *needRemoveModels = [[NSMutableArray alloc] init];
    NSArray *needRemoveIndexsCopy = [self.needRemoveIndexs copy];
    for (NSNumber *indexValue in needRemoveIndexsCopy) {
        NSUInteger idx = indexValue.integerValue;
        if (idx < self.dataController.dataSource.count) {
            [needRemoveModels addObject:[self.dataController.dataSource objectAtIndex:idx]];
        }
    }
    [self.dataController.dataSource removeObjectsInArray:needRemoveModels];
    [self.needRemoveIndexs removeAllObjects];
    [self.viewController reloadContent];
}

- (void)refreshContentDataIsRetry:(BOOL)isRetry completion:(void (^)(NSError *, NSArray *, BOOL))completion
{
    if (isRetry) {
        [ACCTracker() trackEvent:@"reload_mv_shoot_page"
                           params:@{
                               @"shoot_way" : self.publishModel.repoTrack.referString ?: @"",
                               @"creation_id" : self.publishModel.repoContext.createId ?: @"",
                               @"langing_type" : self.isLandingCategory && self.dataController.dataSource.count == 0 ? @"default" : @"operated",
                               @"tab_name" : self.category.categoryName ?: @"",
                               @"reload_type" : @"page",
                           }];
    }
    
    if (self.isLandingCategory && !self.usedProloadData) {
        self.usedProloadData = YES;
        if ([ACCMVTemplatesPreloadDataManager sharedInstance].firstPageHotMVTemplates.count) {
            [self.dataController.dataSource addObjectsFromArray:[ACCMVTemplatesPreloadDataManager sharedInstance].firstPageHotMVTemplates];
            self.dataController.hasMore = [ACCMVTemplatesPreloadDataManager sharedInstance].hasMore;
            self.dataController.cursor = [ACCMVTemplatesPreloadDataManager sharedInstance].cursor;
            self.dataController.sortedPosition = [ACCMVTemplatesPreloadDataManager sharedInstance].sortedPosition;
            self.hasFetchLandingTab = YES;
            ACCBLOCK_INVOKE(completion, nil, self.dataController.dataSource, self.dataController.hasMore);
            return;
        }
    }
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    @weakify(self);
    [self.dataController refreshContentDataWithCompletion:^(NSError * error, NSArray<id<ACCMVTemplateModelProtocol>> * templateModels, BOOL hasMore) {
        @strongify(self);
        if (self.isLandingCategory && self.dataController.dataSource.count) {
            [ACCMVTemplatesPreloadDataManager sharedInstance].firstPageHotMVTemplates = self.dataController.dataSource;
            [ACCMVTemplatesPreloadDataManager sharedInstance].hasMore = self.dataController.hasMore;
            [ACCMVTemplatesPreloadDataManager sharedInstance].cursor = self.dataController.cursor;
            [ACCMVTemplatesPreloadDataManager sharedInstance].sortedPosition = self.dataController.sortedPosition;
        }
        [ACCTracker() track:@"mv_shoot_page_load_status"
                      params:@{
                          @"shoot_way" : self.publishModel.repoTrack.referString ?: @"",
                          @"creation_id" : self.publishModel.repoContext.createId ?: @"",
                          @"status" : !error ? @"succeed" : @"failed",
                          @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                          @"landing_type" : self.isLandingCategory && !self.hasFetchLandingTab ? @"default" : @"operated",
                          @"tab_name" : self.category.categoryName ?: @"",
                      }];
        self.hasFetchLandingTab = YES;
        ACCBLOCK_INVOKE(completion, error, templateModels, hasMore);
    }];
    
    if (self.category.categoryType == ACCMVCategoryTypeFavorite) {
        if (![AWEMVTemplateModel sharedManager].templateModels.count) {
            [[AWEMVTemplateModel sharedManager] checkAndUpdatePhotoMovieTemplate];
        }
    }
}

- (void)loadMoreContentDataWithCompletion:(void (^)(NSError *, NSArray *, BOOL))completion
{
    [self.dataController loadMoreContentDataWithCompletion:^(NSError * error, NSArray<id<ACCMVTemplateModelProtocol>> * templateModels, BOOL hasMore) {
        ACCBLOCK_INVOKE(completion, error, templateModels, hasMore);
    }];
}

- (BOOL)hasMore
{
    return self.dataController.hasMore;
}

- (NSUInteger)columnCount
{
    return kColumnCount;
}

- (CGFloat)minimumColumnSpacing
{
    return kminimumColumnSpacing;
}

- (CGFloat)minimumInteritemSpacing
{
    return kminimumItemSpacing;
}

- (UIEdgeInsets)sectionInset
{
    return UIEdgeInsetsMake(kPadding, kPadding, kPadding, kPadding);
}

- (void)registerCellForcollectionView:(UICollectionView *)collectionView
{
    [collectionView registerClass:ACCMVTemplateCollectionViewCell.class forCellWithReuseIdentifier:[ACCMVTemplateCollectionViewCell cellIdentifier]];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self p_filteredDataSource].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCMVTemplateCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[ACCMVTemplateCollectionViewCell cellIdentifier] forIndexPath:indexPath];
    cell.creationID = self.publishModel.repoContext.createId;
    if (indexPath.item < [self p_filteredDataSource].count) {
        id<ACCMVTemplateModelProtocol> templateModel = [self p_filteredDataSource][indexPath.item];
        [cell updateWithTemplateModel:templateModel];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item >= [self p_filteredDataSource].count) {
        return CGSizeZero;
    }
    
    id<ACCMVTemplateModelProtocol> templateModel = [self p_filteredDataSource][indexPath.item];
    CGFloat width = (ACC_SCREEN_WIDTH - kPadding * 2 - kminimumItemSpacing * (kColumnCount - 1)) / kColumnCount;
    CGFloat height = [ACCMVTemplateCollectionViewCell cellHeightForModel:templateModel withWidth:width];
    return CGSizeMake(width, height);
}

- (void)collectionView:(nonnull UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    ACCBLOCK_INVOKE(self.willEnterDetailVCBlock);
    UINavigationController *navigationController = [ACCResponder topNavigationControllerForResponder:self.viewController];
    navigationController.delegate = self.transitionDelegate;
    ACCMVTemplatesDetailTableViewController *detailTableVC = [[ACCMVTemplatesDetailTableViewController alloc] initWithDataController:self.dataController initialIndex:indexPath.item];
    @weakify(self);
    detailTableVC.dataChangedBlock = ^{
        @strongify(self);
        [self.viewController diffReloadContent];
    };
    detailTableVC.initialNavigaitonDelegate = self.transitionDelegate;
    detailTableVC.didPickTemplateBlock = self.didPickTemplateBlock;
    detailTableVC.publishModel = self.publishModel;
    [self.transitionDelegate wireToViewController:detailTableVC];
    [navigationController pushViewController:detailTableVC animated:YES];

    id<ACCMVTemplateModelProtocol> templateModel = self.dataController.dataSource[indexPath.item];
    [ACCTracker() trackEvent:@"click_mv_card"
                       params:@{
                           @"mv_id" : @(templateModel.templateID),
                           @"enter_from" : self.publishModel.repoTrack.enterFrom ?: @"",
                           @"shoot_way" : self.publishModel.repoTrack.referString ?: @"",
                           @"creation_id" : self.publishModel.repoContext.createId ?: @"",
                           @"content_type" : templateModel.accTemplateType == ACCMVCategoryTypeClassic ? @"mv" : @"jianying_mv",
                           @"mv_recommend" : @"1",
                           @"impr_position" : @(indexPath.item + 1)
                       }
              needStagingFlag:NO];
}

- (ACCUIKitViewControllerEmptyPageConfig *)accui_emptyPageConfigForState:(NSUInteger)state
{
    ACCUIKitViewControllerEmptyPageConfig *config = [ACCUIKitViewControllerEmptyPageConfig new];
    config.backgroundColor = ACCResourceColor(ACCColorBGView);
    config.style = ACCUIKitViewControllerEmptyPageStyleB;
    if (state == ACCUIKitViewControllerStateError) {
        config.iconImage = [UIImage imageNamed:@"img_empty_neterror"];
    } else if (state == ACCUIKitViewControllerStateEmpty) {
        config.style = ACCUIKitViewControllerEmptyPageStyleE;
        if (self.category.categoryType == ACCMVCategoryTypeFavorite) {
            config.titleText = @" "; 
            config.informativeText = ACCLocalizedString(@"creation_mv_favourite_no_content_hint", @"你还没有收藏过任何内容");
        }
    }

    return config;
}

- (void)didReceiveMemoryWarning
{
    BOOL currentVCVisible = YES;
    if (self.currentVCVisibleBlock) {
        currentVCVisible = self.currentVCVisibleBlock();
    }
    if (!currentVCVisible) {
        NSArray *visibleCells = self.viewController.collectionView.visibleCells;
        for (ACCMVTemplateCollectionViewCell *cell in visibleCells) {
            cell.coverImageView.image = nil;
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item >= 0 && indexPath.item < [self p_filteredDataSource].count) {
        id<ACCMVTemplateModelProtocol> templateModel = [self p_filteredDataSource][indexPath.item];
        [ACCTracker() trackEvent:@"mv_show"
                           params:@{
                               @"mv_id" : @(templateModel.templateID),
                               @"enter_from" : @"video_shoot_page",
                               @"shoot_way" : self.publishModel.repoTrack.referString ?: @"",
                               @"creation_id" : self.publishModel.repoContext.createId ?: @"",
                               @"content_type" : templateModel.accTemplateType == ACCMVCategoryTypeClassic ? @"mv" : @"jianying_mv",
                               @"mv_recommend" : @"1",
                               @"impr_position" : @(indexPath.item + 1)
                           }
                  needStagingFlag:NO];
    }
}

#pragma mark - Utils

- (NSArray<id<ACCMVTemplateModelProtocol>> *)p_filteredDataSource
{
    if (self.category.categoryType == ACCMVCategoryTypeFavorite) {
        return [self.dataController.dataSource filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id<ACCMVTemplateModelProtocol>  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return evaluatedObject.isCollected;
        }]];
    } else {
        return self.dataController.dataSource;
    }
}

- (void)p_handleDidFavoriteMVTemplate:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    id<ACCMVTemplateModelProtocol> template = [userInfo objectForKey:ACCMVTemplateFavoriteTemplateKey];
    if (template) {
        if (self.category.categoryType == ACCMVCategoryTypeFavorite) {
            __block NSUInteger index = NSNotFound;
            [self.dataController.dataSource enumerateObjectsUsingBlock:^(id<ACCMVTemplateModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.templateID == template.templateID) {
                    obj.isCollected = YES;
                    index = idx;
                    *stop = YES;
                }
            }];
            if (index == NSNotFound) {
                [self.dataController.dataSource insertObject:template atIndex:0];
            } else if ([self.needRemoveIndexs containsObject:@(index)]) {
                [self.needRemoveIndexs removeObject:@(index)];
            }
            [self.viewController reloadContent];
        }
    }
}

- (void)p_handleDidUnFavoriteMVTemplate:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    id<ACCMVTemplateModelProtocol> template = [userInfo objectForKey:ACCMVTemplateFavoriteTemplateKey];
    if (template) {
        __block NSUInteger removeIdx = NSNotFound;
        [self.dataController.dataSource enumerateObjectsUsingBlock:^(id<ACCMVTemplateModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.templateID == template.templateID) {
                obj.isCollected = NO;
                removeIdx = idx;
                *stop = YES;
            }
        }];
        if (self.category.categoryType == ACCMVCategoryTypeFavorite) {
            if (removeIdx != NSNotFound) {
                [self.needRemoveIndexs addObject:@(removeIdx)];
            }
        }
    }
}

#pragma mark - Getters

- (id<ACCMVTemplatesDataControllerProtocol>)dataController
{
    if (!_dataController) {
        if (self.category.categoryType == ACCMVCategoryTypeFavorite) {
            _dataController = [ACCFavoriteMVTemplatesDataController new];
        } else if (self.category.categoryType == ACCMVCategoryTypeCutTheSame) {
            _dataController = [ACCCategoryMVTemplatesDataController new];
            _dataController.categoryModel = self.category;
        } else {
            _dataController = [ACCClassicalMVTemplatesDataController new];
        }
    }
    return _dataController;
}

- (ACCMVTemplatesTransitionDelegate *)transitionDelegate
{
    if (!_transitionDelegate) {
        _transitionDelegate = [ACCMVTemplatesTransitionDelegate new];
    }
    return _transitionDelegate;
}

- (NSMutableSet<NSNumber *> *)needRemoveIndexs
{
    if (!_needRemoveIndexs) {
        _needRemoveIndexs = [NSMutableSet set];
    }
    return _needRemoveIndexs;
}

@end
