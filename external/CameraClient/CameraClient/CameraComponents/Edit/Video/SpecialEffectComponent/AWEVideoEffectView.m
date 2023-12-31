//
//  AWEVideoEffectView.m
//  Aweme
//
//  Created by hanxu on 2017/4/10.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWERepoVoiceChangerModel.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVideoEffectView.h"
#import <CreationKitArch/HTSVideoSepcialEffect.h>
#import <CameraClient/ACCButton.h>
#import <CreationKitArch/AWEEffectFilterDataManager.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreationKitArch/AWEScrollStringLabel.h>
#import <CreativeKit/ACCResourceUnion.h>
#import <IESLiveResourcesButler/IESLiveResourceBundle+File.h>
#import <UIKit/UIFeedbackGenerator.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCI18NConfigProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitArch/ACCVoiceEffectSegment.h>

static const CGFloat kAWEVideoEffectViewCollectionCellFontSize = 11;
static const CGFloat kAWEVideoEffectViewCollectionCellLabelHeight = 14;
static const CGFloat kAWEVideoEffectViewCollectionCellImageSize = 56.f;

@interface AWEVideoEffectViewCollectionCell()
@property (nonatomic, strong) UIImageView *statusIndicator;
@property (nonatomic, strong) UIView *imageBackgroundView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGes;
@property (nonatomic, strong) UILongPressGestureRecognizer *longGes;
@property (nonatomic, assign) AWEVideoEffectViewType type;
@end

@implementation AWEVideoEffectViewCollectionCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
        self.exclusiveTouch = NO;
        [self.contentView addGestureRecognizer:self.tapGes];
        [self.contentView addGestureRecognizer:self.longGes];
    }
    return self;
}

- (void)commonInit
{
    [self.contentView addSubview:self.imageBackgroundView];
    ACCMasMaker(self.imageBackgroundView, {
        make.top.equalTo(self.contentView).offset(10);
        make.centerX.equalTo(self.contentView);
        make.width.height.equalTo(@52);
    });
    
    YYAnimatedImageView *imageView = [[YYAnimatedImageView alloc] init];
    [self.imageBackgroundView addSubview:imageView];
    ACCMasMaker(imageView, {
        make.center.equalTo(self.imageBackgroundView);
        make.size.mas_equalTo(CGSizeZero);
    });
    _imageView = imageView;
    _imageBackgroundView.layer.cornerRadius = 52 / 2.f;
    _imageBackgroundView.layer.masksToBounds = YES;
    
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.numberOfLines = 2;
    nameLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    nameLabel.font = [ACCFont() acc_systemFontOfSize:kAWEVideoEffectViewCollectionCellFontSize
                                              weight:ACCFontWeightRegular];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.contentView addSubview:nameLabel];
    ACCMasMaker(nameLabel, {
        make.top.equalTo(self.imageBackgroundView.mas_bottom).offset(10);
        make.centerX.equalTo(self.contentView);
        make.width.equalTo(self.contentView);
        make.height.lessThanOrEqualTo(@35);
    });
    self.nameLabel = nameLabel;

    _statusIndicator = [[UIImageView alloc] init];
    self.statusIndicator.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.statusIndicator];
    [self.statusIndicator mas_makeConstraints:^(MASConstraintMaker *maker) {
        maker.width.equalTo(@16);
        maker.height.equalTo(@16);
        maker.right.equalTo(self.imageView);
        maker.bottom.equalTo(self.imageView);
    }];
    self.isAccessibilityElement = YES;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (selected) {
        self.colorView.backgroundColor = self.coverColor;
        self.colorView.image = ACCResourceImage(@"icCameraDetermine");
        [UIView animateWithDuration:.2 animations:^{
            self.colorView.alpha = 1;
        }];
    } else {
        self.colorView.backgroundColor = self.coverColor;
        self.colorView.image = [UIImage new];
        [UIView animateWithDuration:.2 animations:^{
            self.colorView.alpha = 0;
        }];
    }
}

- (UIImageView *)colorView
{
    if (_colorView == nil) {
        _colorView = [[UIImageView alloc] initWithFrame:self.imageView.frame];
        _colorView.contentMode = UIViewContentModeCenter;
        _colorView.layer.cornerRadius = 25;
        _colorView.alpha = 0;
        [self.contentView addSubview:_colorView];
        ACCMasMaker(_colorView, {
            make.centerX.centerY.equalTo(self.imageView);
            make.width.height.equalTo(@(kAWEVideoEffectViewCollectionCellImageSize));
        });
    }
    return _colorView;
}

- (UIView *)imageBackgroundView
{
    if (!_imageBackgroundView) {
        _imageBackgroundView = [[UIImageView alloc] init];
        _imageBackgroundView.backgroundColor = ACCUIColorFromRGBA(0xffffff, 0.15f);
    }
    return _imageBackgroundView;
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

- (void)updateText:(NSString *)text
{
    self.nameLabel.text = text;
}

- (void)setCenterImage:(UIImage *)img size:(CGSize)size
{
    acc_dispatch_main_async_safe(^{
        self.imageView.image = img;
        ACCMasUpdate(self.imageView, {
            make.size.mas_equalTo(size);
        });
    });
}

- (UILongPressGestureRecognizer *)longGes
{
    if (_longGes == nil) {
        _longGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedAnimationWithGesture:)];
        _longGes.minimumPressDuration = 0.1;
        _longGes.cancelsTouchesInView = NO;
    }
    return _longGes;
}

