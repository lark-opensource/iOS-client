//
//  AWEModernStickerTitleCollectionViewCell.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/15.
//  Copyright © 2018年 bytedance. All rights reserved.
//
#import "AWEModernStickerTitleCollectionViewCell.h"

#import <CreationKitInfra/UILabel+ACCAdditions.h>

#import <CreationKitInfra/ACCI18NConfigProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>

#import <CreativeKit/ACCFontProtocol.h>
#import <CameraClient/AWEModernStickerTitleCellViewModel.h>

#import <CreativeKit/NSNumber+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <BDWebImage/BDWebImage.h>

static NSString * const ACCStickerTitleViewCellUnSelectFontWeight = @"acc.sticker_title_view_cell.title.unselect.weight";

@interface AWEModernStickerTitleCollectionViewCell ()

@property (nonatomic, strong) UIView *yellowDot;
@property (nonatomic, strong) CALayer *imageMaskLayer;

@property (nonatomic, strong) AWEModernStickerTitleCellViewModel *viewModel;

@end

@implementation AWEModernStickerTitleCollectionViewCell

+ (void)categoryFrameWithContainerHeight:(CGFloat)height
                                   title:(NSString *)title
                                   image:(UIImage *)image
                              completion:(void(^)(CGSize cellSize, CGRect titleFrame, CGRect imageFrame))completion
{
    if (height == 0.f) {
        if (completion) {
            completion(CGSizeZero, CGRectZero, CGRectZero);
        }
        return;
    }
    const CGFloat margin = 2.f;
    const CGFloat horizontalPadding = [self enableNewFavoritesTitle] ? 14.f : 16.f;

    CGSize textSize = [self titleLabelSizeWithTitle:title height:height];

    CGRect titleFrame = CGRectZero;
    titleFrame.size = textSize;
    CGRect imageFrame = CGRectZero;

    BOOL showImage = image && image.size.height > 0;
    BOOL showTitle = title.length > 0;

    if (showImage) {
        CGFloat imgWHRadio = image.size.width / image.size.height;
        CGFloat imgH = 24.f; // UX 确认只有 24 这个尺寸
        CGSize imgSize = CGSizeMake(imgH*imgWHRadio, imgH);
        imageFrame.size = imgSize;
    }

    CGFloat cellWidth = 0.f;
    CGFloat imgX = 0.f;
    CGFloat titleX = 0.f;
    if (showImage && showTitle) {
        cellWidth = imageFrame.size.width + margin + textSize.width + 2 * horizontalPadding;
        imgX = horizontalPadding;
        titleX = imgX + imageFrame.size.width + margin;
    } else if (showImage) {
        cellWidth = imageFrame.size.width + 2 * horizontalPadding;
        imgX = horizontalPadding;
    } else if (showTitle) {
        cellWidth = textSize.width + 2 * horizontalPadding;
        titleX = horizontalPadding;
    }

    CGFloat imgY = (height - imageFrame.size.height) / 2;
    imageFrame.origin = CGPointMake(imgX, imgY);

    CGFloat titleY = (height - textSize.height) / 2;
    titleFrame.origin = CGPointMake(titleX, titleY);

    CGSize cellSize = CGSizeMake(cellWidth, height);

    if (completion) {
        completion(cellSize, titleFrame, imageFrame);
    }
}

+ (void)favoirteFrameWithContainerHeight:(CGFloat)height
                              completion:(void(^)(CGSize cellSize, CGRect titleFrame, CGRect imageFrame))completion
{
    if (height == 0.f) {
        if (completion) {
            completion(CGSizeZero, CGRectZero, CGRectZero);
        }
        return;
    }

    if ([self enableNewFavoritesTitle]) {
        // 收藏夹只显示文字，按照特效分类样式布局
        [self categoryFrameWithContainerHeight:height title:ACCLocalizedString(@"profile_favourite", @"收藏") image:nil completion:completion];
    } else {
        if (completion) {
            CGFloat cellWidth = 52.f;
            CGSize favoriteImgSize = CGSizeMake(20.f, 20.f);
            CGFloat favoriteImgX = (cellWidth - favoriteImgSize.width) / 2;
            CGFloat favoriteImgY = (height - favoriteImgSize.height) / 2;
            CGRect imageFrame = CGRectMake(favoriteImgX, favoriteImgY, favoriteImgSize.width, favoriteImgSize.height);

            if (completion) {
                completion(CGSizeMake(cellWidth, height), CGRectZero, imageFrame);
            }
        }
    }
}

