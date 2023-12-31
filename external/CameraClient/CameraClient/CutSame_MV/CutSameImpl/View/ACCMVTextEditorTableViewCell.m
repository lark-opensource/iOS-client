//
//  ACCMVTextEditorTableViewCell.m
//  CameraClient
//
//  Created by long.chen on 2020/3/18.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCMVTextEditorTableViewCell.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "ACCTemplateTextFragment.h"

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface ACCMVTextEditorTableViewCell ()

@property (nonatomic, strong) UIView *topVerticalLine;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIView *bottomVerticalLine;

@property (nonatomic, strong) UIView *textContainerView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIImageView *hintIcon;
@property (nonatomic, strong) UILabel *hintLabel;

@property (nonatomic, strong, readwrite) ACCTemplateTextFragment *textFragment;
@property (nonatomic, assign, readwrite) BOOL isCellSelected;

@end

@implementation ACCMVTextEditorTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI
{
    self.contentView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    [self.contentView addSubview:self.topVerticalLine];
    ACCMasMaker(self.topVerticalLine, {
        make.top.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(31);
        make.width.equalTo(@(1));
        make.height.equalTo(@(15));
    });
    
    [self.contentView addSubview:self.coverImageView];
    ACCMasMaker(self.coverImageView, {
        make.top.equalTo(self.topVerticalLine.mas_bottom);
        make.left.equalTo(self.contentView).offset(16);
        make.size.equalTo(@(CGSizeMake(30, 30)));
    });
    
    [self.contentView addSubview:self.bottomVerticalLine];
    ACCMasMaker(self.bottomVerticalLine, {
        make.top.equalTo(self.coverImageView.mas_bottom);
        make.left.equalTo(self.topVerticalLine);
        make.width.equalTo(self.topVerticalLine);
        make.bottom.equalTo(self.contentView);
    });
    
    [self.contentView addSubview:self.textContainerView];
    ACCMasMaker(self.textContainerView, {
        make.top.equalTo(self.contentView).offset(8);
        make.left.equalTo(self.contentView).offset(62);
        make.bottom.equalTo(self.contentView).offset(-8);
        make.right.equalTo(self.contentView).offset(-16);
    });
    
    [self.textContainerView addSubview:self.contentLabel];
    ACCMasMaker(self.contentLabel, {
        make.top.equalTo(self.textContainerView).offset(12);
        make.left.equalTo(self.textContainerView).offset(12);
        make.bottom.equalTo(self.textContainerView).offset(-12);
        make.right.equalTo(self.textContainerView).offset(-12);
    });
    
    [self.textContainerView addSubview:self.hintIcon];
    ACCMasMaker(self.hintIcon, {
        make.top.equalTo(self.contentLabel.mas_bottom).offset(8);
        make.left.equalTo(self.contentLabel);
        make.size.equalTo(@(CGSizeMake(16, 16)));
        make.bottom.equalTo(self.textContainerView).offset(-12);
    });
    
    [self.textContainerView addSubview:self.hintLabel];
    ACCMasMaker(self.hintLabel, {
        make.centerY.equalTo(self.hintIcon);
        make.left.equalTo(self.hintIcon.mas_right).offset(2);
    });
    self.hintLabel.hidden = YES;
}


#pragma mark - Public

+ (NSString *)cellIdentifier
{
    return NSStringFromClass(self.class);
}

