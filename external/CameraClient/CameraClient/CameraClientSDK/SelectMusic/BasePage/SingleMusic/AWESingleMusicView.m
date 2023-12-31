//
//  AWESingleMusicView.m
//  CameraClient
//
//  Created by 李彦松 on 2018/9/7.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWESingleMusicView.h"
#import "AWESingleMusicView+Private.h"
#import "AWEMusicTitleControl.h"
#import "ACCSelectMusicViewControllerProtocol.h"
#import "ACCAudioMusicServiceProtocol.h"
#import "ACCMusicEnumDefines.h"
#import "ACCMusicFontProtocol.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitInfra/ACCConfigManager.h>

#import <CameraClient/ACCCollectionButton.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

static const CGFloat kMusicTagContentHeight = 14;
static const CGFloat kAuthorNamelabelLineHeight = 16.f;

static NSString * const AWEMusicDidChangeFavoriteStatusNotification = @"AWEMusicDidChangeFavoriteStatusNotification";

static const CGFloat kAuthorNameLabelToCoverInset = 12.f;
static const CGFloat kAuthorNameLabelToActionViewInset = 12.f;
static const CGFloat LogoImageSize = 64.f;
static const CGFloat kActionViewSize = 24.f;

static const NSLineBreakMode kAuthorNameLabelPGCStyleLineBreakMode = NSLineBreakByWordWrapping;

#define kAuthorNameLabelFont ([MusicFont() systemFontOfSize:13])
#define kAuthorNameLabelHeight (MusicFontScale() * kAuthorNamelabelLineHeight)

#define kAWESocialShowSongEntranceTypeDefault 0

#define kLogoImageSize (MusicFontScale() * LogoImageSize)

@implementation AWESingleMusicTitleView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.songTagLabel.targetLabel];
    [self addSubview:self.titleLabel];
    
    ACCMasMaker(self.songTagLabel.targetLabel, {
        make.centerY.right.equalTo(self);
    });
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [MusicFont() systemFontOfSize:15 weight:UIFontWeightSemibold];
        [_titleLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                       forAxis:UILayoutConstraintAxisHorizontal];
        [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                     forAxis:UILayoutConstraintAxisHorizontal];
        [ACCLanguage() disableLocalizationsOfObj:_titleLabel];
    }
    return _titleLabel;
}

- (id<ACCInsetsLabelProtocol>)songTagLabel {
    if(!_songTagLabel) {
        
        // copy from: MusicPlaySongTagLabel
        id<ACCInsetsLabelProtocol> label = [IESAutoInline(ACCBaseServiceProvider(), ACCSelectMusicViewControllerBuilderProtocol) createInsetsLabel];
        [label.targetLabel setContentHuggingPriority:UILayoutPriorityRequired
                                 forAxis:UILayoutConstraintAxisHorizontal];
        [label.targetLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                               forAxis:UILayoutConstraintAxisHorizontal];
        
        
        label.targetLabel.backgroundColor = ACCResourceColor(ACCColorPrimary);
        label.targetLabel.font = [MusicFont() systemFontOfSize:10 weight:UIFontWeightRegular];
        label.targetLabel.textColor = ACCResourceColor(ACCColorConstTextInverse2);
        label.targetLabel.layer.cornerRadius = 2;
        label.targetLabel.clipsToBounds = YES;
        label.targetLabel.textAlignment = NSTextAlignmentCenter;
        [label setEdgeInsets:UIEdgeInsetsMake(3, 5, 3, 5)];
        
        [label.targetLabel setText:ACCLocalizedString(@"full_song", @"全曲")];
        // copy from: MusicPlaySongTagLabel end---
        
        _songTagLabel = label;
    }
    
    return _songTagLabel;
}

- (void)setIsEliteVersion:(BOOL)isEliteVersion
{
    _isEliteVersion = isEliteVersion;
    if (isEliteVersion) {
        self.titleLabel.textColor = ACCResourceColor(ACCColorTextPrimary);
    } else {
        self.titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    ACCMasReMaker(self.titleLabel, {
        make.top.left.bottom.equalTo(self);
        if (self.songTagLabel.targetLabel.isHidden) {
            make.right.equalTo(self);
        } else {
            make.right.equalTo(self.songTagLabel.targetLabel.mas_left).offset(-4);
        }
    });
}

@end

@implementation AWESingleMusicView

- (instancetype)initWithEnableSongTag:(BOOL)enable; {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _enableSongTag = enable;
        _currentStatus = AWESingleMusicViewLayoutStatusNormal;
        [self setupUI];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleFavoriteStatusChangedNotification:)
                                                     name:AWEMusicDidChangeFavoriteStatusNotification
                                                   object:nil];
        self.shouldGroupAccessibilityChildren = YES;
        self.accessibilityElements = @[self.logoView, self.collectionButton];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithEnableSongTag:NO];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [ACCAudioMusicService() removeObserver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    //[self.applyButton btd_setBackgroundColor:[AWEUIColor constColorWithName:AWEUIColorPrimary]
                                    //forState:UIControlStateNormal];
    CGRect logoFrame = self.logoView.frame;
    CGFloat collectionButtonX = self.collectionButton.frame.origin.x;
    // 如果显示了挑战icon，判断的distance需要变化，因为有了icon, songNameView的constraint会让它最小有18的宽度
    // (4: paddin + 14: icon width)，加上collection button left padding(32) 加上 songNameView自己的左padding(12)
    // 会超过60，所以永远也不会隐藏songNameView
    CGFloat thresDistance = [self shouldShowSongTag] ? 70 : 60 ;
    if (collectionButtonX - logoFrame.origin.x - logoFrame.size.width < thresDistance) {
        [self transformToStatus:AWESingleMusicViewLayoutStatusNormalHideLabel animated:YES];
    }
}

#pragma mark - Public

- (void)switchToDarkBackgroundMode
{
    self.songNameView.titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    self.authorNameLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse4);
    self.durationLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse4);
    [self.collectionButton setImage:ACCResourceImage(@"icon_white_collection") forState:UIControlStateNormal];
    [self.clipButton setImage:ACCResourceImage(@"iconCameraMusicclip-1") forState:UIControlStateNormal];
}

