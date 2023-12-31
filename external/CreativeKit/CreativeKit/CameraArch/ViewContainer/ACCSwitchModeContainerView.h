//
//  ACCSwitchModeItemContainerView.h
//  CameraClient
//
//  Created by liyingpeng on 2020/5/14.
//

#import <Foundation/Foundation.h>
#import "ACCSwitchModeContainerCollectionView.h"

NS_ASSUME_NONNULL_BEGIN

@class AWESwitchModeSingleTabConfig;

@protocol ACCSwitchModeContainerViewDelegate <NSObject>

- (void)didSelectItemAtIndex:(NSInteger)index;

@optional
- (void)willDisplayItemAtIndex:(NSInteger)index;
- (BOOL)forbidScrollChangeMode;

@end

@protocol ACCSwitchModeContainerViewDataSource <NSObject>

@property (nonatomic, copy, nullable) NSArray<AWESwitchModeSingleTabConfig *> *tabConfigArray;

@end

@protocol ACCSwitchModeContainerView <NSObject>

@property (nonatomic, weak) id<ACCSwitchModeContainerViewDelegate> delegate;
@property (nonatomic, weak) id<ACCSwitchModeContainerViewDataSource> dataSource;

@property (nonatomic, assign, getter=isPanned) BOOL panned;
@property (nonatomic, assign) BOOL forbidScroll;
@property (nonatomic, assign, readonly) NSInteger selectedIndex;
@property (nonatomic, strong) UICollectionView<ACCSwitchModeContainerCollectionView> *collectionView;
@property (nonatomic, strong) UIView *cursorView;

- (void)reloadData;
- (void)updateTabConfigForModeId:(NSInteger)modeId;
- (void)setDefaultItemAtIndex:(NSInteger)index;
- (void)selectItemAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)refreshColorWithUIStyle:(BOOL)blackStyle animated:(BOOL)animated;
- (void)addGradientMask;

@end

NS_ASSUME_NONNULL_END
