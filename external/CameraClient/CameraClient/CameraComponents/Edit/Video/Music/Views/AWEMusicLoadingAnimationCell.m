//
//  AWEMusicLoadingAnimationCell.m
//  AAWELaunchMainPlaceholder-iOS8.0
//
//  Created by chengfei xiao on 2019/3/17.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEMusicLoadingAnimationCell.h"
#import <lottie-ios/Lottie/LOTAnimationView.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>

@interface AWEMusicLoadingAnimationCell ()

@property(nonatomic, strong) LOTAnimationView *loadingAnimation;
@property(nonatomic, strong) UILabel *loadingTipLbl;

@end


@implementation AWEMusicLoadingAnimationCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        
        //lottie
         self.loadingAnimation.frame = CGRectMake(0, (57-48)/2.f,305,48);
         [self.contentView addSubview:self.loadingAnimation];
        
        _loadingTipLbl = [UILabel new];
        _loadingTipLbl.textAlignment = NSTextAlignmentCenter;
        _loadingTipLbl.text = ACCLocalizedCurrentString(@"com_mig_loading_xk6x01");
        _loadingTipLbl.font = [ACCFont() systemFontOfSize:11];
        _loadingTipLbl.textColor = ACCResourceColor(ACCUIColorTextTertiary);
        [self.contentView addSubview:_loadingTipLbl];
        ACCMasMaker(_loadingTipLbl, {
            make.left.right.equalTo(self.contentView);
            make.bottom.equalTo(self.contentView).offset(-5.f);
            make.height.equalTo(@15);
        });
        _loadingTipLbl.hidden = YES;
    }
    return self;
}

- (void)startAnimating
{
    //lottie
    self.loadingAnimation.animationProgress = 0;
    [self.loadingAnimation play];
    //[self.loadingAnimation playWithCompletion:^(BOOL animationFinished) {}];
}

- (void)stopAnimating {
    [self.loadingAnimation stop];
    self.loadingAnimation.animationProgress = 0;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (self.animationFillToContent) {
        _loadingAnimation.frame = frame;
    }
}

- (LOTAnimationView *)loadingAnimation
{
    if (!_loadingAnimation) {
        NSString *animationName = [self loadingAnimationName];
        _loadingAnimation = [LOTAnimationView animationWithFilePath:ACCResourceFile(animationName)];
        _loadingAnimation.loopAnimation = YES;
        _loadingAnimation.userInteractionEnabled = NO;
        _loadingAnimation.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _loadingAnimation;
}

- (NSString *)loadingAnimationName
{
    return ACC_FLOAT_EQUAL_TO(ACC_SCREEN_WIDTH, 414.f) ? @"ai_music_loading_lottie_for_black_spacing16.json":@"ai_music_loading_lottie_for_black_spacing12.json";
}

@end
