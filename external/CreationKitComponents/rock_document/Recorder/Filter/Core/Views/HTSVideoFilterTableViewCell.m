//
//  HTSVideoFilterTableViewCell.m
//  Pods
//
//Created by he Hai on 16 / 7 / 7
//
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "HTSVideoFilterTableViewCell.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

static const CGFloat kHTSVideoFilterTableViewCellSelectIndicatorEdge = 58.f;
static const CGFloat kHTSVideoFilterTableViewCellIconImageEdge = 52.f;
static const CGFloat kHTSVideoFilterTableViewCellBorderWidth = 2;

static NSString * const ACCVideoFilterTableViewNameLabelFont = @"acc_video_filter_tableview_namelabel_font";


@interface HTSVideoFilterTableViewCell ()

@property (nonatomic, strong) UIImageView *yesImageView;
@property (nonatomic, strong) UIImageView *statusIndicator;
@property (nonatomic, strong) IESEffectModel *filterModel;
@property (nonatomic, strong) UIView *coverView;
@property (nonatomic, strong) UIView *flagDotView;
@property (nonatomic, strong) UIView *selectedIndicatorView;

@end

@implementation HTSVideoFilterTableViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self reset];
}

- (void)commonInit
{
    self.contentView.clipsToBounds = NO;
    
    [self.contentView addSubview:self.coverView];
    ACCMasMaker(self.coverView, {
        make.left.top.width.equalTo(self.contentView);
        make.height.equalTo(self.contentView.mas_width);
    });
    
    self.previewImageView = [[UIImageView alloc] init];
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.coverView addSubview:self.previewImageView];
    ACCMasMaker(self.previewImageView, {
        make.center.equalTo(self.coverView);
        make.width.height.mas_equalTo(kHTSVideoFilterTableViewCellIconImageEdge);
    });

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.numberOfLines = 2;
    self.nameLabel.lineBreakMode =  NSLineBreakByTruncatingTail;
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.font = [ACCFont() acc_systemFontOfSize:12 weight:ACCFontWeightRegular];
    self.nameLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    ACC_LANGUAGE_DISABLE_LOCALIZATION(self.nameLabel);
    [self.contentView addSubview:self.nameLabel];
    ACCMasMaker(self.nameLabel, {
        make.top.equalTo(self.coverView.mas_bottom).offset(8);
        make.centerX.equalTo(self.coverView);
        make.width.mas_lessThanOrEqualTo(self.contentView);
    });

    [self.coverView addSubview:self.yesImageView];
    ACCMasMaker(self.yesImageView, {
        make.center.equalTo(self.coverView);
    });
    
    [self.contentView addSubview:self.selectedIndicatorView];
    ACCMasMaker(self.selectedIndicatorView, {
        make.width.height.equalTo(@(kHTSVideoFilterTableViewCellSelectIndicatorEdge));
        make.center.equalTo(self.coverView);
    });
    
    _statusIndicator = [[UIImageView alloc] init];
    self.statusIndicator.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.statusIndicator];
    [self.statusIndicator mas_makeConstraints:^(MASConstraintMaker *maker) {
        maker.width.equalTo(@16);
        maker.height.equalTo(@16);
        maker.right.equalTo(self.coverView);
        maker.bottom.equalTo(self.coverView);
    }];
    
    ACCMasReMaker(_coverView, {
        make.width.height.mas_equalTo(kHTSVideoFilterTableViewCellIconImageEdge);
        make.centerX.top.equalTo(self.contentView);
    });
    
    [self reset];
    [self configWithIconStyle:AWEFilterCellIconStyleRound];
}

- (void)setSelected:(BOOL)selected
{
    if (self.downloadStatus != AWEEffectDownloadStatusDownloaded) {
        [self reset];
        return;
    }
    if (selected) {
        self.nameLabel.textColor = self.selectedColor;
        self.yesImageView.hidden = YES;
    } else {
        self.nameLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        [self reset];
    }
    self.selectedIndicatorView.hidden = !selected;
}

- (void)setSelectedColor:(UIColor *)selectedColor
{
    _selectedColor = selectedColor;
    _selectedIndicatorView.layer.borderColor = selectedColor.CGColor;
}

- (void)setEnableSliderMaskImage:(BOOL)enableSliderMaskImage {
    if (_enableSliderMaskImage == enableSliderMaskImage) {
        return;
    }
    _enableSliderMaskImage = enableSliderMaskImage;
    self.yesImageView.image = [self yesImage];
}

- (void)setIconStyle:(AWEFilterCellIconStyle)iconStyle
{
    if (_iconStyle != iconStyle) {
        _iconStyle = iconStyle;
        [self configWithIconStyle: iconStyle];
    }
}