- (UITapGestureRecognizer *)tapGes
{
    if (!_tapGes) {
        _tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAnimation)];
        _tapGes.cancelsTouchesInView = NO;
    }
    return _tapGes;
}

- (void)longPressedAnimationWithGesture:(UILongPressGestureRecognizer *)ges
{
    if (self.type == AWEVideoEffectViewTypeFilter) {
        return;
    }
    CATransform3D transform = CATransform3DIdentity;
    switch (ges.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:{
            transform = CATransform3DMakeScale(1.1, 1.1, 1.1);
            break;
        }
        default:
            transform = CATransform3DIdentity;
            break;
    }
    [UIView animateWithDuration:0.1 animations:^{
        self.imageBackgroundView.layer.transform = transform;
    }];
}

- (void)tapAnimation
{
    if (self.type == AWEVideoEffectViewTypeFilter) {
        return;
    }
    [UIView animateWithDuration:0.1 animations:^{
        self.imageBackgroundView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1.1);
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.imageBackgroundView.layer.transform = CATransform3DIdentity;
            }];
        }
    }];
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.nameLabel.text;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

@end

@interface AWEVideoEffectViewFilterCell ()
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
@end

@implementation AWEVideoEffectViewFilterCell
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self.contentView addGestureRecognizer:self.longPressGesture];
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{   // override, do nothing
}

- (UILongPressGestureRecognizer *)longPressGesture
{
    if (_longPressGesture == nil) {
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        _longPressGesture.minimumPressDuration = 0.1;
    }
    return _longPressGesture;
}

- (void)longPress:(UILongPressGestureRecognizer *)gesture
{
    if (self.longPressBlock) {
        self.longPressBlock(self, gesture.state);
    }
}
@end

@interface AWEVideoEffectViewTimeCell ()
@property (nonatomic, strong) UIView *selectedIndicatorView;
@property (nonatomic, strong) AWEScrollStringLabel *titleLabel;
@end

@implementation AWEVideoEffectViewTimeCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self.contentView addSubview:self.selectedIndicatorView];
        [self.selectedIndicatorView mas_makeConstraints:^(MASConstraintMaker *maker) {
            maker.center.equalTo(self.imageView);
            maker.width.height.equalTo(@(kAWEVideoEffectViewCollectionCellImageSize));
        }];
        self.selectedIndicatorView.layer.cornerRadius = kAWEVideoEffectViewCollectionCellImageSize / 2.0;
        
        [self.contentView addSubview:self.titleLabel];
        ACCMasMaker(self.titleLabel, {
            make.top.equalTo(self.imageBackgroundView.mas_bottom).offset(8);
            make.centerX.equalTo(self.contentView);
            make.width.equalTo(@60);
            make.height.equalTo(@18);
        });
        self.nameLabel.hidden = YES;
        self.titleLabel.hidden = NO;
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{
}

- (UIView *)selectedIndicatorView
{
    if (!_selectedIndicatorView) {
        _selectedIndicatorView = [[UIView alloc] init];
        _selectedIndicatorView.backgroundColor = [UIColor clearColor];
        _selectedIndicatorView.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
        _selectedIndicatorView.layer.borderWidth = 2;
        _selectedIndicatorView.alpha = 0.0f;
    }
    return _selectedIndicatorView;
}

- (void)updateText:(NSString *)text
{
    acc_dispatch_main_async_safe(^{
        [self.titleLabel configWithTitleWithTextAlignCenter:text
                                                 titleColor:ACCColorFromRGBA(255, 255, 255, 1.f)
                                                   fontSize:kAWEVideoEffectViewCollectionCellFontSize
                                                     isBold:NO
                                                contentSize:CGSizeMake(60,kAWEVideoEffectViewCollectionCellLabelHeight)];
    });
}

- (AWEScrollStringLabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[AWEScrollStringLabel alloc] initWithHeight:kAWEVideoEffectViewCollectionCellLabelHeight type:AWEScrollStringLabelTypeVoiceEffect];
    }
    return _titleLabel;
}

- (NSString *)accessibilityLabel
{
    return self.titleLabel.leftLabel.text;
}
@end


@implementation AWEVideoEffectViewTransitionCell
- (UIImageView *)colorView {
    return nil;
}
@end

@interface AWEVideoEffectViewToolCell ()

@property (nonatomic, strong) UIView *selectedIndicatorView;
@property (nonatomic, strong) AWEScrollStringLabel *titleLabel;

@end