- (void)setShowMoreButton:(BOOL)showMoreButton
{
    if (_showMoreButton == showMoreButton) {
        return;
    }
    _showMoreButton = showMoreButton;
    [self adjustUI];
}

- (void)setNeedShowPGCMusicInfo:(BOOL)needShowPGCMusicInfo {
    if (needShowPGCMusicInfo == _needShowPGCMusicInfo) {
        return;
    }
    _needShowPGCMusicInfo = needShowPGCMusicInfo;
    [self adjustUI];
}

- (void)setShowClipButton:(BOOL)showClipButton
{
    if (_showClipButton != showClipButton) {
        _showClipButton = showClipButton;
    }
}

- (UIImage *)logoPlaceholderImage
{
    if (!_logoPlaceholderImage) {
        _logoPlaceholderImage = ACCResourceImage(@"bg_musiclist_img");
    }
    return _logoPlaceholderImage;
}

- (UIImage *)originalMusicMusiCianIcon
{
    if (!_originalMusicMusiCianIcon) {
        _originalMusicMusiCianIcon = [UIImage imageNamed:@"icon_original_musican"];
    }
    return _originalMusicMusiCianIcon;
}

#pragma mark - UI Reload

#pragma mark Public

- (void)configWithMusicModel:(id<ACCMusicModelProtocol>)model {
    [self configWithMusicModel:model rank:NSNotFound];
}

- (void)configWithMusicModel:(id<ACCMusicModelProtocol>)model rank:(NSInteger)rank
{
    self.musicModel = model;
	///=======================================================================================
    // @description: 添加ALog定位`musicName`为空时，对应的`musicModel`是否为空
    // @date: 2021/May/7
    // @slardar: https://slardar.bytedance.net/node/app_detail/?aid=1128&os=iOS&region=cn&lang=zh#/abnormal/detail/exception/1128_313ad27b8f3002ae8262730225f0ca94Exception
    // @author: yuanxin.07@bytedance.com
    if(!model.musicName){
        AWELogToolError(AWELogToolTagMusic, @"musicName is nil, musicModel: %@", model);
    }
    //=======================================================================================
    [self configTitleLabelWithMusicName:[model musicName]];
    [self configAuthorNameLabelWithModel:model];
    [self configLyricsLabelWithModel:model];
    [self configMusicTagContentViewWithModel:model];
    self.collectionButton.selected = (model.collectStat.integerValue == 1);
    self.collectionButton.accessibilityLabel = (model.collectStat.integerValue == 1) ? @"取消收藏" : @"收藏";
    [self configRankeImageWithRank:rank];
    [self configLogoViewWithModel:model];
    [self configDurationLabelWithModel:model];
}

#pragma mark Internal

- (void)configLogoViewWithModel:(id<ACCMusicModelProtocol>)model
{
    NSArray *coverURLArray = model.mediumURL.URLList ?: model.thumbURL.URLList;
    [ACCWebImage() imageView:self.logoView
        setImageWithURLArray:coverURLArray
                 placeholder:ACCConfigBool(kConfigBool_enable_music_selected_page_render_optims) ? self.logoPlaceholderImage : ACCResourceImage(@"bg_musiclist_img")
                     options: ACCWebImageOptionsSetImageWithFadeAnimation | ACCWebImageOptionsDefaultOptions
                  completion:nil];
}

- (void)configTitleLabelWithMusicName:(NSString *)musicName
{
    if (musicName == nil) {
        return;
    }
    NSMutableAttributedString *mutAttrStr = [[NSMutableAttributedString alloc] initWithString:musicName];
    if ([self.musicModel.externalMusicModelArray.firstObject.thirdPlatformName isEqualToString:@"awa"]) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = ACCResourceImage(@"icon_select_music_tag_AWA");
        NSAttributedString *imageAttrStr = [NSAttributedString attributedStringWithAttachment:attachment];
        [mutAttrStr appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        [mutAttrStr appendAttributedString:imageAttrStr];
        self.songNameView.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    } else {
        self.songNameView.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    if (self.musicModel.isOriginal) {
        NSTextAttachment *originalAttachment = [[NSTextAttachment alloc] init];
        originalAttachment.image = ACCConfigBool(kConfigBool_enable_music_selected_page_render_optims) ? self.originalMusicMusiCianIcon : [UIImage imageNamed:@"icon_original_musican"];
        originalAttachment.bounds = CGRectMake(0, -2, 16, 16);
        NSAttributedString *originalAttachmentStr = [NSAttributedString attributedStringWithAttachment:originalAttachment];
        [mutAttrStr insertAttributedString:originalAttachmentStr atIndex:0];
    }
    self.songNameView.titleLabel.attributedText = [mutAttrStr copy];
    [self.songNameView.songTagLabel.targetLabel setHidden:![self shouldShowSongTag]];
}

- (void)configRankeImageWithRank:(NSInteger)rank
{
    if (rank == NSNotFound || rank >= 12)  {
        self.rankImageView.hidden = YES;
    } else {
        self.rankImageView.hidden = NO;
        // TODO(liyansong): 确定icon的使用
        NSString *imageName;
        if (rank < 12) {
            imageName = [NSString stringWithFormat:@"img_top_%ld", (long)rank+1];
            self.rankImageView.image = ACCResourceImage(imageName);
        }
        ACCMasReMaker(self.rankImageView, {
            BOOL largeRank = rank < 3;
            CGFloat leftPadding = largeRank ? -2 : 0;
            CGFloat topPadding = largeRank ? -2 : 0;
            CGFloat height = largeRank ? 15 : 12;
            CGFloat width = largeRank ? 28 : 18;
            make.leading.equalTo(self.logoView).offset(leftPadding);
            make.top.equalTo(self.logoView).offset(topPadding);
            make.width.equalTo(@(width));
            make.height.equalTo(@(height));
        });
    }
}

- (UIColor *)lyricsLabelHighlightColor
{
    return [UIColor colorWithRed:22.0f / 255.0f green:24.0f / 255.0f blue:35.0f / 255.0f alpha:0.9f];
}

- (UIColor *)lyricsLabelNormalColor
{
    return [UIColor colorWithRed:22.0f / 255.0f green:24.0f / 255.0f blue:35.0f / 255.0f alpha:0.5f];
}

- (void)configLyricsLabelWithModel:(id<ACCMusicModelProtocol>)model
{
    BOOL hasLyric = self.showLyricLabel && model.shortLyric.length > 0;
    if (hasLyric) {
        if (!self.lyricLabel.superview) {
            [self addSubview:self.lyricLabel];
            ACCMasMaker(self.lyricLabel, {
                make.top.equalTo(self.logoView.mas_bottom).offset(10.5);
                make.leading.equalTo(self.songNameView);
                make.bottom.equalTo(self).offset(-13.5);
                make.trailing.equalTo(self);
            });
        }

        NSDictionary *attributes = @{
            NSForegroundColorAttributeName: [self lyricsLabelNormalColor],
            NSParagraphStyleAttributeName: ({
                NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
                style.alignment = NSTextAlignmentCenter;
                style.minimumLineHeight = 18;
                style.maximumLineHeight = 18;
                style.lineBreakMode = NSLineBreakByTruncatingTail;
                style.alignment = NSTextAlignmentLeft;
                [style copy];
            }),
        };
        NSMutableAttributedString *lyricText = [[NSMutableAttributedString alloc] initWithString:model.shortLyric attributes:attributes];
        [model.shortLyricHighlights enumerateObjectsUsingBlock:^(id<ACCPositonProtocol> obj, NSUInteger idx, BOOL *stop) {
            NSRange highlightedRange = NSMakeRange(obj.begin, obj.end - obj.begin);
            if (obj.begin >= 0 && obj.end <= lyricText.length) {
                [lyricText addAttribute:NSForegroundColorAttributeName
                                       value:[self lyricsLabelHighlightColor]
                                       range:highlightedRange];
            }
        }];
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:@"歌词：" attributes:attributes];
        [attributedText appendAttributedString:lyricText];
        self.lyricLabel.attributedText = [attributedText copy];
    } else {
        [self.lyricLabel removeFromSuperview];
    }
}

