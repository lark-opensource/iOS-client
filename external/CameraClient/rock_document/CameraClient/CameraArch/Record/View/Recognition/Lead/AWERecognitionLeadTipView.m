//
//  AWERecognitionLeadTipView.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/2.
//

#import "AWERecognitionLeadTipView.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>

@interface AWERecognitionLeadTipView()
@property (nonatomic, strong) LOTAnimationView *longPressLottie;
@end

@implementation AWERecognitionLeadTipView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setupViews];
        [self setupConstraints];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)setupViews
{
    _titleLabel = [[UILabel alloc] acc_initWithFontSize:20 isBold:YES textColor:UIColor.whiteColor text:nil];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_titleLabel];
    
    _contentLabel = [[UILabel alloc] acc_initWithFontSize:14 isBold:YES textColor:UIColor.whiteColor text:nil];
    _contentLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_contentLabel];

    NSString *lottieName = @"recognition_long_press_lead.json";
    var animationView = [LOTAnimationView animationWithFilePath:ACCResourceFile(lottieName)];
    animationView.loopAnimation = NO;
    animationView.userInteractionEnabled = NO;
    animationView.contentMode = UIViewContentModeScaleAspectFit;
    self.longPressLottie = animationView;
    [self addSubview:self.longPressLottie];
}

- (void)setupConstraints
{
    ACCMasMaker(_titleLabel, {
        make.centerX.equalTo(self);
        make.top.equalTo(self);
        make.width.equalTo(self);
        make.height.mas_equalTo(25);
    });
    
    ACCMasMaker(_contentLabel, {
        make.top.equalTo(_titleLabel.mas_bottom).offset(5);
        make.width.equalTo(self);
        make.height.equalTo(@(20));
        make.centerX.equalTo(self);
    })

    ACCMasMaker(_longPressLottie, {
        make.top.equalTo(_titleLabel.mas_bottom).offset(18);
        make.centerX.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(140, 140));
    });
}

- (void)playWithCompletion:(dispatch_block_t)completion
{
    [self playWithTimes:1 completion:completion];
}

- (void)playWithTimes:(NSInteger)times completion:(dispatch_block_t)completion
{
    if (times <= 0){
        completion();
        return;
    }
    @weakify(self)
    [self.longPressLottie playWithCompletion:^(BOOL animationFinished) {
        @strongify(self)
        [self playWithTimes:times-1 completion:completion];
    }];
}

@end