@implementation AWEVideoEffectViewToolCell
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.imageView.layer.cornerRadius = 0;
        self.imageView.layer.masksToBounds = NO;
        self.colorView.layer.cornerRadius = 0;
        self.colorView.layer.masksToBounds = NO;
        self.imageBackgroundView.layer.cornerRadius = 0;
        self.imageBackgroundView.backgroundColor = UIColor.clearColor;
        [self.contentView addSubview:self.selectedIndicatorView];
        [self.selectedIndicatorView mas_makeConstraints:^(MASConstraintMaker *maker) {
            maker.center.equalTo(self.imageView);
            maker.width.height.equalTo(@(kAWEVideoEffectViewCollectionCellImageSize));
        }];
        [self.contentView addSubview:self.titleLabel];
        ACCMasMaker(self.titleLabel, {
            make.top.equalTo(self.imageBackgroundView.mas_bottom).offset(10);
            make.centerX.equalTo(self.contentView);
            make.width.equalTo(@60);
            make.height.equalTo(@14);
        });
        self.nameLabel.hidden = YES;
        self.titleLabel.hidden = NO;
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{
    if (self.downloadStatus != AWEEffectDownloadStatusDownloaded) {
        self.selectedIndicatorView.alpha = 0;
        return;
    }
    if (selected) {
        [UIView animateWithDuration:0.2 animations:^{
            self.selectedIndicatorView.alpha = 1;
            [self.titleLabel updateTextColor:ACCResourceColor(ACCColorPrimary)];
        }];
        [self.titleLabel startAnimation];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.selectedIndicatorView.alpha = 0;
            [self.titleLabel updateTextColor:ACCColorFromRGBA(255, 255, 255, 1.f)];
        }];
        [self.titleLabel stopAnimation];
    }
}

- (UIView *)selectedIndicatorView
{
    if (!_selectedIndicatorView) {
        _selectedIndicatorView = [[UIView alloc] init];
        _selectedIndicatorView.backgroundColor = [UIColor clearColor];
        _selectedIndicatorView.layer.cornerRadius = 6;
        _selectedIndicatorView.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
        _selectedIndicatorView.layer.borderWidth = 2;
        _selectedIndicatorView.alpha = 0.0f;
    }
    return _selectedIndicatorView;
}

- (void)updateText:(NSString *)text
{
    
    [self.titleLabel configWithTitleWithTextAlignCenter:text
                                             titleColor:ACCColorFromRGBA(255, 255, 255, 1.f)
                                               fontSize:kAWEVideoEffectViewCollectionCellFontSize
                                                 isBold:NO
                                            contentSize:CGSizeMake(60,kAWEVideoEffectViewCollectionCellLabelHeight)];
}

- (AWEScrollStringLabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[AWEScrollStringLabel alloc] initWithHeight:kAWEVideoEffectViewCollectionCellLabelHeight type:AWEScrollStringLabelTypeVoiceEffect];
    }
    return _titleLabel;
}

- (NSString *)accessibilityLabel
{
    return self.titleLabel.leftLabel.text;
}

@end

@interface AWEVideoEffectView ()<UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) ACCButton *revokeBtn;
@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *loadingView;

@property (nonatomic, copy) NSArray<HTSVideoSepcialEffect *> *timeEffects;
@property (nonatomic, copy) NSArray<IESEffectModel *> *effects;

@property (nonatomic, copy, readwrite) NSString *effectCategory; //特效所属分类
@property (nonatomic, strong, readwrite) IESEffectModel *selectedToolEffect; //选中的道具特效
@property (nonatomic, getter=isLongPressing) BOOL longPressing;

@end


@implementation AWEVideoEffectView

- (instancetype)initWithType:(AWEVideoEffectViewType)type
                     effects:(nullable NSArray<IESEffectModel *> *)effects
              effectCategory:(nullable NSString *)effectCategory
                publishModel:(AWEVideoPublishViewModel *)publishModel
{
    if (self = [super init]) {
        _type = type;
        _effectCategory = [effectCategory copy];
        _longPressing = NO;
        _publishModel = publishModel;
        
        [self setBackgroundColor:[UIColor clearColor]];
        
        [self addSubview:self.loadingView];
        [self addSubview:self.textLabel];
        [self addSubview:self.collectionView];
        
        switch (type) {
            case AWEVideoEffectViewTypeTime:{
                self.timeEffects = [HTSVideoSepcialEffect allEffects];
                if ([self hasValidMultiVoiceEffectSegment]) {
                    self.textLabel.text = ACCLocalizedString(@"by_section_disabled_hint", @"Voice effects are applied. You can use reverse motion.");
                }
            }
                break;
                
            case AWEVideoEffectViewTypeTool: {
                self.effects = effects;
                self.textLabel.text = ACCLocalizedString(@"av_effect_sticker_hint", @"av_effect_sticker_hint");
            }
                break;
                
            case AWEVideoEffectViewTypeTransition: {
                self.effects = effects;
                self.textLabel.text = ACCLocalizedString(@"effect_trans_hint",@"effect_trans_hint");
                [self addSubview:self.revokeBtn];
                ACCMasMaker(self.revokeBtn, {
                    make.trailing.equalTo(self.revokeBtn.superview.mas_trailing).offset(-16);
                    make.top.equalTo(self.revokeBtn.superview.mas_top).offset(12);
                    make.height.equalTo(@(28));
                });
            }
                break;
                
            case AWEVideoEffectViewTypeFilter: {
                self.effects = effects;
                self.textLabel.text = ACCLocalizedString(@"effect_hint1",@"effect_hint1");
                [self addSubview:self.revokeBtn];
                ACCMasMaker(self.revokeBtn, {
                    make.trailing.equalTo(self.revokeBtn.superview.mas_trailing).offset(-16);
                    make.top.equalTo(self.revokeBtn.superview.mas_top).offset(12);
                    make.height.equalTo(@(28));
                });
            }
                break;
        }

        if (self.type != AWEVideoEffectViewTypeTime && effects.count == 0) {
            [self p_startLoadingAnim];
        }
    }
    return self;
}