+ (CGSize)titleLabelSizeWithTitle:(NSString *)title height:(CGFloat)height
{
    NSStringDrawingOptions opts = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
    NSDictionary *attributes = @{
        NSFontAttributeName: [ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold]
    };
    CGSize textSize = [title boundingRectWithSize:CGSizeMake(MAXFLOAT, height)
                                          options:opts
                                       attributes:attributes
                                          context:nil].size;
    textSize.width += 2;
    return textSize;
}

+ (BOOL)enableNewFavoritesTitle {
    NSString *currentLanguage = ACCI18NConfig().currentLanguage;
    return [currentLanguage isEqualToString:@"zh"];;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        [self addSubviews];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.titleLabel.frame = self.viewModel.titleFrame;
    self.imageView.frame = self.viewModel.imageFrame;
    self.imageMaskLayer.frame = self.imageView.bounds;

    [self layoutDot];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.viewModel = nil;
}

- (void)bindViewModel:(AWEModernStickerTitleCellViewModel *)viewModel
{
    self.viewModel = viewModel;
    self.imageView.image = viewModel.image;
    self.titleLabel.text = viewModel.title;
    [self configWithViewModel:viewModel];
}

- (void)configWithViewModel:(AWEModernStickerTitleCellViewModel *)viewModel
{
    if ([viewModel isFavorite]) {
        if ([self.class enableNewFavoritesTitle]) {
            [self configWithTitle:ACCLocalizedString(@"profile_favourite", @"收藏") showYellowDot:NO];
        } else {
            [self configWithCollectionImage];
        }
    } else {
        BOOL shouldShowYellowDot = [viewModel shouldShowYellowDot];
        [self updateLabelAlpha];
        self.titleLabel.hidden = NO;

        self.imageView.layer.mask = nil;
        self.imageView.hidden = NO;
        self.imageView.backgroundColor = [UIColor clearColor];
        self.imageView.alpha = self.selected ? 1.0f : 0.6f;

        self.yellowDot.hidden = !shouldShowYellowDot;
    }

    [self setNeedsLayout];
}

- (void)showYellowDotAnimated:(BOOL)animated
{
    if (self.selected) {
        return ;
    }
    if (animated) {
        self.yellowDot.alpha = 0.0f;
        self.yellowDot.hidden = NO;
        [UIView animateWithDuration:0. animations:^{
            self.yellowDot.alpha = 1.0f;
            self.yellowDot.hidden = NO;
        }];
    } else {
        self.yellowDot.alpha = 1.0;
        self.yellowDot.hidden = NO;
    }
}

// 目前只有收藏夹在使用
- (void)playTitleAnimationWithYellowDotShow:(BOOL)showYellowDot
{
    if (self.selected) {
        return ;
    }
    if (showYellowDot) {
        self.yellowDot.alpha = 0.0f;
        self.yellowDot.hidden = NO;
    }

    // 动画
    self.titleLabel.alpha = self.selected ? 0.6 : 1;
    [UIView animateWithDuration:0.15 animations:^{
        self.titleLabel.center = CGPointMake(self.contentView.center.x, self.contentView.center.y-2);
    } completion:^(BOOL finished) {
        if (finished) {
            if (showYellowDot) {
                self.yellowDot.alpha = 1.0f;
                self.yellowDot.hidden = NO;
            }

            [self updateLabelAlpha];
            [UIView animateWithDuration:0.15 animations:^{
                self.titleLabel.center = CGPointMake(self.contentView.center.x, self.contentView.center.y);
            }];
        }
    }];
}

// 目前只有收藏夹在使用
- (void)playImageAnimationWithYellowDotShow:(BOOL)showYellowDot
{
    if (self.selected) {
        return ;
    }
    if (showYellowDot) {
        self.yellowDot.alpha = 0.0f;
        self.yellowDot.hidden = NO;
    }

    self.imageView.alpha = 1;
    [UIView animateWithDuration:0.15 animations:^{
        self.imageView.center = CGPointMake(self.contentView.center.x, self.contentView.center.y-2);
    } completion:^(BOOL finished) {
        if (finished) {
            self.imageView.alpha = 0.6;
            if (showYellowDot) {
                self.yellowDot.alpha = 1.0f;
                self.yellowDot.hidden = NO;
            }
            [UIView animateWithDuration:0.15 animations:^{
                self.imageView.center = CGPointMake(self.contentView.center.x, self.contentView.center.y);
            }];
        }
    }];
}

#pragma mark - Private

