//
//  CAKAlbumAssetListCell.m
//  CameraClient
//
//  Created by lixingdong on 2020/6/30.
//

#import <Photos/Photos.h>
#import <KVOController/KVOController.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "CAKAlbumAssetListCell.h"
#import "CAKPhotoManager.h"
#import "CAKCircularProgressView.h"
#import "CAKGradientView.h"
#import "UIColor+AlbumKit.h"
#import "CAKLanguageManager.h"
#import "UIImage+AlbumKit.h"
#import "UIImage+CAKUIKit.h"
#import "CAKAlbumAssetModel.h"

//#import <CameraClient/UIView+ACCRTL.h>

@interface CAKAlbumAssetListCell()

@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) CAKGradientView *selectedGradientView;
@property (nonatomic, strong) CAKGradientView *repeatSelectGradientView;

@property (nonatomic, strong) UIView *videoCellMaskView;
@property (nonatomic, strong) UIView *selectedCellMaskView;

@property (nonatomic, strong) UIImageView *unCheckImageView;
@property (nonatomic, strong) UIImageView *numberBackGroundImageView;
@property (nonatomic, strong) UIImageView *iCloudErrorImageView;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UILabel *hasSelectHintLabel;
@property (nonatomic, strong) UIButton *leftCornerTag;
@property (nonatomic, strong) UIImageView *favoriteImageView;

@property (nonatomic, assign) int32_t imageRequestID;

@property (nonatomic, strong) CAKCircularProgressView *circularProgressView;
@property (nonatomic, assign) BOOL animationFinished;

@property (nonatomic, assign) BOOL isCellAnimating;

@property (class, nonatomic, assign) CGFloat screenScale;

@end


@implementation CAKAlbumAssetListCell

static CGFloat _screenScale = 0;

+ (CGFloat)screenScale
{
    if (_screenScale == 0) {
        _screenScale = ACC_SCREEN_SCALE;
        if (_screenScale >= 2) {
            _screenScale = 2;
        }
        if (ACC_SCREEN_WIDTH > 700) {
            _screenScale = 1.5;
        }
    }
    return _screenScale;
}

+ (void)setScreenScale:(CGFloat)screenScale
{
    NSAssert(screenScale != 0, @"You can't set screen scale to 0");
    _screenScale = screenScale;
}

