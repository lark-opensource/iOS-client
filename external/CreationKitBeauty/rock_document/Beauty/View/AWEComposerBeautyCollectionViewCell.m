//
//  AWEComposerBeautyCollectionViewCell.m
//  CameraClient
//
//  Created by HuangHongsen on 2019/11/6.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitBeauty/AWEComposerBeautyCollectionViewCell.h>
#import <CreationKitBeauty/AWETitleRollingTextView.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEComposerBeautyCollectionViewCell()

@property (nonatomic, strong, readwrite) UIView *backView;
@property (nonatomic, strong, readwrite) UIImageView *iconImageView;
@property (nonatomic, strong, readwrite) UIView *coverIconImageView; // add on iconImageView
@property (nonatomic, strong) UIView *selectedIndicatorView;
@property (nonatomic, strong, readwrite) UILabel *nameLabel;
@property (nonatomic, strong) AWETitleRollingTextView *rollingTitleView;
@property (nonatomic, strong) UIView *appliedIndicator;
@property (nonatomic, strong) UIImageView *downloadImgView;
@property (nonatomic, strong) UIImageView *downloadingImgView;
@property (nonatomic, strong, readwrite) UIView *flagDotView;

@property (nonatomic, assign) BOOL textFolded;
@property (nonatomic, assign) BOOL applied;

@property (nonatomic, strong) UIColor *rollingTitleViewColor;
@property (nonatomic, strong) UIColor *selectedIndicatorViewColor;
@property (nonatomic, strong) UIColor *namelblSelectColor;
@property (nonatomic, strong) UIColor *namelblUnSelectColor;
@property (nonatomic, strong) UIColor *appliedIndicatorColor;
@property (nonatomic, strong) UIColor *appliedIndicatorUnSelectColor;

@end

@implementation AWEComposerBeautyCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self);
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.clipsToBounds = NO;
        
        _rollingTitleViewColor = ACCResourceColor(ACCColorPrimary);
        _selectedIndicatorViewColor = ACCResourceColor(ACCColorPrimary);
        _namelblSelectColor = ACCResourceColor(ACCColorPrimary);
        _namelblUnSelectColor = [self unselectedNameLabelTextColor];
        _appliedIndicatorColor = ACCResourceColor(ACCColorPrimary);
        _appliedIndicatorUnSelectColor = [self unselectedNameLabelTextColor];
        _iconWidth = 52.f;
        _selectIndicatorWidth = 58.f;
        _selectBorderWidth = 2.f;
        _selectedFont = [ACCFont() acc_systemFontOfSize:12 weight:ACCFontWeightSemibold];
        _unselectedFont = [ACCFont() acc_systemFontOfSize:12 weight:ACCFontWeightRegular];
        
        [self addSubviews];
        [self configWithIconStyle:_iconStyle];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self makeDeselected];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (!self.useSystemSelection) {
        return;
    }
    if (self.downloadStatus != AWEEffectDownloadStatusDownloaded) {
        [self makeDeselected];
        return;
    }
    if (selected) {
        [self makeSelected];
    } else {
        [self makeDeselected];
    }
}

- (void)addSubviews
{
    [self.contentView addSubview:self.selectedIndicatorView];
    ACCMasMaker(self.selectedIndicatorView, {
        make.width.height.equalTo(@(self.selectIndicatorWidth));
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(1);
    });
    
    [self.contentView addSubview:self.backView];
    ACCMasMaker(self.backView, {
        make.width.height.equalTo(@(self.iconWidth));
        make.center.equalTo(self.selectedIndicatorView);
    });
    
    [self.backView addSubview:self.iconImageView];
    ACCMasMaker(self.iconImageView, {
        make.edges.equalTo(self.backView);
    });
    
    [self.contentView addSubview:self.downloadImgView];
    ACCMasMaker(self.downloadImgView, {
        make.right.bottom.equalTo(self.backView);
        make.width.height.equalTo(@18);
    });
    
    [self.contentView addSubview:self.nameLabel];
    ACCMasMaker(self.nameLabel, {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.selectedIndicatorView.mas_bottom).offset(7);
        make.width.lessThanOrEqualTo(@([AWEComposerBeautyCollectionViewCell maxTextWidth]));
    });
    
    [self.contentView addSubview:self.rollingTitleView];
    self.rollingTitleView.hidden = YES;
    ACCMasMaker(self.rollingTitleView, {
        make.left.right.equalTo(self.nameLabel);
        make.top.equalTo(self.nameLabel);
        make.height.equalTo(self.nameLabel);
    });
    
    [self.contentView addSubview:self.appliedIndicator];
    self.appliedIndicator.hidden = YES;
    ACCMasMaker(self.appliedIndicator, {
        make.centerX.equalTo(self.iconImageView);
        make.top.equalTo(self.nameLabel.mas_bottom).with.offset(8);
        make.width.height.equalTo(@4);
    });
    
    [self.contentView addSubview:self.downloadingImgView];
    ACCMasMaker(self.downloadingImgView, {
        make.right.bottom.equalTo(self.backView);
        make.width.height.equalTo(@18);
    });
}

