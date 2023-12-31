//
//  AWEStickerPickerCategoryCell.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/26.
//

#import "AWEStickerPickerCategoryCell.h"
#import <CreationKitInfra/ACCI18NConfigProtocol.h>
#import "AWEDouyinStickerCategoryModel.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/IESCategoryModel+AWEAdditions.h>

#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/NSNumber+CameraClientResource.h>

static NSString * const ACCStickerTitleViewCellUnSelectFontWeight = @"acc.sticker_title_view_cell.title.unselect.weight";

@interface AWEStickerPickerCategoryCell () <CAAnimationDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *yellowDot;

@end

@implementation AWEStickerPickerCategoryCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        [self setupSubviews];
    }
    return self;
}

- (void)categoryDidUpdate {
    [super categoryDidUpdate];
    [self executeTwinkleAnimation];
}

- (void)setCategoryModel:(AWEStickerCategoryModel *)categoryModel {
    [super setCategoryModel:categoryModel];
    
    if ([self.categoryModel isKindOfClass:AWEDouyinStickerCategoryModel.class]) {
        AWEDouyinStickerCategoryModel *categoryModel = (AWEDouyinStickerCategoryModel *)self.categoryModel;
        self.imageView.image = categoryModel.image;
        self.titleLabel.text = categoryModel.categoryName;
    }
    
    if (self.categoryModel.favorite) {
        if ([[ACCI18NConfig() currentLanguage] isEqualToString:@"zh"]) {
            [self configWithTitle:ACCLocalizedString(@"profile_favourite", @"收藏") showYellowDot:NO];
        } else {
            [self configWithCollectionImage];
        }
    } else {
        BOOL shouldShowYellowDot = [categoryModel shouldShowYellowDot];
        UIColor *unselectedTitleColor = ACCResourceColor(ACCUIColorConstTextTertiary4);
        UIColor *selectedTitleColor = ACCResourceColor(ACCUIColorConstTextInverse);
        self.titleLabel.textColor = self.selected ? selectedTitleColor : unselectedTitleColor;
        self.titleLabel.hidden = NO;
        
        self.imageView.layer.mask = nil;
        self.imageView.hidden = NO;
        self.imageView.alpha = self.selected ? 1.0f : 0.6f;
        
        self.yellowDot.hidden = !shouldShowYellowDot;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if ([self.categoryModel isKindOfClass:AWEDouyinStickerCategoryModel.class]) {
        AWEDouyinStickerCategoryModel *categoryModel = (AWEDouyinStickerCategoryModel *)self.categoryModel;
        self.titleLabel.frame = categoryModel.titleFrame;
        self.imageView.frame = categoryModel.imageFrame;
    }
    
    [self layoutDot];
}

#pragma mark - private

- (void)setupSubviews {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textColor = ACCResourceColor(ACCUIColorTextS1);
    _titleLabel.text = @"hot";
    _titleLabel.font = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightSemibold];
    _titleLabel.hidden = YES;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    
    _imageView = [[UIImageView alloc] init];
    UIImage *collectionImage = ACCResourceImage(@"iconStickerCollection");
    _imageView.image = collectionImage;
    _imageView.hidden = YES;
    
    _yellowDot = [[UIView alloc] init];
    _yellowDot.layer.cornerRadius = 3;
    _yellowDot.backgroundColor = ACCResourceColor(ACCUIColorPrimary);
    _yellowDot.hidden = YES;
    
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.yellowDot];
}

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

- (void)executeTwinkleAnimation {
    if (self.selected) {
        return;
    }
    
    [self configCollectionImageBackgroundColor:YES];
    
    NSTimeInterval duration = 0.15;
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
    animation.duration = duration;
    animation.values = @[@(self.layer.position.y), @(self.layer.position.y-4), @(self.layer.position.y)];
    animation.delegate = self;
    self.titleLabel.textColor = !self.selected ? ACCResourceColor(ACCUIColorBGContainer6) : ACCResourceColor(ACCUIColorTextS1);
    
    [self.contentView.layer addAnimation:animation forKey:nil];
}