- (void)configAuthorNameLabelWithModel:(id<ACCMusicModelProtocol>)model
{
    NSString *matchedPGCMusicInfoString = [model awe_matchedPGCMusicInfoStringWithPrefix];
    if (self.needShowPGCMusicInfo && !ACC_isEmptyString(matchedPGCMusicInfoString)) {
        self.authorNameLabel.text = nil;
        self.authorNameLabel.attributedText = [self authorNamePGCMusicInfoAttributedTextWithText:matchedPGCMusicInfoString];
        // expand animation may causes more line break, so fixed lines.
        self.authorNameLabel.numberOfLines = MusicBigFontModeOn() ? 1 : [[self class] getTextLineCountWithText:matchedPGCMusicInfoString contentPadding:self.contentPadding];
        self.authorNameLabel.lineBreakMode = MusicBigFontModeOn() ? NSLineBreakByTruncatingTail:kAuthorNameLabelPGCStyleLineBreakMode;
    } else {
        self.authorNameLabel.attributedText = nil;
        self.authorNameLabel.text = model.authorName;
        if (!ACC_isEmptyString(model.matchedPGCMixedAuthor)) {
            self.authorNameLabel.text = model.matchedPGCMixedAuthor;
        }
        self.authorNameLabel.numberOfLines = 1;
        self.authorNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }

    if (model.musicTags.count>0) {
        [self.authorNameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        ACCMasReMaker(self.authorNameLabel, {
            make.left.equalTo(self.musicTagContentView.mas_right).offset(2);
            make.right.equalTo(self.collectionButton.mas_left).offset(-15);
            make.centerY.equalTo(self.musicTagContentView);
            make.top.equalTo(self.songNameView.mas_bottom).offset(6);
        });

    }else {
        ACCMasReMaker(self.authorNameLabel, {
            make.top.equalTo(self.songNameView.mas_bottom).offset(4);
            make.left.equalTo(self.logoView.mas_right).offset(12);
        });
    }
}

- (void)configDurationLabelWithModel:(id<ACCMusicModelProtocol>)model
{
    NSNumber *musicDuration = nil;
    //音乐时长显示从音乐本身的duration改为server下发的shoot_duration字段，https://wiki.bytedance.net/pages/viewpage.action?pageId=358817943
    if (model.isPGC) {
        musicDuration = model.shootDuration ?: model.duration;
    } else {
        musicDuration = model.duration ?: model.shootDuration;
    }
    int second = [musicDuration intValue] % 60;
    int minute = [musicDuration intValue] / 60;
    NSString *timeString = [NSString stringWithFormat:@"%02d:%02d", minute, second];
    if (self.isSearchMusic) {
        NSString *userCountString = [self musicUseCountString:self.musicModel.userCount.integerValue];
        self.durationLabel.text = [NSString stringWithFormat:@"%@ · %@", timeString, userCountString];
    }else{
        self.durationLabel.text = timeString;
    }
}

- (void)configMusicTagContentViewWithModel:(id<ACCMusicModelProtocol>)model
{
    [self.musicTagContentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if (model.musicTags.count > 0) {
        self.musicTagContentView.hidden = NO;
        CGFloat tagX = 0;
        for (id<ACCMusicTagModelProtocol> tagModel in model.musicTags) {
            UILabel *tagLabel = nil;
            tagLabel = [self musicTagLabelWithTitle:tagModel.tagTitle titleColor:tagModel.tagTitleLightColor backgroundColor:tagModel.tagLightColor borderColor:tagModel.tagBorderLightColor];
            tagLabel.frame = CGRectMake(tagX, 0, tagLabel.frame.size.width, kMusicTagContentHeight);
            tagX += (tagLabel.frame.size.width+3);
            [self.musicTagContentView addSubview:tagLabel];
        }
        [self.musicTagContentView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        ACCMasReMaker(self.musicTagContentView, {
            make.left.equalTo(self.songNameView);
            make.right.lessThanOrEqualTo(self.songNameView);
            make.width.equalTo(@(tagX));
            make.top.equalTo(self.songNameView.mas_bottom).offset(6);
            make.height.equalTo(@(kMusicTagContentHeight));
        });
    } else {
        self.musicTagContentView.hidden = YES;
    }
}

#pragma mark - Utils

- (NSAttributedString *)authorNamePGCMusicInfoAttributedTextWithText:(NSString *)text {
    
    if (ACC_isEmptyString(text)) {
        return nil;
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.maximumLineHeight = kAuthorNameLabelHeight;
    paragraphStyle.minimumLineHeight = kAuthorNameLabelHeight;
    
    UIColor *textColor = self.authorNameLabel.textColor ?: ACCResourceColor(ACCUIColorConstTextTertiary);
    
    return [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName : kAuthorNameLabelFont,
                                                                        NSParagraphStyleAttributeName:paragraphStyle,
                                                                        NSForegroundColorAttributeName : textColor}];
    
}
    
- (UILabel *)musicTagLabelWithTitle:(NSString *)title titleColor:(NSString *)titleColor backgroundColor:(NSString *)backgroundColor borderColor:(NSString *)borderColor
{
    UILabel * tagLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    tagLabel.text = title;
    tagLabel.font = [MusicFont() boldSystemFontOfSize:9];
    tagLabel.textColor = [self colorFromARGBHexString:titleColor defaultColor:[UIColor clearColor]];
    tagLabel.textAlignment = NSTextAlignmentCenter;
    [tagLabel sizeToFit];
    tagLabel.frame = CGRectMake(0, 0, tagLabel.frame.size.width+6, 14);
    tagLabel.backgroundColor = [self colorFromARGBHexString:backgroundColor defaultColor:[UIColor clearColor]];
    tagLabel.layer.cornerRadius = 2;
    tagLabel.layer.borderWidth = 1;
    tagLabel.layer.borderColor = [self colorFromARGBHexString:borderColor defaultColor:[UIColor clearColor]].CGColor;
    
    return tagLabel;
}

- (UIColor *)colorFromARGBHexString:(NSString *)argbStr defaultColor:(UIColor *)defaultColor
{
    if (!(!ACC_isEmptyString(argbStr) &&
          [argbStr isKindOfClass:[NSString class]])) {
        return defaultColor;
    }
    
    unsigned int argb = 0;
    NSScanner *scanner = [NSScanner scannerWithString:argbStr];
    [scanner setScanLocation:1];
    if (![scanner scanHexInt:&argb]) {
        return defaultColor;
    }
    
    return [UIColor colorWithRed:((argb & 0xFF0000) >> 16) / 255.0
                           green:((argb & 0xFF00) >> 8) / 255.0
                            blue:(argb & 0xFF) / 255.0
                           alpha:((argb & 0xFF000000) >> 24) / 255.0];
}

- (NSString *)musicUseCountString:(NSInteger)count
{
    NSString *userCount = [ACCLanguage() formatedNumber:count];
    NSString *format = [ACCLanguage() pluralizedStringWithString:@"im_music_user_count" count:count];
    NSString *userCountString = [NSString stringWithFormat:format, userCount];
    return userCountString;
}

#pragma mark - Play Status

- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus {
    [self configWithPlayerStatus:playerStatus animated:YES];
}

- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus animated:(BOOL)animated {
    if (ACCConfigBool(kConfigBool_enable_music_selected_page_render_optims) && self.playerStatus == playerStatus) {
        return;
    }
    self.playerStatus = playerStatus;
    NSString *imageName = @"icon_play_music";
    self.accessibilityElements = @[self.logoView, self.collectionButton];
    [self p_stopAnimation];
    if (playerStatus == ACCAVPlayerPlayStatusPlaying) {
        imageName = @"icon_pause_music";
        [self transformToStatus:AWESingleMusicViewLayoutStatusNormalShowApply animated:animated];
        self.accessibilityElements = @[self.logoView, self.clipButton, self.collectionButton, self.applyControl];
        self.logoView.accessibilityLabel = [NSString stringWithFormat:@"%@, %@, %@, %@", @"暂停", self.songNameView.titleLabel.text, self.authorNameLabel.text, self.durationLabel.text];
    } else if (playerStatus == ACCAVPlayerPlayStatusLoading) {
        imageName = @"icon_play_music_loading";
        [self p_startAnimation];
        self.logoView.accessibilityLabel = @"下载中";
    } else {
        [self transformToStatus:AWESingleMusicViewLayoutStatusNormal animated:animated];
        self.logoView.accessibilityLabel = [NSString stringWithFormat:@"%@, %@, %@, %@", @"播放", self.songNameView.titleLabel.text, self.authorNameLabel.text, self.durationLabel.text];
    }
    self.playView.image = ACCResourceImage(imageName);
}

- (void)configWithNewPlayerStatus:(ACCMusicServicePlayStatus)playerStatus {
    NSString *imageName = @"icon_play_music";
    [self p_stopAnimation];
    if (playerStatus == ACCMusicServicePlayStatusPlaying) {
        imageName = @"icon_pause_music";
    } else if (playerStatus == ACCMusicServicePlayStatusLoading) {
        imageName = @"icon_play_music_loading";
        [self p_startAnimation];
    }
    self.playView.image = ACCResourceImage(imageName);
}

- (void)configWithFavoriteListStatus:(ACCMusicServicePlayStatus)playerStatus {
    if (playerStatus == ACCMusicServicePlayStatusPlaying) {
        [self transformToStatus:AWESingleMusicViewLayoutStatusNormalShowApply animated:NO];
    } else {
        [self transformToStatus:AWESingleMusicViewLayoutStatusNormal animated:NO];
    }
}

- (void)transformToStatus:(AWESingleMusicViewLayoutStatus)status animated:(BOOL)animated
{
    if (status == AWESingleMusicViewLayoutStatusNormalShowApply) {
        self.currentStatus = status;
        [self updateConstraintsShowApplyAnimated:animated];
    } else if (self.currentStatus == AWESingleMusicViewLayoutStatusNormalShowApply &&
               status == AWESingleMusicViewLayoutStatusNormalHideLabel) {
        self.currentStatus = status;
        [self updateConstraintsHideLabelAnimated:animated];
    } else if (self.currentStatus == AWESingleMusicViewLayoutStatusNormalShowApply &&
               status == AWESingleMusicViewLayoutStatusNormal) {
        self.currentStatus = status;
        [self updateConstraintsApplyBackToNormalAnimated:animated];
    } else if (self.currentStatus == AWESingleMusicViewLayoutStatusNormalHideLabel &&
               status == AWESingleMusicViewLayoutStatusNormal) {
        self.currentStatus = status;
        [self updateConstraintsHideLabelBackToNormalAnimated:animated];
    }
}

#pragma mark - Private

- (void)handleFavoriteStatusChangedNotification:(NSNotification *)notification {
    NSString *musicId = [notification.userInfo acc_stringValueForKey:@"music_id"];
    AWEStudioMusicCollectionType type = [notification.userInfo[@"type"] integerValue];
    
    if (!musicId) {
        return;
    }
    
    if ([self.musicModel.musicID isEqualToString:musicId]) {
        if (type == AWEStudioMusicCollectionTypeCollection) {
            [self configWithCollectionSelected:YES];
            self.musicModel.collectStat = @(1);
        } else {
            [self configWithCollectionSelected:NO];
            self.musicModel.collectStat = @(0);
        }
    }
}

- (void)configWithCollectionSelected:(BOOL)selected {
    self.collectionButton.selected = selected;
    self.collectionButton.accessibilityLabel = selected ? @"取消收藏" : @"收藏";
    [UIView animateWithDuration:0.15f
                     animations:^{
        self.collectionButton.transform = CGAffineTransformMakeScale(0.7f, 0.7f);
    }];
    [UIView animateWithDuration:0.05f
                          delay:0.15f
                        options:0
                     animations:^{
        self.collectionButton.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)p_startAnimation {
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    anim.toValue = @(M_PI * 2.0);
    anim.duration = 1;
    anim.cumulative = YES;
    anim.repeatCount = FLT_MAX;
    [self.playView.layer addAnimation:anim forKey:@"rotateAnimation"];
}

- (void)p_stopAnimation {
    [self.playView.layer removeAllAnimations];
}

- (BOOL)shouldShowSongTag
{
    return self.enableSongTag
    && self.musicModel.matchedSong != nil
    && !ACC_isEmptyString(self.musicModel.matchedSong.h5URL)
    && ACCConfigInt(kConfigInt_social_show_song_entrance) != kAWESocialShowSongEntranceTypeDefault;
}

#pragma mark Constraint

- (void)updateConstraintsShowApplyAnimated:(BOOL)animated
{
    ACCMasReMaker(self.applyControl, {
        make.centerY.equalTo(self.logoView);
        make.right.equalTo(self);
    });
    
    if (self.showMoreButton) {
        ACCMasReMaker(self.moreButton, {
            make.centerY.equalTo(self.logoView);
            make.width.height.equalTo(@(kActionViewSize));
            make.right.equalTo(self.applyControl.mas_left).offset(-16);
        });
    } else {
        ACCMasReMaker(self.collectionButton, {
            make.centerY.equalTo(self.logoView);
            make.width.height.equalTo(@(kActionViewSize));
            make.right.equalTo(self.applyControl.mas_left).offset(-16);
            make.left.greaterThanOrEqualTo(self.songNameView.mas_right).offset(12 + (self.showClipButton ? 36 : 0));
            make.left.equalTo(self.authorNameLabel.mas_right).offset(kAuthorNameLabelToActionViewInset + (self.showClipButton ? 36 : 0));
        });
    }
    
    if ([self.delegate respondsToSelector:@selector(singleMusicView:enableClipMusic:)]) {
        self.clipButton.enabled = [self.delegate singleMusicView:self enableClipMusic:self.musicModel];
    }
    
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self layoutIfNeeded];
                             self.applyControl.alpha = 1.0;
                             self.clipButton.alpha = self.showClipButton ? 1 : 0;
                             // 这个是为了让label能瞬间根据它的frame更新文字，而不是动画以后更新
                             [self.songNameView.titleLabel setNeedsDisplay];
                             [self.authorNameLabel setNeedsDisplay];
                         } completion:nil];
    } else {
        self.applyControl.alpha = 1.0;
        self.clipButton.alpha = self.showClipButton ? 1 : 0;
    }
}

- (void)updateConstraintsHideLabelAnimated:(BOOL)animated
{
    ACCMasReMaker(self.collectionButton, {
        make.left.equalTo(self.logoView.mas_right).offset(60);
        make.centerY.equalTo(self.logoView);
        make.width.height.equalTo(@(kActionViewSize));
        make.right.equalTo(self.moreButton.mas_left).offset(-16);
    });
    
    if (self.showMoreButton) {
        ACCMasReMaker(self.moreButton, {
            make.centerY.equalTo(self.logoView);
            make.width.height.equalTo(@(kActionViewSize));
            make.left.equalTo(self.collectionButton.mas_right).offset(16);
        });
    }
    
    ACCMasReMaker(self.applyControl, {
        make.centerY.equalTo(self.logoView);
        if (self.showMoreButton) {
            make.left.equalTo(self.moreButton.mas_right).offset(16);
        } else {
            make.left.equalTo(self.collectionButton.mas_right).offset(16);
        }
    });
    
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self layoutIfNeeded];
                             self.songNameView.alpha = 0.0;
                             self.authorNameLabel.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             
                         }];
    } else {
        self.songNameView.alpha = 0.0;
        self.authorNameLabel.alpha = 0.0;
    }
}