- (void)setTextFragment:(ACCTemplateTextFragment *)textFragment
             topContent:(BOOL)topContent
          bottomContent:(BOOL)bottomContent
               selected:(BOOL)selected
{
    self.textFragment = textFragment;
    self.isCellSelected = selected;
    NSString *content = textFragment.content;
    if (ACC_isEmptyString(content)) {
        self.contentLabel.textColor = ACCResourceColor(ACCColorConstTextInverse5);
        self.contentLabel.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightMedium];
        if (selected) {
            content = @"";
        } else {
            content = ACCLocalizedString(@"creation_mv_text_no_content", @"无内容");
        }
        ACCMasReMaker(self.contentLabel, {
            make.top.equalTo(self.textContainerView).offset(14);
            make.left.equalTo(self.textContainerView).offset(12);
            make.bottom.equalTo(self.textContainerView).offset(-14);
        });
        ACCMasReMaker(self.hintIcon, {
            make.top.equalTo(self.textContainerView).offset(14);
            make.left.equalTo(self.contentLabel);
            make.bottom.equalTo(self.textContainerView).offset(-14);
        });
    } else {
        if (selected) {
            self.contentLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
            self.contentLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
            ACCMasReMaker(self.contentLabel, {
                make.top.equalTo(self.textContainerView).offset(12);
                make.left.equalTo(self.textContainerView).offset(12);
                make.right.equalTo(self.textContainerView).offset(-12);
            });
        } else {
            self.contentLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
            self.contentLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
            ACCMasReMaker(self.contentLabel, {
                make.top.equalTo(self.textContainerView).offset(12);
                make.left.equalTo(self.textContainerView).offset(12);
                make.bottom.equalTo(self.textContainerView).offset(-12);
                make.right.equalTo(self.textContainerView).offset(-12);
            });
        }
        ACCMasReMaker(self.hintIcon, {
            make.top.equalTo(self.contentLabel.mas_bottom).offset(8);
            make.left.equalTo(self.contentLabel);
            make.size.equalTo(@(CGSizeMake(16, 16)));
            make.bottom.equalTo(self.textContainerView).offset(-12);
        });
    }
    
    self.textContainerView.backgroundColor = selected ? ACCResourceColor(ACCColorConstBGContainer5) : ACCResourceColor(ACCColorConstBGContainer6);
    self.contentLabel.text = content;
    self.coverImageView.image = textFragment.albumImage;
    self.topVerticalLine.hidden = topContent;
    self.bottomVerticalLine.hidden = bottomContent;
    self.hintIcon.hidden = !selected;
    self.hintLabel.hidden = !selected;
}

- (void)prepareForUnSelectedAnimation
{
    self.textContainerView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
    self.hintIcon.hidden = YES;
    self.hintLabel.hidden = YES;
}

- (void)updateCover:(UIImage *)cover
{
    self.coverImageView.image = cover;
}

#pragma makr - Getters

- (UIView *)topVerticalLine
{
    if (!_topVerticalLine) {
        _topVerticalLine = [UIView new];
        _topVerticalLine.backgroundColor = ACCResourceColor(ACCColorConstLineInverse);
    }
    return _topVerticalLine;
}

- (UIImageView *)coverImageView
{
    if (!_coverImageView) {
        _coverImageView = [UIImageView new];
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.backgroundColor = ACCResourceColor(ACCColorConstLineInverse);
        _coverImageView.layer.masksToBounds = YES;
        _coverImageView.layer.cornerRadius = 2;
    }
    return _coverImageView;
}

- (UIView *)bottomVerticalLine
{
    if (!_bottomVerticalLine) {
        _bottomVerticalLine = [UIView new];
        _bottomVerticalLine.backgroundColor = ACCResourceColor(ACCColorConstLineInverse);
    }
    return _bottomVerticalLine;
}

- (UIView *)textContainerView
{
    if (!_textContainerView) {
        _textContainerView = [UIView new];
        _textContainerView.backgroundColor = ACCResourceColor(ACCColorBGInput2);
        _textContainerView.layer.masksToBounds = YES;
        _textContainerView.layer.cornerRadius = 4;
    }
    return _textContainerView;
}

- (UILabel *)contentLabel
{
    if (!_contentLabel) {
        _contentLabel = [UILabel new];
        _contentLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
        _contentLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        _contentLabel.numberOfLines = 0;
    }
    return _contentLabel;
}

- (UIImageView *)hintIcon
{
    if (!_hintIcon) {
        _hintIcon = [UIImageView new];
        _hintIcon.image = ACCResourceImage(@"icon_text_edit");
    }
    return _hintIcon;
}

- (UILabel *)hintLabel
{
    if (!_hintLabel) {
        _hintLabel = [UILabel new];
        _hintLabel.font = [ACCFont() systemFontOfSize:12 weight:ACCFontWeightMedium];
        _hintLabel.textColor = ACCResourceColor(ACCColorConstTextInverse5);
        _hintLabel.text = ACCLocalizedString(@"creation_mv_text_click_to_edit_hint", @"点击编辑");
    }
    return _hintLabel;
}

@end
