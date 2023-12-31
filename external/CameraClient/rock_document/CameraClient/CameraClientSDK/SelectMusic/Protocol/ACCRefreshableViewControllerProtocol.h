//
//  ACCRefreshableViewControllerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/5/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MJRefreshHeader, MJRefreshFooter;

@protocol AWEStudioMusicModelProtocol, ACCListDataControllerProtocol;

@protocol ACCRefreshableViewControllerProtocol <NSObject>

- (void)configScrollViewHeader:(MJRefreshHeader *)header footer:(MJRefreshFooter *)footer infiniteScrollingAction:(dispatch_block_t)infiniteScrollingAction;
- (void)beginRefreshing;
- (void)endLoadingAndRefreshingWithMoreData:(BOOL)hasMore;
- (void)reloadWithModelArray:(NSArray *)modelArray;
- (void)appendWithModelArray:(NSArray *)modelArray;

@optional

@property (nonatomic, strong) NSObject<ACCListDataControllerProtocol> * dataController;

@end

NS_ASSUME_NONNULL_END
