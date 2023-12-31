//
//  AWESingleKaraokeMusicView.m
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/4/2.
//

#import "AWESingleKaraokeMusicView.h"

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <Masonry/Masonry.h>

#import "ACCCollectionButton.h"
#import "AWEMusicTitleControl.h"
#import "ACCMusicModelProtocolD.h"
#import "AWESingleMusicView+Private.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCProtocolContainer.h>
#import "AWEKaraokeSelectMusicViewFactory.h"

@interface AWESingleKaraokeMusicView () {
    NSArray *_karaokeAccessibilityElements;
}

@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) NSArray<UIImageView *> *tagArray;
@property (nonatomic, strong) UIStackView *tagsDurationStackView;

@end

@implementation AWESingleKaraokeMusicView

- (NSArray *)accessibilityElements
{
    return _karaokeAccessibilityElements;
}

- (void)setupUI
{
    [super setupUI];
    [self.collectionButton removeFromSuperview];
    [self.applyControl removeFromSuperview];
    [self.clipButton removeFromSuperview];
    [self.songNameView.songTagLabel.targetLabel removeFromSuperview];
    [self.rankImageView removeFromSuperview];
    [self.rankLabel removeFromSuperview];
    [self.recommandView removeFromSuperview];
    [self.moreButton removeFromSuperview];
    [self.tagLabel removeFromSuperview];
    [self.tagContentView removeFromSuperview];
    [self.musicTagContentView removeFromSuperview];
    [self.durationLabel removeFromSuperview];
    
    [self addSubview:self.actionButton];
    [ACCAccessibility() enableAccessibility:self.actionButton traits:UIAccessibilityTraitButton label:@"我要唱"];
    ACCMasMaker(self.actionButton, {
        make.size.equalTo(@(CGSizeMake(72, 32)));
        make.centerY.equalTo(self);
        make.right.equalTo(self);
    });
    ACCMasReMaker(self.songNameView, {
        make.left.equalTo(self.logoView.mas_right).offset(12);
        make.top.equalTo(self.logoView).offset(2);
        make.right.lessThanOrEqualTo(self.actionButton.mas_left);
    });
    
    UIStackView *stackView = [[UIStackView alloc] initWithFrame:CGRectZero];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 4;
    
    [self addSubview:stackView];
    ACCMasMaker(stackView, {
        make.bottom.equalTo(self.logoView);
        make.left.equalTo(self.songNameView);
        make.right.lessThanOrEqualTo(self.actionButton.mas_left);
        make.height.equalTo(@20);
    });
    self.tagsDurationStackView = stackView;
    
    self.tagArray = @[
        [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 26, 14)],
        [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 26, 14)]
    ];
    
    [stackView addArrangedSubview:self.tagArray[0]];
    [stackView addArrangedSubview:self.tagArray[1]];
    [stackView addArrangedSubview:self.durationLabel];
    
    _karaokeAccessibilityElements = @[self.logoView, self.actionButton];
    
}

- (void)configMusicTagContentViewWithModel:(id<ACCMusicModelProtocol>)model
{
    // do nothing for karaoke music view
}

- (void)configTitleLabelWithMusicName:(NSString *)musicName
{
    [super configTitleLabelWithMusicName:ACCGetProtocol(self.musicModel, ACCMusicModelProtocolD).karaoke.title];
}

- (void)configAuthorNameLabelWithModel:(id<ACCMusicModelProtocolD>)model
{
    self.authorNameLabel.attributedText = nil;
    self.authorNameLabel.text = model.karaoke.author;
    self.authorNameLabel.numberOfLines = 1;
    self.authorNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    ACCMasReMaker(self.authorNameLabel, {
        make.left.equalTo(self.logoView.mas_right).offset(12);
        make.top.equalTo(self.songNameView.mas_bottom).offset(4);
        make.right.lessThanOrEqualTo(self.actionButton.mas_left);
    });
    self.authorNameLabel.hidden = !model.karaoke.showAuthor;
}

- (void)configLogoViewWithModel:(id<ACCMusicModelProtocolD>)model
{
    [ACCWebImage() imageView:self.logoView
        setImageWithURLArray:model.karaoke.coverMedium.URLList
                 placeholder:ACCConfigBool(kConfigBool_enable_music_selected_page_render_optims) ? self.logoPlaceholderImage : ACCResourceImage(@"bg_musiclist_img")
                     options: ACCWebImageOptionsSetImageWithFadeAnimation | ACCWebImageOptionsDefaultOptions
                  completion:nil];
}

- (void)configDurationLabelWithModel:(id<ACCMusicModelProtocolD>)model
{
    int duration = model.karaokeShootDuration;
    int second = duration % 60;
    int minute = duration / 60;
    NSString *timeString = [NSString stringWithFormat:@"%02d:%02d", minute, second];
    if (self.isSearchMusic) {
        NSString *userCountString = [self musicUseCountString:[ACCGetProtocol(model, ACCMusicModelProtocolD).karaoke.userCount integerValue]];
        self.durationLabel.text = [NSString stringWithFormat:@"%@ · %@", timeString, userCountString];
    }else{
        self.durationLabel.text = timeString;
    }
    
    NSArray<id<ACCMusicKaraokeTagModelProtocol>> *tags = model.karaoke.tags;
    if (tags.count > 0) {
        UIImage *image0 = [[AWEKaraokeSelectMusicViewFactory sharedInstance] tagFromModel:tags[0]];
        UIImage *image1 = nil;
        if (tags.count > 1) {
            image1 = [[AWEKaraokeSelectMusicViewFactory sharedInstance] tagFromModel:tags[1]];
        }
        self.tagArray[0].hidden = image0 == nil;
        self.tagArray[0].image = image0;
        self.tagArray[1].hidden = image1 == nil;
        self.tagArray[1].image = image1;
    } else {
        self.tagArray[0].hidden = YES;
        self.tagArray[1].hidden = YES;
    }
}

- (UIColor *)lyricsLabelHighlightColor
{
    return [UIColor colorWithWhite:1.0 alpha:0.9f];
}

- (UIColor *)lyricsLabelNormalColor
{
    return [UIColor colorWithWhite:1.0 alpha:0.5f];
}

- (void)transformToStatus:(AWESingleMusicViewLayoutStatus)status animated:(BOOL)animated
{
    // do nothing, because karaoke no not need to animate status change
    // see figma https://www.figma.com/file/9upVQcpkfXh1J95eDBJh8L/%E3%80%90%E6%8B%8D%E6%91%84%E3%80%91K%E6%AD%8C?node-id=3722%3A148
}

#pragma mark - Actions

- (void)clickedActionButton:(UIButton *)sender
{
    [self.delegate singleMusicViewDidTapUse:self music:self.musicModel];
}

#pragma mark - Getters

- (UIButton *)actionButton
{
    if (!_actionButton) {
        _actionButton = [[UIButton alloc] init];
        if (ACCConfigBool(kConfigBool_karaoke_select_music_new_style)) {
            [_actionButton setTitle:@"去K歌" forState:UIControlStateNormal];
            [_actionButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            _actionButton.layer.cornerRadius = 16;
        } else {
            [_actionButton setTitle:@"我要唱" forState:UIControlStateNormal];
            [_actionButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.9] forState:UIControlStateNormal];
            _actionButton.layer.cornerRadius = 4;
            _actionButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
            _actionButton.layer.borderWidth = 1;
        }
        _actionButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
        _actionButton.titleLabel.font = [UIFont acc_systemFontOfSize:14 weight:ACCFontWeightRegular];
        [_actionButton addTarget:self action:@selector(clickedActionButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _actionButton;
}

@end
