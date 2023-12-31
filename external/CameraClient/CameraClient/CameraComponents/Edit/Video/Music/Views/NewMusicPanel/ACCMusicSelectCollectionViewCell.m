//
//  ACCMusicSelectCollectionViewCell.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/7/5.
//

#import "ACCMusicSelectCollectionViewCell.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitArch/AWEScrollStringLabel.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/ACCI18NConfigProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+ACCAdditions.h>
#import <CreativeKit/ACCFontProtocol.h>

@interface ACCMusicSelectCollectionViewCell ()

@property (nonatomic, copy) NSString *musicName;
@property (nonatomic, strong) AWEScrollStringLabel *scrollSrtingLabel;
@property (nonatomic, strong) CAGradientLayer *fadeLayer;

@property (nonatomic, strong) UIButton *lyricStickerButton;//添加歌词贴纸按钮
@property (nonatomic, strong) UIButton *clipButton;  // 裁减按钮
@property (nonatomic, strong) UIButton *favoriteButton;   // 收藏按钮

@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIView *dotView;
@property (nonatomic, strong) UIView *line;

@property (nonatomic, assign) BOOL hasRemarkDowningIncon;
@property (nonatomic, assign) BOOL isCurrent;

@end

@implementation ACCMusicSelectCollectionViewCell

@synthesize useBigLoadingIcon = _useBigLoadingIcon;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupOptimization];
    }
    return self;
}

- (void)setupOptimization {
    self.contentView.backgroundColor = ACCResourceColor(ACCColorBGReverse);
    
    self.titleLabelColor = ACCResourceColor(ACCColorTextReverse);
    [self.recommendedImageView removeFromSuperview];
    [self.musicItemView removeFromSuperview];

    self.musicItemView = [[AWEPhotoMovieMusicItemView alloc] initWithRectangleImageSize:CGSizeMake(48, 48) circleViewOffset:3 radius:4.f];
    self.musicItemView.isAccessibilityElement = YES;
    [self.musicItemView setMusicBackgroundColor:ACCResourceColor(ACCColorBGInputReverse)];
    [self.musicItemView addSubview:self.recommendedImageView];
    [self insertSubview:self.musicItemView belowSubview:self.downloadIcon];
    [self.loadingIcon removeFromSuperview];
    [self insertSubview:self.loadingIcon aboveSubview:self.musicItemView];
    self.musicItemView.userInteractionEnabled = NO;
    
    ACCMasUpdate(self.musicItemView, {
        make.centerY.equalTo(self);
        make.left.equalTo(@16);
        make.width.height.equalTo(@51);
    });
    
    ACCMasUpdate(self.recommendedImageView, {
        make.left.top.equalTo(self.musicItemView);
        make.width.equalTo(@26);
        make.height.equalTo(@26);
    });
    
    // 下载状态
    ACCMasReMaker(self.downloadIcon, {
        make.center.equalTo(self.musicItemView);
        make.width.height.equalTo(@15);
    });
    
    ACCMasReMaker(self.loadingIcon, {
        make.center.equalTo(self.musicItemView);
        make.width.height.equalTo(@15);
    });
    
    self.recommendedImageView.image = [self photoMusicEditorRecommendedImage];

    CGFloat cellWidth = self.frame.size.width;
    CGFloat cellHeight = self.frame.size.height;
    self.favoriteButton = ({
        UIButton *favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        favoriteButton.frame = CGRectMake(cellWidth - 54, 0, 44, cellHeight);
        [self.contentView addSubview:favoriteButton];
        UIImage *defaultImage = [ACCResourceImage(@"ic_favorite_unselected") acc_ImageWithTintColor:ACCResourceColor(ACCColorTextReverse)];
        [favoriteButton setImage:defaultImage forState:UIControlStateNormal];
        [favoriteButton setImage:ACCResourceImage(@"ic_favorite_selected") forState:UIControlStateSelected];
        [favoriteButton addTarget:self action:@selector(toggleFavorite:) forControlEvents:UIControlEventTouchUpInside];
        favoriteButton.hidden = YES;
        favoriteButton.isAccessibilityElement = YES;
        favoriteButton.accessibilityLabel = @"收藏";
        favoriteButton;
    });
    
    self.clipButton = ({
        UIButton *clipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.contentView addSubview:clipButton];
        clipButton.frame = CGRectMake(cellWidth - 98, 0, 44, cellHeight);
        UIImage *img = ACCResourceImage(@"iconCameraMusicclip-1");
        img = [img acc_ImageWithTintColor:ACCResourceColor(ACCColorTextReverse)];
        [clipButton setImage:img forState:UIControlStateNormal];
        [clipButton addTarget:self action:@selector(clipMusic:) forControlEvents:UIControlEventTouchUpInside];
        clipButton.hidden = YES;
        clipButton.isAccessibilityElement = YES;
        clipButton.accessibilityLabel = @"裁剪音乐";
        clipButton;
    });
    
    self.lyricStickerButton = ({
        UIButton *lyricStickerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.contentView addSubview:lyricStickerButton];
        lyricStickerButton.frame = CGRectMake(cellWidth - 142, 0, 44, cellHeight);
        UIImage *defaultImage = [ACCResourceImage(@"ic_music_lyrics_default") acc_ImageWithTintColor:ACCResourceColor(ACCColorTextReverse)];
        [lyricStickerButton setImage:defaultImage forState:UIControlStateNormal];
        [lyricStickerButton setImage:ACCResourceImage(@"ic_music_lyrics_highlight") forState:UIControlStateSelected];
        [lyricStickerButton addTarget:self action:@selector(toggleLyricSticker:) forControlEvents:UIControlEventTouchUpInside];
        lyricStickerButton.hidden = YES;
        lyricStickerButton.isAccessibilityElement = YES;
        lyricStickerButton.accessibilityLabel = @"歌词贴纸";
        lyricStickerButton;
    });
    
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
    ACCMasReMaker(self.titleLabel, {
        make.left.offset(80);
        make.top.equalTo(@11);
        make.width.equalTo(@(cellWidth - 80 - 142));
        make.height.equalTo(@22);
    });
    
    self.authorLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular];
        label.textColor = ACCResourceColor(ACCColorTextReverse3);
        label.textAlignment = NSTextAlignmentLeft;
        CGFloat maxWidth = cellWidth - 80 - 142 - 14 - 32;
        label.frame = CGRectMake(80, 35, maxWidth, 16);
        [self addSubview:label];
        label;
    });
    
    self.dotView = ({
        CGRect frame = self.authorLabel.frame;
        UIView *dotView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(frame) + 6, 42, 2, 2)];
        dotView.layer.cornerRadius = 1.0;
        dotView.backgroundColor = ACCResourceColor(ACCColorTextReverse3);
        [self addSubview:dotView];
        dotView;
    });
        
    self.durationLabel = ({
        CGRect frame = self.dotView.frame;
        UILabel *label = [[UILabel alloc] init];
        label.minimumScaleFactor = 0.8;
        label.adjustsFontSizeToFitWidth = YES;
        label.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular];
        label.textColor = ACCResourceColor(ACCColorTextReverse3);
        label.frame = CGRectMake(CGRectGetMaxX(frame) + 6, 35, 32, 16);
        [self addSubview:label];
        label;
    });
    
    self.line = ({
        CGFloat scale = [UIScreen mainScreen].scale;
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(80, cellHeight - 1/scale, cellWidth - 80, 1/scale)];
        line.backgroundColor = ACCResourceColor(ACCColorLineReverse2);
        [self addSubview:line];
        line;
    });
}

