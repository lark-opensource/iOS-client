//
//  AWERecordLoadingView.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/3/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWERecordLoadingView.h"
#import <lottie-ios/Lottie/LOTAnimationView.h>
#import <AVFoundation/AVFoundation.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCRTL.h>

@implementation AWERecordLoadingMaskView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    return nil;
}

@end


@interface AWERecordLoadingView ()<AVAudioPlayerDelegate>

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) AWERecordLoadingMaskView *maskView;
@property (nonatomic, strong) UIImage *gifImage;
@property (nonatomic, copy) void (^completion)(void);
@property (nonatomic, strong) LOTAnimationView *countDownAnimationView;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSArray *audioSegementName;
@property (nonatomic, assign) NSInteger audioIndex;

@end

@implementation AWERecordLoadingView

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame animationCompletion:nil];
}

- (instancetype)initWithFrame:(CGRect)frame
          animationCompletion:(void (^)(void))animationCompletion {
    self = [super initWithFrame:frame];
    if (self) {
        self.accrtl_viewType = ACCRTLViewTypeNormal;
        _completion = [animationCompletion copy];
        if  (!_countDownAnimationView) {
            _countDownAnimationView = [LOTAnimationView animationWithFilePath:ACCResourceFile(@"countdown_3_lottie.json")];
            _countDownAnimationView.frame = CGRectMake(0, 0, round(self.bounds.size.width / 3), round(self.bounds.size.height / 3));
            _countDownAnimationView.center = self.center;
            _countDownAnimationView.contentMode = UIViewContentModeScaleAspectFit;
            [self addSubview:_countDownAnimationView];
            @weakify(self);
            [_countDownAnimationView playWithCompletion:^(BOOL animationFinished) {
                @strongify(self);
                if (self.superview) {
                    [self removeFromSuperview];
                }
                ACCBLOCK_INVOKE(self.completion);
            }];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
              delayRecordMode:(AWEDelayRecordMode)delayRecordMode
          animationCompletion:(void (^)(void))animationCompletion
{
    self = [super initWithFrame:frame];
    if (self) {
        self.audioSegementName = [NSArray arrayWithObjects:@"A__II.mp3", @"B__II.mp3", @"C__II.mp3", nil];
        self.accrtl_viewType = ACCRTLViewTypeNormal;
        _completion = [animationCompletion copy];
        if  (!_countDownAnimationView) {
            _countDownAnimationView = [LOTAnimationView animationWithFilePath:ACCResourceFile(delayRecordMode == AWEDelayRecordMode3S ? @"countdown_3_lottie.json" : @"countdown_10_lottie.json")];
            _countDownAnimationView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
            _countDownAnimationView.center = self.center;
            _countDownAnimationView.contentMode = UIViewContentModeScaleAspectFit;
            
            [self addSubview:_countDownAnimationView];
            
            if (!_maskView) {
                _maskView = [[AWERecordLoadingMaskView alloc] initWithFrame:frame];
                [self addSubview:_maskView];
            }

            [[AVAudioSession sharedInstance] setActive:YES error:nil];
            self.player = [self playerWithFirstAudioIndex:delayRecordMode == AWEDelayRecordMode10S ? 0 : 1];
            [self.player play];
            
            @weakify(self)
            [_countDownAnimationView playWithCompletion:^(BOOL animationFinished) {
                @strongify(self);
                if (self.player) {
                    [self.player stop];
                    self.player.delegate = nil;
                    self.player = nil;
                }

                if (self.superview) {
                    [self removeFromSuperview];
                }
                ACCBLOCK_INVOKE(self.completion);
            }];
        }
    }
    return self;
}

- (AVAudioPlayer *)playerWithFirstAudioIndex:(NSInteger)index
{
    if (!_player) {
        if (!self.audioSegementName || index > [self.audioSegementName count] - 1) {
            return nil;
        }
        self.audioIndex = index;
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:ACCResourceFile([self.audioSegementName objectAtIndex:index])] error:nil];
        switch (index) {
            case 0:
                _player.numberOfLoops = 6;
                break;
            case 1:
                _player.numberOfLoops = 1;
                break;
            default:
                break;
        }
        _player.delegate = self;
        [_player prepareToPlay];
    }
    return _player;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag) {
        if (self.audioIndex < [self.audioSegementName count] - 1) {
            self.audioIndex ++;
            if (self.player) {
                [self.player stop];
                self.player.delegate = nil;
                self.player = nil;
            }
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:ACCResourceFile([self.audioSegementName objectAtIndex:self.audioIndex])] error:nil];
            if (!self.player) {
                return;
            }
            self.player.delegate = self;
            self.player.numberOfLoops = (self.audioIndex == 1 ? 1 : 0);
            [self.player prepareToPlay];
            [self.player play];
        }
    }
}
@end
