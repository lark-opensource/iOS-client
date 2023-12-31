//
//  ACCSingleLocalMusicTableViewCell.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/2.
//

#import "ACCSingleLocalMusicTableViewCell.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCToastProtocol.h>

@interface ACCSingleLocalMusicTableViewCell()

@property (nonatomic, strong) UIImageView *backMusicView;
@property (nonatomic, strong) UIImageView *playStateView;
@property (nonatomic, strong) UILabel *musicTitle;
@property (nonatomic, strong) UILabel *authorNameLabel;
@property (nonatomic, strong) UILabel *durationLabel;

@property (nonatomic, strong) UIView *featureContainView;
@property (nonatomic, strong) UIButton *clipButton;//剪裁
@property (nonatomic, strong) UIButton *confirmButton;//使用

@property (nonatomic, strong) UIButton *deleteButton;//删除
@property (nonatomic, strong) UIButton *renameButton;//重命名

@property (nonatomic, assign) ACCAVPlayerPlayStatus playerStatus;
@property (nonatomic, assign) ACCSingleLocalMusicCellStatus featureStatus;

@end

@implementation ACCSingleLocalMusicTableViewCell

#pragma mark - public

+ (CGFloat)sectionHeight
{
    return 84;
}

- (void)bindMusicModel:(id<ACCMusicModelProtocol>)model{
    self.musicModel = model;
    [self p_configDurationLabel:self.musicModel];
    self.musicTitle.text = self.musicModel.musicName;
    self.authorNameLabel.text = self.musicModel.authorName;
    if (self.musicModel.isFromiTunes) {
        self.renameButton.alpha = 0.2;
        self.deleteButton.alpha = 0.2;
    } else {
        self.renameButton.alpha = 1.0;
        self.deleteButton.alpha = 1.0;
    }
    
    if (!ACC_isEmptyArray(self.musicModel.thumbURL.URLList)) {
        NSArray<NSString *> *coverURLArray = self.musicModel.thumbURL.URLList;
        NSString *coverPath = coverURLArray.firstObject;
        NSURL *url = [NSURL URLWithString:coverPath];
        NSData *datatest = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:datatest];
        self.backMusicView.image = image;
    } else {
        UIImage *image = ACCResourceImage(@"background_music_mask");//兜底
        self.backMusicView.image = image;
    }
    
    if (!ACC_isEmptyString(self.authorNameLabel.text)) {
        [self remakeMusicInfoArea];
    }
}

- (void)configWithEditStatus:(BOOL)isEdit{
    if (isEdit == YES) {
        [self transformToStatus:ACCSingleLocalMusicCellStatusShowEdit animated:YES];
    } else {
        if (self.featureStatus == ACCSingleLocalMusicCellStatusShowEdit) {
            [self transformToStatus:ACCSingleLocalMusicCellStatusNormal animated:YES];
        }
    }
}

- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus{
    [self configWithPlayerStatus:playerStatus animated:YES];
}

- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus animated:(BOOL)animated{
    if (self.playerStatus == playerStatus) {
        return;
    }
    self.playerStatus = playerStatus;
    [self p_stopLoadingAnimation];
    NSString *imageName = @"icon_play_music";
    if (playerStatus == ACCAVPlayerPlayStatusPlaying) {
        imageName = @"icon_pause_music";
        [self p_prepareConfigWithPlayerStatus:ACCSingleLocalMusicCellStatusShowApply animated:animated];
    } else if (playerStatus == ACCAVPlayerPlayStatusLoading) {
        imageName = @"icon_play_music_loading";
        [self p_startloadingStateAnimation];//loading的icon有动画
    } else {
        [self p_prepareConfigWithPlayerStatus:ACCSingleLocalMusicCellStatusNormal animated:animated];
    }
    self.playStateView.image = ACCResourceImage(imageName);
}

- (void)p_prepareConfigWithPlayerStatus:(ACCSingleLocalMusicCellStatus)cellStatus animated:(BOOL)animated{
    if (self.featureStatus == cellStatus) {
        return;
    }
    if (self.featureStatus == ACCSingleLocalMusicCellStatusShowEdit) {
        return;
        //edit状态下 右边布局不会因为playstatus改变
    }
    [self transformToStatus:cellStatus animated:animated];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.playerStatus = ACCAVPlayerPlayStatusPause;
        self.featureStatus = ACCSingleLocalMusicCellStatusNormal;
        [self setUI];
    }
    return self;
}

