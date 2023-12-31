//
//  AWEVideoEditEmojiStickerCollectionViewController.m
//  CameraClient
//
//  Created by HuangHongsen on 2020/2/6.
//

#import "AWEVideoEditEmojiStickerCollectionViewController.h"
#import "AWEEmojiStickerCollectionViewCell.h"
#import "AWEEmojiStickerDataManager.h"
#import <CreationKitInfra/ACCLoadMoreFooter.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCMacros.h>

@implementation AWEVideoEditEmojiStickerCollectionViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.horizontalInset = 0.f;
        CGFloat width = (ACC_SCREEN_WIDTH - 2 * self.horizontalInset) / 5;
        self.itemSize = CGSizeMake(width, (57 / 75.0) * width); //height / width = 57 / 75
    }
    return self;
}

#pragma mark - Override

- (void)configureCollectionView
{
    [self.collectionView registerClass:[AWEEmojiStickerCollectionViewCell class] forCellWithReuseIdentifier:[AWEEmojiStickerCollectionViewCell identifier]];
    
    @weakify(self)
    self.collectionView.mj_footer = [ACCLoadMoreFooter footerWithRefreshingBlock:^{
        @strongify(self);
        if (![AWEEmojiStickerDataManager defaultManager].emojiHasMore) {
            [self.collectionView.mj_footer endRefreshingWithNoMoreData];
            return;
        }

        [self loadmoreEmoji];
    }];

    [AWEEmojiStickerDataManager defaultManager].logger = self.logger;
}

- (void)loadmoreEmoji
{
    @weakify(self);
    [[AWEEmojiStickerDataManager defaultManager] loadMoreEmojisWithCompletion:^(BOOL downloadSuccess) {
        @strongify(self);
        if (downloadSuccess) {
            self.categories = [[AWEEmojiStickerDataManager defaultManager] emojiCategories];
            self.effects = [[AWEEmojiStickerDataManager defaultManager] emojiEffects];
            acc_dispatch_main_async_safe(^{
                [self.collectionView reloadData];
            });
        } else {
            acc_dispatch_main_async_safe(^{
                [ACCToast() show:ACCLocalizedString(@"com_mig_there_was_a_problem_with_the_internet_connection_try_again_later_yq455g", @"网络不给力，请稍后重试")];
            });
        }
        
        acc_dispatch_main_async_safe(^{
            if ([AWEEmojiStickerDataManager defaultManager].emojiHasMore) {
                [self.collectionView.mj_footer endRefreshing];
            } else {
                [self.collectionView.mj_footer endRefreshingWithNoMoreData];
            }
        });
    }];
}

- (AWEBaseStickerCollectionViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.collectionView dequeueReusableCellWithReuseIdentifier:[AWEEmojiStickerCollectionViewCell identifier] forIndexPath:indexPath];
}

- (void)fetchDataWithCompletion:(void (^)(BOOL))completion
{
    @weakify(self)
    void (^completionBlock)(BOOL downloadSuccess) = ^(BOOL downloadSuccess) {
        if (!downloadSuccess || [[AWEEmojiStickerDataManager defaultManager] emojiEffects].count == 0) {
            ACCBLOCK_INVOKE(completion, NO);
        } else {
            @strongify(self)
            self.categories = [[AWEEmojiStickerDataManager defaultManager] emojiCategories];
            self.effects = [[AWEEmojiStickerDataManager defaultManager] emojiEffects];
            ACCBLOCK_INVOKE(completion, YES);
        }
    };
    
    
    [[AWEEmojiStickerDataManager defaultManager] fetchEmojiPanelCategoriesAndDefaultEffects:completionBlock];
}

- (AWEVideoEditStickerCollectionViewStyle)style
{
    return AWEVideoEditStickerCollectionViewStyleNone;
}

- (NSString *)stickerType
{
    return @"emoji";
}

- (NSDictionary *)logPB
{
    return @{
        @"impr_id" : [AWEEmojiStickerDataManager defaultManager].requestID ? : @"",
    };
}

@end
