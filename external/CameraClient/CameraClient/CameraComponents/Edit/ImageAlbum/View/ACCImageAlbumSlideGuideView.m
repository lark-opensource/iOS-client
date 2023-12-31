//
//  ACCImageAlbumSlideGuideView.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/4/15.
//

#import "ACCImageAlbumSlideGuideView.h"

#import <CreativeKit/ACCResourceHeaders.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>
#import <Masonry/View+MASAdditions.h>

static const NSInteger kACCImageAlbumLottieAnimationTimes = 3;

@interface ACCImageAlbumSlideGuideView ()

@property (nonatomic, strong) LOTAnimationView *lottieView;
@property (nonatomic, strong) UILabel *hintLabel;

@end

@implementation ACCImageAlbumSlideGuideView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = ACCResourceColor(ACCColorSDTertiary);
        
        [self addSubview:self.lottieView];
        [self addSubview:self.hintLabel];
        
        ACCMasMaker(self.lottieView, {
            make.center.equalTo(self);
            make.size.equalTo(@(CGSizeMake(80, 58)));
        });
        
        ACCMasMaker(self.hintLabel, {
            make.centerX.equalTo(self);
            make.top.equalTo(self.lottieView.mas_bottom).offset(8);
            make.height.equalTo(@24);
        });
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)p_dismissWithCallback:(BOOL)needCallback
{
    [self removeFromSuperview];
    if (needCallback) {
        ACCBLOCK_INVOKE(self.didDisappearBlock);
    }
}

#pragma mark - Override

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    [self p_dismissWithCallback:YES]; // 有交互后被移除，但是本身不响应手势事件
    return [super hitTest:point withEvent:event];
}

#pragma mark - Notifications

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self p_dismissWithCallback:NO];
}

#pragma mark - Getters

- (LOTAnimationView *)lottieView
{
    if (!_lottieView) {
        [self p_setupLottieView];
    }
    return _lottieView;
}

- (void)p_setupLottieView
{
    if (_lottieView) {
        [_lottieView removeFromSuperview];
        _lottieView = nil;
    }
    
    _lottieView = [LOTAnimationView animationWithFilePath:ACCResourceFile(@"left_slide_guide.json")];
    
    static NSInteger loopTimes = 0;
    __weak typeof(self) weakSelf = self;
    _lottieView.completionBlock = ^(BOOL animationFinished) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        loopTimes++;
        if (loopTimes >= kACCImageAlbumLottieAnimationTimes) {
            [strongSelf p_dismissWithCallback:YES];
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [strongSelf p_setupLottieView];
            });
        }
    };
    
    [_lottieView play];
    
    if (!_lottieView.superview) {
        [self addSubview:_lottieView];
    }
    
    ACCMasMaker(_lottieView, {
        make.center.equalTo(self);
        make.size.equalTo(@(CGSizeMake(80, 58)));
    });
    
    ACCMasReMaker(self.hintLabel, {
        make.centerX.equalTo(self);
        make.top.equalTo(_lottieView.mas_bottom).offset(8);
        make.height.equalTo(@24);
    });
}

- (UILabel *)hintLabel
{
    if (!_hintLabel) {
        _hintLabel = [[UILabel alloc] init];
        _hintLabel.text = @"左滑查看下一张图片";
        _hintLabel.font = [ACCFont() systemFontOfSize:17 weight:ACCFontWeightMedium];
        _hintLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _hintLabel.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
        _hintLabel.layer.shadowOffset = CGSizeMake(1, 1);
        _hintLabel.layer.shadowOpacity = 1.f;
    }
    return _hintLabel;
}

@end
