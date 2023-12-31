//
//  ACCEditContainerView.m
//  AWEStudio
//
//  Created by guochenxiang on 2019/11/8.
//

#import "ACCEditContainerView.h"
#import <CreationKitArch/AWEEditGradientView.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <ACCConfigKeyDefines.h>

NSString * const AWEEditViewRemoveSyncToFriendsBubbleNotification = @"AWEEditViewRemoveSyncToFriendsBubbleNotification";

@interface ACCEditContainerView ()

@property (nonatomic, strong) AWEEditGradientView *bottomGradientView;
@property (nonatomic, strong) UIImageView *playButton;

@end

@implementation ACCEditContainerView

@synthesize videoPlayerTappedBlock;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.playButton];
        if (![UIDevice acc_isIPhoneX] && !ACCConfigBool(kConfigBool_studio_adjust_black_mask)) {
            [self addSubview:self.bottomGradientView];
        }
        
        ACCMasMaker(self.playButton, {
            make.center.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(90, 90));
        });
    }
    return self;
}

- (AWEEditGradientView *)bottomGradientView
{
    if (!_bottomGradientView) {
        _bottomGradientView = [[AWEEditGradientView alloc] initWithFrame:CGRectMake(0, ACC_SCREEN_HEIGHT - 334, ACC_SCREEN_WIDTH, 334) topColor:ACCUIColorFromRGBA(0X000000, .0) bottomColor:ACCUIColorFromRGBA(0X000000, .5)];
    }

    return _bottomGradientView;
}

- (UIImageView *)playButton
{
    if (!_playButton) {
        _playButton = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_segment_play")];
        _playButton.contentMode = UIViewContentModeScaleAspectFit;
        _playButton.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(videoPlayerTapped:)];
        [_playButton addGestureRecognizer:tap];
        _playButton.alpha = 0;
    }
    return _playButton;
}

#pragma mark - Public

- (BOOL)displayPlayButton:(BOOL)display {
    BOOL needToggle = display != (self.playButton.alpha == 1);
    if (display) {
        self.playButton.transform = CGAffineTransformMakeScale(2, 2);
        [UIView animateWithDuration:0.15 animations:^{
            self.playButton.transform = CGAffineTransformIdentity;
            self.playButton.alpha = 1;
        }];
    } else { // isPlaying
        [UIView animateWithDuration:0.1 animations:^{
            self.playButton.alpha = 0;
        }];
    }
    return needToggle;
}

#pragma mark - Action

- (void)videoPlayerTapped:(UITapGestureRecognizer *)gesture {
    ACCBLOCK_INVOKE(self.videoPlayerTappedBlock, gesture.view);
}

#pragma mark - HitTest

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    ACCBLOCK_INVOKE(self.interactionBlock);
    [[NSNotificationCenter defaultCenter] postNotificationName:AWEEditViewRemoveSyncToFriendsBubbleNotification object:nil];
    UIView* tmpView = [super hitTest:point withEvent:event];
    if (tmpView == self) {
        return nil;
    }
    return tmpView;
}

@end