- (CGFloat)checkImageHeight
{
    return 22;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = CAKResourceColor(ACCUIColorConstBGContainer);
        self.clipsToBounds = YES;
        
        UIImageView *thumbnailImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        thumbnailImageView.backgroundColor = CAKResourceColor(ACCUIColorConstBGInput);
        thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        thumbnailImageView.clipsToBounds = YES;
        thumbnailImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth;
        _thumbnailImageView = thumbnailImageView;
        [self.contentView addSubview:thumbnailImageView];

        _videoCellMaskView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        BOOL shouldAdjustBlackMask = ACCConfigBool(ACCConfigKeyDefaultPair(@"studio_adjust_black_mask", @(NO)));
        if (shouldAdjustBlackMask) {
            UIImageView *cornerBlackImageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 40, _videoCellMaskView.bounds.size.width - 20, _videoCellMaskView.bounds.size.height - 40)];
            cornerBlackImageView.image = [UIImage cak_imageWithName:@"album_corner_shadow"];
            [_videoCellMaskView addSubview:cornerBlackImageView];
        }else {
            CAGradientLayer *gradient = [CAGradientLayer layer];
            gradient.frame = self.contentView.bounds;
            CGColorRef fromColor = CAKResourceColor(ACCColorSDTertiary).CGColor;
            CGColorRef toColor = [UIColor clearColor].CGColor;
            gradient.colors = @[(__bridge id)fromColor, (__bridge id)toColor];
            gradient.startPoint = CGPointMake(1, 1);
            gradient.endPoint = CGPointMake(0, 0);
            [_videoCellMaskView.layer addSublayer:gradient];
        }
        _videoCellMaskView.hidden = YES;
        [self.contentView addSubview:_videoCellMaskView];

        _selectedCellMaskView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        _selectedCellMaskView.backgroundColor = CAKResourceColor(ACCUIColorSDTertiary2);
        _selectedCellMaskView.hidden = YES;
        [self.contentView addSubview:_selectedCellMaskView];

        UILabel *label = [[UILabel alloc] init];
        label.textColor = CAKResourceColor(ACCUIColorConstTextInverse);
        label.font = [UIFont acc_systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentRight;
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        label.shadowOffset = CGSizeMake(0, 1);
        label.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.15];
        if ([ACCAccessibility() respondsToSelector:@selector(setAccessibilityProperty:isAccessibilityElement:)]) {
            [ACCAccessibility() setAccessibilityProperty:label isAccessibilityElement:NO];
        }
        [self.contentView addSubview:label];
        _timeLabel = label;
        
        UILabel *selectedlabel = [[UILabel alloc] init];
        selectedlabel.textColor = CAKResourceColor(ACCColorTextReverse2);
        selectedlabel.font = [UIFont acc_systemFontOfSize:10 weight:ACCFontWeightMedium];
        selectedlabel.text = CAKLocalizedString(@"creation_mv_upload_selected_label",@"已选");
        selectedlabel.textAlignment = NSTextAlignmentCenter;
        selectedlabel.backgroundColor = CAKResourceColor(ACCColorBGReverse);
        selectedlabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        selectedlabel.layer.masksToBounds = YES;
        selectedlabel.layer.cornerRadius = 2;
        selectedlabel.layer.borderColor = CAKResourceColor(ACCColorLineReverse2).CGColor;
        selectedlabel.layer.borderWidth = 0.5;
        [self.contentView addSubview:selectedlabel];
        _hasSelectHintLabel = selectedlabel;
        _hasSelectHintLabel.hidden = YES;
        
        [self configleftCornerTag];
        [self setUpfavoriteImageView];

        _selectedGradientView = [[CAKGradientView alloc] init];
        _selectedGradientView.gradientLayer.startPoint = CGPointMake(0, 0);
        _selectedGradientView.gradientLayer.endPoint = CGPointMake(0, 1);
        _selectedGradientView.gradientLayer.locations = @[@0, @1];
        _selectedGradientView.gradientLayer.colors = @[(__bridge id)[UIColor clearColor].CGColor,
                                                       (__bridge id)CAKResourceColor(ACCUIColorConstSDSecondary).CGColor];
        [self.contentView insertSubview:_selectedGradientView aboveSubview:_thumbnailImageView];
        
        _repeatSelectGradientView = [[CAKGradientView alloc] init];
        _repeatSelectGradientView.gradientLayer.startPoint = CGPointMake(1, 0);
        _repeatSelectGradientView.gradientLayer.endPoint = CGPointMake(0, 1);
        _repeatSelectGradientView.gradientLayer.locations = @[@0, @0.5];
        _repeatSelectGradientView.gradientLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0 alpha:0.2].CGColor,
                                                           (__bridge id)UIColor.clearColor.CGColor];
        _repeatSelectGradientView.hidden = YES;
        [self.contentView insertSubview:_repeatSelectGradientView aboveSubview:_thumbnailImageView];

        self.selectPhotoView = [[UIView alloc] init];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectAssetButtonClick:)];
        [self.selectPhotoView addGestureRecognizer:tapGesture];
        [self.contentView addSubview:self.selectPhotoView];
        
        CGFloat checkImageHeight = [self checkImageHeight];
        _unCheckImageView = [[UIImageView alloc] initWithImage:CAKResourceImage(@"icon_album_unselect")];
        [_selectPhotoView addSubview:_unCheckImageView];

        UIImage *cornerImage = [UIImage cak_imageWithSize:CGSizeMake(checkImageHeight, checkImageHeight) cornerRadius:checkImageHeight * 0.5 borderWidth:1.5 borderColor:[UIColor whiteColor] backgroundColor:CAKResourceColor(ACCColorPrimary)];
        _numberBackGroundImageView = [[UIImageView alloc] initWithImage:cornerImage];
        _numberLabel = [[UILabel alloc] init];
