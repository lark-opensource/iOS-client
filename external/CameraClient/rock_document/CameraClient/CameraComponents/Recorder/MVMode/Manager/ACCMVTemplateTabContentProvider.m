//
//  ACCMVTemplateTabContentProvider.m
//  CameraClient
//
//  Created by long.chen on 2020/3/3.
//

#import "ACCMVTemplateTabContentProvider.h"
#import "ACCMVTemplatesContentProvider.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCMVCategoryModel.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "AWERepoTrackModel.h"
#import <CameraClient/AWERepoMVModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>

@interface ACCMVTemplateTabContentProvider ()

@property (nonatomic, assign) NSUInteger currentSelectedVCIndex;
@property (nonatomic, copy) NSArray<ACCWaterfallViewController *> *viewControllers;

@end

@implementation ACCMVTemplateTabContentProvider

@synthesize viewController;

- (instancetype)init
{
    if (self = [super init]) {
        _currentSelectedVCIndex = NSNotFound;
    }
    return self;
}

- (void)setCategories:(NSArray<ACCMVCategoryModel *> *)categories
{
    NSMutableArray *result = categories.mutableCopy;
    
    if([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]){
        ACCMVCategoryModel *favoriteCategory = [ACCMVCategoryModel new];
        favoriteCategory.categoryName = ACCLocalizedString(@"add_to_favorite", nil);
        favoriteCategory.categoryType = ACCMVCategoryTypeFavorite;
        [result insertObject:favoriteCategory atIndex:0];
    }
    
    for (ACCMVCategoryModel *category in result) {
        category.categoryName = [NSString stringWithFormat:@"\u202A%@", category.categoryName]; // to forbid translation
    }
    _categories = result.copy;
}

- (NSUInteger)initialSelectedIndex
{
    if (self.categories.count > 2) {
        return 2;
    }
    return 0;
}

- (nonnull NSArray<NSString *> *)tabTitlesArray
{
    return [self.categories acc_mapObjectsUsingBlock:^NSString * _Nonnull(ACCMVCategoryModel * _Nonnull obj, NSUInteger idex) {
        return obj.categoryName;
    }];
}

- (nonnull NSArray<UIViewController *> *)slidingViewControllers
{
    return self.viewControllers;
}

- (NSArray<ACCWaterfallViewController *> *)viewControllers
{
    if (!_viewControllers) {
        NSMutableArray *viewControllers = @[].mutableCopy;
        for (int i = 0; i < self.categories.count; i++) {
            ACCWaterfallViewController *templateVC = [ACCWaterfallViewController new];
            ACCMVTemplatesContentProvider *contentProvider = [ACCMVTemplatesContentProvider new];
            if (i == 2) {
                contentProvider.isLandingCategory = YES;
            }
            contentProvider.category = self.categories[i];
            templateVC.contentProvider = contentProvider;
            templateVC.collectionView.contentInset = self.contentInsets;
            contentProvider.viewController = templateVC;
            contentProvider.willEnterDetailVCBlock = self.willEnterDetailVCBlock;
            contentProvider.didPickTemplateBlock = self.didPickTemplateBlock;
            contentProvider.publishModel = self.publishModel;
            @weakify(self);
            @weakify(contentProvider);
            contentProvider.currentVCVisibleBlock = ^BOOL{
                @strongify(self);
                @strongify(contentProvider);
                ACCWaterfallViewController *currentVC = self.viewControllers[self.currentSelectedVCIndex];
                return currentVC == contentProvider.viewController;
            };
            [viewControllers addObject:templateVC];
        }
        _viewControllers = viewControllers;
    }
    return _viewControllers;
}

- (void)slidingViewController:(nonnull ACCSlidingViewController *)slidingViewController didSelectIndex:(NSInteger)index
{
    if (index == self.currentSelectedVCIndex) {
        ACCWaterfallViewController *currentVC = self.viewControllers[self.currentSelectedVCIndex];
        [currentVC refreshContent];
    } else {
        ACCMVCategoryModel *category = self.categories[index];
        self.publishModel.repoMV.mvTemplateCategoryID = category.categoryID;
        NSMutableDictionary *params = @{
            @"shoot_way" : self.publishModel.repoTrack.referString ?: @"",
            @"creation_id" : self.publishModel.repoContext.createId ?: @"",
            @"tab_name" : category.categoryName ?: @"",
            @"tab_id" : @(category.categoryID),
        }.mutableCopy;
        if (self.currentSelectedVCIndex == NSNotFound) { // index is initial index
            [params setValue:@"default" forKey:@"landing_type"];
        } else {
            [params setValue:@"operated" forKey:@"landing_type"];
        }
        
        if (self.publishModel.repoTrack.schemaTrackParams) {
            [params addEntriesFromDictionary:self.publishModel.repoTrack.schemaTrackParams];
        }
        [ACCTracker() trackEvent:@"enter_mv_tab"
                           params:params.copy
                  needStagingFlag:NO];
        self.currentSelectedVCIndex = index;
    }
}

- (UIView *)acc_zoomTransitionStartViewForItemOffset:(NSInteger)itemOffset
{
    if (self.currentSelectedVCIndex < 0 || self.currentSelectedVCIndex >= self.viewControllers.count) {
        return nil;
    }
    ACCWaterfallViewController *currentVC = self.viewControllers[self.currentSelectedVCIndex];
    return [currentVC transitionCollectionCellForItemOffset:itemOffset];
}

@end