- (void)updateWithType:(AWEVideoEffectViewType)type
               effects:(nullable NSArray<IESEffectModel *> *)effects
        effectCategory:(nullable NSString *)effectCategory
{
    if (self.isLongPressing) {
        return;
    }
    
    switch (type) {
        case AWEVideoEffectViewTypeTime:{
            self.timeEffects = [HTSVideoSepcialEffect allEffects];
        }
            break;
            
        case AWEVideoEffectViewTypeTool:
        case AWEVideoEffectViewTypeTransition:
        case AWEVideoEffectViewTypeFilter: {
            self.effects = effects;
        }
            break;
    }
    
    if (self.type != AWEVideoEffectViewTypeTime) {
        if (effects.count == 0) {
            [self p_startLoadingAnim];
        } else {
            [self p_stopLoadingAnim];
        }
    }
    
    [self.collectionView reloadData];
}

- (void)updateCellWithEffect:(nullable IESEffectModel *)effect {
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems) {
        if (indexPath.row < self.effects.count && self.effects[indexPath.row] == effect) {
            AWEVideoEffectViewCollectionCell *cell = (AWEVideoEffectViewCollectionCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            if (cell) {
                acc_dispatch_main_async_safe(^{
                    [self configCell:cell withEffect:effect];
                });
            } else {
                acc_dispatch_main_async_safe(^{
                    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                });
            }
            break;
        }
    }
}

- (void)updateCellWithTimeEffect:(HTSPlayerTimeMachineType)type{
    HTSVideoSepcialEffect *timeEffect = [HTSVideoSepcialEffect effectWithType:type];
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems) {
        if (indexPath.row < self.timeEffects.count && self.timeEffects[indexPath.row] == timeEffect) {
            AWEVideoEffectViewCollectionCell *cell = (AWEVideoEffectViewCollectionCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            if (cell) {
                if (timeEffect.forbidden) {
                    cell.alpha = 0.5;
                } else {
                    cell.alpha = 1;
                }
            } else {
                acc_dispatch_main_async_safe(^{
                    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                });
            }
            break;
        }
    }
}

- (void)reload
{
    [self.collectionView reloadData];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (AWEVideoEffectViewTypeTool == self.type) {
        self.textLabel.frame = CGRectMake(15, 11, self.frame.size.width - 30, 30);
    } else {
        self.textLabel.frame = CGRectMake(15, 11, self.frame.size.width - 15 - 20 - 60, 30);
    }
    CGFloat offsetY = self.frame.size.height - 118;
    if (self.hideEffectCategoryMessage) {
        offsetY = offsetY / 2.0;
    }
    self.collectionView.frame = CGRectMake(0, offsetY, self.frame.size.width, 118);
    self.loadingView.center = self.collectionView.center;
}

- (void)longPressedAnimationStart:(AWEVideoEffectViewCollectionCell *)cell
{
    CGFloat scale = 1.2;
    CATransform3D transform = CATransform3DMakeScale(scale, scale, scale);
    [UIView animateWithDuration:0.1 animations:^{
        cell.imageBackgroundView.layer.transform = transform;
    }];
}

- (void)setPublishModel:(AWEVideoPublishViewModel *)publishModel {
    _publishModel = publishModel;
    if (self.type == AWEVideoEffectViewTypeTime) {
        if (![self hasValidMultiVoiceEffectSegment]) {
            self.textLabel.text = ACCLocalizedString(@"effect_time_click", @"Tap to use time warp effects");;
        } else {
            self.textLabel.text = ACCLocalizedString(@"by_section_disabled_hint", @"Voice effects are applied. You can use reverse motion.");
        }
    }
}

#pragma mark - Public

- (NSString *)effectCategoryTitle
{
    return self.textLabel.text;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    switch (self.type) {
        case AWEVideoEffectViewTypeFilter:
        case AWEVideoEffectViewTypeTool:
        case AWEVideoEffectViewTypeTransition:
            return self.effects.count;
        case AWEVideoEffectViewTypeTime:
            return self.timeEffects.count;
    }
    return 0;
}

