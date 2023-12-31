//
//  AWEStickerContainerFakeProfileView.m
//  Pods
//
//  Created by resober on 2019/7/1.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEStickerContainerFakeProfileView.h"
#import <BDWebImage/UIImageView+BDWebImage.h>
#import <CreationKitArch/AWEAnimatedMusicCoverButton.h>
#import "AWEXScreenAdaptManager.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/ACCRTLProtocol.h>

static const CGFloat kAWEStickerContainerFakeProfileViewBottomViewHeight = 200.f;
static const CGFloat kAWEStickerContainerFakeProfileViewBottomContainerTopMargin = 85.0f;
@interface AWEStickerContainerFakeProfileView()
@property (nonatomic, strong) UIView *bottomContainerView;
@property (nonatomic, strong) UIView *rightContainerView;
@property (nonatomic, strong) AWEAnimatedMusicCoverButton *musicCoverButton;
@property (nonatomic, assign) BOOL ignoreRTL;
@end

@implementation AWEStickerContainerFakeProfileView

- (instancetype)initWithNeedIgnoreRTL:(BOOL)ignoreRTL {
    self = [super init];
    if (self) {
        _ignoreRTL = ignoreRTL;
        [self setupUI];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.userInteractionEnabled = NO;
    id<ACCUserModelProtocol> userModel = [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel];
    self.backgroundColor = [UIColor clearColor];
    /** ========== Bottom ========== */
    _bottomContainerView = [UIView new];
    [self addSubview:_bottomContainerView];
    _bottomContainerView.backgroundColor = [UIColor clearColor];
    _bottomContainerView.alpha = 0.5;
    ACCMasMaker(_bottomContainerView, {
        make.bottom.left.right.equalTo(self);
        make.height.equalTo(@(kAWEStickerContainerFakeProfileViewBottomViewHeight));
    });

    UILabel *inputLabel = [UILabel new];
    inputLabel.text = ACCLocalizedString(@"comment_hint", @"有爱评论，说点儿好听的~");
    inputLabel.textColor = [UIColor whiteColor];
    inputLabel.font = [UIFont systemFontOfSize:15.f];
    [_bottomContainerView addSubview:inputLabel];
    ACCMasMaker(inputLabel, {
        make.size.mas_equalTo(CGSizeMake(180.f, 18));
        if ([ACCRTL() enableRTL] && !self.ignoreRTL) {
            make.right.equalTo(self->_bottomContainerView).offset(-12.f);
        } else {
            make.left.equalTo(self->_bottomContainerView).offset(12.f);
        }
        make.bottom.equalTo(self->_bottomContainerView.mas_bottom).offset(-17);
    });

    UIImageView *emotionIcon = [UIImageView new];
    emotionIcon.backgroundColor = [UIColor clearColor];
    emotionIcon.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:1];
    [_bottomContainerView addSubview:emotionIcon];
    emotionIcon.image = [ACCResourceImage(@"iconMessageEmoji") imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    ACCMasMaker(emotionIcon, {
        if ([ACCRTL() enableRTL] && !self.ignoreRTL) {
            make.left.equalTo(self->_bottomContainerView).offset(17.f);
        } else {
            make.right.equalTo(self->_bottomContainerView.mas_right).offset(-17.f);
        }
        make.bottom.equalTo(self->_bottomContainerView.mas_bottom).offset(-15.f);
        make.size.mas_equalTo(CGSizeMake(22.f, 22.f));
    });

    UIImageView *atIcon = [UIImageView new];
    atIcon.backgroundColor = [UIColor clearColor];
    atIcon.image = ACCResourceImage(@"iconMessageAtWhite");
    [_bottomContainerView addSubview:atIcon];
    ACCMasMaker(atIcon, {
        if ([ACCRTL() enableRTL] && !self.ignoreRTL) {
            make.left.equalTo(emotionIcon.mas_right).offset(21.8);
        } else {
            make.right.equalTo(emotionIcon.mas_left).offset(-21.8);
        }
        make.bottom.equalTo(self->_bottomContainerView.mas_bottom).offset(-15.f);
        make.size.mas_equalTo(CGSizeMake(22.2, 22.f));
    });

    UIView *horizontalLine = [UIView new];
    [_bottomContainerView addSubview:horizontalLine];
    horizontalLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    ACCMasMaker(horizontalLine, {
        make.width.equalTo(self->_bottomContainerView);
        make.height.equalTo(@(0.5f));
        make.left.equalTo(self->_bottomContainerView);
        make.bottom.equalTo(self->_bottomContainerView).offset(-51.5);
    });

    UIImageView *musicIcon = [UIImageView new];
    musicIcon.backgroundColor = [UIColor clearColor];
    musicIcon.image = ACCResourceImage(@"icon_music_info_logo");
    [_bottomContainerView addSubview:musicIcon];
    musicIcon.alpha = 0.5;
    ACCMasMaker(musicIcon, {
        if ([ACCRTL() enableRTL] && !self.ignoreRTL) {
            make.right.equalTo(_bottomContainerView).offset(-9.5);
        } else {
            make.left.equalTo(@9.5);
        }
        make.bottom.equalTo(horizontalLine.mas_top).offset(-17.f);
        make.size.mas_equalTo(CGSizeMake(9, 10.5));
    });

    UILabel *musicLabel = [UILabel new];
    NSString *userName = nil;
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin] && userModel) {
        // m 用户名与登陆用户名一致 dt 用户昵称与登陆昵称一致
        userName = userModel.socialName;
    } else {
        userName = ACCLocalizedString(@"com_mig_musically", @"抖音");
    }
    musicLabel.text = [NSString stringWithFormat:@"@%@%@", userName, ACCLocalizedString(@"com_mig_original_music", @"的原创音乐")];
    musicLabel.textColor = [UIColor whiteColor];
    musicLabel.font = [UIFont systemFontOfSize:15.f];
    [_bottomContainerView addSubview:musicLabel];
    ACCMasMaker(musicLabel, {
        make.size.mas_equalTo(CGSizeMake(260.f, 21));
        if ([ACCRTL() enableRTL] && !self.ignoreRTL) {
            make.right.equalTo(musicIcon.mas_left).offset(-4.5);
        } else {
            make.left.equalTo(musicIcon.mas_right).offset(4.5);
        }
        make.bottom.equalTo(self->_bottomContainerView.mas_bottom).offset(-64);
    });

    UILabel *userNameLabel = [UILabel new];
    userNameLabel.text = [NSString stringWithFormat:@"@%@", userName];
    userNameLabel.textColor = [UIColor whiteColor];
    userNameLabel.font = [UIFont systemFontOfSize:18.f];
    [_bottomContainerView addSubview:userNameLabel];
    ACCMasMaker(userNameLabel, {
        make.size.mas_equalTo(CGSizeMake(260.f, 25));
        if ([ACCRTL() enableRTL] && !self.ignoreRTL) {
            make.right.equalTo(self->_bottomContainerView).offset(-8);
        } else {
            make.left.equalTo(self->_bottomContainerView).offset(8);
        }
        make.bottom.equalTo(musicLabel.mas_top).offset(-5);
        make.top.mas_greaterThanOrEqualTo(kAWEStickerContainerFakeProfileViewBottomContainerTopMargin);
    });

    AWEAnimatedMusicCoverButton *musicCoverButton = [AWEAnimatedMusicCoverButton new];
    musicCoverButton.ownerImageWidth = 27.f;
    [_bottomContainerView addSubview:musicCoverButton];
    ACCMasMaker(musicCoverButton, {
        make.size.mas_equalTo(CGSizeMake(48.9, 49.f));
        if ([ACCRTL() enableRTL] && !self.ignoreRTL) {
            make.left.equalTo(self->_bottomContainerView).offset(6.f);
        } else {
            make.right.equalTo(self->_bottomContainerView).offset(-6.f);
        }
        make.bottom.equalTo(self->_bottomContainerView).offset(-65.f);
    });
    self.musicCoverButton = musicCoverButton;
    musicCoverButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    musicCoverButton.layer.cornerRadius = 49.f / 2;
    musicCoverButton.layer.masksToBounds = YES;

    /** ========== Right ========== */

    _rightContainerView = [UIView new];
    [self addSubview:_rightContainerView];
    _rightContainerView.backgroundColor = [UIColor clearColor];
    _rightContainerView.alpha = 0.5;
    ACCMasMaker(_rightContainerView, {
        if ([ACCRTL() enableRTL] && !self.ignoreRTL) {
            make.bottom.height.equalTo(self);
            make.left.equalTo(self.mas_left).offset(6);
        } else {
            make.bottom.height.right.equalTo(self);
        }
        make.width.equalTo(@56.f);
    });

    UILabel *commentCountLabel = [UILabel new];
    commentCountLabel.text = @"0";
    commentCountLabel.textColor = [UIColor whiteColor];
    commentCountLabel.font = [UIFont systemFontOfSize:12.f];
    [_rightContainerView addSubview:commentCountLabel];
    ACCMasMaker(commentCountLabel, {
        make.size.mas_equalTo(CGSizeMake(7.5, 16.5));
        make.right.equalTo(self->_rightContainerView).offset(-25.5);
        make.bottom.equalTo(musicIcon.mas_top).offset(-109);
    });

    UIImageView *commentIcon = [UIImageView new];
    commentIcon.backgroundColor = [UIColor clearColor];
    commentIcon.image = ACCResourceImage(@"iconHomeComment");
    [_rightContainerView addSubview:commentIcon];
    ACCMasMaker(commentIcon, {
        make.right.equalTo(self->_rightContainerView).offset(-13.f);
        make.bottom.equalTo(commentCountLabel.mas_top).offset(-6.2);
        make.size.mas_equalTo(CGSizeMake(34.5, 33.3));
    });

    UIImageView *moreIcon = [UIImageView new];
    moreIcon.backgroundColor = [UIColor clearColor];
    moreIcon.image = ACCResourceImage(@"iconHomeShare");
    [_rightContainerView addSubview:moreIcon];
    ACCMasMaker(moreIcon, {
        make.right.equalTo(self->_rightContainerView).offset(-10.f);
        make.top.equalTo(commentCountLabel.mas_bottom).offset(12);
        make.size.mas_equalTo(CGSizeMake(40.f, 38.f));
    });


    UILabel *likeCountLabel = [UILabel new];
    likeCountLabel.text = @"0";
    likeCountLabel.textColor = [UIColor whiteColor];
    likeCountLabel.font = [UIFont systemFontOfSize:12.f];
    [_rightContainerView addSubview:likeCountLabel];
    ACCMasMaker(likeCountLabel, {
        make.size.mas_equalTo(CGSizeMake(7.5, 16.5));
        make.right.equalTo(self->_rightContainerView).offset(-25.5);
        make.bottom.equalTo(commentIcon.mas_top).offset(-22.5);
    });

    UIImageView *likeIcon = [UIImageView new];
    likeIcon.backgroundColor = [UIColor clearColor];
    likeIcon.image = ACCResourceImage(@"iconHomeLikeBefore");
    [_rightContainerView addSubview:likeIcon];
    ACCMasMaker(likeIcon, {
        make.right.equalTo(self->_rightContainerView).offset(-12.3);
        make.bottom.equalTo(likeCountLabel.mas_top).offset(-4.5);
        make.size.mas_equalTo(CGSizeMake(35.3, 32.3));
    });

    UIImageView *userAvatarImageView = [UIImageView new];
    userAvatarImageView.backgroundColor = [UIColor clearColor];
    userAvatarImageView.image = nil; // TODO: 用户头像
    userAvatarImageView.layer.masksToBounds = YES;
    userAvatarImageView.layer.cornerRadius = 49.f / 2;
    userAvatarImageView.layer.borderWidth = 1;
    userAvatarImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    [_rightContainerView addSubview:userAvatarImageView];
    ACCMasMaker(userAvatarImageView, {
        make.right.equalTo(self->_rightContainerView).offset(-6);
        make.bottom.equalTo(likeIcon.mas_top).offset(-27.f);
        make.size.mas_equalTo(CGSizeMake(49.f, 49.f));
    });
    UIImage *avatarPlaceholder = ACCResourceImage(@"watermark_profile");
    [userAvatarImageView bd_setImageWithURLs:userModel.avatarThumb.URLList ?: @[] placeholder:avatarPlaceholder options:BDImageRequestNotCacheToDisk transformer:nil progress:NULL completion:NULL];

    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        inputLabel.hidden = YES;
        atIcon.hidden = YES;
        emotionIcon.hidden = YES;
        horizontalLine.hidden = YES;
    }

    UIImage *imageCoverPlaceholder = ACCResourceImage(@"ic_camera_edit_addmusic");
    self.musicCoverButton.ownerImageView.image = imageCoverPlaceholder;
}

- (void)updateMusicCoverWithMusicModel:(id<ACCMusicModelProtocol>)model {
    if (model) {
        [self.musicCoverButton refreshWithMusic:model defaultAvatarURL:nil];
    } else {
        UIImage *imageCoverPlaceholder = ACCResourceImage(@"ic_camera_edit_addmusic");
        self.musicCoverButton.ownerImageView.image = imageCoverPlaceholder;
    }
}
- (CGFloat)bottomContainerTopMargin
{
    return kAWEStickerContainerFakeProfileViewBottomContainerTopMargin;
}

@end