- (void)configIconImageWithCategoryModel:(AWEStickerCategoryModel *)categoryModel showYellowDot:(BOOL)show {
    NSString *title = categoryModel.category.categoryName;
    self.titleLabel.text = title;
    self.titleLabel.hidden = title.length == 0;
    self.titleLabel.textColor = self.selected ? ACCResourceColor(ACCUIColorBGContainer6) : ACCResourceColor(ACCUIColorTextS1);
    
    self.imageView.layer.mask = nil;
    self.imageView.hidden = NO;
    self.imageView.alpha = self.selected ? 1.0f : 0.6f;
    
    self.yellowDot.hidden = !show;
}

- (void)configWithTitle:(NSString *)title showYellowDot:(BOOL)show {
    self.titleLabel.text = title;
    self.titleLabel.hidden = NO;
    
    UIColor *unselectedTitleColor = ACCResourceColor(ACCUIColorConstTextTertiary4);
    UIColor *selectedTitleColor = ACCResourceColor(ACCUIColorConstTextInverse);
    self.titleLabel.textColor = self.selected ? selectedTitleColor : unselectedTitleColor;
    
    self.imageView.layer.mask = nil;
    self.imageView.hidden = YES;
    self.imageView.alpha = 1.0f;
    
    self.yellowDot.hidden = !show;
}

- (void)configWithCollectionImage {
    self.titleLabel.hidden = YES;
    self.titleLabel.textColor = self.selected ? ACCResourceColor(ACCUIColorBGContainer6) : ACCResourceColor(ACCUIColorTextS1);
    self.titleLabel.text = @"";
    
    self.imageView.hidden = NO;
    self.imageView.alpha = 1.0f;
    [self configCollectionImageBackgroundColor:self.selected];
    
    self.yellowDot.hidden = YES;
}

- (void)configCollectionImageBackgroundColor:(BOOL)selected {
    self.imageView.alpha = selected ? 1 : 0.6;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    UIColor *selectedTitleColor = ACCResourceColor(ACCUIColorConstTextInverse);
    UIColor *unselectedTitleColor = ACCResourceColor(ACCStickerTitleViewCellTitleUnSelectColor);
    self.titleLabel.textColor = selected ? selectedTitleColor : unselectedTitleColor;

    ACCFontWeight weight = ACCIntConfig(ACCStickerTitleViewCellUnSelectFontWeight);
    UIFont *unselectedFont =  [ACCFont() acc_systemFontOfSize:15 weight:weight];
    UIFont *selectedFont = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightSemibold];
    
    self.titleLabel.font = selected ? selectedFont : unselectedFont;
    self.imageView.alpha = selected ? 1.0f : 0.6f;
    
    // 因为手动调用`selectItemAtIndexPath:animated:scrollPosition:`方法不会调用`UICollectionView`的`didSelectItem:atIndexPath`方法
    // 所以在统一这里进行调用移除黄点的方法
    if (selected) {
        BOOL shouldShowYellowDot = [self.categoryModel.category showRedDotWithTag:@"new"];
        if (self.categoryModel && shouldShowYellowDot) {
            [self.categoryModel markAsReaded];
        }
        self.yellowDot.hidden = YES;
    }
}

- (void)showYellowDotAnimated:(BOOL)animated {
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

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    if (self.categoryModel.isSearch) {
        return @"搜索";
    }
    return self.categoryModel ? self.categoryModel.categoryName : ACCLocalizedCurrentString(@"add_to_favorite");
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton;
}

- (void)accessibilityElementDidBecomeFocused {
    if ([self.superview isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self.superview;
        [collectionView scrollToItemAtIndexPath:[collectionView indexPathForCell:self] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally|UICollectionViewScrollPositionCenteredVertically animated:NO];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self);
    }
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    self.titleLabel.textColor = self.selected ? ACCResourceColor(ACCUIColorBGContainer6) : ACCResourceColor(ACCUIColorTextS1);
    if (self.categoryModel.favorite) {
        [self configCollectionImageBackgroundColor:self.selected];
    }
}

@end