- (void)configCell:(AWEVideoEffectViewCollectionCell *)cell withEffect:(IESEffectModel *)effect {
    if (effect.builtinIcon) {
        NSMutableString *gifName = [NSMutableString stringWithString:effect.builtinIcon];
        if (![[gifName lowercaseString] containsString:@".gif"]) {
            [gifName appendString:@".gif"];
        }
        NSString *path = ACCResourceUnion.cameraResourceBundle.filePath(gifName);
        if (![path length]) {
            NSMutableString *webpName = [NSMutableString stringWithString:effect.builtinIcon];
            if (![[webpName lowercaseString] containsString:@".webp"]) {
                [webpName appendString:@".webp"];
            }
            path = ACCResourceFile(webpName);
        }
        @autoreleasepool {
            YYImage *image = [YYImage imageWithContentsOfFile:path];
            UIImage *coverImage = [self effectCoverNeedReduce] ? [self staticImageWithImage:image] : image;
            cell.imageView.image = coverImage;
        }
    } else {
        [cell setCenterImage:nil size:CGSizeMake(32, 32)];
        @autoreleasepool {
            @weakify(cell);
            @weakify(self);
            [ACCWebImage() imageView:cell.imageView setImageWithURLArray:effect.iconDownloadURLs placeholder:ACCResourceImage(@"tool_EffectLoadingIcon") completion:^(UIImage *image, NSURL *url, NSError *error) {
                @strongify(cell);
                @strongify(self);
                if (image != nil) {
                    image = [self effectCoverNeedReduce] ? [self staticImageWithImage:image] : image;
                    [cell setCenterImage:image size:CGSizeMake(52, 52)];
                }
            }];
        }
    }
    cell.downloadStatus = [[AWEEffectFilterDataManager defaultManager] downloadStatusOfEffect:effect];
    //cell.nameLabel.text = effect.effectName;
    [cell updateText:effect.effectName];
    // draw select indicator if needed
    [cell setSelected:[self.selectedToolEffect isEqual:effect]];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)acell forItemAtIndexPath:(NSIndexPath *)indexPath {
    AWEVideoEffectViewCollectionCell *cell = (AWEVideoEffectViewCollectionCell *)acell;
    switch (self.type) {
        case AWEVideoEffectViewTypeTool:
        case AWEVideoEffectViewTypeTransition:
        case AWEVideoEffectViewTypeFilter:
        {
            IESEffectModel *effect = self.effects[indexPath.item];
            [self configCell:cell withEffect:effect];
        }
            break;
        default:
            break;
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWEVideoEffectViewCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AWEVideoEffectViewCollectionCell" forIndexPath:indexPath];
    cell.type = self.type;
    switch (self.type) {
        case AWEVideoEffectViewTypeTime:{
            HTSVideoSepcialEffect *effect = self.timeEffects[indexPath.item];
            if (indexPath.row == 0) {
                [cell setCenterImage:ACCResourceImage(@"icVoiceStickerClear") size:CGSizeMake(24, 24)];
            } else {
                NSDictionary *coversDic = ACCConfigDict(kConfigDict_builtin_effect_covers);
                NSDictionary *urlMap = @{@(HTSPlayerTimeMachineNormal):@"time_normal",
                                         @(HTSPlayerTimeMachineReverse):@"time_reverser",
                                         @(HTSPlayerTimeMachineTimeTrap):@"time_trap",
                                         @(HTSPlayerTimeMachineRelativity):@"time_relativity"};
                
                NSString *urlKey = urlMap[@(effect.timeMachineType)];
                if (urlKey) {
                    NSArray *urlArray = [coversDic acc_arrayValueForKey:urlKey];
                    if (urlArray) {
                        @autoreleasepool {
                            @weakify(cell);
                            @weakify(self);
                            [ACCWebImage() imageView:cell.imageView setImageWithURLArray:urlArray placeholder:ACCResourceImage(@"tool_EffectLoadingIcon") completion:^(UIImage *image, NSURL *url, NSError *error) {
                                @strongify(cell);
                                @strongify(self);
                                if (image != nil) {
                                    image = [self effectCoverNeedReduce] ? [self staticImageWithImage:image] : image;
                                    [cell setCenterImage:image size:CGSizeMake(52, 52)];
                                }
                            }];
                        }
                    }
                }
            }
            cell.downloadStatus = AWEEffectDownloadStatusDownloaded;
            [cell updateText:effect.name];
            cell.coverColor = effect.effectColor;
            BOOL forbidCellDuetToMultiVoiceSegments =
            (effect.timeMachineType == HTSPlayerTimeMachineTimeTrap || effect.timeMachineType == HTSPlayerTimeMachineRelativity) && [self hasValidMultiVoiceEffectSegment];
            if (effect.forbidden || forbidCellDuetToMultiVoiceSegments) {
                cell.alpha = 0.5;
            } else {
                cell.alpha = 1;
            }
        }
            break;
            
        case AWEVideoEffectViewTypeTool: {
            IESEffectModel *effect = self.effects[indexPath.item];
            [self configCell:cell withEffect:effect];
            cell.coverColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        }
            break;
            
        case AWEVideoEffectViewTypeTransition: {
            IESEffectModel *effect = self.effects[indexPath.item];
            [self configCell:cell withEffect:effect];
        }
            break;
            
        case AWEVideoEffectViewTypeFilter:{
            IESEffectModel *effect = self.effects[indexPath.item];
            [self configCell:cell withEffect:effect];
            @weakify(self);
            ((AWEVideoEffectViewFilterCell *)cell).longPressBlock = ^(AWEVideoEffectViewCollectionCell *blockCell, UIGestureRecognizerState state) {
                @strongify(self);
                //时间特效通过长按触发
                if (state == UIGestureRecognizerStateBegan) {
                    [self longPressedAnimationStart:blockCell];
                    [self generateLightImpact];
                    self.longPressing = YES;
                    for (UICollectionViewCell *visibleCell in self.collectionView.visibleCells) {
                        visibleCell.userInteractionEnabled = NO;
                    }
                    [UIView animateWithDuration:0.2 animations:^{
                        blockCell.imageView.transform = CGAffineTransformMakeScale(1.2, 1.2);
                        blockCell.colorView.alpha = 1;
                        blockCell.colorView.transform = CGAffineTransformMakeScale(1.2, 1.2);
                    }];
                    if ([self.delegate respondsToSelector:@selector(videoEffectView:beginLongPressWithType:)]) {
                        [self.delegate videoEffectView:self beginLongPressWithType:effect];
                    }
                } else if (state == UIGestureRecognizerStateChanged) {
                    [self longPressedAnimationStart:blockCell];
                    if ([self.delegate respondsToSelector:@selector(videoEffectView:beingLongPressWithType:)]) {
                        [self.delegate videoEffectView:self beingLongPressWithType:effect];
                    }
                } else if (state == UIGestureRecognizerStateEnded) {
                    self.longPressing = NO;
                    for (UICollectionViewCell *visibleCell in self.collectionView.visibleCells) {
                        visibleCell.userInteractionEnabled = YES;
                    }
                    [self endLongPress:blockCell];
                    if ([self.delegate respondsToSelector:@selector(videoEffectView:didFinishLongPressWithType:)]) {
                        [self.delegate videoEffectView:self didFinishLongPressWithType:effect];
                    }
                } else if (state == UIGestureRecognizerStateCancelled) {
                    self.longPressing = NO;
                    for (UICollectionViewCell *visibleCell in self.collectionView.visibleCells) {
                        visibleCell.userInteractionEnabled = YES;
                    }
                    [self endLongPress:blockCell];
                    if ([self.delegate respondsToSelector:@selector(videoEffectView:didCancelLongPressWithType:)]) {
                        [self.delegate videoEffectView:self didCancelLongPressWithType:effect];
                    }
                }
            };
        }
            break;
    }
    
    return cell;
}

- (void)generateLightImpact
{
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];
        [generator impactOccurred];
    }
}

