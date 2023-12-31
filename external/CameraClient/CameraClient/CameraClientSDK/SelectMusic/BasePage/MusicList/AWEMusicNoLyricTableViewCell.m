//
//  AWEMusicNoLyricTableViewCell.m
//  CameraClient
//
//  Created by Liu Deping on 2019/10/9.
//

#import "AWEMusicNoLyricTableViewCell.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEMusicNoLyricTableViewCell ()

@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UILabel *songNameLabel;
@property (nonatomic, strong) UILabel *authorNameLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UILabel *tipLabel;

@end

@implementation AWEMusicNoLyricTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self _setupViewComponents];
    }
    return self;
}

- (void)_setupViewComponents
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.logoView];
    ACCMasMaker(self.logoView, {
        make.width.height.equalTo(@(64));
        make.centerY.equalTo(self.contentView);
        make.leading.equalTo(self.contentView.mas_leading).offset(16.0f);
    });
    
    [self.contentView addSubview:self.tipLabel];
    ACCMasMaker(self.tipLabel, {
        make.trailing.equalTo(self.contentView.mas_trailing).offset(-16);
        make.centerY.equalTo(self.contentView);
    });
    
    [self.contentView addSubview:self.songNameLabel];
    ACCMasMaker(self.songNameLabel, {
        make.leading.equalTo(self.logoView.mas_right).offset(12);
        make.trailing.equalTo(self.tipLabel.mas_leading);
        make.top.equalTo(self.contentView).offset(12);
    });
    
    [self.contentView addSubview:self.authorNameLabel];
    ACCMasMaker(self.authorNameLabel, {
        make.top.equalTo(self.songNameLabel.mas_bottom).offset(2);
        make.leading.equalTo(self.logoView.mas_trailing).offset(12);
        make.trailing.equalTo(self.tipLabel.mas_leading);
    });
    
    [self.contentView addSubview:self.durationLabel];
    ACCMasMaker(self.durationLabel, {
        make.bottom.equalTo(self.logoView);
        make.leading.equalTo(self.logoView.mas_trailing).offset(12);
    });
}

- (void)configWithMusicModel:(id<ACCMusicModelProtocol>)model
{
    [ACCWebImage() imageView:self.logoView
        setImageWithURLArray:model.mediumURL.URLList
                 placeholder:ACCResourceImage(@"bg_musiclist_img")];
    
    NSMutableAttributedString *mutAttrStr = [[NSMutableAttributedString alloc] initWithString:[model musicName]];
    if ([model.externalMusicModelArray.firstObject.thirdPlatformName isEqualToString:@"awa"]) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = ACCResourceImage(@"icon_select_music_tag_AWA");
        NSAttributedString *imageAttrStr = [NSAttributedString attributedStringWithAttachment:attachment];
        [mutAttrStr appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        [mutAttrStr appendAttributedString:imageAttrStr];
        self.songNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    } else {
        self.songNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    
    if (model.isOriginal) {
        NSTextAttachment *originalAttachment = [[NSTextAttachment alloc] init];
        // AWECommonBundle
        originalAttachment.image = [UIImage imageNamed:@"icon_original_musican"];
        originalAttachment.bounds = CGRectMake(0, -2, 16, 16);
        NSAttributedString *originalAttachmentStr = [NSAttributedString attributedStringWithAttachment:originalAttachment];
        [mutAttrStr insertAttributedString:originalAttachmentStr atIndex:0];
    }
    self.songNameLabel.attributedText = [mutAttrStr copy];
    
    self.authorNameLabel.text = model.authorName;
    int second = model.duration.intValue % 60;
    int minute = model.duration.intValue / 60;
    self.durationLabel.text = [NSString stringWithFormat:@"%02d:%02d", minute, second];
}

- (UIImageView *)logoView
{
    if (!_logoView) {
        _logoView = [[UIImageView alloc] init];
        _logoView.contentMode = UIViewContentModeScaleAspectFill;
        _logoView.image = ACCResourceImage(@"bg_musiclist_img");
        _logoView.layer.cornerRadius = 2.0;
        _logoView.layer.masksToBounds = YES;
        _logoView.alpha = 0.65;
    }
    return _logoView;
}

- (UILabel *)songNameLabel
{
    if (!_songNameLabel) {
        _songNameLabel = [[UILabel alloc] init];
        _songNameLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold];
        // TODO: @zhangzhihao 优化点：在深色模式下，颜色显示找设计师确认
        _songNameLabel.textColor = ACCResourceColor(ACCUIColorTextPrimary);
        [_songNameLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_songNameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                        forAxis:UILayoutConstraintAxisHorizontal];
        [ACCLanguage() disableLocalizationsOfObj:_songNameLabel];
        [_songNameLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_songNameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                        forAxis:UILayoutConstraintAxisHorizontal];
        _songNameLabel.alpha = 0.65;
    }
    return _songNameLabel;
}

- (UILabel *)authorNameLabel
{
    if (!_authorNameLabel) {
        _authorNameLabel = [[UILabel alloc] init];
        _authorNameLabel.textColor = [UIColor colorWithRed:255/255.f green:255/255.f blue:255/255.f alpha:0.5];
        _authorNameLabel.font = [ACCFont() systemFontOfSize:13];
        [ACCLanguage() disableLocalizationsOfObj:_authorNameLabel];
        [_authorNameLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                            forAxis:UILayoutConstraintAxisHorizontal];
        [_authorNameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                          forAxis:UILayoutConstraintAxisHorizontal];
        _authorNameLabel.alpha = 0.65;
    }
    return _authorNameLabel;
}

- (UILabel *)durationLabel
{
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.textColor = [UIColor colorWithRed:255/255.f green:255/255.f blue:255/255.f alpha:0.5];
        _durationLabel.font = [ACCFont() systemFontOfSize:13];
        [ACCLanguage() disableLocalizationsOfObj:_durationLabel];
        [_durationLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_durationLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                        forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _durationLabel;
}

- (UILabel *)tipLabel
{
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.textColor = [UIColor colorWithRed:255/255.f green:255/255.f blue:255/255.f alpha:0.5];
        _tipLabel.textAlignment = NSTextAlignmentRight;
        _tipLabel.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightRegular];
        _tipLabel.text = ACCLocalizedString(@"creation_edit_sticker_lyrics_music_selection_page_search_result", @"暂不支持歌词");
    }
    return _tipLabel;
}

@end