//        _numberLabel.accrtl_viewType = ACCRTLViewTypeNormal;
        _numberLabel.font = [UIFont acc_systemFontOfSize:13];
        _numberLabel.textColor = CAKResourceColor(ACCUIColorConstTextInverse);
        _numberLabel.textAlignment = NSTextAlignmentCenter;
        [_numberBackGroundImageView addSubview:_numberLabel];
        [_selectPhotoView addSubview:_numberBackGroundImageView];

        [self showAlreadySelectedHint:NO];
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.timeLabel.frame = CGRectMake(0, self.contentView.acc_height - 18, self.contentView.acc_right - 5, 15);
    
    self.hasSelectHintLabel.frame = CGRectMake(4, 6, 28, 16);
    
    self.selectedGradientView.frame = CGRectMake(0, self.contentView.acc_height * 0.5, self.contentView.acc_width, self.contentView.acc_height * 0.5);
    
    self.selectPhotoView.frame = CGRectMake(self.contentView.acc_right - 44, 0, 44, 44);
    
    self.repeatSelectGradientView.frame = CGRectMake(self.contentView.acc_right - 40, 0, 40, 40);;
    
    CGFloat checkImageHeight = [self checkImageHeight];
    
    self.unCheckImageView.frame = CGRectMake(38 - checkImageHeight, 6, checkImageHeight, checkImageHeight);
    self.numberBackGroundImageView.frame = self.unCheckImageView.frame;
    self.numberLabel.frame = self.numberBackGroundImageView.bounds;
}

- (void)configCircularProgressView
{
    if (self.circularProgressView) {
        return;
    }
    _circularProgressView = [[CAKCircularProgressView alloc] init];
    _iCloudErrorImageView = [[UIImageView alloc] initWithImage:CAKResourceImage(@"icloud_download_fail")];
    _iCloudErrorImageView.hidden = YES;
    [self.contentView addSubview:_iCloudErrorImageView];
    _circularProgressView.progressRadius = 4.f;
    _circularProgressView.backgroundWidth = 8.f;
    _circularProgressView.progressTintColor = CAKResourceColor(ACCUIColorConstBGContainer);
    _circularProgressView.progressBackgroundColor = [CAKResourceColor(ACCUIColorConstBGContainer) colorWithAlphaComponent:0.5];
    self.circularProgressView.frame = CGRectMake(2, self.contentView.acc_height - 22, 20, 20);
    self.iCloudErrorImageView.frame = self.circularProgressView.frame;
    _circularProgressView.lineWidth = 2.0;
    _circularProgressView.hidden = YES;
    [self.contentView addSubview:_circularProgressView];
}

- (void)configleftCornerTag
{
    _leftCornerTag = [[UIButton alloc] init];
    _leftCornerTag.userInteractionEnabled = NO;
    _leftCornerTag.backgroundColor = CAKResourceColor(ACCColorBGInverse3);
    _leftCornerTag.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    _leftCornerTag.layer.masksToBounds = YES;
    [_leftCornerTag.layer setCornerRadius:2];
    _leftCornerTag.contentEdgeInsets = UIEdgeInsetsMake(0, 3, 0, 3);
    _leftCornerTag.hidden = YES;
    [_leftCornerTag setTitleColor:CAKResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
    _leftCornerTag.titleLabel.font = [UIFont acc_systemFontOfSize:10 weight:ACCFontWeightMedium];
    _leftCornerTag.titleLabel.textAlignment = NSTextAlignmentCenter;
    _leftCornerTag.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _leftCornerTag.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_leftCornerTag];
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_leftCornerTag attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:6];
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:_leftCornerTag attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:6];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_leftCornerTag attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:16];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:_leftCornerTag attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.contentView attribute:NSLayoutAttributeWidth multiplier:1 constant:-46];
    [self.contentView addConstraints:@[left,top,height,width]];
}

- (void)setUpfavoriteImageView
{
    _favoriteImageView = [[UIImageView alloc] init];
    _favoriteImageView.hidden = YES;
    _favoriteImageView.image = CAKResourceImage(@"icon_favorite_symbol");
    [self.contentView addSubview:_favoriteImageView];
    ACCMasMaker(_favoriteImageView, {
        make.size.mas_equalTo(CGSizeMake(18, 18));
        make.bottom.equalTo(self.contentView).offset(-2);
        make.left.equalTo(self.contentView).offset(2);
    });
}

- (void)selectAssetButtonClick:(UIButton *)button
{
    if (self.isCellAnimating) {
        return;
    }
    // repeat select can't unselect asset
    BOOL willUnselectAsset = self.assetModel.selectedNum && !self.checkMaterialRepeatSelect;
    ACCBLOCK_INVOKE(self.didSelectedAssetBlock, self, willUnselectAsset);
}

