//
//  MinutesScrollView.h
//  Minutes
//
//  Created by chenlehui on 2021/12/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MinutesScrollView : UIScrollView

@property(nullable, nonatomic, copy) BOOL (^contentOffsetChanging)(UIScrollView*, CGPoint, CGPoint);
@property(nullable, nonatomic, weak) UIScrollView* innerScrollView;

@end

NS_ASSUME_NONNULL_END