#pragma mark - config

- (void)setTitle:(NSString *)title
{
    self.nameLabel.text = title;
     
    [self.rollingTitleView configureWithRollingText:title
                                               font:_unselectedFont
                                          textColor:self.rollingTitleViewColor
                                         labelSpace:5.f
                                      numberOfRolls:3];
    
    CGRect boundingRect = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 15.f) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{} context:NULL];
    if (ceil(boundingRect.size.width) > [AWEComposerBeautyCollectionViewCell maxTextWidth]) {
        self.textFolded = YES;
    } else {
        self.textFolded = NO;
    }
}

- (void)setImageWithUrls:(NSArray *)urls placeholder:(UIImage *)placeholder
{
    [ACCWebImage() imageView:self.iconImageView setImageWithURLArray:urls
                         placeholder:placeholder
                            progress:nil
                         postProcess:^UIImage *(UIImage *image) {
                            return image;
                         }
                          completion:nil];
}

- (void)setIconImage:(UIImage *)image
{
    [ACCWebImage() imageView:self.iconImageView setImageWithURLArray:@[]
                        placeholder:nil
                           progress:nil
                        postProcess:^UIImage *(UIImage *image) {
                           return image;
                        }
                         completion:nil];
    self.iconImageView.image = image;
}

- (void)setIsSmallIcon:(BOOL)isSmallIcon
{
    if (_isSmallIcon != isSmallIcon) {
        ACCMasReMaker(self.iconImageView, {
            if (isSmallIcon) {
                make.center.equalTo(self.backView);
                make.width.height.equalTo(@(32));
            } else {
                make.edges.equalTo(self.backView);
            }
        });
    }
    _isSmallIcon = isSmallIcon;
}

- (void)setIconStyle:(AWEBeautyCellIconStyle)iconStyle
{
    if (_iconStyle != iconStyle) {
        _iconStyle = iconStyle;
        [self configWithIconStyle: iconStyle];
    }
}

- (void)configWithIconStyle:(AWEBeautyCellIconStyle)iconStyle
{
    switch (iconStyle) {
        case AWEBeautyCellIconStyleRound:
            [self configWithRoundStyle];
            break;
        case AWEBeautyCellIconStyleSquare:
            [self configWithSquareStyle];
            break;
        default:
            break;
    }
}

- (void)configWithRoundStyle
{
    _backView.layer.cornerRadius = self.iconWidth / 2;
    _selectedIndicatorView.layer.cornerRadius = self.selectIndicatorWidth / 2;
}

- (void)configWithSquareStyle
{
    _backView.layer.cornerRadius = 4;
    _selectedIndicatorView.layer.cornerRadius = 6 + self.selectBorderWidth;
}

#pragma mark - seleted

- (void)makeSelected
{
    [self updateWithSelected:YES];
}

- (void)makeDeselected
{
    [self updateWithSelected:NO];
}

- (void)updateWithSelected:(BOOL)selected
{
    self.nameLabel.font = selected ? _selectedFont : _unselectedFont;
    
    self.nameLabel.textColor = selected ? self.namelblSelectColor : self.namelblUnSelectColor;
    self.selectedIndicatorView.hidden = !selected;
    self.appliedIndicator.backgroundColor = selected ? self.appliedIndicatorColor : self.appliedIndicatorUnSelectColor;
    if (selected && self.textFolded) {
        self.nameLabel.hidden = YES;
        self.rollingTitleView.hidden = NO;
        [self.rollingTitleView startAnimatingWithDuration:3 fromView:nil];
    } else {
        self.nameLabel.hidden = NO;
        self.rollingTitleView.hidden = YES;
        [self.rollingTitleView stopAnimatingWithCompletion:nil];
    }
}

