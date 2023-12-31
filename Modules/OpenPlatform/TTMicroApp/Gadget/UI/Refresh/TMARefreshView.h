//
//  TMARefreshView.h
//  Timor
//
//  Created by CsoWhy on 2018/7/24.
//

#import <UIKit/UIKit.h>

#define kTMAPullRefreshHeight 58
#define KTMASecondsNeedScrollToLoading 0.4

typedef enum {
    TMAPULL_REFRESH_STATE_INIT,
    TMAPULL_REFRESH_STATE_PULL,
    TMAPULL_REFRESH_STATE_LOADING,
} TMAPullState;


@class TMARefreshView;

@protocol TMARefreshAnimationDelegate <NSObject>

- (void)startLoading;
- (void)updateAnimationWithScrollOffset:(CGFloat)offset;
- (void)updateViewWithPullState:(TMAPullState)state;
- (void)stopLoading;
- (void)configurePullRefreshLoadingHeight:(CGFloat)pullRefreshLoadingHeight;

@optional

- (void)animationWithScrollViewBackToLoading;
- (void)completionWithScrollViewBackToLoading;

@end

@interface TMARefreshView : UIView

@property (nonatomic) BOOL enabled;
@property (nonatomic, assign) TMAPullState state;
@property (nonatomic, assign) NSInteger lastTime;
@property (nonatomic, copy) dispatch_block_t actionHandler;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isObserving;
@property (nonatomic, assign) BOOL isObservingContentInset;
@property (nonatomic, assign) BOOL isUserPullAndRefresh;
@property (nonatomic) CGFloat pullRefreshLoadingHeight;
@property (nonatomic, assign) CGFloat secondsNeedScrollToLoading;

- (void)startObserve;
- (void)removeObserve:(UIScrollView *)scrollView;

- (void)showAnimationView;
- (void)stopAnimation:(BOOL)success;

- (void)triggerRefresh;
- (void)triggerRefreshAndHideAnimationView;

- (void)reConfigureWithRefreshAnimateView:(UIView<TMARefreshAnimationDelegate> *)refreshAnimateView WithConfigureSuccessCompletion:(void (^)(BOOL isSuccess))completion;

@end
