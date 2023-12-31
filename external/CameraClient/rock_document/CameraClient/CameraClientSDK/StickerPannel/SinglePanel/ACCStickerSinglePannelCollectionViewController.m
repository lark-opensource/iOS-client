//
//  ACCStickerSinglePannelCollectionViewController.m
//  AAWELaunchOptimization-Pods-DouYin
//
//  Created by liyingpeng on 2020/8/19.
//

#import "ACCStickerSinglePannelCollectionViewController.h"

#import <CreationKitInfra/ACCLoadMoreFooter.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCStickerPannelDataManager.h"

@interface ACCStickerSinglePannelCollectionViewController ()

@property (nonatomic, strong) ACCStickerPannelDataPagination *page;

@end

@implementation ACCStickerSinglePannelCollectionViewController
@synthesize uiConfig = _uiConfig;

- (void)setUiConfig:(ACCStickerPannelUIConfig *)uiConfig {
    _uiConfig = uiConfig;
    self.horizontalInset = self.uiConfig.horizontalInset;
    NSInteger numberOfItemsInOneRow = self.uiConfig.numberOfItemsInOneRow;
    CGFloat width = (ACC_SCREEN_WIDTH - self.horizontalInset * 2) / numberOfItemsInOneRow;
    CGFloat height = self.uiConfig.sizeRatio * width;
    self.itemSize = CGSizeMake(width, height);
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)fetchDataWithCompletion:(void (^)(BOOL))completion
{
    @weakify(self)
    [self.dataManager fetchCategoryStickers:self.category.categoryKey completion:^(BOOL downloadSuccess, NSArray<IESEffectModel *> * _Nonnull effects, ACCStickerPannelDataPagination * _Nonnull pagination) {
        @strongify(self)
        if (downloadSuccess) {
            self.page = pagination;
            self.effects = effects;
            ACCBLOCK_INVOKE(completion, YES);
        } else {
            ACCBLOCK_INVOKE(completion, NO);
        }
    }];
}

- (AWEVideoEditStickerCollectionViewStyle)style
{
    return AWEVideoEditStickerCollectionViewStyleNone;
}

- (void)configureCollectionView
{
    [self.collectionView registerClass:[AWEInformationStickerCollectionViewCell class] forCellWithReuseIdentifier:[AWEInformationStickerCollectionViewCell identifier]];
    
    @weakify(self)
    self.collectionView.mj_footer = [ACCLoadMoreFooter footerWithRefreshingBlock:^{
        @strongify(self);
        if (!self.page.hasMore) {
            [self.collectionView.mj_footer endRefreshingWithNoMoreData];
            return;
        }

        [self loadMoreSticker];
    }];
}

- (void)loadMoreSticker {
    @weakify(self)
    [self.dataManager loadMoreStckerWithCategory:self.category.categoryKey page:self.page completion:^(BOOL downloadSuccess, NSArray<IESEffectModel *> * _Nonnull effects, ACCStickerPannelDataPagination * _Nonnull pagination) {
        @strongify(self);
        if (downloadSuccess) {
            NSMutableArray *result = [NSMutableArray arrayWithArray:self.effects];
            [result addObjectsFromArray:effects];
            self.effects = result.copy;
            [self.collectionView reloadData];
        }
        self.page = pagination;
        if (pagination.hasMore) {
            [self.collectionView.mj_footer endRefreshing];
        } else {
            [self.collectionView.mj_footer endRefreshingWithNoMoreData];
        }
    }];
}

- (AWEBaseStickerCollectionViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath
{
    AWEBaseStickerCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:[AWEInformationStickerCollectionViewCell identifier] forIndexPath:indexPath];
    cell.uiConfig = self.uiConfig;
    return cell;
}

@end