- (void)layoutDot {
    CGFloat dotWidth = 6.f;
    CGFloat dotHeight = 6.f;
    CGFloat dotX = 0.f;
    CGFloat dotY = CGRectGetMinY(self.contentView.frame) + 10;
    if (self.titleLabel.text.length > 0) {
        dotX = CGRectGetMaxX(self.titleLabel.frame) + 2;
    } else {
        dotX = CGRectGetMaxX(self.imageView.frame) + 2;
    }
    self.yellowDot.frame = CGRectMake(dotX, dotY, dotWidth, dotHeight);
}

- (void)addSubviews
{
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.yellowDot];
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] acc_initWithFontSize:14 isBold:YES textColor:ACCResourceColor(ACCUIColorTextS1) text: ACCLocalizedCurrentString(@"hot")];
        _titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold];
        _titleLabel.hidden = YES;
        _titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        ACC_LANGUAGE_DISABLE_LOCALIZATION(_titleLabel);
    }
    return _titleLabel;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[BDImageView alloc] init];
        _imageView.backgroundColor = ACCResourceColor(ACCUIColorBGContainer8);
        UIImage *colletionImage = ACCResourceImage(@"iconStickerCollection");
        _imageView.image = colletionImage;
        _imageView.hidden = YES;
    }
    return _imageView;
}

- (CALayer *)imageMaskLayer {
    if (!_imageMaskLayer) {
        UIImage *colletionImage = ACCResourceImage(@"iconStickerCollection");

        _imageMaskLayer = [[CALayer alloc] init];
        _imageMaskLayer.frame = CGRectMake(0, 0, 20, 20);
        _imageMaskLayer.contents = (__bridge id _Nullable)(colletionImage.CGImage);
    }
    return _imageMaskLayer;
}


- (UIView *)yellowDot {
    if (!_yellowDot) {
        _yellowDot = [[UIView alloc] init];
        _yellowDot.layer.cornerRadius = 3;
        _yellowDot.backgroundColor = ACCResourceColor(ACCColorLink);
        _yellowDot.hidden = YES;
    }
    return _yellowDot;
}

- (void)configWithTitle:(NSString *)title showYellowDot:(BOOL)show
{
    self.titleLabel.text = title;
    self.titleLabel.hidden = NO;

    [self updateLabelAlpha];

    self.imageView.layer.mask = nil;
    self.imageView.hidden = YES;
    self.imageView.alpha = 1.0f;

    self.yellowDot.hidden = !show;
}

- (void)configWithCollectionImage
{
    self.titleLabel.hidden = YES;
    [self updateLabelAlpha];
    self.titleLabel.text = @"";

    self.imageView.hidden = NO;
    self.imageView.alpha = 1.0f;
    self.imageView.layer.mask = self.imageMaskLayer;

    UIImage *colletionImage = ACCResourceImage(@"iconStickerCollection");
    self.imageView.image = colletionImage;

    self.yellowDot.hidden = YES;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    UIFont *selectedFont = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold];

    ACCFontWeight weight = ACCIntConfig(ACCStickerTitleViewCellUnSelectFontWeight);
    UIFont *unselectedFont =  [ACCFont() systemFontOfSize:15 weight:weight];

    self.titleLabel.font = selected ? selectedFont : unselectedFont;

    [self updateLabelAlpha];

    if ([self.viewModel shouldUseIconDisplay]) {
        self.imageView.backgroundColor = [UIColor clearColor];
    }
    self.imageView.alpha = selected ? 1.0f : 0.6f;

    // 因为手动调用`selectItemAtIndexPath:animated:scrollPosition:`方法不会调用`UICollectionView`的`didSelectItem:atIndexPath`方法
    // 所以在统一这里进行调用移除黄点的方法
    if (selected) {
        BOOL shouldShowYellowDot = [self.viewModel shouldShowYellowDot];
        if (self.viewModel && shouldShowYellowDot) {
            [self.viewModel markAsReaded];
        }
        self.yellowDot.hidden = YES;
    }
}

- (void)updateLabelAlpha {
    self.titleLabel.alpha = self.selected ? 1 : 0.6;
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel {
    return self.viewModel.title ? self.viewModel.title : ACCLocalizedString(@"add_to_favorite", @"add_to_favorite");
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton;
}

- (void)accessibilityElementDidBecomeFocused
{
    if ([self.superview isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self.superview;
        [collectionView scrollToItemAtIndexPath:[collectionView indexPathForCell:self] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally|UICollectionViewScrollPositionCenteredVertically animated:NO];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self);
    }
}

@end
