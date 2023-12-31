//
//  IESEffectSectionCollectionViewCell.m
//  EffectPlatformSDK
//
//  Created by Kun Wang on 2018/3/6.
//

#import "IESEffectSectionCollectionViewCell.h"
#import <BDWebImage/UIImageView+BDWebImage.h>
#import "IESEffectUIConfig.h"
#import "Masonry.h"

@interface IESEffectSectionCollectionViewCell()
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *sectionTitleLabel;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURL *selectedURL;
@property (nonatomic, strong) UIView *seperator;
@property (nonatomic, strong) UIView *redDot;
@property (nonatomic, strong) IESEffectUIConfig *uiConfig;
@end
@implementation IESEffectSectionCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_iconImageView];
        [_iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(@0);
            make.size.mas_equalTo(CGSizeMake(25, 25));
        }];
        
        _sectionTitleLabel = [[UILabel alloc] init];
        _sectionTitleLabel.textColor = [UIColor whiteColor];
        _sectionTitleLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_sectionTitleLabel];
        [_sectionTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(@0);
        }];
        
        _seperator = [[UIView alloc] init];
        [_seperator setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.4]];
        [self.contentView addSubview:_seperator];
        [_seperator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(@0);
            make.top.equalTo(@6);
            make.bottom.equalTo(@-6);
            make.width.equalTo(@1);
        }];
        
        _redDot = [[UIView alloc] init];
        _redDot.backgroundColor = [UIColor colorWithRed:255.0 / 255.0 green:34.0 / 255.0 blue:0 alpha:1];
        _redDot.layer.cornerRadius = 3.0;
        _redDot.layer.masksToBounds = YES;
        
        [self.contentView addSubview:_redDot];
        [_redDot mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@9);
            make.trailing.equalTo(@-8);
            make.width.height.equalTo(@6);
        }];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_iconImageView bd_cancelImageLoad];
    _iconImageView.image = nil;
    _redDot.hidden = YES;
}

- (void)updateWithTitle:(NSString *)title
               imageURL:(NSURL *)url
            selectedURL:(NSURL *)selectedURL
             showRedDot:(BOOL)showRedDot
             cellConfig:(IESEffectUIConfig *)uiConfig
{
    _uiConfig = uiConfig;
    _sectionTitleLabel.text = title;
    _sectionTitleLabel.font = uiConfig.sectionTextFont;
    _url = url;
    _selectedURL = selectedURL;
    _seperator.hidden = YES;
    _redDot.hidden = !showRedDot;
    if (url) {
        _iconImageView.hidden = NO;
        [_iconImageView bd_setImageWithURL:url];
        if (title) {
            [_iconImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(@0);
                make.centerY.equalTo(@-8);
                make.size.mas_equalTo(CGSizeMake(25, 25));
            }];
            [_sectionTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(@0);
                make.top.equalTo(_iconImageView.mas_bottom);
            }];
        } else {
            [_iconImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.center.equalTo(@0);
                make.size.mas_equalTo(CGSizeMake(25, 25));
            }];
        }
    } else {
        _iconImageView.hidden = YES;
        [_sectionTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(@0);
        }];
    }
}

- (void)setItemSelected:(BOOL)selected
{
    [_iconImageView bd_setImageWithURL:(selected ? _selectedURL : _url)];
    self.sectionTitleLabel.textColor = selected ?  self.uiConfig.sectionTitleSelectedColor : self.uiConfig.sectionTitleUnSelectedColor;
    if (selected) {
        self.redDot.hidden = YES;
    }
}


@end
