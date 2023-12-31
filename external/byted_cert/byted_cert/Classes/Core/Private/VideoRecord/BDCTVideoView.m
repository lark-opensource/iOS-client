//
//  BDCTVideoView.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/19.
//

#import "BDCTVideoView.h"
#import "BDCTAdditions.h"
#import "BDCTAdditions+VideoRecord.h"

#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>
#import <ByteDanceKit/UIButton+BTDAdditions.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import <ByteDanceKit/UIImage+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>

static NSString *byted_cert_video_view_play_time_string(int seconds) {
    if (seconds < 60) {
        return [NSString stringWithFormat:@"00:%02d", seconds];
    } else {
        int minutes = seconds / 60;
        seconds = seconds % 60;
        return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    }
}


@interface BDCTVideoView ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UILabel *playTimeLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UISlider *sliderView;
@property (nonatomic, strong) UIView *progressView;

@end


@implementation BDCTVideoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];

        [self layoutContenViews];
    }
    return self;
}

- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    self.durationLabel.text = byted_cert_video_view_play_time_string(@(CMTimeGetSeconds(self.player.currentItem.asset.duration)).intValue);

#if DEBUG
    long long videoSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:videoURL.path error:nil] fileSize];
    UILabel *videoSizeLabel = [UILabel new];
    videoSizeLabel.text = [NSString stringWithFormat:@"%0.2fMB", videoSize / 1024.0 / 1024.0];
    videoSizeLabel.textColor = UIColor.whiteColor;
    videoSizeLabel.backgroundColor = UIColor.blackColor;
    [self addSubview:videoSizeLabel];
    [videoSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self);
    }];
#endif
}

- (AVPlayerLayer *)playerLayer {
    if (!_playerLayer) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        [self.layer insertSublayer:_playerLayer atIndex:0];
    }
    return _playerLayer;
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [[AVPlayer alloc] init];
        @weakify(self);
        [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self);
            self.playTimeLabel.text = byted_cert_video_view_play_time_string(@(CMTimeGetSeconds(self.player.currentTime)).intValue);
            self.durationLabel.text = byted_cert_video_view_play_time_string(@(CMTimeGetSeconds(self.player.currentItem.duration)).intValue);
            CGFloat progress = CMTimeGetSeconds(self.player.currentItem.currentTime) / CMTimeGetSeconds(self.player.currentItem.duration);
            if (!self.sliderView.isTracking) {
                self.sliderView.value = progress;
            }
            if (progress == 1.0f) {
                [self.player seekToTime:CMTimeMake(0, 1)];
                [self updateVideoPlayState:NO];
            }
        }];
    }
    return _player;
}

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [_playBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [_playBtn setImage:[UIImage bdct_videoRecordimageWithName:@"bdct_icon_video_play"] forState:UIControlStateNormal];
        [_playBtn setImage:[UIImage bdct_videoRecordimageWithName:@"bdct_icon_video_play"] forState:UIControlStateHighlighted];
        [_playBtn setImage:[UIImage new] forState:UIControlStateSelected];
        [_playBtn setImage:[UIImage new] forState:UIControlStateSelected | UIControlStateHighlighted];
        [self addSubview:_playBtn];
        @weakify(self);
        [_playBtn btd_addActionBlockForTouchUpInside:^(__kindof UIButton *_Nonnull sender) {
            @strongify(self);
            if (sender.selected) {
                [self.player pause];
                [self updateVideoPlayState:NO];
            } else {
                [self.player play];
                [self updateVideoPlayState:YES];
            }
        }];
    }
    return _playBtn;
}

- (UILabel *)playTimeLabel {
    if (!_playTimeLabel) {
        _playTimeLabel = [UILabel new];
        _playTimeLabel.text = @"00:00";
        _playTimeLabel.textColor = UIColor.whiteColor;
        _playTimeLabel.font = [UIFont systemFontOfSize:14];
        _playTimeLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        _playTimeLabel.layer.shadowOffset = CGSizeMake(0, 0);
        _playTimeLabel.layer.shadowOpacity = 1;
        [self addSubview:_playTimeLabel];
    }
    return _playTimeLabel;
}

- (UISlider *)sliderView {
    if (!_sliderView) {
        _sliderView = [UISlider new];
        _sliderView.tintColor = UIColor.whiteColor;
        [_sliderView setThumbImage:[UIImage btd_imageWithSize:CGSizeMake(12, 12) cornerRadius:6 backgroundColor:UIColor.whiteColor] forState:UIControlStateNormal];
        [_sliderView addTarget:self action:@selector(sliderDidTouch) forControlEvents:UIControlEventTouchDown];
        [_sliderView addTarget:self action:@selector(sliderDidDrag) forControlEvents:UIControlEventValueChanged];
        [_sliderView addTarget:self action:@selector(sliderDidTouchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        [self addSubview:_sliderView];
    }
    return _sliderView;
}

- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [UILabel new];
        _durationLabel.text = @"--:--";
        _durationLabel.textColor = UIColor.whiteColor;
        _durationLabel.font = [UIFont systemFontOfSize:14];
        _durationLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        _durationLabel.layer.shadowOffset = CGSizeMake(0, 0);
        _durationLabel.layer.shadowOpacity = 1;
        [self addSubview:_durationLabel];
    }
    return _durationLabel;
}

- (UIView *)progressView {
    if (!_progressView) {
        _progressView = [UIView new];
        [_progressView addSubview:self.playTimeLabel];
        [_progressView addSubview:self.sliderView];
        [_progressView addSubview:self.durationLabel];

        [self.playTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.bottom.equalTo(self.progressView).insets(UIEdgeInsetsMake(16, 16, 16, 0));
        }];
        [self.sliderView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [self.sliderView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

        [self.playTimeLabel sizeToFit];
        [self.sliderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.progressView).insets(UIEdgeInsetsMake(0, 16 + 6 + self.playTimeLabel.btd_width, 0, 16 + 6 + self.playTimeLabel.btd_width));
            make.centerY.equalTo(self.playTimeLabel);
        }];
        [self.durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.playTimeLabel);
            make.right.equalTo(self.progressView).offset(-16);
        }];
        [self addSubview:_progressView];
    }
    return _progressView;
}

- (void)layoutContenViews {
    [self.playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
    }];
    [self updateVideoPlayState:NO];
}

- (void)updateVideoPlayState:(BOOL)isPlaying {
    [self.playBtn setSelected:isPlaying];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    self.playerLayer.frame = self.bounds;
}

- (void)sliderDidTouch {
    [self.player pause];
}

- (void)sliderDidDrag {
    int seekToSeconds = self.sliderView.value * CMTimeGetSeconds(self.player.currentItem.duration);
    [self.player seekToTime:CMTimeMake(seekToSeconds, 1)];
}

- (void)sliderDidTouchUp {
    [self.player play];
    [self updateVideoPlayState:YES];
}

- (void)applicationWillResignActive {
    [self.player pause];
    [self.player seekToTime:CMTimeMake(0, 1)];
    [self updateVideoPlayState:NO];
}

@end
