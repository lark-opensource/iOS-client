//
//  FeedScrollView.h
//  LarkFeed
//
//  Created by 夏汝震 on 2021/3/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FeedScrollView : UIScrollView

@property(nullable, nonatomic, copy) BOOL (^contentOffsetChanging)(UIScrollView*, CGPoint, CGPoint);
@property(nullable, nonatomic, weak) UIScrollView* innerScrollView;

@end

NS_ASSUME_NONNULL_END
