//
//  ACCASSCurrentSelectedView.m
//  CameraClient
//
//  Created by Chen Long on 2020/9/15.
//

#import "ACCASSCurrentSelectedView.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>

#import <Masonry/View+MASAdditions.h>

#if __has_feature(modules)
@import CoreMedia;
@import AVFoundation;
#else
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#endif

@interface ACCASSCurrentSelectedView ()

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *clipButton;
@property (nonatomic, strong) UIView *sepLineView;
@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, strong) id<ACCMusicModelProtocol> selectedMusic;

@property (nonatomic, strong) AVPlayer *internalPlayer;
@property (nonatomic, assign) BOOL pausedByBackground;

@end

@implementation ACCASSCurrentSelectedView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithMusic:(id<ACCMusicModelProtocol>)music
{
    if (self = [super initWithFrame:CGRectZero]) {
        _selectedMusic = music;
        [self p_setupUI];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)stop
{
    [self.internalPlayer seekToTime:CMTimeMake(0, 10)];
    [self.internalPlayer pause];
    [self.playButton setImage:ACCResourceImage(@"icon_play_music") forState:UIControlStateNormal];
}

- (void)updateCancelButtonToDistouchableColor
{
    self.deleteButton.alpha = 0.34;
}

- (void)setEnableClipBlock:(BOOL (^)(id<ACCMusicModelProtocol> _Nonnull))enableClipBlock
{
    _enableClipBlock = enableClipBlock;
    self.clipButton.enabled = ACCBLOCK_INVOKE(enableClipBlock, self.selectedMusic);
}

#pragma mark - UI

- (void)hideDeleteActionBtn;
{
    self.deleteButton.hidden = YES;
    self.sepLineView.hidden = YES;
}

- (void)hideClipActionBtn;
{
    self.clipButton.hidden = YES;
    self.sepLineView.hidden = YES;
}

- (void)p_setupUI
{
    self.userInteractionEnabled = YES;
    self.backgroundColor = UIColor.whiteColor;
    
    self.layer.cornerRadius =  8;
    self.layer.borderColor = ACCResourceColor(ACCColorLineReverse2).CGColor;
    self.layer.borderWidth = 0.5;
    
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.layer.shadowRadius = 8;
    self.layer.shadowOpacity = 1;
    
    [self addSubview:self.coverImageView];
    ACCMasMaker(self.coverImageView, {
        make.left.equalTo(self).offset(12);
        make.centerY.equalTo(self);
        make.size.equalTo(@(CGSizeMake(40, 40)));
    });
    
    [self.coverImageView addSubview:self.playButton];
    ACCMasMaker(self.playButton, {
        make.center.equalTo(self.coverImageView);
        make.size.equalTo(@(CGSizeMake(20, 24)));
    });
    
    [self addSubview:self.deleteButton];
    ACCMasMaker(self.deleteButton, {
        make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(self);
        make.size.equalTo(@(CGSizeMake(24, 24)));
    });
    
    [self addSubview:self.sepLineView];
    ACCMasMaker(self.sepLineView, {
        make.right.equalTo(self.deleteButton.mas_left).offset(-10);
        make.centerY.equalTo(self);
        make.size.equalTo(@(CGSizeMake(0.5, 12)));
    });
    
    [self addSubview:self.clipButton];
    ACCMasMaker(self.clipButton, {
        make.right.equalTo(self.sepLineView.mas_left).offset(-10);
        make.centerY.equalTo(self);
        make.size.equalTo(@(CGSizeMake(24, 24)));
    });
    
    [self addSubview:self.titleLabel];
    ACCMasMaker(self.titleLabel, {
        make.left.equalTo(self.coverImageView.mas_right).offset(12);
        make.right.lessThanOrEqualTo(self.clipButton.mas_left).offset(-16);
        make.centerY.equalTo(self);
    });
}

- (void)p_replayFromRangeLocation
{
    [self.internalPlayer seekToTime:CMTimeMakeWithSeconds(self.audioRange.location, NSEC_PER_SEC)];
    [self.internalPlayer play];
}

#pragma mark - Actions

- (void)p_didClickPlayButton:(id)sender
{
    if ((self.internalPlayer.rate != 0) && (self.internalPlayer.error == nil)) {
        // playing
        [self stop];
    } else {
        [self.playButton setImage:ACCResourceImage(@"icon_pause_music") forState:UIControlStateNormal];
        [self p_replayFromRangeLocation];
        ACCBLOCK_INVOKE(self.didStartPlayMusic);
    }
}

- (void)p_didClickClipButton:(id)sender
{
    ACCBLOCK_INVOKE(self.didClickClipButton, self.selectedMusic);
}

- (void)p_didClickDeleteButton:(id)sender
{
    [self stop];
    ACCBLOCK_INVOKE(self.didClickDeleteButton, self.selectedMusic);
}

#pragma mark - Getters

- (UIImageView *)coverImageView
{
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.layer.masksToBounds = YES;
        _coverImageView.layer.cornerRadius = 2;
        [_coverImageView acc_addSingleTapRecognizerWithTarget:self action:@selector(p_didClickPlayButton:)];
        NSArray *coverURLArray = self.selectedMusic.mediumURL.URLList ?: self.selectedMusic.thumbURL.URLList;
        if (!ACC_isEmptyArray(coverURLArray)) {
            [ACCWebImage() imageView:_coverImageView setImageWithURLArray:coverURLArray];
        } else {
            _coverImageView.image = ACCResourceImage(@"background_music_mask");
        }
    }
    return _coverImageView;
}