- (void)endLongPress:(AWEVideoEffectViewCollectionCell *)cell
{
    //结束长按
    [UIView animateWithDuration:0.2 animations:^{
        cell.imageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        cell.colorView.alpha = 0;
        cell.colorView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }];
    
    [UIView animateWithDuration:0.1 animations:^{
        cell.imageBackgroundView.layer.transform = CATransform3DIdentity;
    }];
}

- (void)didClickedRevokeBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(videoEffectView:didClickedRevokeBtn:)]) {
        [self.delegate videoEffectView:self didClickedRevokeBtn:btn];
    }
}

- (void)hideRevokeBtn:(BOOL)hide
{
    if (self.type == AWEVideoEffectViewTypeFilter || self.type == AWEVideoEffectViewTypeTransition || self.type == AWEVideoEffectViewTypeTime) {
        if (hide) {
            self.revokeBtn.hidden = YES;
        } else {
            if (self.revokeBtn.hidden) {
                self.revokeBtn.hidden = NO;
                self.revokeBtn.alpha = 0;
                [UIView animateWithDuration:0.2 animations:^{
                    self.revokeBtn.alpha = 1;
                }];
            }
        }
    }
}

- (void)setUpScalableRangeViewTip:(CGFloat)selectedDuration
{
    if (AWEVideoEffectViewTypeTool == self.type || AWEVideoEffectViewTypeTime == self.type) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.maximumFractionDigits = 1;
        NSString *duration = [formatter stringFromNumber:@(selectedDuration)] ?: @"0";
        self.textLabel.text = [NSString stringWithFormat:ACCLocalizedString(@"com_mig_s_selected",@"已选择：%@s"), duration];
    }
}

- (void)resetToolEffectTip
{
    if (AWEVideoEffectViewTypeTool == self.type) {
        self.textLabel.text = ACCLocalizedString(@"av_effect_sticker_hint",@"av_effect_sticker_hint");
    }
}