- (void)updateConstraintsApplyBackToNormalAnimated:(BOOL)animated {
    ACCMasReMaker(self.applyControl, {
        make.centerY.equalTo(self.logoView);
        make.left.equalTo(self.mas_right);
    });
    
    UIView *actionView = self.showMoreButton ? self.moreButton : self.collectionButton;
    ACCMasReMaker(actionView, {
        make.centerY.equalTo(self.logoView);
        make.width.height.equalTo(@(kActionViewSize));
        make.right.equalTo(self);
        if (actionView == self.collectionButton) {
            make.left.greaterThanOrEqualTo(self.songNameView.mas_right).offset(12);
            make.left.equalTo(self.authorNameLabel.mas_right).offset(kAuthorNameLabelToActionViewInset);
        }
    });
    
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self layoutIfNeeded];
                             self.applyControl.alpha = 0.0;
                             self.clipButton.alpha = 0;
                         }];
    } else {
        self.applyControl.alpha = 0.0;
        self.clipButton.alpha = 0;
    }
}

- (void)updateConstraintsHideLabelBackToNormalAnimated:(BOOL)animated {
    UIView *actionView = self.showMoreButton ? self.moreButton : self.collectionButton;
    ACCMasReMaker(actionView, {
        make.centerY.equalTo(self.logoView);
        make.width.height.equalTo(@(kActionViewSize));
        make.right.equalTo(self);
    });
    
    if (self.showMoreButton) {
        ACCMasReMaker(self.collectionButton, {
            make.left.greaterThanOrEqualTo(self.songNameView.mas_right).offset(12);
            make.left.equalTo(self.authorNameLabel.mas_right).offset(kAuthorNameLabelToActionViewInset);
            make.centerY.equalTo(self.logoView);
            make.width.height.equalTo(@(kActionViewSize));
            if (self.needShowPGCMusicInfo) {
                make.centerX.equalTo(self.moreButton);
            } else {
               make.right.equalTo(self.moreButton.mas_left).offset(-16);
            }
        });
    }
    
    ACCMasReMaker(self.applyControl, {
        make.centerY.equalTo(self.logoView);
        make.left.equalTo(self.mas_right);
    });
    
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self layoutIfNeeded];
                             self.applyControl.alpha = 0.0;
                             self.songNameView.alpha = 1.0;
                             self.authorNameLabel.alpha = 1.0;
                         }];
    } else {
        self.applyControl.alpha = 0.0;
        self.songNameView.alpha = 1.0;
        self.authorNameLabel.alpha = 1.0;
    }
}

