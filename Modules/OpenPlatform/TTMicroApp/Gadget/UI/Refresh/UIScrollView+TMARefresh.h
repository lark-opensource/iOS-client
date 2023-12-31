//
//  UIScrollView+TMARefresh.h
//  Timor
//
//  Created by CsoWhy on 2018/7/24.
//

#import <UIKit/UIKit.h>
#import "TMARefreshView.h"

@interface UIScrollView (TMARefresh)

@property (nonatomic, strong) TMARefreshView *tmaRefreshView;
@property (nonatomic, assign) BOOL needPullRefresh;
@property (nonatomic, assign) UIEdgeInsets originContentInset;
@property (nonatomic, assign) CGFloat customTopOffset;
@property (nonatomic, assign) CGFloat tmaRefreshViewTopInset;

- (void)addPullDownWithActionHandler:(dispatch_block_t)actionHandler;

- (void)tmaTriggerPullDown;
- (void)tmaFinishPullDownWithSuccess:(BOOL)success;
- (void)tmaTriggerPullDownAndHideAnimationView;
- (void)tmaPullView:(UIView *)view stateChange:(TMAPullState)state;

@end