- (void)selectTimeEffect:(HTSPlayerTimeMachineType)type
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:type inSection:0];
    if (indexPath.row < [self.collectionView numberOfItemsInSection:0]) {
        AWEVideoEffectViewTimeCell *timeCell = (AWEVideoEffectViewTimeCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if ([timeCell isKindOfClass:[AWEVideoEffectViewTimeCell class]]) {
            [self configTimeCell:timeCell withSelectedStatus:YES];
        }
    }
    
    if (![self hasValidMultiVoiceEffectSegment]) {
        [self setDescriptionText:[HTSVideoSepcialEffect descriptionWithType:type]];
    } else {
        [self setDescriptionText:ACCLocalizedString(@"by_section_disabled_hint", @"Voice effects are applied. You can use reverse motion.")];
    }
}

- (BOOL)hasValidMultiVoiceEffectSegment {
    __block BOOL r = NO;
    if (self.publishModel.repoVoiceChanger.voiceEffectSegments.count == 0) {
        return r;
    }
    [self.publishModel.repoVoiceChanger.voiceEffectSegments enumerateObjectsUsingBlock:^(ACCVoiceEffectSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.effectId.length > 0) {
            r = YES;
            *stop = YES;
        }
    }];
    return r;
}

- (void)setDescriptionText:(NSString *)text
{
    [self.textLabel setText:text];
    self.textLabel.frame = CGRectMake(15, 11, self.frame.size.width - 15 - 20 - 60, 30);
}

- (NSInteger)findToolEffectWithEffectId:(NSString *)effectId {
    if (!effectId || AWEVideoEffectViewTypeTool != self.type) {
        return NSNotFound;
    }
    
    NSInteger position = NSNotFound;
    for (NSUInteger index = 0; index < self.effects.count; index++) {
        IESEffectModel *model = [self.effects objectAtIndex:index];
        if ([effectId isEqualToString:model.effectIdentifier]) {
            position = index;
            break;
        }
    }
    return position;
}

- (void)selectToolEffectWithEffectId:(nullable NSString *)effectId animated:(BOOL)animated
{
    NSInteger position = [self findToolEffectWithEffectId:effectId];
    if (position == NSNotFound) {
        return;
    }
    
    IESEffectModel *effectModel = [self.effects objectAtIndex:position];
    self.selectedToolEffect = effectModel;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:position inSection:0];
    [self.collectionView setNeedsLayout];
    [self.collectionView layoutIfNeeded];
    if (animated) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    } else {
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (void)deselectToolEffectWithEffectId:(nullable NSString *)effectId {
    NSInteger position = [self findToolEffectWithEffectId:effectId];
    if (position == NSNotFound) {
        return;
    }
    IESEffectModel *effectModel = [self.effects objectAtIndex:position];
    if (self.selectedToolEffect == effectModel) {
        self.selectedToolEffect = nil;
        [self.collectionView deselectItemAtIndexPath:[NSIndexPath indexPathForRow:position inSection:0] animated:YES];
    }
}

- (void)configVideoEffectRevokeButton:(UIButton *)button
{
    if (!UIAccessibilityIsBoldTextEnabled() && ![[ACCI18NConfig() currentLanguage] isEqualToString:@"en"]) {
        [button setTitle:ACCLocalizedString(@"effect_delte", @"撤销") forState:UIControlStateNormal];
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 12);
    } else {
        [button setTitle:@"" forState:UIControlStateNormal];
        button.contentEdgeInsets = UIEdgeInsetsMake(4, 12, 4, 12);
    }
}

#pragma mark - UICollectionViewDelegate
- (void)configTimeCell:(AWEVideoEffectViewTimeCell *)timeCell withSelectedStatus:(BOOL)selected
{
    if (timeCell.downloadStatus != AWEEffectDownloadStatusDownloaded) {
        timeCell.selectedIndicatorView.alpha = 0;
        return;
    }
    if (selected) {
        [UIView animateWithDuration:0.2 animations:^{
           timeCell.selectedIndicatorView.alpha = 1;
           [timeCell.titleLabel updateTextColor:ACCResourceColor(ACCColorPrimary)];
        }];
        [timeCell.titleLabel startAnimation];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            timeCell.selectedIndicatorView.alpha = 0;
            [timeCell.titleLabel updateTextColor:ACCColorFromRGBA(255, 255, 255, 1.f)];
        }];
        [timeCell.titleLabel stopAnimation];
    }
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.type == AWEVideoEffectViewTypeTime) {
//        时间特效,通过点击cell触发
        HTSVideoSepcialEffect *effect = self.timeEffects[indexPath.item];
        
        if ((effect.timeMachineType == HTSPlayerTimeMachineRelativity || effect.timeMachineType == HTSPlayerTimeMachineTimeTrap) && [self hasValidMultiVoiceEffectSegment]) {
            // cannot apply time machine effect duet to voiceEffectSegments.count > 0;
            return;
        }

        BOOL showClickedStyle = YES;
        if ([self.delegate respondsToSelector:@selector(videoEffectViewShouldShowClickedStyleWithTimeEffect:)]) {
            showClickedStyle = [self.delegate videoEffectViewShouldShowClickedStyleWithTimeEffect:effect];
        }

        if ([self.delegate respondsToSelector:@selector(videoEffectView:clickedCellWithTimeEffect:showClickedStyle:)]) {
            [self.delegate videoEffectView:self clickedCellWithTimeEffect:effect showClickedStyle:showClickedStyle];
        }
        
        if (showClickedStyle) {
            [[collectionView visibleCells] enumerateObjectsUsingBlock:^(__kindof AWEVideoEffectViewTimeCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[AWEVideoEffectViewTimeCell class]]) {
                    [self configTimeCell:obj withSelectedStatus:NO];
                }
            }];
            
            [self setDescriptionText:[HTSVideoSepcialEffect descriptionWithType:effect.timeMachineType]];
  
            AWEVideoEffectViewTimeCell *timeCell = (AWEVideoEffectViewTimeCell *)[collectionView cellForItemAtIndexPath:indexPath];
            if ([timeCell isKindOfClass:[AWEVideoEffectViewTimeCell class]]) {
                [self configTimeCell:timeCell withSelectedStatus:YES];
            }
        }
    } else {
        IESEffectModel *effect = self.effects[indexPath.item];
        if (effect) {
            if ([self.delegate respondsToSelector:@selector(videoEffectView:didSelectEffect:)]) {
                [self.delegate videoEffectView:self didSelectEffect:effect];
            }
        }
    }
}