- (void)setupUI
{
    [self addSubview:self.logoView];
    ACCMasMaker(self.logoView, {
        make.width.height.equalTo(@(kLogoImageSize));
        make.top.equalTo(self).offset(10);
        make.left.equalTo(self);
    });
    
    [self addSubview:self.playView];
    ACCMasMaker(self.playView, {
        make.width.equalTo(@(30));
        make.height.equalTo(@(30));
        make.center.equalTo(self.logoView);
    });
    
    [self addSubview:self.songNameView];
    ACCMasMaker(self.songNameView, {
        make.left.equalTo(self.logoView.mas_right).offset(12);
        make.top.equalTo(self.logoView).offset(2);
    });
    
    [self bringSubviewToFront:self.songNameView];
    
    [self addSubview:self.authorNameLabel];
    ACCMasMaker(self.authorNameLabel, {
        make.top.equalTo(self.songNameView.mas_bottom).offset(4);
        make.left.equalTo(self.logoView.mas_right).offset(kAuthorNameLabelToCoverInset);
    });
    
    [self addSubview:self.musicTagContentView];
    
    [self addSubview:self.durationLabel];
    ACCMasMaker(self.durationLabel, {
        if ([ACCFont() acc_bigFontModeOn]) {
            make.bottom.equalTo(self);
        } else {
            make.bottom.equalTo(self.logoView);
        }
        make.left.equalTo(self.logoView.mas_right).offset(12);
    });
        
    [self addSubview:self.moreButton];
    ACCMasMaker(self.moreButton, {
        make.width.height.equalTo(@(kActionViewSize));
        make.right.equalTo(self);
        make.centerY.equalTo(self.logoView);
    });
    
    self.moreButton.hidden = !self.showMoreButton;
    
    [self addSubview:self.collectionButton];
    ACCMasMaker(self.collectionButton, {
        make.left.greaterThanOrEqualTo(self.songNameView.mas_right).offset(12);
        make.left.equalTo(self.authorNameLabel.mas_right).offset(kAuthorNameLabelToActionViewInset);
        make.centerY.equalTo(self.logoView);
        make.width.height.equalTo(@(kActionViewSize));
        if (self.showMoreButton && !self.needShowPGCMusicInfo) {
            make.right.equalTo(self.moreButton.mas_left).offset(-16);
        } else {
            make.centerX.equalTo(self.moreButton);
        }
    });
    
    [self addSubview:self.clipButton];
    ACCMasMaker(self.clipButton, {
        make.right.equalTo(self.collectionButton.mas_left).offset(-12);
        make.centerY.equalTo(self.collectionButton);
        make.size.equalTo(@(CGSizeMake(30, 30)));
    });
    self.clipButton.alpha = 0;
    
    [self addSubview:self.applyControl];
    ACCMasMaker(self.applyControl, {
        make.centerY.equalTo(self.logoView);
        make.left.equalTo(self.mas_right);
    });
    
    [self addSubview:self.rankImageView];
}

