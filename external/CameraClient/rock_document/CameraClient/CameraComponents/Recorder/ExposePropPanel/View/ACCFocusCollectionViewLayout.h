//
//  ACCFocusCollectionViewLayout.h
//  CameraClient
//
//  Created by Shen Chen on 2020/4/1.
//  Copyright © 2020 Shen Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCFocusCollectionViewLayout;
@protocol ACCFocusCollectionViewLayoutDelegate <NSObject>

@optional
- (CGFloat)layout:(ACCFocusCollectionViewLayout *)layout targetContentOffsetXForProposedContentOffsetX:(CGFloat)proposedContentOffsetX withScrollingVelocityX:(CGFloat)velocity;

@end

@interface ACCFocusCollectionViewLayout : UICollectionViewFlowLayout
@property (nonatomic, assign) CGSize normalCellSize;
@property (nonatomic, assign) CGSize centerCellSize;
@property (nonatomic, assign) CGFloat normalMargin;
@property (nonatomic, assign) CGFloat centerMargin;
@property (nonatomic, assign) CGFloat contentWidth;
@property (nonatomic, assign) BOOL enablePaging;
@property (nonatomic, assign) CGFloat resistance; // 1 by default
@property (nonatomic, assign) CGFloat bandWidth;
@property (nonatomic, weak) id<ACCFocusCollectionViewLayoutDelegate> delegate;
@property (nonatomic, assign) NSUInteger homeIndex;
- (CGFloat)currentCenterPosition;
- (NSInteger)indexOfCurrentCenteredItem;
- (CGFloat)contentOffsetForCenteredItemAtIndex:(NSInteger)index;
- (CGFloat)itemWidth;
@end

NS_ASSUME_NONNULL_END
