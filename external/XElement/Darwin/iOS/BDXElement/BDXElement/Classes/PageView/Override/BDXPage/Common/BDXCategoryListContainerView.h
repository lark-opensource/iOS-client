//
//  BDXCategoryListScrollView.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/9/12.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDXCategoryViewDefines.h"
#import "BDXCategoryBaseView.h"
@class BDXCategoryListContainerView;


typedef NS_ENUM(NSUInteger, BDXCategoryListContainerType) {
    BDXCategoryListContainerType_ScrollView,
    BDXCategoryListContainerType_CollectionView,
};

@protocol BDXCategoryListContentViewDelegate <NSObject>


- (UIView *)listView;
- (UIScrollView *)listScrollView;

@optional


- (void)listWillAppear;

- (void)listDidAppear;

- (void)listWillDisappear;

- (void)listDidDisappear;

@end

@protocol BDXCategoryListContainerViewDelegate <NSObject>

- (NSInteger)numberOfListsInlistContainerView:(BDXCategoryListContainerView *)listContainerView;

- (id<BDXCategoryListContentViewDelegate>)listContainerView:(BDXCategoryListContainerView *)listContainerView initListForIndex:(NSInteger)index;

@optional

- (Class)scrollViewClassInlistContainerView:(BDXCategoryListContainerView *)listContainerView;

- (BOOL)listContainerView:(BDXCategoryListContainerView *)listContainerView canInitListAtIndex:(NSInteger)index;

- (void)listContainerViewDidScroll:(UIScrollView *)scrollView;

@end


@interface BDXCategoryListContainerView : UIView <BDXCategoryViewListContainer>

@property (nonatomic, assign, readonly) BDXCategoryListContainerType containerType;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) NSDictionary <NSNumber *, id<BDXCategoryListContentViewDelegate>> *validListDict;

@property (nonatomic, assign) CGFloat initListPercent;
@property (nonatomic, assign) BOOL bounces; 

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithType:(BDXCategoryListContainerType)type delegate:(id<BDXCategoryListContainerViewDelegate>)delegate NS_DESIGNATED_INITIALIZER;

@end

