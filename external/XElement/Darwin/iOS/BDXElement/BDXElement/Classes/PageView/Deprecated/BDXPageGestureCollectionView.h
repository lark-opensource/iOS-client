//
//  BDXPageGestureCollectionView.h
//  BDXElement
//
//  Created by AKing on 2020/9/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXPageGestureCollectionView : UICollectionView<UIGestureRecognizerDelegate>
@property (nonatomic, assign) BOOL needReserveEdgeBack;
@end

NS_ASSUME_NONNULL_END