- (void)adjustUI {
    ACCMasReMaker(self.logoView, {
        make.width.height.equalTo(@(kLogoImageSize));
        if (self.needShowPGCMusicInfo) {
            make.top.equalTo(self).offset(10.f);
        } else {
            make.centerY.equalTo(self);
        }
        make.left.equalTo(self);
    });
    
    ACCMasReMaker(self.playView, {
        make.width.equalTo(@(30));
        make.height.equalTo(@(30));
        make.center.equalTo(self.logoView);
    });
    
    ACCMasReMaker(self.songNameView, {
        make.left.equalTo(self.logoView.mas_right).offset(12);
        make.top.equalTo(self.logoView);
    });
    
    ACCMasReMaker(self.authorNameLabel, {
        make.top.equalTo(self.songNameView.mas_bottom).offset(4);
        make.left.equalTo(self.logoView.mas_right).offset(kAuthorNameLabelToCoverInset);
    });
    
    ACCMasReMaker(self.durationLabel, {
        if (self.needShowPGCMusicInfo) {
            make.bottom.equalTo(self.logoView).priorityLow();
            make.left.equalTo(self.logoView.mas_right).offset(12);
            make.top.greaterThanOrEqualTo(self.authorNameLabel.mas_bottom).inset(6);
        }else {
            make.bottom.equalTo(self.logoView);
            make.left.equalTo(self.logoView.mas_right).offset(12);
        }
    });
    
    self.moreButton.hidden = !self.showMoreButton;
    if (self.showMoreButton) {
        ACCMasReMaker(self.moreButton, {
            make.width.height.equalTo(@(kActionViewSize));
            make.right.equalTo(self);
            make.centerY.equalTo(self.logoView);
        });
    }
    
    ACCMasReMaker(self.collectionButton, {
        make.left.greaterThanOrEqualTo(self.songNameView.mas_right).offset(12);
        make.left.equalTo(self.authorNameLabel.mas_right).offset(12);
        make.centerY.equalTo(self.logoView);
        make.width.height.equalTo(@(kActionViewSize));
        if (self.showMoreButton && !self.needShowPGCMusicInfo) {
            make.right.equalTo(self.moreButton.mas_left).offset(-16);
        } else {
            make.centerX.equalTo(self.moreButton);
        }
    });
    
    
    ACCMasReMaker(self.applyControl, {
        make.centerY.equalTo(self.logoView);
        make.left.equalTo(self.mas_right);
    });
}

