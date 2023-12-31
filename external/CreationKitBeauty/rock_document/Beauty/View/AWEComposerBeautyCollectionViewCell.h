//
//  AWEComposerBeautyCollectionViewCell.h
//  CameraClient
//
//  Created by HuangHongsen on 2019/11/6.
//

#import <UIKit/UIKit.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <CreationKitBeauty/ACCBeautyDefine.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEComposerBeautyCollectionViewCell : UICollectionViewCell

@property (nonatomic, assign) BOOL isNewStyle;
@property (nonatomic, assign) BOOL shouldShowAppliedInidicator;
@property (nonatomic, assign) AWEEffectDownloadStatus downloadStatus;
/// handle system setSelected method, and automatically call makeSelected or makeDeselected
@property (nonatomic, assign) BOOL useSystemSelection;
/// should make image view smaller, for local source icon image
@property (nonatomic, assign) BOOL isSmallIcon;
@property (nonatomic, assign) AWEBeautyCellIconStyle iconStyle;
@property (nonatomic, assign) CGFloat iconWidth;
@property (nonatomic, assign) CGFloat selectIndicatorWidth;
@property (nonatomic, assign) CGFloat selectBorderWidth;
@property (nonatomic, strong, readonly) UILabel *nameLabel;
@property (nonatomic, strong, readonly) UIView *flagDotView;
@property (nonatomic, strong, readonly) UIImageView *iconImageView;
@property (nonatomic, strong, readonly) UIView *backView;
@property (nonatomic, strong) UIFont *selectedFont;
@property (nonatomic, strong) UIFont *unselectedFont;

+ (NSString *)identifier;

- (void)setTitle:(NSString *)title;
- (void)setImageWithUrls:(NSArray *)urls placeholder:(nullable UIImage *)placeholder;
- (void)setIconImage:(UIImage *)image;
- (void)setApplied:(BOOL)applied;
- (void)setAvailable:(BOOL)available;
- (void)setShouldShowAppliedIndicator:(BOOL)shouldShow;
- (void)setShouldShowAppliedIndicatorWhenSwitchIsEnabled:(BOOL)shouldShow;
- (void)setFlagDotViewHidden:(BOOL)hidden;
- (void)enableCellItem:(BOOL)enabled;

- (void)makeSelected;
- (void)makeDeselected;

// for custom style
- (void)configRollingTitleViewColor:(UIColor *)color;
- (void)configSelectedIndicatorViewColor:(UIColor *)color;
- (void)configNamelblSelectColor:(UIColor *)color unSelect:(UIColor *)unSelectColor;
- (void)configAppliedIndicatorColor:(UIColor *)color unSelect:(UIColor *)unSelectColor;

// add cover
- (void)addCoverIconImageView:(UIView *)view;
- (void)removeCoverIconImageView;
@end

NS_ASSUME_NONNULL_END
