//
//  BDXCategoryCollectionView.h

//
//  Created by jiaxin on 2018/3/21.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDXCategoryIndicatorProtocol.h"
@class BDXCategoryCollectionView;

@protocol BDXCategoryCollectionViewGestureDelegate <NSObject>
@optional
- (BOOL)categoryCollectionView:(BDXCategoryCollectionView *)collectionView gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;
- (BOOL)categoryCollectionView:(BDXCategoryCollectionView *)collectionView gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
@end

@interface BDXCategoryCollectionView : UICollectionView

@property (nonatomic, strong) NSArray <UIView<BDXCategoryIndicatorProtocol> *> *indicators;
@property (nonatomic, weak) id<BDXCategoryCollectionViewGestureDelegate> gestureDelegate;

@end