- (void)p_didClickClipButton:(id)sender
{
    if (self.playerStatus == ACCAVPlayerPlayStatusLoading) {
        if ([self.delegate respondsToSelector:@selector(singleMusicViewDidTapUseWhileLoading)]) {
            [self.delegate singleMusicViewDidTapUseWhileLoading];
        }
    } else {
        [self configWithPlayerStatus:ACCAVPlayerPlayStatusPause];
        if ([self.delegate respondsToSelector:@selector(singleMusicViewDidTapClip:music:)]) {
            [self.delegate singleMusicViewDidTapClip:self music:self.musicModel];
        }
    }
}

- (void)collectionBtnClicked:(ACCCollectionButton *)sender
{
    [self.delegate singleMusicViewDidTapFavouriteMusic:self.musicModel];
}

- (void)moreButtonClicked
{
    [self.delegate singleMusicViewDidTapMoreButton:self.musicModel];
}

- (void)applyed:(UIControl *)control
{
    if (self.playerStatus == ACCAVPlayerPlayStatusLoading) {
        [self.delegate singleMusicViewDidTapUseWhileLoading];
    } else {
        [self.delegate singleMusicViewDidTapUse:self music:self.musicModel];
    }
}

#pragma mark - Properties

- (UIImageView *)logoView {
    if (!_logoView) {
        _logoView = [[UIImageView alloc] init];
        _logoView.contentMode = UIViewContentModeScaleAspectFill;
        _logoView.image = ACCResourceImage(@"bg_musiclist_img");
        _logoView.layer.cornerRadius = 2.0;
        _logoView.layer.masksToBounds = YES;
        _logoView.isAccessibilityElement = YES;
        _logoView.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return _logoView;
}

- (UIImageView *)playView {
    if (!_playView) {
        UIImage *img = ACCResourceImage(@"icon_play_music");
        _playView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, img.size.width, img.size.height)];
        _playView.image = img;
    }
    return _playView;
}

- (UIImageView *)rankImageView {
    if (!_rankImageView) {
        _rankImageView = [[UIImageView alloc] init];
        _rankImageView.hidden = YES;
    }
    return _rankImageView;
}

- (UILabel *)rankLabel {
    if (!_rankLabel) {
        _rankLabel = [[UILabel alloc] init];
        _rankLabel.font = [UIFont fontWithName:@"DINCond-Black" size:10];
        _rankLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _rankLabel.hidden = YES;
    }
    return _rankLabel;
}

