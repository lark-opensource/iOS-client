//
//  EMALoadingView.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/3.
//

#import "EMALoadingView.h"
#import <TTMicroApp/BDPLoadingAnimationView.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UIImage+EMA.h>
#import <OPFoundation/EMADebugUtil.h>
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/UIFont+EMA.h>
#import "EMAAppEngine.h"
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <TTMicroApp/BDPTaskManager.h>
#import <TTMicroApp/BDPTimorClient+Business.h>
#import <OPFoundation/UIImage+EMA.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

@interface EMALoadingView ()

@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UILabel *titleView;
@property (nonatomic, strong) BDPLoadingAnimationView *loadingView;
@property (nonatomic, strong) BDPUniqueID *uniqueID;

@end

@implementation EMALoadingView

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

    UIWindow *window = self.window;
    if (self.bdp_width > 0 && self.bdp_height > 0 && window) {

        UINavigationController *nav = [OPNavigatorHelper topmostNavWithSearchSubViews:NO window:window];
        CGFloat navbarHeight = nav.navigationBar.bdp_height ?: 44;

        // if里的为原逻辑不变，为了适配ipad，将布局部分拿出来，layoutsubviews时进行刷新
        if (!self.loadingView) {
            self.logoView.image = self.logoView.image ?: [UIImage ema_imageNamed:@"mp_app_icon_default"];
            self.logoView.bdp_size = CGSizeMake(42, 42);
            self.logoView.contentMode = UIViewContentModeScaleAspectFit;
            self.logoView.layer.cornerRadius = 8;
            self.logoView.layer.masksToBounds = YES;
            [self addSubview:self.logoView];

            self.titleView.numberOfLines = 1;
            self.titleView.textAlignment = NSTextAlignmentCenter;
            self.titleView.font = [UIFont ema_title17];
            self.titleView.textColor = UDOCColor.textTitle;
            if (BDPIsEmptyString(self.titleView.text)) {
                self.titleView.text = @"  ";    // 占位计算高度
            }
            [self addSubview:self.titleView];

            self.loadingView = [[BDPLoadingAnimationView alloc] initWithFrame:CGRectZero];
            [self addSubview:self.loadingView];
            [self.loadingView startLoading];
        }
        self.logoView.bdp_centerX = self.bdp_width / 2;
        self.logoView.bdp_top = UIApplication.sharedApplication.statusBarFrame.size.height + navbarHeight + 10;
        self.titleView.bdp_width = self.bdp_width;
        self.titleView.bdp_height = MAX([self.titleView sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].height, 17);
        self.titleView.bdp_top = self.logoView.bdp_bottom + 8;
        self.loadingView.frame = CGRectMake(0, self.bdp_height / 2 - 3.0f, self.bdp_width, 6.0f);
        self.loadingView.bdp_top = self.titleView.bdp_bottom + 20.f;
    }
}

- (void)updateLoadingViewWithModel:(BDPModel *)appModel {
    self.uniqueID = appModel.uniqueID;
    [BDPNetworking setImageView:self.logoView url:[NSURL URLWithString:appModel.icon] placeholder:[UIImage ema_imageNamed:@"mp_app_icon_default"]];
    self.titleView.text = appModel.name;
}

//- (CAAnimation *)newHideAnimationWithDuration:(NSTimeInterval)duration {
//    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
//    animation.fromValue = @1;
//    animation.toValue = @0;
//    animation.duration = duration;
//    animation.repeatCount = 0;
//    animation.fillMode = kCAFillModeBoth;
//    animation.removedOnCompletion = NO;
//    return animation;
//}

- (void)hideLoadingView {
//    NSTimeInterval duration = [EMAAppEngine.currentEngine.onlineConfig loadingDismissScaleAnimationDurationForUniqueID:self.uniqueID];
//    if (duration > 0) {
//        [self.logoView.layer addAnimation:[self newHideAnimationWithDuration:duration] forKey:nil];
//        [self.titleView.layer addAnimation:[self newHideAnimationWithDuration:duration] forKey:nil];
//        [self.loadingView.layer addAnimation:[self newHideAnimationWithDuration:duration] forKey:nil];
//    }
}

- (void)changeToFailState:(int)state withTipInfo:(NSString *)tipInfo {
    if (BDPTimorClient.sharedClient.appearanceConfg.hideAppWhenLaunchError) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UDToastForOC showTipsWith:tipInfo on:self.window];
        });
    } else {
        self.hidden = YES;
    }
}

@end