- (UIButton *)playButton
{
    if (!_playButton) {
        _playButton = [[UIButton alloc] init];
        _playButton.userInteractionEnabled = NO;
        [_playButton setImage:ACCResourceImage(@"icon_play_music") forState:UIControlStateNormal];
    }
    return _playButton;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightMedium];
        _titleLabel.textColor = ACCResourceColor(ACCColorTextReverse);
        _titleLabel.text = [NSString stringWithFormat:ACCLocalizedCurrentString(@"choose_music_using"), self.selectedMusic.musicName];
    }
    return _titleLabel;
}

- (UIButton *)clipButton
{
    if (!_clipButton) {
        _clipButton = [[UIButton alloc] init];
        [_clipButton setImage:ACCResourceImage(@"icon_music_cut_black") forState:UIControlStateNormal];
        [_clipButton addTarget:self action:@selector(p_didClickClipButton:) forControlEvents:UIControlEventTouchUpInside];
        _clipButton.accessibilityLabel = @"剪裁";
    }
    return _clipButton;
}

- (UIView *)sepLineView
{
    if (!_sepLineView) {
        _sepLineView = [[UIView alloc] init];
        _sepLineView.backgroundColor = ACCResourceColor(ACCColorLineReverse2);
    }
    return _sepLineView;
}

- (UIButton *)deleteButton
{
    if (!_deleteButton) {
        _deleteButton = [[UIButton alloc] init];
        [_deleteButton setImage:ACCResourceImage(@"icon_panel_delete_black") forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(p_didClickDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
        _deleteButton.accessibilityLabel = @"删除";
    }
    return _deleteButton;
}

- (AVPlayer *)internalPlayer
{
    if (!_internalPlayer) {
        AVAsset *asset = [[AVURLAsset alloc] initWithURL:self.selectedMusic.loaclAssetUrl options:@{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES }];
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:asset];
        _internalPlayer = [[AVPlayer alloc] initWithPlayerItem:item];
        @weakify(self);
        [_internalPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            @strongify(self);
            Float64 currentTime = CMTimeGetSeconds(self.internalPlayer.currentTime);
            Float64 totalTime = self.selectedMusic.auditionDuration.floatValue;
            NSTimeInterval maxThreshold = self.audioRange.location + self.audioRange.length;
            
            if ((maxThreshold != 0 && currentTime >= maxThreshold) || currentTime >= totalTime) {
                [self p_replayFromRangeLocation];
            }
        }];
    }
    return _internalPlayer;;
}

#pragma mark - Notifications

- (void)applicationWillResignActive:(NSNotification *)notification
{
    if ((self.internalPlayer.rate != 0) && (self.internalPlayer.error == nil)) {
        self.pausedByBackground = YES;
        [self.internalPlayer pause];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (self.pausedByBackground) {
        [self.internalPlayer play];
    }
}

@end
