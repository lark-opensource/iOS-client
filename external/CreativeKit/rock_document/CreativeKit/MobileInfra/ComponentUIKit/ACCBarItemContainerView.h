//
//  ACCBarItemContainerView.h
//  CameraClient
//
//  Created by Liu Deping on 2020/3/16.
//

#import <Foundation/Foundation.h>
#import "ACCBarItem.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IESServiceProvider;
@protocol ACCBarItemContainerView;

@protocol ACCBarItemSortDataSource <NSObject>

- (NSArray *)barItemSortArray;

@end

@protocol ACCBarItemContainerViewDelegate <NSObject>

- (void)barItemContainer:(id<ACCBarItemContainerView>)barItemContainer
       didClickedBarItem:(void *)itemId;

@end

@protocol ACCBarItemContainerView <NSObject>

- (BOOL)addBarItem:(ACCBarItem *)item;

- (void)removeBarItem:(void *)itemId;

- (void)containerViewDidLoad;

- (ACCBarItem *)barItemWithItemId:(void *)itemId;

- (UIView *)barItemContentView;

- (void)updateBarItemWithItemId:(void *)itemId;

- (void)updateAllBarItems;

- (NSArray<ACCBarItem *> *)barItems;

@property (nonatomic, strong) id<ACCBarItemSortDataSource> sortDataSource;
@property (nonatomic, strong) id<ACCBarItemContainerViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
