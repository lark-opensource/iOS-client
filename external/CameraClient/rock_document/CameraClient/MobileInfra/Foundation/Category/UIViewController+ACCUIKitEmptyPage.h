//
//  UIViewController+ACCUIKitEmptyPage.h
//  ACCUIKit
//
//  Created by 熊典 on 2018/6/26.
//

#import <UIKit/UIKit.h>

typedef void(^ACCUIKitEmptyPageInformativeLinkBlock)(UIViewController *vc);
typedef NSString *(^ACCUIKitEmptyPageInformativeTranslationBlock)(NSString *);

typedef enum : NSUInteger {
    ACCUIKitViewControllerStateNormal,
    ACCUIKitViewControllerStateEmpty,
    ACCUIKitViewControllerStateEmptyShouldLogin,
    ACCUIKitViewControllerStateEmptyReachedMaximum,
    ACCUIKitViewControllerStateEmptyHarmfulCategory,
    ACCUIKitViewControllerStateNoMusicFeedback,
    ACCUIKitViewControllerStateNoMusicFeedbackNoImage,
    ACCUIKitViewControllerStateError,
} ACCUIKitViewControllerState;

typedef enum : NSUInteger {
    ACCUIKitViewControllerEmptyPageStyleNotDetermined,
    ACCUIKitViewControllerEmptyPageStyleA,
    ACCUIKitViewControllerEmptyPageStyleB,
    ACCUIKitViewControllerEmptyPageStyleC,
    ACCUIKitViewControllerEmptyPageStyleD,
    ACCUIKitViewControllerEmptyPageStyleE,
    ACCUIKitViewControllerEmptyPageStyleF,
} ACCUIKitViewControllerEmptyPageStyle;

//可能改变布局
typedef enum : NSUInteger {
    ACCUIKitViewControllerEmptyPageTemplateUndefined,
    ACCUIKitViewControllerEmptyPageTemplateOld,
    ACCUIKitViewControllerEmptyPageTemplateNew,
} ACCUIKitViewControllerEmptyPageTemplate;

extern const CGFloat acc_newStyleHeaderDistanceMultiplier;
extern const CGFloat acc_newStyleFooterDistanceMultiplier;
extern const CGFloat acc_newStylePlaceHolderComponentHeightWithNoButton;
extern const CGFloat acc_newStylePlaceHolderComponentHeightWithNoImageNoButton;
extern const CGFloat acc_newStylePlaceHolderComponentHeightWithNoImage;
extern const CGFloat acc_newStylePlaceHolderComponentHeight;
extern const CGFloat acc_newStylePlaceHolderImageLength;
extern const CGFloat acc_newStylePlaceHolderTopMinMargin;
extern const CGFloat acc_newStylePlaceHolderBottomMinMargin;

@interface ACCUIKitViewControllerEmptyPageConfig: NSObject

@property (nonatomic, assign) ACCUIKitViewControllerEmptyPageStyle style;
@property (nonatomic, strong) UIImage *iconImage;
@property (nonatomic, copy) UIView * (^customImageViewGenerator)(void);
@property (nonatomic, strong) NSString *titleText;
@property (nonatomic, strong) NSString *informativeText;
@property (nonatomic, assign) NSRange linkRange;
@property (nonatomic, strong) ACCUIKitEmptyPageInformativeLinkBlock linkBlock;
@property (nonatomic, strong) NSString *primaryButtonTitle;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *titleTextColor;
@property (nonatomic, strong) UIColor *informativeTextColor;
@property (nonatomic, strong) UIColor *informativeHighlightColor;
@property (nonatomic, strong) UIFont *informativeHighlightFont;
@property (nonatomic, strong) NSNumber *informativeLabelAlpha;
@property (nonatomic, strong) UIColor *buttonTitleColor;
@property (nonatomic, strong) UIColor *buttonBorderColor;
@property (nonatomic, strong) UIColor *buttonBackgroundColor;
@property (nonatomic, copy) UIView * (^appendixViewGenerator)(void);
@property (nonatomic, assign) ACCUIKitViewControllerEmptyPageTemplate templateType;

@end


@interface UIViewController (ACCUIKitEmptyPage)

@property (nonatomic, assign) ACCUIKitViewControllerState accui_viewControllerState;
@property (nonatomic, readonly) UIView *accui_emptyPageView;

// 全局样式
+ (void)accui_setDefaultEmptyPageConfig:(ACCUIKitViewControllerEmptyPageConfig *)config forState:(ACCUIKitViewControllerState)state;
+ (void)accui_setDefaultEmptyPageConfigBlock:(ACCUIKitViewControllerEmptyPageConfig * (^)(void))config forState:(ACCUIKitViewControllerState)state;
+ (void)accui_setInformativeLabelTranslationBlock:(ACCUIKitEmptyPageInformativeTranslationBlock)translationBlock;

// 自定配置
- (ACCUIKitViewControllerEmptyPageConfig *)accui_emptyPageConfigForState:(ACCUIKitViewControllerState)state;
- (UIView *)accui_emptyPageBelowView;
- (UIEdgeInsets)accui_emptyPageEdgeInsets;

// Actions
- (void)accui_emptyPagePrimaryButtonTapped:(UIButton *)sender;

//更新布局
- (void)accui_emptyPageReload;

@end