- (void)doSelectedAnimation
{
    self.isCellAnimating = YES;
    
    if (self.checkMaterialRepeatSelect) {
        [self p_doRepeatSelectAnimation];
        self.isCellAnimating = NO;
        return;
    }
    
    UIView *fromView = nil;
    UIView *toView = nil;
    if (self.assetModel.selectedNum) {
        // select
        if (self.assetsSelectedIconStyle != CAKAlbumAssetsSelectedIconStyleCheckMark) {
            self.numberLabel.text = [NSString stringWithFormat:@"%@", @([self.assetModel.selectedNum integerValue])];
        } else {
            self.numberBackGroundImageView.image = CAKResourceImage(@"icon_album_selected_checkmark");
            [self.numberBackGroundImageView layoutIfNeeded];
        }
        fromView = self.unCheckImageView;
        toView = self.numberBackGroundImageView;

        self.selectedCellMaskView.hidden = NO;
        self.selectedCellMaskView.alpha = 0;
        self.thumbnailImageView.transform = CGAffineTransformIdentity;
        [UIView animateWithDuration:0.3 animations:^{
            self.thumbnailImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            self.selectedCellMaskView.alpha = 1;
        }];

    } else {
        // unselect
        self.numberLabel.text = nil;
        toView = self.unCheckImageView;
        fromView = self.numberBackGroundImageView;
        
        self.selectedCellMaskView.hidden = NO;
        self.selectedCellMaskView.alpha = 1;
        self.thumbnailImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        [UIView animateWithDuration:0.3 animations:^{
            self.thumbnailImageView.transform = CGAffineTransformIdentity;
            self.selectedCellMaskView.alpha = 0;
        }];
        
    }
    
    CGFloat firstAnimationDuration = 0.05;
    CGFloat secondAnimationDuration = 0.3;

    fromView.hidden = NO;
    fromView.transform = CGAffineTransformIdentity;
    fromView.alpha = 1;
    [UIView animateWithDuration:firstAnimationDuration animations:^{
        fromView.transform = CGAffineTransformMakeScale(0.3, 0.3);
        fromView.alpha = 0;
    } completion:^(BOOL finished) {
        fromView.hidden = YES;
        fromView.alpha = 1;
        fromView.transform = CGAffineTransformIdentity;
        
        toView.hidden = NO;
        toView.alpha = 0;
        toView.transform = CGAffineTransformMakeScale(0.3, 0.3);
        [UIView animateWithDuration:secondAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toView.alpha = 1;
            toView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            self.isCellAnimating = NO;
        }];
    }];
}

- (void)updateSelectStatus
{
    if (self.checkMaterialRepeatSelect) {
        [self p_updateRepeatSelectStatus];
        return;
    }
    
    if (self.assetModel.selectedNum) {
        self.contentView.alpha = 1;
        // select
        if (self.assetsSelectedIconStyle != CAKAlbumAssetsSelectedIconStyleCheckMark) {
            self.numberLabel.text = [NSString stringWithFormat:@"%@", @([self.assetModel.selectedNum integerValue])];
        } else {
            self.numberBackGroundImageView.image = CAKResourceImage(@"icon_album_selected_checkmark");
            [self.numberBackGroundImageView layoutIfNeeded];
        }

        self.unCheckImageView.hidden = YES;
        self.numberBackGroundImageView.hidden = NO;
        self.selectedCellMaskView.hidden = NO;
        self.selectedCellMaskView.alpha = 1;
    } else {
        // unselect
        self.unCheckImageView.hidden = NO;
        self.numberBackGroundImageView.hidden = YES;
        self.numberLabel.text = nil;
        self.selectedCellMaskView.hidden = NO;
        self.selectedCellMaskView.alpha = 0;
    }
}

- (void)showAlreadySelectedHint:(BOOL)show
{
    self.selectedGradientView.hidden = !show;
    self.hasSelectHintLabel.hidden = !show;
}

- (void)configureCellWithAsset:(CAKAlbumAssetModel *)assetModel greyMode:(BOOL)greyMode showRightTopIcon:(BOOL)showRightTopIcon
{
    [self configureCellWithAsset:assetModel greyMode:greyMode showRightTopIcon:showRightTopIcon alreadySelect:NO];
}

- (void)configureCellWithAsset:(CAKAlbumAssetModel *)assetModel greyMode:(BOOL)greyMode showRightTopIcon:(BOOL)showRightTopIcon alreadySelect:(BOOL)alreadySelect
{
    [self configureCellWithAsset:assetModel greyMode:greyMode showRightTopIcon:showRightTopIcon showGIFMark:NO alreadySelect:NO];
}