- (AWESingleMusicTitleView *)songNameView {
    if (!_songNameView) {
        _songNameView = [[AWESingleMusicTitleView alloc] init];
        [_songNameView setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                         forAxis:UILayoutConstraintAxisHorizontal];
        [_songNameView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                       forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _songNameView;
}

- (UILabel *)authorNameLabel {
    if (!_authorNameLabel) {
        _authorNameLabel = [[UILabel alloc] init];
        _authorNameLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary);
        _authorNameLabel.font = kAuthorNameLabelFont;
        [ACCLanguage() disableLocalizationsOfObj:_authorNameLabel];
        // issues are triggered after multiline text animationed
        // so change lable's layout "greaterThan" to "equal" and reduce compression priority
        [_authorNameLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_authorNameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                       forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _authorNameLabel;
}

- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary);
        _durationLabel.font = [MusicFont() systemFontOfSize:13];
        [ACCLanguage() disableLocalizationsOfObj:_durationLabel];
        [_durationLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_durationLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                          forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _durationLabel;
}

- (UILabel *)lyricLabel
{
    if (!_lyricLabel) {
        _lyricLabel = [[UILabel alloc] init];
        _lyricLabel.textColor = [UIColor colorWithRed:22.0f / 255.0f green:24.0f / 255.0f blue:35.0f / 255.0f alpha:0.5f];
        _lyricLabel.font = [MusicFont() systemFontOfSize:13];
        _lyricLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _lyricLabel;
}

- (UIImageView *)recommandView {
    if (!_recommandView) {
        _recommandView = [[UIImageView alloc] init];
        _recommandView.hidden = YES;
    }
    return _recommandView;
}

- (UIButton *)clipButton
{
    if (!_clipButton) {
        _clipButton = [[UIButton alloc] init];
        _clipButton.enabled = NO;
        [_clipButton setImage:ACCResourceImage(@"icon_music_cut_black") forState:UIControlStateNormal];
        [_clipButton addTarget:self action:@selector(p_didClickClipButton:) forControlEvents:UIControlEventTouchUpInside];
        _clipButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -8, -6, -6);
        _clipButton.isAccessibilityElement = YES;
        _clipButton.accessibilityTraits = UIAccessibilityTraitButton;
        _clipButton.accessibilityLabel = @"剪辑";
    }
    return _clipButton;
}

- (ACCCollectionButton *)collectionButton 
{
    if (!_collectionButton) {
        _collectionButton = [[ACCCollectionButton alloc] init];
        [_collectionButton setImage:ACCResourceImage(@"icon_black_collection") forState:UIControlStateSelected];
        [_collectionButton setImage:ACCResourceImage(@"icon_black_nocollection") forState:UIControlStateNormal];
        [_collectionButton addTarget:self action:@selector(collectionBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        _collectionButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -8, -10, -15);
        _collectionButton.isAccessibilityElement = YES;
        _collectionButton.accessibilityTraits = UIAccessibilityTraitButton;
        _collectionButton.accessibilityLabel = @"收藏";
    }
    return _collectionButton;
}

- (UIButton *)moreButton {
    if (!_moreButton) {
        _moreButton = [[UIButton alloc] init];
        [_moreButton setImage:ACCResourceImage(@"iconBlackMusicdetails") forState:UIControlStateNormal];
        [_moreButton acc_addSingleTapRecognizerWithTarget:self action:@selector(moreButtonClicked)];
        _moreButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -8, -6, -6);
        _moreButton.accessibilityLabel = @"音乐详情";
    }
    return _moreButton;
}

- (AWEMusicTitleControl *)applyControl {
    if (!_applyControl) {
        _applyControl = [[AWEMusicTitleControl alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        _applyControl.aweTitleLabel.text = ACCLocalizedString(@"com_mig_use", @"使用");
        _applyControl.aweTitleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        _applyControl.paddings = UIEdgeInsetsMake(7, 17, 7, 17);
        [_applyControl addTarget:self action:@selector(applyed:) forControlEvents:UIControlEventTouchUpInside];
        _applyControl.backgroundColorView.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
        _applyControl.backgroundColorView.layer.cornerRadius = 2.0;
        _applyControl.backgroundColorView.layer.masksToBounds = YES;
        [_applyControl setContentHuggingPriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisHorizontal];
        [_applyControl setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                       forAxis:UILayoutConstraintAxisHorizontal];
        _applyControl.isAccessibilityElement = YES;
        _applyControl.accessibilityLabel  = ACCLocalizedString(@"com_mig_use", @"使用");
        _applyControl.accessibilityTraits = UIAccessibilityTraitButton;
        _applyControl.alpha = 0.0;
    }
    return _applyControl;
}

- (UIView *)musicTagContentView
{
    if (!_musicTagContentView) {
        _musicTagContentView = [[UIView alloc] init];
        _musicTagContentView.clipsToBounds = YES;
    }
    return _musicTagContentView;
}

- (void)setIsEliteVersion:(BOOL)isEliteVersion
{
    _isEliteVersion = isEliteVersion;
    self.songNameView.isEliteVersion = isEliteVersion;
    if (isEliteVersion) {
        self.authorNameLabel.textColor = ACCResourceColor(ACCColorTextTertiary);
        self.durationLabel.textColor = ACCResourceColor(ACCColorTextTertiary);
        [self.moreButton setImage:ACCResourceImage(@"icon_ost_detail") forState:UIControlStateNormal];
    } else {
        self.authorNameLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary);
        self.durationLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary);
        [self.moreButton setImage:ACCResourceImage(@"iconBlackMusicdetails") forState:UIControlStateNormal];
    }
}

- (void)setShowCollectionButton:(BOOL)showCollectionButton
{
    _showCollectionButton = showCollectionButton;
    self.collectionButton.hidden = !showCollectionButton;
}

- (void)setIsFavoriteList:(BOOL)isFavoriteList {
    _isFavoriteList = isFavoriteList;
    [ACCAudioMusicService() removeObserver:self];
    [ACCAudioMusicService() addObserver:self];
}

+ (CGFloat)heightWithMusic:(id<ACCMusicModelProtocol>)model
                baseHeight:(CGFloat)baseHeight
            contentPadding:(CGFloat)contentPadding {
    
    if (model.isOffLine) {
        return baseHeight;
    }
    
    NSString *matchedPGCMusicInfoString = [model awe_matchedPGCMusicInfoStringWithPrefix];
    if (ACC_isEmptyString(matchedPGCMusicInfoString)) {
        return baseHeight;
    }
    
    NSInteger textLines = [self getTextLineCountWithText:matchedPGCMusicInfoString contentPadding:contentPadding];
    
    if (textLines <= 1 || MusicBigFontModeOn()) {
        return baseHeight;
    }
    
    return baseHeight + 12.f/* first additional line */ + (textLines - 2) * kAuthorNameLabelHeight;
}

+ (NSInteger)getTextLineCountWithText:(NSString *)text contentPadding:(CGFloat)contentPadding {
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = kAuthorNameLabelPGCStyleLineBreakMode;
    style.minimumLineHeight = kAuthorNamelabelLineHeight;
    style.maximumLineHeight = kAuthorNamelabelLineHeight;
    
    CGFloat maxWidth = ACC_SCREEN_WIDTH - 2 * contentPadding - kLogoImageSize - kAuthorNameLabelToCoverInset - kAuthorNameLabelToActionViewInset -  kActionViewSize;
    
    NSInteger ret =  [text acc_lineCountWithFont:kAuthorNameLabelFont
                                  paragraphStyle:style
                           appendOtherAttributes:nil
                                        maxWidth:maxWidth];
    return MAX(ret, 1);
}

@end