// the white point
- (void)setApplied:(BOOL)applied
{
    if (!self.isNewStyle) {
        applied = NO;
    }
    _applied = applied;
    self.appliedIndicator.hidden = !self.shouldShowAppliedInidicator || !applied;
}

- (void)setAvailable:(BOOL)available
{
    self.iconImageView.alpha = available ? 1.f : 0.40f;
    self.nameLabel.alpha = 1.f;
    if (!available) {
        [self setApplied:NO];
        [self makeDeselected];
    }
}

- (void)setShouldShowAppliedIndicator:(BOOL)shouldShow
{
    _shouldShowAppliedInidicator = shouldShow;
    self.appliedIndicator.hidden = shouldShow ? !self.applied : YES;
}

- (void)setShouldShowAppliedIndicatorWhenSwitchIsEnabled:(BOOL)shouldShow
{
    _shouldShowAppliedInidicator = shouldShow;
    self.appliedIndicator.hidden = !self.applied;
}

- (void)setFlagDotViewHidden:(BOOL)hidden
{
    if (!hidden && !_flagDotView) {
        _flagDotView = [[UIView alloc] init];
        _flagDotView.layer.cornerRadius = 4;
        _flagDotView.layer.masksToBounds = YES;
        _flagDotView.backgroundColor = ACCResourceColor(ACCColorLink);
        _flagDotView.hidden = YES;
        [self.contentView addSubview:_flagDotView];
        
        ACCMasMaker(_flagDotView, {
            make.width.height.mas_equalTo(8);
            make.right.equalTo(self.backView.mas_right).offset(2);
            make.top.equalTo(self.backView.mas_top);
        });
    }
    _flagDotView.hidden = hidden;
}

- (void)enableCellItem:(BOOL)enabled
{
    CGFloat alpha = enabled ? 1 : 0.4;
    self.iconImageView.alpha = alpha;
    self.nameLabel.alpha = alpha;
    self.appliedIndicator.alpha = alpha;
}

#pragma mark - lazy init property

- (UIView *)backView
{
    if (!_backView) {
        _backView = [[UIView alloc] initWithFrame:CGRectZero];
        _backView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainerInverse);
        _backView.layer.masksToBounds = YES;
    }
    return _backView;
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _iconImageView;
}

- (UIView *)selectedIndicatorView
{
    if (!_selectedIndicatorView) {
        _selectedIndicatorView = [[UIView alloc] initWithFrame:CGRectZero];
        _selectedIndicatorView.layer.borderColor = self.selectedIndicatorViewColor.CGColor;
        _selectedIndicatorView.layer.borderWidth = self.selectBorderWidth;
        _selectedIndicatorView.hidden = YES;
    }
    return _selectedIndicatorView;
}

- (UIColor *)unselectedNameLabelTextColor {
    return ACCResourceColor(ACCUIColorConstTextInverse2);
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = self.namelblUnSelectColor;
        _nameLabel.font = [ACCFont() acc_systemFontOfSize:12 weight:ACCFontWeightRegular];
        _nameLabel.numberOfLines = 1;
        _nameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _nameLabel;
}

- (UIView *)appliedIndicator
{
    if (!_appliedIndicator) {
        _appliedIndicator = [[UIView alloc] init];
        _appliedIndicator.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer);
        _appliedIndicator.layer.cornerRadius = 2.f;
        _appliedIndicator.layer.masksToBounds = YES;
    }
    return _appliedIndicator;
}

- (AWETitleRollingTextView *)rollingTitleView
{
    if (!_rollingTitleView) {
        _rollingTitleView = [[AWETitleRollingTextView alloc] initWithFrame:CGRectMake(0, 0, [AWEComposerBeautyCollectionViewCell maxTextWidth], 15.f)];
    }
    return _rollingTitleView;
}