- (void)configureCellWithAsset:(CAKAlbumAssetModel *)assetModel greyMode:(BOOL)greyMode showRightTopIcon:(BOOL)showRightTopIcon showGIFMark:(BOOL)showGIFMark  alreadySelect:(BOOL)alreadySelect
{
    [self configCircularProgressView];
    
    if (self.checkMaterialRepeatSelect) {
        [self.numberBackGroundImageView removeFromSuperview];
        self.unCheckImageView.frame = CGRectMake(20, 4, 20, 20);
        self.unCheckImageView.image = CAKResourceImage(@"icon_album_normal_repeat_select");
        self.repeatSelectGradientView.hidden = NO;
    }
    
    [self removeiCloudKVOObservor];
    self.assetModel = assetModel;
    [self addiCloudKVOObservor];
    
    PHAsset *asset = self.assetModel.phAsset;
    if (asset.mediaType == PHAssetMediaTypeImage) {
        BOOL isGIF = NO;
        @try {
            isGIF = [[asset valueForKey:@"filename"] hasSuffix:@"GIF"];
        } @catch (NSException *exception) {}
        // CAKAlbumAssetModelMediaSubTypePhotoGif is not work cause of CAKAlbumAssetModel.m:67
        if (isGIF && showGIFMark) {
            self.videoCellMaskView.hidden = NO;
            self.timeLabel.hidden = NO;
            self.timeLabel.text = @"GIF";
        } else {
            self.videoCellMaskView.hidden = YES;
            self.timeLabel.hidden = YES;
        }
    } else {
        self.videoCellMaskView.hidden = NO;
        self.timeLabel.hidden = NO;
        self.timeLabel.text = self.assetModel.videoDuration;
    }
    if (asset.favorite) {
        self.favoriteImageView.hidden = NO;
    } else {
        self.favoriteImageView.hidden = YES;
    }
    [self showAlreadySelectedHint:alreadySelect];

    if (showRightTopIcon) {
        self.selectPhotoView.hidden = NO;
        [self updatePhotoSelectedWithNum:assetModel.selectedNum greyMode:greyMode];
    } else {
        self.selectPhotoView.hidden = YES;
    }
    
    self.thumbnailImageView.image = nil;
    self.thumbnailImageView.backgroundColor = CAKResourceColor(ACCColorBGInput);
    if (asset == nil) {
        return;
    }

    CGSize size = self.thumbnailImageView.bounds.size;
    CGFloat imageSizeWidth = size.width * [CAKAlbumAssetListCell screenScale];
    CGFloat imageSizeHeight = size.height * [CAKAlbumAssetListCell screenScale];
    CGSize imageSize = CGSizeMake(imageSizeWidth, imageSizeHeight);
    
    NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    __block int32_t imageRequestID = 0;
    @weakify(self);
    imageRequestID = [CAKPhotoManager getUIImageWithPHAsset:asset
                                                  imageSize:imageSize
                                       networkAccessAllowed:NO
                                            progressHandler:^(CGFloat progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {}
                                                 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        @strongify(self);
        if (assetModel == self.assetModel) {
            if (photo) {
                [self adjustThumbnailImageViewContentModeIfNeeded:photo];
                if (!isDegraded) {
                    self.imageRequestID = 0;
                    assetModel.coverImage = photo;
                    self.thumbnailImageView.image = photo;
                } else {
                    self.thumbnailImageView.image = photo;
                }
                assetModel.isDegraded = isDegraded;
                ACCBLOCK_INVOKE(self.didFetchThumbnailBlock,CFAbsoluteTimeGetCurrent() - start);
            }
        } else {
            [CAKPhotoManager cancelImageRequest:imageRequestID];
        }
    }];
    if (imageRequestID && self.imageRequestID && self.imageRequestID != imageRequestID) {
        [CAKPhotoManager cancelImageRequest:self.imageRequestID];
    }
    self.imageRequestID = imageRequestID;
}

- (void)adjustThumbnailImageViewContentModeIfNeeded:(UIImage *)currentImage
{
    if (!self.shouldAdjustThumbnailImageViewContentMode) {
        return;
    }

    UIColor *backgroundColor = CAKResourceColor(ACCUIColorConstBGInput);
    UIViewContentMode contentMode = UIViewContentModeScaleAspectFill;
    if (currentImage.size.width > currentImage.size.height) {
        backgroundColor = CAKResourceColor(ACCColorConstBGInverse);
        contentMode = UIViewContentModeScaleAspectFit;
    }

    self.thumbnailImageView.backgroundColor = backgroundColor;
    self.thumbnailImageView.contentMode = contentMode;
}

