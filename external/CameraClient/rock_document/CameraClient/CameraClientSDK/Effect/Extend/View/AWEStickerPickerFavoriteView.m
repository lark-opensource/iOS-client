//
//  AWEStickerPickerFavoriteView.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/5/20.
//

#import "AWEStickerPickerFavoriteView.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/ACCI18NConfigProtocol.h>

#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

#import <Masonry/Masonry.h>

@interface AWEStickerPickerFavoriteView ()

@property (nonatomic, strong) CALayer *bgLayer;

@property (nonatomic, strong, readwrite) ACCCollectionButton *favoriteButton;

@property (nonatomic, assign) BOOL isAnimated;

@end

@implementation AWEStickerPickerFavoriteView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];

        self.isAnimated = NO;
        
        // Add background layer.
        CALayer *bgLayer = [CALayer layer];
        self.bgLayer = bgLayer;
        bgLayer.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer3).CGColor;
        bgLayer.cornerRadius = 18;
        //bgLayer.frame = CGRectMake(8, 8, layerWidth, 36);
        bgLayer.name = @"cornerButtonLayer";
        [self.layer addSublayer:bgLayer];
        
        // Add favorite button.
        ACCCollectionButton *favoriteButton = [ACCCollectionButton buttonWithType:UIButtonTypeCustom];
        self.favoriteButton = favoriteButton;
        favoriteButton.contentMode = UIViewContentModeCenter;
        // [stickerConfig configFavoriteButtonImage:favoriteButton];
        // New Style
        if ([self enableNewFavoritesTitle]) {
            favoriteButton.displayMode = ACCCollectionButtonDisplayModeTitleAndImage;
            favoriteButton.titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold];
            [favoriteButton setImage:ACCResourceImage(@"iconStickerCollectionBeforeNew") forState:UIControlStateNormal];
            [favoriteButton setImage:ACCResourceImage(@"iconStickerCollectionAfterNew") forState:UIControlStateSelected];
            [favoriteButton setTitle:[self buttonTitleForState:NO] forState:UIControlStateNormal];
            [favoriteButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
            [favoriteButton setTitle:[self buttonTitleForState:YES] forState:UIControlStateSelected];
            [favoriteButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateSelected];
            favoriteButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            favoriteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            favoriteButton.imageEdgeInsets = UIEdgeInsetsMake(0, 18, 1, 0);
            favoriteButton.titleEdgeInsets = UIEdgeInsetsMake(0, 18, 1, 0);
        }
        [self addSubview:favoriteButton];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [CATransaction begin];
    [CATransaction setDisableActions:!self.isAnimated];
    self.bgLayer.frame = CGRectInset(self.bounds, 9, 9);
    self.favoriteButton.frame = self.bounds;
    [CATransaction commit];
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;

    self.isAnimated = NO;
    self.favoriteButton.selected = _selected;

    CGFloat buttonWidth = [self getFavoriteButtonBackgroundWidthForState:_selected];
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(buttonWidth));
    }];
}

- (void)toggleSelected
{
    _selected = !_selected;

    self.isAnimated = YES;
    [self.favoriteButton beginTouchAnimation];
    
    CGFloat buttonWidth = [self getFavoriteButtonBackgroundWidthForState:_selected];
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(buttonWidth));
    }];
}

- (NSString *)buttonTitleForState:(BOOL)selected
{
    if (selected) {
        return ACCLocalizedString(@"added_to_favorite", @"已收藏");
    }
    
    return ACCLocalizedString(@"profile_favourite", @"收藏");
}

- (CGFloat)getFavoriteButtonBackgroundWidthForState:(BOOL)selected
{
    if ([self enableNewFavoritesTitle]) {
        NSString *title = [self buttonTitleForState:selected];
        UIFont *font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold];
        NSStringDrawingOptions opts = NSStringDrawingUsesLineFragmentOrigin |
        NSStringDrawingUsesFontLeading;
        NSDictionary *attributes = @{NSFontAttributeName: font};
        CGSize textSize = [title boundingRectWithSize:CGSizeMake(MAXFLOAT, 21)
                                              options:opts
                                           attributes:attributes
                                              context:nil].size;
        // 按钮图片与标题间隔2，图片加左右间隔44
        return textSize.width + 46 + 18;
    }
    
    return 54.0f;
}

- (BOOL)enableNewFavoritesTitle
{
    NSString *currentLanguage = ACCI18NConfig().currentLanguage;
    return [currentLanguage isEqualToString:@"zh"];;
}

@end