- (void)configWithIconStyle:(AWEFilterCellIconStyle)iconStyle
{
    CGSize imageSize = CGSizeMake(kHTSVideoFilterTableViewCellIconImageEdge, kHTSVideoFilterTableViewCellIconImageEdge);
    _selectedIndicatorView.layer.cornerRadius = [self selectedIndicatorCornerRadius];
    
    CGFloat radius = iconStyle == AWEFilterCellIconStyleRound ? kHTSVideoFilterTableViewCellIconImageEdge / 2 : 4;
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, imageSize.width, imageSize.height) cornerRadius:radius];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = maskPath.CGPath;
    maskLayer.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    _coverView.layer.mask = maskLayer;
}

- (void)reset
{
    self.yesImageView.hidden = YES;
}

- (UIImageView *)yesImageView {
    if (!_yesImageView) {
        UIImage *img = [self yesImage];
        _yesImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, img.size.width, img.size.height)];
        _yesImageView.image = img;
    }
    return _yesImageView;
}

- (UIView *)selectedIndicatorView
{
    if (!_selectedIndicatorView) {
        _selectedIndicatorView = [[UIView alloc] initWithFrame:CGRectZero];
        _selectedIndicatorView.layer.borderWidth = kHTSVideoFilterTableViewCellBorderWidth;
        _selectedIndicatorView.hidden = YES;
    }
    return _selectedIndicatorView;
}

- (UIView *)coverView
{
    if (!_coverView) {
        _coverView = [[UIImageView alloc] init];
        _coverView.backgroundColor = ACCUIColorFromRGBA(0xffffff, 0.15f);
    }
    return _coverView;
}

- (void)configWithFilter:(IESEffectModel *)filter
{
    [ACCWebImage() imageView:self.previewImageView
        setImageWithURLArray:filter.iconDownloadURLs
                 placeholder:ACCResourceImage(@"ic_loading_rect")
                  completion:nil];
    if (filter.builtinResource && 0 == filter.iconDownloadURLs.count) {
        UIImage *image = [UIImage imageWithContentsOfFile:filter.builtinIcon];
        [self setCenterImage:image];
    }
    self.filterModel = filter;
    self.nameLabel.text = filter.effectName;
}

- (CGFloat)selectedIndicatorCornerRadius
{
    if (self.iconStyle == AWEFilterCellIconStyleRound) {
        return kHTSVideoFilterTableViewCellSelectIndicatorEdge / 2;
    }
    return 4 + kHTSVideoFilterTableViewCellBorderWidth;
}

- (UIImage *)yesImage
{
    return self.enableSliderMaskImage ? ACCResourceImage(@"pictureFilterMark") : ACCResourceImage(@"icCameraDetermine");
}

- (void)setDownloadStatus:(AWEEffectDownloadStatus)downloadStatus {
    _downloadStatus = downloadStatus;
    switch (downloadStatus) {
        case AWEEffectDownloadStatusDownloadFail:
        case AWEEffectDownloadStatusUndownloaded: {
            [self stopDownloadAnimation];
            self.statusIndicator.transform = CGAffineTransformIdentity;
            self.statusIndicator.hidden = NO;
            self.statusIndicator.image = ACCResourceImage(@"icStickersEffectsDownload");
            break;
        }
        case AWEEffectDownloadStatusDownloading: {
            self.statusIndicator.transform = CGAffineTransformIdentity;
            self.statusIndicator.hidden = NO;
            self.statusIndicator.image = ACCResourceImage(@"icStickersEffectsLoading");
            [self startDownloadAnimation];
            break;
        }
        case AWEEffectDownloadStatusDownloaded: {
            [self stopDownloadAnimation];
            if (!self.statusIndicator.isHidden) {
                [UIView animateWithDuration:0.2
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                                     self.statusIndicator.transform = CGAffineTransformMakeScale(0.001, 0.001);
                                 }
                                 completion:^(BOOL finish) {
                                     self.statusIndicator.hidden = YES;
                                 }];
            }
            break;
        }
    }
}

- (void)setCenterImage:(UIImage *)image
{
    self.previewImageView.image = image;
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
            make.right.equalTo(self.coverView.mas_right).offset(2);
            make.top.equalTo(self.coverView.mas_top);
        });
    }
    _flagDotView.hidden = hidden;
}

- (NSString *)getEffectName
{
    return self.filterModel.effectName;
}

- (void)startDownloadAnimation {
    [self.statusIndicator.layer removeAllAnimations];
    [self.statusIndicator.layer addAnimation:[self createRotationAnimation] forKey:@"transform.rotation.z"];
}

- (void)stopDownloadAnimation {
    [self.statusIndicator.layer removeAllAnimations];
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

@end
