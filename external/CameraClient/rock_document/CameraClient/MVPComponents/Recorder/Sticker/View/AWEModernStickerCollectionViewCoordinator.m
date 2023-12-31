//
//  AWEModernStickerCollectionViewCoordinator.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/15.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEModernStickerCollectionViewCoordinator.h"
#import "AWEModernStickerContentCollectionViewCell.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>

@interface AWEModernStickerCollectionViewCoordinator () <UIScrollViewDelegate, UICollectionViewDelegate, AWEModernStickerSwitchTabViewDelegate>

@property (nonatomic, assign) BOOL allowShowLoginView;

@end

@implementation AWEModernStickerCollectionViewCoordinator

- (void)setStickerSwitchTabView:(AWEModernStickerSwitchTabView *)stickerSwitchTabView
{
    _stickerSwitchTabView = stickerSwitchTabView;
    stickerSwitchTabView.delegate = self;
}

- (void)setContentCollectionView:(AWEModernStickerContentCollectionView *)contentCollectionView
{
    _contentCollectionView = contentCollectionView;
    contentCollectionView.delegate = self;
}

// 旧道具面板：左右滑动的collectionView
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.allowShowLoginView = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.contentCollectionView) {
        _contentCollectionViewIsScrolling = YES;

        if (self.stickerSwitchTabView.shouldIgnoreAnimation) {
            return;
        }

        CGFloat offsetX = self.contentCollectionView.contentOffset.x;

        if (offsetX < self.contentCollectionView.frame.size.width && ! [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) {
            self.contentCollectionView.contentOffset = CGPointMake(self.contentCollectionView.frame.size.width, self.contentCollectionView.contentOffset.y);
            if (self.allowShowLoginView) {
                self.allowShowLoginView = NO;
                [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
                    self.allowShowLoginView = YES;
                }];
            }
            return;
        }

        CGFloat proportion = 0;
        CGFloat contentCollectionViewWidth = self.contentCollectionView.frame.size.width;
        if (contentCollectionViewWidth > 0) {
            proportion = offsetX / contentCollectionViewWidth;
        }
        self.stickerSwitchTabView.proportion = proportion;
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.contentCollectionView) {
        AWEModernStickerContentCollectionViewCell *collectionViewCell = (AWEModernStickerContentCollectionViewCell *)cell;
        if (indexPath.row == 0 && [collectionViewCell.collectionView numberOfSections] > 0) {
            NSString *emptyLabel = [collectionViewCell.collectionView numberOfItemsInSection:0] > 0 ? nil : ACCLocalizedCurrentString(@"com_mig_you_can_now_add_stickers_to_favorites_to_use_or_find_them_later");
            [collectionViewCell configWithEmptyString:emptyLabel];
        }
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == self.contentCollectionView) {
        self.stickerSwitchTabView.shouldIgnoreAnimation = NO;
        _contentCollectionViewIsScrolling = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self.contentCollectionView) {
        _contentCollectionViewIsScrolling = NO;
        NSInteger wouldSelectIndex = scrollView.contentOffset.x / self.contentCollectionView.frame.size.width;
        if (self.stickerSwitchTabView.selectedIndex != wouldSelectIndex) {
            [self.stickerSwitchTabView selectItemAtIndex:scrollView.contentOffset.x / self.contentCollectionView.frame.size.width animated:YES];
        }
    }
}

- (void)switchTabDidSelectedAtIndex:(NSInteger)index
{
    if ([self.delegate respondsToSelector:@selector(modernStickerSwitchTabViewDidSelectedAtIndex:)]) {
        [self.delegate modernStickerSwitchTabViewDidSelectedAtIndex:index];
    }
    if (index < 0 || index >= [self.contentCollectionView numberOfItemsInSection:0]) {
        return;
    }

    // bugfix: 无障碍打开以及切换到其他Tab时，道具的选择状态不正确
    if (UIAccessibilityIsVoiceOverRunning()) {
        [self.contentCollectionView reloadData];
        [self.contentCollectionView layoutIfNeeded];
    }

    [self.contentCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (BOOL)switchTabWillSelectedAtIndex:(NSInteger)index {
    if ([self.delegate conformsToProtocol:@protocol(AWEModernStickerCollectionViewCoordinatorDelegate)] &&
        [self.delegate respondsToSelector:@selector(modernStickerSwitchTabViewWillSeletedAtIndex:)]) {
        return [self.delegate modernStickerSwitchTabViewWillSeletedAtIndex:index];
    }
    return NO;
}

- (void)switchTab:(AWEModernStickerSwitchTabView *)switchTab didTapToChangeTabAtIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(modernStickerSwitchTabViewDidTapToChangeTabAtIndex:)]) {
        [self.delegate modernStickerSwitchTabViewDidTapToChangeTabAtIndex:index];
    }
}

- (AWEVideoPublishViewModel *)switchTabPublishModel
{
    return [self.delegate modernStickerSwitchTabViewPublishModel];
}

- (void)scrollContentCollectionViewToItemWithoutAnimation:(NSIndexPath *)indexPath {
    if (indexPath.row < 0 || indexPath.row >= [self.contentCollectionView numberOfItemsInSection:0]) {
        return;
    }
    [self.contentCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    _contentCollectionViewIsScrolling = NO;
}

@end