- (void)setUI
{
    [self.contentView addSubview:self.backMusicView];
    ACCMasMaker(self.backMusicView, {
        make.left.equalTo(self).offset(16);
        make.size.mas_equalTo(CGSizeMake(64, 64));
        make.centerY.equalTo(self);
    });
    [self.backMusicView addSubview:self.playStateView];
    ACCMasMaker(self.playStateView, {
        make.center.equalTo(self.backMusicView);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    });
    
    CGFloat maxTitleLength = [self p_maxTitleLength];
    [self.contentView addSubview:self.musicTitle];
    [self.contentView addSubview:self.durationLabel];
    ACCMasMaker(self.musicTitle, {
        make.left.equalTo(self.backMusicView.mas_right).offset(12);
        make.height.mas_equalTo(21);
        make.top.equalTo(self).offset(19);
        make.width.mas_equalTo(maxTitleLength);
    });
    ACCMasMaker(self.durationLabel, {
        make.left.equalTo(self.musicTitle);
        make.height.mas_equalTo(18);
        make.top.equalTo(self.musicTitle.mas_bottom).offset(6);
    });
}

#pragma mark Constraint
- (void)remakeMusicInfoArea{
    [self.contentView addSubview:self.authorNameLabel];
    CGFloat maxTitleLength = [self p_maxTitleLength];
    ACCMasReMaker(self.musicTitle, {
        make.height.mas_equalTo(18);
        make.left.equalTo(self.backMusicView.mas_right).offset(12);
        make.top.equalTo(self).offset(12);
        make.width.mas_equalTo(maxTitleLength);
    });
    ACCMasReMaker(self.authorNameLabel, {
        make.height.mas_equalTo(16);
        make.left.equalTo(self.musicTitle);
        make.top.equalTo(self.musicTitle.mas_bottom).offset(2);
        make.width.mas_equalTo(maxTitleLength);
    });
    ACCMasReMaker(self.durationLabel, {
        make.left.equalTo(self.musicTitle);
        make.height.mas_equalTo(18);
        make.top.equalTo(self.authorNameLabel.mas_bottom).offset(8);
    });
}

//右半边更新布局动画方法
- (void)transformToStatus:(ACCSingleLocalMusicCellStatus)newStatus animated:(BOOL)animated{
    if (self.featureStatus == newStatus) {
        return;
    }
    self.featureStatus = newStatus;
    if (newStatus == ACCSingleLocalMusicCellStatusShowEdit) {
        //->编辑 都需要更新UI
        [self.featureContainView acc_removeAllSubviews];
        [self.featureContainView removeFromSuperview];
        [self.contentView addSubview:self.featureContainView];
        ACCMasReMaker(self.featureContainView, {
            make.top.equalTo(self);
            make.height.equalTo(self);
            make.right.equalTo(self);
            make.width.mas_equalTo(85);
        });
        [self.contentView bringSubviewToFront:self.featureContainView];
        [self.featureContainView addSubview:self.deleteButton];
        ACCMasReMaker(self.deleteButton, {
            make.size.mas_equalTo(CGSizeMake(24, 24));
            make.right.equalTo(self.featureContainView).offset(-16);
            make.centerY.equalTo(self.featureContainView);
        });
        [self.featureContainView addSubview:self.renameButton];
        ACCMasReMaker(self.renameButton, {
            make.size.mas_equalTo(CGSizeMake(24, 24));
            make.right.equalTo(self.deleteButton.mas_left).offset(-16);
            make.centerY.equalTo(self.featureContainView);
        });
        if (animated) {
            [self p_MusicControlAnimate];
        }
    } else if (newStatus == ACCSingleLocalMusicCellStatusShowApply) {
        [self.featureContainView acc_removeAllSubviews];
        [self.featureContainView removeFromSuperview];
        [self.contentView addSubview:self.featureContainView];
        ACCMasReMaker(self.featureContainView, {
            make.top.equalTo(self);
            make.height.equalTo(self);
            make.right.equalTo(self);
            make.width.mas_equalTo(125);
        });
        [self.contentView bringSubviewToFront:self.featureContainView];
        [self.featureContainView addSubview:self.confirmButton];
        ACCMasReMaker(self.confirmButton, {
            make.size.mas_equalTo(CGSizeMake(64, 32));
            make.right.equalTo(self.featureContainView).offset(-16);
            make.centerY.equalTo(self.featureContainView);
        });
        [self.featureContainView addSubview:self.clipButton];
        ACCMasReMaker(self.clipButton, {
            make.size.mas_equalTo(CGSizeMake(24, 24));
            make.right.equalTo(self.confirmButton.mas_left).offset(-16);
            make.centerY.equalTo(self.featureContainView);
        });
        self.clipButton.alpha = self.disableClipButton ? 0 : 1;
        if (animated) {
            [self p_MusicControlAnimate];
        }
    } else if (newStatus == ACCSingleLocalMusicCellStatusNormal) {
        if (animated) {
            [self p_MusicControlAnimate];
        } else {
            [self.featureContainView acc_removeAllSubviews];
            [self.featureContainView removeFromSuperview];
        }
    }
    CGFloat maxTitleLength = [self p_maxTitleLength];
    ACCMasUpdate(self.musicTitle, {
        make.width.mas_equalTo(maxTitleLength);
    });
    ACCMasUpdate(self.authorNameLabel, {
        make.width.mas_equalTo(maxTitleLength);
    });
    [self p_MusicControlAnimate];
}

