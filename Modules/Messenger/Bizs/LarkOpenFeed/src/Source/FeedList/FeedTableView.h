//
//  FeedTableView.h
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FeedTableView : UITableView

@property(nullable, nonatomic, copy) BOOL (^contentOffsetChanging)(UIScrollView*, CGPoint, CGPoint);
@property(nullable, nonatomic, weak) UIScrollView* outerScrollView;

@end


NS_ASSUME_NONNULL_END
