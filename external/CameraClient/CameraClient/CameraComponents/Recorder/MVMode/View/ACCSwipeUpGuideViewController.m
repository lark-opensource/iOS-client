//
//  ACCSwipeUpGuideViewController.m
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/7/7.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCSwipeUpGuideViewController.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreativeKit/NSNumber+CameraClientResource.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>
#import <Masonry/View+MASAdditions.h>

static NSString *kACCMVSwipeUpGuideFontName = @"acc.mv.swipeup.guide.font.name";
static NSString *kACCMVSwipeUpGuideFontSize = @"acc.mv.swipeup.guide.font.size";

@interface ACCSwipeUpGuideViewController ()<UIScrollViewDelegate>

@property (nonatomic, strong, readwrite) UILabel *mainLabel;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) CGPoint originOffSet;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) LOTAnimationView *imageView;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) BOOL isPresentCompleted;
@property (nonatomic, assign) BOOL hasFinishedSwipeUp;

@end

@implementation ACCSwipeUpGuideViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self registerNotifications];
}

- (void)registerNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(p_appDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)setupUI
{
    self.view.backgroundColor = ACCResourceColor(ACCColorSDSecondary);
    self.view.userInteractionEnabled = YES;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.bounces = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    if (@available(iOS 11, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
    
    UIView *container = [[UIView alloc] init];
    [self.scrollView addSubview:container];
    ACCMasMaker(container, {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    });
    
    UIView *contentView = [[UIView alloc] init];
    [container addSubview:contentView];
    ACCMasMaker(contentView, {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view);
        make.height.mas_equalTo(@295);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
    });
    
    self.imageView = [LOTAnimationView animationWithFilePath:ACCResourceFile(@"hand_swip_lottie_ios.json")];
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [contentView addSubview:self.imageView];
    ACCMasMaker(self.imageView, {
        make.centerX.equalTo(contentView);
        make.left.right.equalTo(contentView);
        make.top.equalTo(contentView);
        make.height.mas_equalTo(@210);
    });
    self.imageView.loopAnimation = YES;
    self.imageView.userInteractionEnabled = YES;
    
    self.mainLabel = [[UILabel alloc] init];
    self.mainLabel.text = ACCLocalizedCurrentString(@"creation_mv_slide_hint");
    self.mainLabel.font = [UIFont fontWithName:[NSString acc_strValueWithName:kACCMVSwipeUpGuideFontName] size:ACCIntConfig(kACCMVSwipeUpGuideFontSize)];
    self.mainLabel.textAlignment = NSTextAlignmentCenter;
    self.mainLabel.textColor =  ACCResourceColor(ACCUIColorConstTextInverse);
    self.mainLabel.numberOfLines = 2;
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    [contentView addSubview:self.mainLabel];
    ACCMasMaker(self.mainLabel, {
        make.top.equalTo(self.imageView.mas_bottom).offset(20);
        make.left.equalTo(contentView).offset(20);
        make.right.equalTo(contentView).offset(-20);
        make.bottom.equalTo(contentView.mas_bottom);
    });
    
    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = [UIColor clearColor];
    [container addSubview:overlay];
    ACCMasMaker(overlay, {
        make.edges.equalTo(container);
        make.height.equalTo(self.scrollView).multipliedBy(2);
    });
}

- (void)showSwipeUpGuideOnTableView:(UITableView *)tableView
{
    [self showSwipeUpGuideOnTableView:tableView containerView:nil];
}

- (void)showSwipeUpGuideOnTableView:(UITableView *)tableView containerView:(nullable UIView *)view
{
    UIView *containerView = view;
    if (containerView == nil) {
        containerView = [UIApplication sharedApplication].keyWindow;
    }
    [containerView addSubview:self.view];
    self.scrollView.frame = tableView.frame;
    self.originOffSet = tableView.contentOffset;
    self.tableView = tableView;
    self.view.alpha = 0.0f;
    self.isPresentCompleted = NO;
    
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:0.3 animations:^{
        self.view.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [self.imageView play];
    }];
}

- (void)dismissSwipeUpGuide
{
    self.scrollView.delegate = nil;
    [UIView animateWithDuration:0.3 animations:^{
        self.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        self.tableView = nil;
    }];
}

- (void)dismissWithGestureByScrollView:(UIScrollView *)scrollView
{
    if (self.lastContentOffset < scrollView.contentOffset.y) {
        [self dismissSwipeUpGuide];
    } else {
        if (self.isPresentCompleted) {
            [self dismissSwipeUpGuide];
        }
    }
}

#pragma mark - Notification
- (void)p_appDidBecomeActive
{
    if (self.imageView) {
        [self.imageView play];
    }
}

#pragma mark - UIScrollview delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.tableView.contentOffset = CGPointMake(0, self.originOffSet.y + scrollView.contentOffset.y);
    if ([self.tableView.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.tableView.delegate scrollViewDidScroll:self.tableView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.tableView.delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [self.tableView.delegate scrollViewWillBeginDragging:self.tableView];
    }
    self.lastContentOffset = scrollView.contentOffset.y;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.tableView.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.tableView.delegate scrollViewDidEndDecelerating:self.tableView];
    }
    [self dismissWithGestureByScrollView:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self.tableView.delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.tableView.delegate scrollViewDidEndDragging:self.tableView willDecelerate:decelerate];
    }
    if (!decelerate) {
        [self dismissWithGestureByScrollView:scrollView];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if ([self.tableView.delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [self.tableView.delegate scrollViewWillEndDragging:self.tableView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if ([self.tableView.delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [self.tableView.delegate scrollViewDidEndScrollingAnimation:self.tableView];
    }
}


@end