- (void)p_MusicControlAnimate{
    if (self.featureStatus != ACCSingleLocalMusicCellStatusNormal) {
        [self.featureContainView setNeedsLayout];
        [self.featureContainView layoutIfNeeded];
        ////make correct frame before animate
        
        self.featureContainView.alpha = 0;
        self.featureContainView.transform = CGAffineTransformMake(1, 0, 0, 1, self.featureContainView.bounds.size.width * 0.5, 0);
        [UIView animateWithDuration:0.3
                         animations:^{
            self.featureContainView.alpha = 1;
            self.featureContainView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    } else {
        [UIView animateWithDuration:0.3
                         animations:^{
            [self layoutIfNeeded];
            self.featureContainView.transform = CGAffineTransformMake(1, 0, 0, 1, self.featureContainView.bounds.size.width * 0.5, 0);
            self.featureContainView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.featureContainView acc_removeAllSubviews];
            [self.featureContainView removeFromSuperview];
        }];
    }
}


- (void)p_startloadingStateAnimation{
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    anim.toValue = @(M_PI * 2.0);
    anim.duration = 1;
    anim.cumulative = YES;
    anim.repeatCount = FLT_MAX;
    [self.playStateView.layer addAnimation:anim forKey:@"rotateAnimation"];
}

- (void)p_stopLoadingAnimation{
    [self.playStateView.layer removeAllAnimations];
}

- (void)clipButtonClick{
    ACCBLOCK_INVOKE(self.clipAction,self.musicModel);
}

- (void)confirmButtonClick{
    ACCBLOCK_INVOKE(self.confirmAction,self.musicModel);
}

- (void)deleteButtonClick{
    if (self.musicModel.isFromiTunes) {
        [ACCToast() show:@"本地音乐不支持删除"];
        return;
    }
    ACCBLOCK_INVOKE(self.deleteAction,self.musicModel);
}

- (void)renameButtonClick{
    if (self.musicModel.isFromiTunes) {
        [ACCToast() show:@"本地音乐不支持重命名"];
        return;
    }
    ACCBLOCK_INVOKE(self.renameAction,self.musicModel);
}

- (CGFloat)p_maxTitleLength{
    if (self.featureStatus == ACCSingleLocalMusicCellStatusShowEdit) {
        return ACC_SCREEN_WIDTH - 92 - 85;//管理状态下 播放不影响右边布局
    }
    if (self.playerStatus == ACCSingleLocalMusicCellStatusShowApply) {
        return ACC_SCREEN_WIDTH - 92 - 125;
    }
    return ACC_SCREEN_WIDTH - 92 - 16;
}

- (void)p_configDurationLabel:(id<ACCMusicModelProtocol>)model{
    NSNumber *musicDuration = model.duration;
    int integerDuration = roundf([musicDuration floatValue]);
    int second = integerDuration % 60;
    int minute = integerDuration / 60;
    NSString *timeString = [NSString stringWithFormat:@"%02d:%02d", minute, second];
    self.durationLabel.text = timeString;
}

- (void)setDisableClipButton:(BOOL)disableClipButton
{
    if (_disableClipButton != disableClipButton) {
        _disableClipButton = disableClipButton;
    }
}

#pragma mark - getter
- (UIImageView *)backMusicView{
    if (!_backMusicView) {
        UIImage *img = ACCResourceImage(@"background_music_mask");//兜底
        _backMusicView = [[UIImageView alloc] init];
        _backMusicView.contentMode = UIViewContentModeScaleAspectFill;
        _backMusicView.image = img;
        _backMusicView.layer.masksToBounds = YES;
        _backMusicView.layer.cornerRadius = 2.0;
    }
    return _backMusicView;
}

- (UIImageView *)playStateView {
    if (!_playStateView) {
        _playStateView = [[UIImageView alloc] init];
        _playStateView.contentMode = UIViewContentModeScaleAspectFill;
        _playStateView.image = ACCResourceImage(@"icon_play_music");
    }
    return _playStateView;
}

- (UILabel *)musicTitle{
    if (!_musicTitle) {
        _musicTitle = [[UILabel alloc] init];
        _musicTitle.font = [ACCFont() systemFontOfSize:15.0 weight:ACCFontWeightMedium];
        _musicTitle.textColor = ACCResourceColor(ACCColorTextReverse);
        _musicTitle.textAlignment = NSTextAlignmentLeft;
        _musicTitle.numberOfLines = 1;
        _musicTitle.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _musicTitle;
}

- (UILabel *)authorNameLabel{
    if (!_authorNameLabel) {
        _authorNameLabel = [[UILabel alloc] init];
        _authorNameLabel.font = [ACCFont() systemFontOfSize:13];
        _authorNameLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
        _authorNameLabel.textAlignment = NSTextAlignmentLeft;
        _authorNameLabel.numberOfLines = 1;
        _authorNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _authorNameLabel;
}

- (UILabel *)durationLabel{
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.font = [ACCFont() systemFontOfSize:13];
        _durationLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
        _durationLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _durationLabel;
}

- (UIButton *)clipButton{
    if (!_clipButton) {
        _clipButton = [[UIButton alloc] init];
        [_clipButton setImage:ACCResourceImage(@"icon_music_cut_black") forState:UIControlStateNormal];
        [_clipButton addTarget:self action:@selector(clipButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _clipButton;
}

- (UIButton *)confirmButton{
    if (!_confirmButton) {
        _confirmButton = [[UIButton alloc] init];
        _confirmButton.layer.cornerRadius = 2.0;
        _confirmButton.backgroundColor = ACCResourceColor(ACCColorPrimary);
        [_confirmButton addTarget:self action:@selector(confirmButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [_confirmButton setTitle:@"使用" forState:UIControlStateNormal];
        [_confirmButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
        _confirmButton.titleLabel.font = [ACCFont() systemFontOfSize:15.0 weight:ACCFontWeightMedium];
    }
    return _confirmButton;
}

- (UIButton *)deleteButton{
    if (!_deleteButton) {
        _deleteButton = [[UIButton alloc] init];
        [_deleteButton setImage:ACCResourceImage(@"icon_delete_local_music") forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(deleteButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

- (UIButton *)renameButton{
    if (!_renameButton) {
        _renameButton = [[UIButton alloc] init];
        [_renameButton setImage:ACCResourceImage(@"icon_edit_local_music") forState:UIControlStateNormal];
        [_renameButton addTarget:self action:@selector(renameButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _renameButton;
}

- (UIView *)featureContainView{
    if (!_featureContainView) {
        _featureContainView = [[UIView alloc] init];
        _featureContainView.backgroundColor = self.contentView.backgroundColor;
    }
    return _featureContainView;
}

@end