#pragma mark - public

- (void)updateMusicName:(NSString *)musicName author:(NSString *)author  isPGC:(BOOL)isPgc matchedPGCTitle:(NSString *)pgcTitle {
    [self updateText:musicName];
    _musicName = musicName;
    self.musicItemView.accessibilityLabel = musicName;
    NSString *authorString = author;
    if (!isPgc && !ACC_isEmptyString(pgcTitle)) {
        // 原声音乐中，使用UGC音乐
        authorString = [NSString stringWithFormat:@"%@", pgcTitle];
    }
    self.authorLabel.text = authorString;
}

- (void)updateLyricStickerButtonStatus:(UIButton *)button {
    if (!button || !self.isCurrent) {
        self.lyricStickerButton.hidden = YES;
        self.lyricStickerButton.selected = NO;
        self.lyricStickerButton.enabled = NO;
        return;
    }
    self.lyricStickerButton.enabled = button.isEnabled;
    self.lyricStickerButton.selected = button.isSelected;
    self.lyricStickerButton.hidden = button.isHidden;
    
    [self updateLyricStickerButtonFrame];
}

- (void)updateClipButtonStatus:(UIButton *)button {
    if (!button || !self.isCurrent) {
        self.clipButton.hidden = YES;
        self.clipButton.selected = NO;
        self.clipButton.enabled = NO;
        return;
    }
    if (!button.isEnabled) {
        // 新面板裁减状态不可用不进行常驻
        self.clipButton.hidden = YES;
    } else {
        self.clipButton.enabled = button.isEnabled;
        self.clipButton.selected = button.isSelected;
        self.clipButton.hidden = button.isHidden;
    }
    
    [self updateLyricStickerButtonFrame];
}

- (void)updateFavoriteButtonStatus:(UIButton *)button {
    if (!button || !self.isCurrent) {
        self.favoriteButton.hidden = YES;
        self.favoriteButton.enabled = NO;
        self.favoriteButton.selected = NO;
        return;
    }
    self.favoriteButton.enabled = button.isEnabled;
    self.favoriteButton.selected = button.isSelected;
    self.favoriteButton.hidden = button.isHidden;
}

- (void)updateLyricStickerButtonFrame {
    CGRect frame = self.lyricStickerButton.frame;
    CGFloat cellWidth = self.frame.size.width;
    if (self.clipButton.hidden) {
        frame.origin.x = cellWidth - 98;
    } else {
        frame.origin.x = cellWidth - 142;
    }
    self.lyricStickerButton.frame = frame;
}

#pragma mark - overwrite