- (UIImageView *)downloadImgView
{
    if (!_downloadImgView) {
        _downloadImgView = [[UIImageView alloc] init];
        _downloadImgView.hidden = YES;
        _downloadImgView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _downloadImgView;
}

- (UIImageView *)downloadingImgView
{
    if (!_downloadingImgView) {
        _downloadingImgView = [[UIImageView alloc] init];
        _downloadingImgView.image = ACCResourceImage(@"icon60LoadingMiddle");
        _downloadingImgView.hidden = YES;
    }
    return _downloadingImgView;
}

- (void)setDownloadStatus:(AWEEffectDownloadStatus)downloadStatus
{
    _downloadStatus = downloadStatus;
    if (!self.isNewStyle) {
        downloadStatus = AWEEffectDownloadStatusDownloaded;
    }
    switch (downloadStatus) {
        case AWEEffectDownloadStatusDownloadFail:
        case AWEEffectDownloadStatusUndownloaded: {
            [self p_stopLoadingAnimation];
            NSString *imageName = @"iconStickerCellDownload";
            self.downloadImgView.image = ACCResourceImage(imageName);
            self.downloadImgView.hidden = NO;
            self.downloadingImgView.hidden = YES;
            [self setApplied:NO];
        }
            break;
        case AWEEffectDownloadStatusDownloading: {
            [self performSelector:@selector(p_startLoadingAnimation) withObject:nil afterDelay:0.3];
            self.downloadImgView.hidden = YES;
            self.downloadingImgView.hidden = NO;
            [self setApplied:NO];
        }
            break;
        case AWEEffectDownloadStatusDownloaded: {
            [self p_stopLoadingAnimation];
            self.downloadImgView.hidden = YES;
            self.downloadingImgView.hidden = YES;
        }
            break;
        default:
            break;
    }
}

+ (CGFloat)maxTextWidth
{
    // TO-DO: delete Magic number
    return 56; // Same as ACCBeautyUIDefaultConfiguration.cellWidth
}

#pragma mark - Animations

- (void)p_startLoadingAnimation
{
    [self.downloadingImgView.layer removeAllAnimations];
    [self.downloadingImgView.layer addAnimation:[self createRotationAnimation] forKey:@"transform.rotation.z"];
}

- (void)p_stopLoadingAnimation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(p_startLoadingAnimation) object:nil];
    [self.downloadingImgView.layer removeAllAnimations];
}

- (CAAnimation *)createRotationAnimation {

    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation * rotations * duration*/  ];
    rotationAnimation.duration = 0.8;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VAL;
    return rotationAnimation;
}

#pragma mark - for custom style

- (void)configRollingTitleViewColor:(UIColor *)color
{
    self.rollingTitleViewColor = color;
}

- (void)configSelectedIndicatorViewColor:(UIColor *)color
{
    self.selectedIndicatorViewColor = color;
    self.selectedIndicatorView.layer.borderColor = self.selectedIndicatorViewColor.CGColor;
}

- (void)configNamelblSelectColor:(UIColor *)color unSelect:(UIColor *)unSelectColor
{
    self.namelblSelectColor = color;
    self.namelblUnSelectColor = unSelectColor;
}

- (void)configAppliedIndicatorColor:(UIColor *)color unSelect:(UIColor *)unSelectColor
{
    self.appliedIndicatorColor = color;
    self.appliedIndicatorUnSelectColor = unSelectColor;
}

- (void)setIconWidth:(CGFloat)iconWidth {
    if (_iconWidth != iconWidth) {
        _iconWidth = iconWidth;
        [self.backView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.height.equalTo(@(iconWidth));
        }];
    }
}

- (void)setSelectIndicatorWidth:(CGFloat)selectIndicatorWidth {
    if (_selectIndicatorWidth != selectIndicatorWidth) {
        _selectIndicatorWidth = selectIndicatorWidth;
        [self.selectedIndicatorView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.height.equalTo(@(selectIndicatorWidth));
        }];
    }
}

- (void)setSelectBorderWidth:(CGFloat)selectBorderWidth {
    if (_selectBorderWidth != selectBorderWidth) {
        _selectBorderWidth = selectBorderWidth;
        [self configWithIconStyle:self.iconStyle];
    }
}

// add view above iconImage
- (void)addCoverIconImageView:(UIView *)view
{
    if (self.coverIconImageView) {
        [self.coverIconImageView removeFromSuperview];
        self.coverIconImageView = nil;
    }
    self.coverIconImageView = view;
    [self.iconImageView addSubview:view];
}

- (void)removeCoverIconImageView
{
    if (self.coverIconImageView) {
        [self.coverIconImageView removeFromSuperview];
        self.coverIconImageView = nil;
    }
}

@end
