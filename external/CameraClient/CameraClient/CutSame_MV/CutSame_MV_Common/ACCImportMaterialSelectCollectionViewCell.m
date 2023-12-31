//
//  ACCImportMaterialSelectCollectionViewCell.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/5.
//

#import "ACCImportMaterialSelectCollectionViewCell.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

static CGFloat const ACCImportMaterialSelectDeleteBtnWH = 26.0;

@implementation ACCImportMaterialSelectCollectionViewCellModel
@end

@interface ACCImportMaterialSelectCollectionViewCell ()

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UILabel *timeLabel;

@end

@implementation ACCImportMaterialSelectCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupUI];
    }
    
    return self;
}

- (void)setupUI
{
    self.contentView.layer.cornerRadius = 2;
    [self.contentView addSubview:self.bgView];
    [self.contentView addSubview:self.thumbnailImageView];
    [self.thumbnailImageView addSubview:self.deleteButton];

    [self.contentView addSubview:self.maskView];

    [self.contentView addSubview:self.timeLabel];
    ACCMasMaker(self.timeLabel, {
        make.bottom.equalTo(self.mas_bottom).offset(-2);
        make.right.equalTo(self.mas_right).offset(-4);
    });
}

- (void)bindModel:(ACCImportMaterialSelectCollectionViewCellModel *)cellModel
{
    _cellModel = cellModel;
    self.timeLabel.text = [NSString stringWithFormat:ACCLocalizedString(@"mv_footage_duration", @"%.1f秒"), cellModel.duration];

    UIColor *bgViewColor = ACCResourceColor(ACCColorBGInputReverse);
    if (self.cellModel.shouldChangeCellColor) {
        bgViewColor = ACCResourceColor(ACCColorBGPlaceholderDefault);
    }
    self.bgView.backgroundColor = bgViewColor;

    if (cellModel.assetModel.coverImage) {
        self.userInteractionEnabled = YES;
        self.thumbnailImageView.hidden = NO;
        self.maskView.hidden = NO;
        self.thumbnailImageView.image = cellModel.assetModel.coverImage;
        self.timeLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
    } else {
        self.userInteractionEnabled = NO;
        self.thumbnailImageView.hidden = YES;
        self.maskView.hidden = YES;
        UIColor *timeLabelColor = ACCResourceColor(ACCColorTextReverse4);
        if (cellModel.shouldChangeCellColor) {
            timeLabelColor = ACCResourceColor(ACCColorConstTextInverse);
        }
        self.timeLabel.textColor = timeLabelColor;
        if (cellModel.highlight) {
            self.bgView.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
            self.bgView.layer.borderWidth = 2.0;
        } else {
            UIColor *bgViewBorderColor = ACCResourceColor(ACCColorLineReverse2);
            if (cellModel.shouldChangeCellColor) {
                bgViewBorderColor = ACCResourceColor(ACCColorConstLineInverse);
            }
            self.bgView.layer.borderColor = bgViewBorderColor.CGColor;
            self.bgView.layer.borderWidth = 0.5;
        }
    }
    self.timeLabel.hidden = !cellModel.shouldShowDuration;
}

- (void)onDeleteAction:(UIButton *)sender
{
    ACCBLOCK_INVOKE(self.deleteAction, self);
}

#pragma mark - Lazy load properties
- (UIView *)bgView
{
    if (!_bgView) {
        _bgView = [[UIView alloc] initWithFrame:self.bounds];
        _bgView.backgroundColor = [UIColor clearColor];
        _bgView.layer.cornerRadius = 2.0;
        _bgView.clipsToBounds = YES;
    }
    
    return _bgView;
}

- (UIImageView *)thumbnailImageView
{
    if (!_thumbnailImageView) {
        _thumbnailImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _thumbnailImageView.userInteractionEnabled = YES;
        _thumbnailImageView.layer.cornerRadius = 2.0;
        _thumbnailImageView.clipsToBounds = YES;
        _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    return _thumbnailImageView;
}

- (UIView *)maskView
{
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.bounds];
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.contentView.bounds;
        CGColorRef fromColor = ACCResourceColor(ACCColorSDTertiary).CGColor;
        CGColorRef toColor = [UIColor clearColor].CGColor;
        gradient.colors = @[(__bridge id)fromColor, (__bridge id)toColor];
        gradient.startPoint = CGPointMake(1, 1);
        gradient.endPoint = CGPointMake(0, 0);
        [_maskView.layer addSublayer:gradient];
        _maskView.hidden = YES;
        _maskView.userInteractionEnabled = NO;
    }
    return _maskView;
}

- (UIButton *)deleteButton
{
    if (!_deleteButton) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteButton.frame = CGRectMake(self.bounds.size.width-ACCImportMaterialSelectDeleteBtnWH, 0,
                                         ACCImportMaterialSelectDeleteBtnWH, ACCImportMaterialSelectDeleteBtnWH);
        _deleteButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
        _deleteButton.imageEdgeInsets = UIEdgeInsetsMake(0, 10, 10, 0);
        _deleteButton.isAccessibilityElement = YES;
        _deleteButton.accessibilityLabel = ACCLocalizedString(@"creation_cancel_asset_selection", @"取消选择");
        [_deleteButton setImage:ACCResourceImage(@"icSelectedDelete") forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(onDeleteAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _deleteButton;
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
        _timeLabel.textColor = ACCResourceColor(ACCColorTextReverse4);
        [_timeLabel sizeToFit];
    }
    
    return _timeLabel;
}

@end
