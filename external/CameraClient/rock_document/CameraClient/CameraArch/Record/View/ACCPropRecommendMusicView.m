//
//  ACCPropRecommendMusicView.m
//  CameraClient
//
//  Created by xiaojuan on 2020/8/5.
//
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCPropRecommendMusicView.h"
#import <CreativeKit/UIFont+ACC.h>
#import <Masonry/Masonry.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitArch/AWEScrollStringLabel.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import "ACCAudioPlayerProtocol.h"
#import "ACCAudioPlayerProtocol.h"
#import <CreationKitInfra/ACCRACWrapper.h>

#define ACCMarginLeft 8
#define ACCMarginRight 14
#define ACCMarginTop 8
#define ACCMarginBottom 8

#define ACCCoverImageWithAndHeight 36
#define ACCPlayIconWidthAndHeight 16
#define ACCTitleLabelWidth 104
#define ACCConfirmBtnWidth 50
#define ACCConfirmBtnHeight 24

@interface ACCPropRecommendMusicView()<ACCPropRecommendMusicProtocol>
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIImageView *playIconView;
@property (nonatomic, strong) AWEScrollStringLabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) id<ACCMusicModelProtocol> playingMusic;
@property (nonatomic, assign) ACCAVPlayerPlayStatus playerStatus;
@property (nonatomic, strong) id<ACCAudioPlayerProtocol> audioPlayWrapper;
@property (nonatomic, copy) NSString *creationID;//For tracking service
@end

@implementation ACCPropRecommendMusicView

- (void)dealloc
{
    [_audioPlayWrapper pause];
    [self p_stopAnimation];
    _playingMusic = nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _audioPlayWrapper = IESAutoInline(ACCBaseServiceProvider(), ACCAudioPlayerProtocol);
        _audioPlayWrapper.delegate = self;
        [self p_setupUI];
        [self addGestureRecognizer];
    }
    return self;
}

- (void)addGestureRecognizer
{
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToPlayPause)];
    [self addGestureRecognizer:ges];
}

- (void)p_setupUI
{
    [self addSubview:self.coverImageView];
    [self addSubview:self.playIconView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.subTitleLabel];
    [self addSubview:self.confirmButton];
  
    ACCMasMaker(self.coverImageView, {
        make.top.equalTo(self).offset(ACCMarginTop);
        make.left.equalTo(self).offset(ACCMarginLeft);
        make.width.height.equalTo(@(ACCCoverImageWithAndHeight));
    });

    ACCMasMaker(self.playIconView, {
        make.center.equalTo(self.coverImageView);
        make.width.height.equalTo(@(ACCPlayIconWidthAndHeight));
    });

    ACCMasMaker(self.titleLabel, {
        make.left.equalTo(self.coverImageView.mas_right).offset(8);
        make.width.equalTo(@(104));
        make.top.equalTo(self.coverImageView);
        make.height.equalTo(@(17));
    });

    ACCMasMaker(self.subTitleLabel, {
        make.left.equalTo(self.titleLabel);
        make.right.equalTo(self.confirmButton.mas_left).offset(-24);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
        make.bottom.equalTo(self).offset(-ACCMarginBottom);
    });

    ACCMasMaker(self.confirmButton, {
        make.width.equalTo(@(ACCConfirmBtnWidth));
        make.height.equalTo(@(ACCConfirmBtnHeight));
        make.top.equalTo(self).offset(14);
        make.right.equalTo(self).offset(-14);
    });
}

- (void)viewAppearEvent
{
    [self.titleLabel startAnimation];
    [self.audioPlayWrapper play];
}

- (void)viewDidDismissEvent
{
    [self.audioPlayWrapper pause];
}

#pragma mark - getter

- (UIImageView *)coverImageView
{
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.layer.masksToBounds = YES;
        _coverImageView.layer.cornerRadius = 2;
    }
    return _coverImageView;
}

- (UIImageView *)playIconView
{
    if (!_playIconView) {
        _playIconView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_playmusic")];
    }
    return _playIconView;
}

- (AWEScrollStringLabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[AWEScrollStringLabel alloc] initWithHeight:17];
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel
{
    if (!_subTitleLabel) {
        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse2);
        _subTitleLabel.font = [UIFont acc_fontWithName:@"PingFangSC-Regular" size:11];
        _subTitleLabel.text = ACCLocalizedString(@"rec_music_based_on_effect", nil);
    }
    return _subTitleLabel;
}

