//
//  EMALoadingView.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/3.
//

#import "OPLoadingView.h"
#import "OPLoadingAnimationView.h"
#import <OPFoundation/OPFoundation.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <BDWebImage/UIImageView+BDWebImage.h>
#import <OPFoundation/OPAppUniqueID.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <UniverseDesignEmpty/UniverseDesignEmpty-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPSDK/OPSDK-Swift.h>

@interface OPLoadingView ()

@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UILabel *titleView;
@property (nonatomic, strong) OPLoadingAnimationView *loadingView;
@property (nonatomic, strong) OPAppUniqueID *uniqueID;
@property (nonatomic, assign, readwrite) int failState;

// 用于显示当前加载错误信息的emptyView
@property (nonatomic, strong) UDEmpty *emptyView;
// 用于加载出错时，显示在导航栏标题位置处的应用名称
@property (nonatomic, strong) UILabel *topTitleView;

@end

@implementation OPLoadingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UDOCColor.bgBody;
        self.titleView = [[UILabel alloc] init];
        self.logoView = [[OPThemeImageView alloc] init];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.op_width > 0 && self.op_height > 0) {

        UINavigationController *nav = [OPNavigatorHelper topmostNavWithSearchSubViews:NO window:[OPWindowHelper fincMainSceneWindow]];
        CGFloat navbarHeight = nav.navigationBar.op_height ?: 44;

        // if里的为原逻辑不变，为了适配ipad，将布局部分拿出来，layoutsubviews时进行刷新
        if (!self.loadingView) {
            self.logoView.image = self.logoView.image ?: [UIImage op_imageNamed:@"mp_app_icon_default"];
            self.logoView.op_size = CGSizeMake(48, 48);
            self.logoView.contentMode = UIViewContentModeScaleAspectFit;
            self.logoView.layer.masksToBounds = YES;
            [OPLoadingFigmaBridge setSmoothCornerWithInputView:self.logoView radius:12.f];
            [self addSubview:self.logoView];

            self.titleView.numberOfLines = 1;
            self.titleView.textAlignment = NSTextAlignmentCenter;
            self.titleView.font = [UIFont op_title17];
            self.titleView.textColor = UDOCColor.textTitle;
            if (OPIsEmptyString(self.titleView.text)) {
                self.titleView.text = @"  ";    // 占位计算高度
            }
            [self addSubview:self.titleView];

            self.loadingView = [[OPLoadingAnimationView alloc] initWithFrame:CGRectZero];
            [self addSubview:self.loadingView];
            [self.loadingView startLoading];
            
            if (self.emptyView && !self.emptyView.hidden) {
                self.loadingView.hidden = YES;
            }
        }
        self.logoView.op_centerX = self.op_width / 2;
        self.logoView.op_top = UIApplication.sharedApplication.statusBarFrame.size.height + navbarHeight + 40;
        self.titleView.op_width = self.op_width;
        self.titleView.op_height = MAX([self.titleView sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].height, 17);
        self.titleView.op_top = self.logoView.op_bottom + 11;
        self.loadingView.frame = CGRectMake(0, self.op_height / 2 - 3.0f, self.op_width, 6.0f);
        self.loadingView.op_top = self.titleView.op_bottom + 13.f;

        self.topTitleView.op_top = UIApplication.sharedApplication.statusBarFrame.size.height + (navbarHeight-self.topTitleView.op_height)/2;
        self.topTitleView.op_centerX = self.op_centerX;
        // 防止与BDPToolBarView重合
        self.topTitleView.op_width = self.op_width - 90 * 2;
    }
}

- (void)updateLoadingViewWithIconUrl:(NSString *)iconUrl appName:(NSString *)appName{
    dispatch_block_t mainTheadCaller = ^() {
        [self.logoView bd_setImageWithURL:[NSURL URLWithString:iconUrl] placeholder:[UIImage op_imageNamed:@"mp_app_icon_default"]];
        self.titleView.text = appName;
        self.topTitleView.text = appName;
        [self.topTitleView sizeToFit];
    };
    if (NSThread.isMainThread) {
        mainTheadCaller();
    }else{
        dispatch_async(dispatch_get_main_queue(), mainTheadCaller);
    }
}

- (CAAnimation *)newHideAnimationWithDuration:(NSTimeInterval)duration {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = @1;
    animation.toValue = @0;
    animation.duration = duration;
    animation.repeatCount = 0;
    animation.fillMode = kCAFillModeBoth;
    animation.removedOnCompletion = NO;
    return animation;
}

- (void)hideLoadingView {
//    NSTimeInterval duration = [EMAAppEngine.currentEngine.onlineConfig loadingDismissScaleAnimationDurationForUniqueIDModifiedType:self.uniqueID];
//    if (duration > 0) {
//        [self.logoView.layer addAnimation:[self newHideAnimationWithDuration:duration] forKey:nil];
//        [self.titleView.layer addAnimation:[self newHideAnimationWithDuration:duration] forKey:nil];
//        [self.loadingView.layer addAnimation:[self newHideAnimationWithDuration:duration] forKey:nil];
//    }
}

- (void)changeToFailState:(int)state withTipInfo:(NSString *)tipInfo {
    self.failState = state;
    UIWindow *window = self.uniqueID.window;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [EMAHUD showTips:tipInfo window:window];
    });
}

/// 将loadingView变换为显示为可恢复错误提示+重试按钮的样式
- (void)changeToFailRetryStateWith:(NSString * _Nonnull )tipInfo uniqueID:(OPAppUniqueID *)uniqueID {
    [self.emptyView removeFromSuperview];
    self.uniqueID = uniqueID;
    // 创建用于显示错误信息的emptyView
    WeakSelf;
    self.emptyView = [self createEmptyViewWithTipInfo:tipInfo retryBlock:^(UIButton * _Nonnull button) {
        StrongSelfIfNilReturn;
        // 重新加载容器
        id<OPContainerProtocol> container = [OPApplicationService.current getContainerWithUniuqeID: self.uniqueID];
        [container reloadWithMonitorCode:GDMonitorCode.about_restart];
        // 恢复原样
        self.loadingView.hidden = NO;
        [self.loadingView startLoading];
        self.titleView.hidden = NO;
        self.logoView.hidden = NO;
        self.topTitleView.hidden = YES;
        // 移除emptyView
        [self.emptyView removeFromSuperview];
        self.emptyView = nil;
    }];
    self.topTitleView.hidden = NO;

    // 隐藏无用的组件
    [self.loadingView stopLoading];
    self.loadingView.hidden = YES;
    self.titleView.hidden = YES;
    self.logoView.hidden = YES;
}

/// 懒加载getter
- (UILabel *)topTitleView {
    if (!_topTitleView) {
        _topTitleView = [[UILabel alloc] init];
        _topTitleView.font = [UIFont systemFontOfSize:16];
        _topTitleView.hidden = YES;
        _topTitleView.textAlignment = NSTextAlignmentCenter;
        _topTitleView.textColor = UDOCColor.textTitle;
        [self addSubview:_topTitleView];
    }
    return _topTitleView;
}

- (void)stopAnimation {
    if (self.loadingView) {
        [self.loadingView stopLoading];
    }
}

- (void)bindUniqueID:(OPAppUniqueID *)uniqueID {
    self.uniqueID = uniqueID;
}

- (void)changeToEmptyView:(UDEmpty *)emptyView {
    self.emptyView = emptyView;
}
@end
