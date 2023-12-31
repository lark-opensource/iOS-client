//
//  ACCLoadMoreFooter.m
//  Pods
//
//  Created by chengfei xiao on 2019/11/26.
//

#import "ACCLoadMoreFooter.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import "ACCLoadingViewProtocol.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCLoadMoreFooter ()

@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *loadingView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, assign) BOOL isFirstAppear;

@end


@implementation ACCLoadMoreFooter

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _addObservers];
        self.showNoMoreDataText = YES;
    }
    return self;
}

- (void)dealloc {
    [self _removeObservers];
}

- (void)prepare
{
    [super prepare];
    
    self.mj_h = 60;
    self.isFirstAppear = YES;
    
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.automaticallyHidden = YES;
//#pragma clang diagnostic pop
    
    [self addSubview:self.loadingView];
    [self addSubview:self.label];
}

- (void)placeSubviews
{
    [super placeSubviews];

    self.label.frame = CGRectInset(self.bounds, 15, 0);
    self.loadingView.center = CGPointMake(self.mj_w * 0.5, self.mj_h * 0.5);
}

- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState

    NSString *refreshText = nil;
    switch (state) {
        case MJRefreshStateIdle:
            refreshText = ACCLocalizedString(@"pull_up_load_more", nil);
            break;
        case MJRefreshStatePulling:
            refreshText = ACCLocalizedString(@"pull_up_load_more", nil);
            break;
        case MJRefreshStateNoMoreData:
            refreshText = ACCLocalizedString(@"com_mig_youve_reached_the_end_fgzcr6", nil);
            if (!ACC_isEmptyString(self.noMoreDataString)) {
                refreshText = self.noMoreDataString;
            }
            break;
        default:
            break;
    }
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
        refreshText = @" ";
    }
    if (ACC_isEmptyString(refreshText)) {
        self.label.hidden = YES;
        [self _startLoadingAnim];
    } else {
        self.label.hidden = NO;
        self.label.text = refreshText;
        [self _stopLoadingAnim];
    }
    
    if (state == MJRefreshStateNoMoreData && !self.showNoMoreDataText) {
        self.label.hidden = YES;
    }
}

- (void)scrollViewContentSizeDidChange:(NSDictionary *)change
{
    [super scrollViewContentSizeDidChange:change];
    
    // Set position and size
    self.mj_y = self.scrollView.mj_contentH;
}

- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change
{
    [super scrollViewContentOffsetDidChange:change];
    
    // You can only start from the pulling state
    if (self.state != MJRefreshStatePulling) {
        return;
    }
    
    // 1) touch is over
    if (!self.scrollView.isTracking) {
        if (self.scrollViewContentHeightBiggerThanFrameHeight) {
            if (self.scrollViewDidReachBottom) {
                // 2.1) Scrollview content has more than one frame and has reached the bottom
                [self beginRefreshing];
            }
        } else {
            if (self.scrollViewDidScrollUp) {
                // 2.2) Scrollview content is less than a frame and is pulled up
                [self beginRefreshing];
            }
        }
    }
}

/* whether the scrollView reaches the bottom at all */
- (BOOL)scrollViewDidReachBottom
{
    return ACC_FLOAT_GREATER_THAN(self.scrollView.mj_offsetY + self.scrollView.mj_h,
                              self.scrollView.mj_contentH + self.scrollView.mj_insetB);
}

- (BOOL)scrollViewDidScrollUp
{
    return ACC_FLOAT_GREATER_THAN(self.scrollView.mj_offsetY,
                              -self.scrollView.mj_insetT);
}

/* Is the scrollable height of the scrollView greater than frame.height */
- (BOOL)scrollViewContentHeightBiggerThanFrameHeight
{
    return ACC_FLOAT_GREATER_THAN(self.scrollView.mj_insetT + self.scrollView.mj_contentH + self.scrollView.mj_insetB,
                              self.scrollView.mj_h);
}

- (void)_startLoadingAnim {
    self.loadingView.hidden = NO;
    [self.loadingView startAnimating];
}

- (void)_stopLoadingAnim {
    self.loadingView.hidden = YES;
    [self.loadingView stopAnimating];
}

- (UIView<ACCLoadingViewProtocol> *)loadingView {
    if (!_loadingView) {
        _loadingView = [ACCLoading() loadingView];
    }
    return _loadingView;
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.font = ACCStandardFont(ACCFontClassP2, ACCFontWeightRegular);
        _label.textColor = ACCResourceColor(ACCUIColorTextTertiary);
        _label.textAlignment = NSTextAlignmentCenter;
        _label.numberOfLines = 0;
    }
    return _label;
}

- (void)setLoadMoreLabelTextColor:(UIColor *)textColor
{
    self.label.textColor = textColor;
}

- (void)setLoadingViewBackgroundColor:(UIColor *)color
{
    self.loadingView.backgroundColor = color;
}

- (void)_addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)_removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)applicationWillEnterForeground:(NSNotification *)noti {
    if (self.state == MJRefreshStateRefreshing) {
        [self _startLoadingAnim];
    }
}

@end