- (UIButton *)confirmButton
{
    if (!_confirmButton) {
        _confirmButton = [[UIButton alloc] init];
        _confirmButton.backgroundColor = ACCResourceColor(ACCColorPrimary);
        _confirmButton.titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _confirmButton.titleLabel.font = [UIFont acc_fontWithName:@"PingFangSC-Medium" size:12];
        [_confirmButton setTitle:ACCLocalizedString(@"com_mig_use", nil) forState:UIControlStateNormal];
        _confirmButton.layer.masksToBounds = YES;
        _confirmButton.layer.cornerRadius = 2;
    }
    return _confirmButton;
}

- (void)updateWithMusicModel:(id<ACCMusicModelProtocol>)model bubbleTitle:(NSString *)bubbleTitle Image:(UIImage *)image creationID:(NSString *)creationID
{
    self.playingMusic = model;
    self.creationID = creationID;
    [self.titleLabel configWithTitleWithTextAlignCenter:model.musicName
                                             titleColor: ACCResourceColor(ACCColorConstTextInverse)
                                               fontSize:12
                                                 isBold:YES
                                            contentSize:self.titleLabel.intrinsicContentSize];
    if (bubbleTitle) {
        self.subTitleLabel.text = bubbleTitle;
    }
    [self layoutIfNeeded];
    CGFloat width = MIN(self.titleLabel.leftLabel.frame.size.width, self.titleLabel.frame.size.width);
    ACCMasUpdate(self.titleLabel, {
        make.width.equalTo(@(width));
    });
    [self.coverImageView setImage:image];
    @weakify(self);
    [self.audioPlayWrapper updateServiceWithMusicModel:model audioPlayerPlayingBlock:^{
        @strongify(self);
        [self p_stopAnimation];
    }];
}

- (void)tapToPlayPause
{
    self.hasTappedOnce = YES;
    NSString *clickType = @"";
    if (self.playerStatus <= ACCAVPlayerPlayStatusPlaying) {
        [self.audioPlayWrapper pause];
        clickType = @"pause";
    } else {
        [self.audioPlayWrapper play];
        clickType = @"continue";
    }
    [ACCTracker() track:@"click_music_popup_option" params:@{@"click_type" : clickType,
                                                             @"enter_from" : @"video_shoot_page",
                                                             @"music_id" : self.playingMusic.musicID ? : @"",
                                                             @"creation_id" : self.creationID ? : @""
    }];
}

- (void)tapPlayImageView
{
    if (!self.playingMusic) {
        return;
    }
    if ([self.playingMusic isOffLine]) {
        [ACCToast() show:self.playingMusic.offlineDesc];
        return;
    }
    if (self.playerStatus <= ACCAVPlayerPlayStatusPlaying) {
        [self p_stopAnimation];
        [self.audioPlayWrapper pause];
    } else {
        [self p_stopAnimation];
        [self.audioPlayWrapper play];
    }
}

- (void)p_startAnimation
{
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    anim.toValue = @(M_PI * 2.0);
    anim.duration = 1;
    anim.cumulative = YES;
    anim.repeatCount = FLT_MAX;
    [self.playIconView.layer addAnimation:anim forKey:@"rotateAnimation"];
}

- (void)p_stopAnimation
{
    [self.playIconView.layer removeAllAnimations];
}

#pragma mark ACCStickerRecommendMusicProtocol

- (void)configDelegateViewWithStatus:(ACCAVPlayerPlayStatus)playerStatus
{
    self.playerStatus = playerStatus;
    NSString *imageName = @"icon_playmusic";
    [self p_stopAnimation];
    if (playerStatus == ACCAVPlayerPlayStatusPlaying) {
        imageName = @"icon_pausemusic";
    } else if (playerStatus == ACCAVPlayerPlayStatusLoading) {
        imageName = @"icon_playmusic_loading";
        [self p_startAnimation];
    }
    self.playIconView.image = ACCResourceImage(imageName);
}

- (CGSize)intrinsicContentSize
{
    CGFloat width = MAX(self.subTitleLabel.intrinsicContentSize.width, ACCTitleLabelWidth);
    CGFloat bubbleWidth = ACCMarginLeft + ACCCoverImageWithAndHeight + 8 + width + 24 + ACCConfirmBtnWidth + ACCMarginRight;
    return CGSizeMake(bubbleWidth, 52);
}
@end