- (void)updatePhotoSelectedWithNum:(NSNumber *)number greyMode:(BOOL)greyMode
{
    if (self.checkMaterialRepeatSelect) {
        [self p_updateRepeatSelectStatusWithMode:greyMode];
        return;
    }
    
    [self updateGreyMode:greyMode withNum:number];
    if (number) {
        //check
        self.unCheckImageView.hidden = YES;
        self.numberBackGroundImageView.hidden = NO;
        if (self.assetsSelectedIconStyle != CAKAlbumAssetsSelectedIconStyleCheckMark) {
            self.numberLabel.text = [NSString stringWithFormat:@"%@", @([number integerValue])];
        } else {
            self.numberBackGroundImageView.image = CAKResourceImage(@"icon_album_selected_checkmark");
            [self.numberBackGroundImageView layoutIfNeeded];
        }
        //mask
        self.selectedCellMaskView.hidden = NO;
        self.selectedCellMaskView.alpha = 1;
        self.thumbnailImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } else {
        //check
        self.unCheckImageView.hidden = NO;
        self.numberBackGroundImageView.hidden = YES;
        self.numberLabel.text = nil;
        //mask
        self.selectedCellMaskView.hidden = YES;
        self.selectedCellMaskView.alpha = 0;
        self.thumbnailImageView.transform = CGAffineTransformIdentity;
    }
}

- (UIImage *)thumbnailImage
{
    return self.thumbnailImageView.image;
}

#pragma mark - update for material repeat select

- (void)p_doRepeatSelectAnimation
{
    if (self.assetModel.selectedNum) {
        self.hasSelectHintLabel.hidden = NO;
        self.repeatSelectGradientView.hidden = YES;
        //mask
        self.selectedCellMaskView.hidden = NO;
        self.thumbnailImageView.transform = CGAffineTransformIdentity;
        [UIView animateWithDuration:0.3 animations:^{
            self.thumbnailImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            self.selectedCellMaskView.alpha = 1;
        }];
        
    } else {
        self.hasSelectHintLabel.hidden = YES;
        self.repeatSelectGradientView.hidden = NO;
        //mask
        self.selectedCellMaskView.hidden = NO;
        self.selectedCellMaskView.alpha = 1;
        self.thumbnailImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        [UIView animateWithDuration:0.3 animations:^{
            self.thumbnailImageView.transform = CGAffineTransformIdentity;
            self.selectedCellMaskView.alpha = 0;
        }];
    }
}

- (void)p_updateRepeatSelectStatus
{
    if (self.assetModel.selectedNum) {
        self.contentView.alpha = 1;
        self.hasSelectHintLabel.hidden = NO;
        self.repeatSelectGradientView.hidden = YES;
        //mask
        self.selectedCellMaskView.hidden = NO;
        self.selectedCellMaskView.alpha = 1;
        self.thumbnailImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } else {
        self.hasSelectHintLabel.hidden = YES;
        self.repeatSelectGradientView.hidden = NO;
        //mask
        self.selectedCellMaskView.hidden = YES;
        self.selectedCellMaskView.alpha = 0;
        self.thumbnailImageView.transform = CGAffineTransformIdentity;
    }
}

- (void)p_updateRepeatSelectStatusWithMode:(BOOL)greyMode
{
    [self updateGreyMode:greyMode withNum:self.assetModel.selectedNum];
    if (self.assetModel.selectedNum) {
        self.hasSelectHintLabel.hidden = NO;
        self.repeatSelectGradientView.hidden = YES;
        //mask
        self.selectedCellMaskView.hidden = NO;
        self.selectedCellMaskView.alpha = 1;
        self.thumbnailImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } else {
        self.hasSelectHintLabel.hidden = YES;
        self.repeatSelectGradientView.hidden = NO;
        //mask
        self.selectedCellMaskView.hidden = YES;
        self.selectedCellMaskView.alpha = 0;
        self.thumbnailImageView.transform = CGAffineTransformIdentity;
    }
}

#pragma mark - icloud methods

