//
//  ACCLoadMoreFooter.h
//  Pods
//
//  Created by chengfei xiao on 2019/11/26.
//

#import <MJRefresh/MJRefreshBackFooter.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCLoadMoreFooter : MJRefreshBackFooter

@property (nonatomic, assign) BOOL showNoMoreDataText;
@property (nonatomic, copy) NSString *noMoreDataString;

- (void)setLoadMoreLabelTextColor:(UIColor *)textColor;
- (void)setLoadingViewBackgroundColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
