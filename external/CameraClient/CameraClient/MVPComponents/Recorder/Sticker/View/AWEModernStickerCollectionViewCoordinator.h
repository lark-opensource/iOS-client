//
//  AWEModernStickerCollectionViewCoordinator.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/15.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWEModernStickerTitleCollectionView.h"
#import "AWEModernStickerContentCollectionView.h"
#import "AWEModernStickerSwitchTabView.h"
@class IESCategoryModel;

@protocol AWEModernStickerCollectionViewCoordinatorDelegate <NSObject>

- (AWEVideoPublishViewModel *)modernStickerSwitchTabViewPublishModel;

@optional
- (void)modernStickerSwitchTabViewDidSelectedAtIndex:(NSInteger)index;
/// 是否需要拦截将要点击的事件
- (BOOL)modernStickerSwitchTabViewWillSeletedAtIndex:(NSInteger)index;
- (void)modernStickerSwitchTabViewDidTapToChangeTabAtIndex:(NSInteger)index;
@end

@interface AWEModernStickerCollectionViewCoordinator : NSObject

@property (nonatomic, weak) id<AWEModernStickerCollectionViewCoordinatorDelegate> delegate;
@property (nonatomic, strong) AWEModernStickerSwitchTabView *stickerSwitchTabView;
@property (nonatomic, strong) AWEModernStickerContentCollectionView *contentCollectionView;
@property (nonatomic, readonly, assign) BOOL contentCollectionViewIsScrolling;

// animated为NO时不会走-scrollViewDidEndScrollingAnimation代理方法，无法重置contentCollectionViewIsScrolling，
// 希望调用此方法代替-scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;
- (void)scrollContentCollectionViewToItemWithoutAnimation:(NSIndexPath *)indexPath;

@end
