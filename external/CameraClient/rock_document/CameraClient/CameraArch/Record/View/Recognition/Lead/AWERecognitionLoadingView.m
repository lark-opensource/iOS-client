//
//  AWERecognitionLoadingView.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/2.
//

#import "AWERecognitionLoadingView.h"
#import <lottie-ios/Lottie/LOTAnimationView.h>
#import <CreativeKit/ACCMacros.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

@interface AWERecognitionLoadingView ()

@property (nonatomic, assign) BOOL loopContinue;
@property (nonatomic,   copy) NSArray<LOTAnimationView *> *lottieArray;
@end

@implementation AWERecognitionLoadingView

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame hideLottie:NO];
}

- (instancetype)initWithFrame:(CGRect)frame hideLottie:(BOOL)hide
{
    if (self = [super initWithFrame:frame]){
        [self setupViews];
        if (!hide){
            [self setupLotties];
        }
        [self setupConstraints];
    }
    return self;
}

- (void)setupViews
{
    _tipTitleLabel = [UILabel new];
    _tipTitleLabel.textColor = UIColor.whiteColor;
    _tipTitleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    _tipTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_tipTitleLabel];

    _tipHintLabel = [UILabel new];
    _tipHintLabel.textColor = UIColor.whiteColor;
    _tipHintLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    _tipHintLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_tipHintLabel];

}

- (void)hideLottie
{
    [self.lottieArray enumerateObjectsUsingBlock:^(LOTAnimationView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    self.lottieArray = nil;
}

#define ROW 4
#define COLUMN 3
#define COUNT ROW*COLUMN
#define OFFSET_Y 65  /// tipHintLabel bottom
- (void)setupLotties
{
    NSMutableArray *ma = [NSMutableArray array];
    for (int i = 0; i < COUNT; i ++){
        [ma btd_addObject:[self createAnimationView]];
    }

    self.lottieArray = ma.copy;
}

- (LOTAnimationView *)createAnimationView
{
    let lottieName = @"recognition_loading_dots.json";
    var animationView = [LOTAnimationView animationWithFilePath:ACCResourceFile(lottieName)];
    animationView.loopAnimation = NO;
    animationView.hidden = YES;
    animationView.userInteractionEnabled = NO;
    animationView.contentMode = UIViewContentModeScaleAspectFit;

    [self addSubview:animationView];
    return animationView;
}

- (CGPoint)randomItemCenter:(NSInteger)row :(NSInteger)column
{
    CGSize area = [self area];

    return CGPointMake(column*area.width+arc4random_uniform(area.width),
                       OFFSET_Y+row*area.height+arc4random_uniform(area.height));
}

- (CGSize)area{
    static CGSize area;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        area = CGSizeMake(self.acc_width / COLUMN, (self.acc_height-OFFSET_Y) / ROW);
    });
    return area;
}

- (void)setupConstraints
{
    ACCMasMaker(_tipTitleLabel, {
        make.top.equalTo(self).offset(65);
        make.leading.trailing.equalTo(self);
        make.height.mas_equalTo(25);
    })
    ACCMasMaker(_tipHintLabel, {
        make.leading.trailing.equalTo(self);
        make.top.equalTo(_tipTitleLabel.mas_bottom).offset(6);
        make.height.mas_equalTo(18);
    })
}

- (void)play
{
    self.loopContinue = YES;
    self.alpha = 1;
    [self p_play];
}

- (void)stop
{
    self.loopContinue = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        for (int i = 0 ; i < COUNT; i ++) {
            var lottie = self.lottieArray[i];
            [lottie stop];
            lottie.hidden = YES;
        }
    }];

}

#define MAX_DELAY_MS 2000
#define DELAY_FILTER MAX_DELAY_MS*0.7
- (void)p_play
{
    for (int i = 0 ; i < ROW; i ++) {
        for (int j = 0; j < COLUMN; j ++){
            [self loopItem:i :j];
        }
    }
}

- (void)loopItem:(NSInteger)i :(NSInteger)j
{
    if (!self.loopContinue){
        return;
    }

    /// dot animation played after a random delay(milliseconds)
    let delay = arc4random_uniform(MAX_DELAY_MS);
    BOOL skip = delay > DELAY_FILTER;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        if (skip){
            [self loopItem:i :j];
            return;
        }
        var lottie = self.lottieArray[i*COLUMN + j];

        /// update position
        lottie.acc_size = CGSizeMake(22, 22);
        lottie.center = [self randomItemCenter:i :j];
        lottie.hidden = NO;
        @weakify(self)
        [lottie playWithCompletion:^(BOOL animationFinished) {
            @strongify(self)
            [self loopItem:i :j];
        }];

    });
}
@end