#pragma mark - 懒加载
- (UILabel *)textLabel
{
    if (_textLabel == nil) {
        _textLabel = [[UILabel alloc] init];
        [_textLabel setTextColor:ACCResourceColor(ACCUIColorConstTextInverse)];
        [_textLabel setFont:[ACCFont() acc_boldSystemFontOfSize:13]];
        [_textLabel setBackgroundColor:[UIColor clearColor]];
        _textLabel.numberOfLines = 0;
        [_textLabel setAdjustsFontSizeToFitWidth:YES];
    }
    return _textLabel;
}

- (UICollectionView *)collectionView
{
    if (_collectionView == nil) {
        UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
        [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        layout.itemSize = CGSizeMake(68, 95);
        layout.headerReferenceSize = CGSizeMake(5, 0);
        layout.minimumLineSpacing = 0;
        _collectionView.bounces = YES;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.canCancelContentTouches = NO;
        switch (self.type) {
            case AWEVideoEffectViewTypeTime:
                [_collectionView registerClass:[AWEVideoEffectViewTimeCell class] forCellWithReuseIdentifier:@"AWEVideoEffectViewCollectionCell"];
                break;
            case AWEVideoEffectViewTypeFilter:
                [_collectionView registerClass:[AWEVideoEffectViewFilterCell class] forCellWithReuseIdentifier:@"AWEVideoEffectViewCollectionCell"];
                break;
            case AWEVideoEffectViewTypeTransition:
                [_collectionView registerClass:[AWEVideoEffectViewTransitionCell class] forCellWithReuseIdentifier:@"AWEVideoEffectViewCollectionCell"];
                break;
            case AWEVideoEffectViewTypeTool:
                [_collectionView registerClass:[AWEVideoEffectViewToolCell class] forCellWithReuseIdentifier:@"AWEVideoEffectViewCollectionCell"];
                break;
        }
        _collectionView.delegate = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
    }
    return _collectionView;
}
- (ACCButton *)revokeBtn
{
    if (_revokeBtn == nil) {
        _revokeBtn = [ACCButton buttonWithSelectedAlpha:0.5];
        _revokeBtn.layer.cornerRadius = 2;
        _revokeBtn.layer.masksToBounds = YES;
        [_revokeBtn setImage:ACCResourceImage(@"iconEffectUndo") forState:UIControlStateNormal];
        [self configVideoEffectRevokeButton:_revokeBtn];
        [_revokeBtn setBackgroundColor:ACCResourceColor(ACCUIColorConstBGContainerInverse)];
        [_revokeBtn setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse2) forState:UIControlStateNormal];
        [_revokeBtn.titleLabel setFont:[ACCFont() acc_systemFontOfSize:13]];
        [_revokeBtn addTarget:self action:@selector(didClickedRevokeBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _revokeBtn;
}

- (UIView<ACCLoadingViewProtocol> *)loadingView {
    if (!_loadingView) {
        _loadingView = [ACCLoading() loadingView];
        _loadingView.hidden = YES;
    }
    return _loadingView;
}

- (void)p_startLoadingAnim {
    self.loadingView.hidden = NO;
    [self.loadingView startAnimating];
}

- (void)p_stopLoadingAnim {
    self.loadingView.hidden = YES;
    [self.loadingView stopAnimating];
}

#pragma mark - Setter

- (void)setHideEffectCategoryMessage:(BOOL)hideEffectCategoryMessage
{
    _hideEffectCategoryMessage = hideEffectCategoryMessage;
    self.textLabel.hidden = hideEffectCategoryMessage;
    self.revokeBtn.hidden = hideEffectCategoryMessage;
}

#pragma mark - Tool Methods
- (UIImage *)staticImageWithImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    
    if ([image isMemberOfClass:[UIImage class]]) {
        return image;
    }
    
    return [UIImage imageWithCGImage:image.CGImage];
}

- (BOOL)effectCoverNeedReduce {
    return [UIDevice acc_isPoorThanIPhone6S];
}

@end

