//
//  BDXPagerSmoothView.h
//  BDXPagerViewExample-OC
//
//  Created by jiaxin on 2019/11/15.
//  Copyright © 2019 jiaxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BDXPagerSmoothView;

@protocol BDXPagerSmoothViewListViewDelegate <NSObject>

- (UIView *)listView;

- (UIScrollView *)listScrollView;

@optional
- (void)listDidAppear;
- (void)listDidDisappear;

@end

@protocol BDXPagerSmoothViewDataSource <NSObject>


- (CGFloat)heightForPagerHeaderInPagerView:(BDXPagerSmoothView *)pagerView;


- (UIView *)viewForPagerHeaderInPagerView:(BDXPagerSmoothView *)pagerView;


- (CGFloat)heightForPinHeaderInPagerView:(BDXPagerSmoothView *)pagerView;


- (UIView *)viewForPinHeaderInPagerView:(BDXPagerSmoothView *)pagerView;


- (NSInteger)numberOfListsInPagerView:(BDXPagerSmoothView *)pagerView;


- (id<BDXPagerSmoothViewListViewDelegate>)pagerView:(BDXPagerSmoothView *)pagerView initListAtIndex:(NSInteger)index;

@end

@protocol BDXPagerSmoothViewDelegate <NSObject>
- (void)pagerSmoothViewDidScroll:(UIScrollView *)scrollView;
@end

@interface BDXPagerSmoothView : UIView


@property (nonatomic, strong, readonly) NSDictionary <NSNumber *, id<BDXPagerSmoothViewListViewDelegate>> *listDict;
@property (nonatomic, strong, readonly) UICollectionView *listCollectionView;
@property (nonatomic, assign) NSInteger defaultSelectedIndex;
@property (nonatomic, weak) id<BDXPagerSmoothViewDelegate> delegate;

- (instancetype)initWithDataSource:(id<BDXPagerSmoothViewDataSource>)dataSource NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (void)reloadData;

@end

