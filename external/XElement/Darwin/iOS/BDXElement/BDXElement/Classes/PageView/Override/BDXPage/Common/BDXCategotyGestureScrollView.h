//
//  BDXCategotyGestureScrollView.h
//  BDXElement
//
//  Created by hanzheng on 2021/2/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDXCategotyGestureScrollViewDirection) {
  BDXCategotyGestureScrollViewDirection_Default = 0,
  BDXCategotyGestureScrollViewDirection_Left,
  BDXCategotyGestureScrollViewDirection_Right,
  BDXCategotyGestureScrollViewDirection_Auto
};

@interface BDXCategotyGestureScrollView : UIScrollView<UIGestureRecognizerDelegate>
@end

@interface BDXCategotyGestureCollectionView : UICollectionView<UIGestureRecognizerDelegate>

@property (nonatomic, assign) BOOL horizonScrollEnable;
@property (nonatomic, assign) BDXCategotyGestureScrollViewDirection direction;
@property (nonatomic, weak) UIView *lynxView;
@property (nonatomic, assign) CGFloat gestureBeginOffset;

@end


NS_ASSUME_NONNULL_END