- (void)setUseBigLoadingIcon:(BOOL)useBigLoadingIcon
{
    //  需要重新实现，remake太频繁
    _useBigLoadingIcon = useBigLoadingIcon;
    
    if (useBigLoadingIcon) {
        if (!self.hasRemarkDowningIncon) {
            self.hasRemarkDowningIncon = YES;
            self.loadingIcon.image = ACCResourceImage(@"iconMusicLoading_ai");
            ACCMasReMaker(self.loadingIcon, {
                make.center.equalTo(self.musicItemView);
                make.width.height.equalTo(@16);
            });
        }
    } else {
        self.hasRemarkDowningIncon = NO;
        self.loadingIcon.image = ACCResourceImage(@"iconDownloadingMusic");
        ACCMasReMaker(self.loadingIcon, {
            make.right.equalTo(self.musicItemView.mas_right).offset(-4);
            make.bottom.equalTo(self.musicItemView.mas_bottom).offset(-4);
            make.width.height.equalTo(@15);
        });
    }
}

- (void)setIsCurrent:(BOOL)isCurrent animated:(BOOL)animated {
    [super setIsCurrent:isCurrent animated:animated];
    self.isCurrent = isCurrent;
}

- (void)setIsCurrent:(BOOL)isCurrent animated:(BOOL)animated completion:(void (^ __nullable)(BOOL))completion needForceUpdate:(BOOL)forceUpdate {
    [self setIsCurrent:isCurrent animated:animated completion:completion];
    if (isCurrent) {
        if ([self.delegate respondsToSelector:@selector(updateCellActionStatus:)] && forceUpdate) {
            [self.delegate updateCellActionStatus:self];
        }
    }
}

- (void)setIsCurrent:(BOOL)isCurrent animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    [super setIsCurrent:isCurrent animated:animated completion:completion];
    self.isCurrent = isCurrent;
    if (!isCurrent) {
        self.lyricStickerButton.hidden = YES;
        self.clipButton.hidden = YES;
        self.favoriteButton.hidden = YES;
    }
    [self updateTitleAndAuthorLabelWithIsCurrentSelected:isCurrent];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        self.contentView.backgroundColor = ACCResourceColor(ACCColorBGInputReverse);
    } else {
        self.contentView.backgroundColor = ACCResourceColor(ACCColorBGReverse);
    }
}

- (void)setDuration:(NSTimeInterval)duration show:(BOOL)show {
    [super setDuration:duration show:NO];
    self.durationLabel.text = [self p_timeStringWithDuration:duration];
}

- (UIImage *)photoMusicEditorRecommendedImage
{
    if (![[ACCI18NConfig() currentLanguage] containsString:@"zh"]) {
        return ACCResourceImage(@"icon_mv_recommended_thumb");
    } else {
        return ACCResourceImage(@"icon_mv_recommended");
    }
}

#pragma mark - private

- (void)updateTitleAndAuthorLabelWithIsCurrentSelected:(BOOL)isCurrent {
    CGFloat cellWidth = self.frame.size.width;
    CGFloat maxWidth = 0;
    if (isCurrent) {
        ACCMasUpdate(self.titleLabel, {
            make.width.equalTo(@(cellWidth - 80 - 142));
        });
        maxWidth = cellWidth - 80 - 142 - 14 - 32;
    } else {
        ACCMasUpdate(self.titleLabel, {
            make.width.equalTo(@(cellWidth - 80 - 16));
        });
        maxWidth = cellWidth - 80 - 14 - 32 - 16;
    }
    
    NSString *authorString = self.authorLabel.text;
    CGSize authorSize = [authorString sizeWithAttributes:@{NSFontAttributeName : [ACCFont() systemFontOfSize:12 weight:ACCFontWeightRegular]}];
    if (authorSize.width <= maxWidth) {
        maxWidth = authorSize.width;
    }
    CGRect authorFrame = self.authorLabel.frame;
    authorFrame.size.width = maxWidth;
    self.authorLabel.frame = authorFrame;
    
    CGRect dotFrame = self.dotView.frame;
    dotFrame.origin.x = CGRectGetMaxX(authorFrame) + 6;
    self.dotView.frame = dotFrame;
    
    CGRect durationFrame = self.durationLabel.frame;
    durationFrame.origin.x = CGRectGetMaxX(dotFrame) + 6;
    self.durationLabel.frame = durationFrame;
}

- (NSString *)p_timeStringWithDuration:(NSTimeInterval)duration
{
    NSInteger seconds = (NSInteger)duration;
    NSInteger second = seconds % 60;
    NSInteger minute = seconds / 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minute, (long)second];
}

#pragma mark - action

- (void)toggleFavorite:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(cellFavoriteButtonTapped:)]) {
        [self.delegate cellFavoriteButtonTapped:sender];
    }
}

- (void)clipMusic:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(cellClipMusicButtonTapped:)]) {
        [self.delegate cellClipMusicButtonTapped:sender];
    }
}

- (void)toggleLyricSticker:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(cellToggleLyricStickerTapped:)]) {
        [self.delegate cellToggleLyricStickerTapped:sender];
    }
}

@end