- (void)runScaleAnimationWithCallback:(void(^)(void))callback {
    if (self.animationFinished) {
        ACCBLOCK_INVOKE(callback);
        return;
    }
    if (self.circularProgressView.hidden) {//only run animation one time
        self.circularProgressView.hidden = NO;
        self.animationFinished = NO;
        self.circularProgressView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
        [UIView animateWithDuration:0.25f animations:^{
            self.circularProgressView.transform = CGAffineTransformMakeScale(1.f, 1.f);
        } completion:^(BOOL finished) {
            self.circularProgressView.transform = CGAffineTransformIdentity;
            self.animationFinished = YES;
            self.circularProgressView.progress = self.assetModel.iCloudSyncProgress;
            ACCBLOCK_INVOKE(callback);
        }];
    } else {
        ACCBLOCK_INVOKE(callback);
    }
}

- (void)removeiCloudKVOObservor
{
    if (self.KVOController.observer) {
        [self.KVOController unobserve:self.assetModel];
    }
}

- (void)addiCloudKVOObservor
{
    self.timeLabel.hidden = NO;
    self.circularProgressView.hidden = YES;
    @weakify(self);
    [self.KVOController observe:self.assetModel keyPath:FBKVOClassKeyPath(CAKAlbumAssetModel,iCloudSyncProgress) options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        if (self.assetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                if (self.assetModel.didFailFetchingiCloudAsset) {
                    self.circularProgressView.hidden = YES;
                    self.timeLabel.hidden = NO;
                    self.iCloudErrorImageView.hidden = NO;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        @strongify(self);
                        self.iCloudErrorImageView.hidden = YES;
                    });
                    return;
                }
                CGFloat newValue = [change[NSKeyValueChangeNewKey] floatValue];
                
                if (newValue == 0.f && self.circularProgressView.hidden) {//多选-cell执行动画-同步中-取消-再多选-cell执行动画-同步中
                    self.animationFinished = NO;
                }
                [self runScaleAnimationWithCallback:^{
                    @strongify(self);
                    self.circularProgressView.progress = newValue;
                    
                    if (self.assetModel.iCloudSyncProgress >= 1.f || newValue >= 1.f) {
                        if (self.assetModel.canUnobserveAssetModel) {
                            [self.KVOController unobserve:self.assetModel];
                        }
                        if (!self.circularProgressView.hidden) {
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                @strongify(self);
                                self.timeLabel.hidden = NO;
                                self.circularProgressView.hidden = YES;
                            });
                        }
                    }
                }];
            });
        }
    }];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageRequestID = 0;
    // deal with memory issue set coverImage nil
    if (!self.assetModel.selectedNum && [CAKPhotoManager enableAlbumLoadOpt]) {
        self.assetModel.coverImage = nil;
    }
}

#pragma mark - Small-grained UI update methods

- (void)updateLeftCornerTagText:(NSString *)text
{
    [self.leftCornerTag setTitle:text forState:UIControlStateNormal];
}

- (void)updateLeftCornerTagShow:(BOOL)show
{
    self.leftCornerTag.hidden = !show;
}

- (void)enablefavoriteSymbolShow:(BOOL)enable
{
    if (enable == NO) {
        self.favoriteImageView.hidden = YES;
    }
}

- (void)updateAssetsMultiSelectMode:(BOOL)showRightTopIcon withAsset:(CAKAlbumAssetModel *)assetModel greyMode:(BOOL)greyMode
{
    if (showRightTopIcon) {
        self.selectPhotoView.hidden = NO;
    } else {
        self.selectPhotoView.hidden = YES;
    }
    [self updatePhotoSelectedWithNum:assetModel.selectedNum greyMode:greyMode];
}

- (void)updateGreyMode:(BOOL)greyMode withNum:(NSNumber *)number
{
    if (number) {
        self.contentView.alpha = 1;
    } else {
        if (greyMode) {
            self.contentView.alpha = 0.5;
        } else {
            self.contentView.alpha = 1;
        }
    }
}

- (void)updateNumberLabel:(NSNumber *)number
{
    if (number) {
        if (self.assetsSelectedIconStyle != CAKAlbumAssetsSelectedIconStyleCheckMark) {
            self.numberLabel.text = [NSString stringWithFormat:@"%@", @([number integerValue])];
        }
    } else {
        self.numberLabel.text = nil;
    }
}

#pragma mark - identifier

+ (NSString *)identifier
{
    return NSStringFromClass([self class]);
}

@end
