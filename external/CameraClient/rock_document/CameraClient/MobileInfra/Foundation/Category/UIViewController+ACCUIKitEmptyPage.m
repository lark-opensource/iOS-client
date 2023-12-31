//
//  UIViewController+ACCUIKitEmptyPage.m
//  ACCUIKit
//
//  Created by 熊典 on 2018/6/26.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "UIViewController+ACCUIKitEmptyPage.h"
#import <objc/runtime.h>
#import <CreativeKit/NSObject+ACCSwizzle.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <YYText/YYLabel.h>
#import <YYText/NSAttributedString+YYText.h>
#import <Masonry/View+MASAdditions.h>

const CGFloat acc_newStyleHeaderDistanceMultiplier = 0.4f;
const CGFloat acc_newStyleFooterDistanceMultiplier = 0.7f;
const CGFloat acc_newStylePlaceHolderComponentHeightWithNoButton = 240;
const CGFloat acc_newStylePlaceHolderComponentHeightWithNoImageNoButton = 146;
const CGFloat acc_newStylePlaceHolderComponentHeightWithNoImage = acc_newStylePlaceHolderComponentHeightWithNoImageNoButton + 44;
const CGFloat acc_newStylePlaceHolderComponentHeight = acc_newStylePlaceHolderComponentHeightWithNoButton + 44;
const CGFloat acc_newStylePlaceHolderImageLength = 70;
const CGFloat acc_newStylePlaceHolderTopMinMargin = 30;
const CGFloat acc_newStylePlaceHolderBottomMinMargin = 30;


@interface ACCUISelectedAlphaButton: UIButton
@end

@implementation ACCUISelectedAlphaButton

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if(self.highlighted) {
        [UIView animateWithDuration:0.15 animations:^{
            [self setAlpha:0.75];
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.15 animations:^{
                [self setAlpha:1];
            }];
        });
    }
}

@end

@interface UIViewController ()

@property (nonatomic, strong) UIView *accui_emptyPageContainerView;
@property (nonatomic, strong) UIImageView *accui_emptyPageImageView;
@property (nonatomic, strong) UILabel *accui_emptyPageTitleLabel;
@property (nonatomic, strong) YYLabel *accui_emptyPageInformativeLabel;
@property (nonatomic, strong) UIButton *accui_emptyPagePrimaryButton;
@property (nonatomic, strong) UIView *accui_emptyPageGroupView;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *accui_emptyPageStyles;

@end

@implementation ACCUIKitViewControllerEmptyPageConfig

@end

static NSMutableDictionary<NSNumber *, id> *acc_defaultConfigDict;
static NSDictionary<NSNumber *, ACCUIKitViewControllerEmptyPageConfig *> *acc_fallbackConfigDict;
static ACCUIKitEmptyPageInformativeTranslationBlock acc_informativeLabelTranslationBlock = nil;

@implementation UIViewController (ACCUIKitEmptyPage)

+ (void)load
{
    [self acc_swizzleMethodsOfClass:self originSelector:@selector(viewDidLayoutSubviews)  targetSelector:@selector(accui_viewDidLayoutSubviews)];
}

+ (void)accui_setDefaultEmptyPageConfig:(ACCUIKitViewControllerEmptyPageConfig *)config forState:(ACCUIKitViewControllerState)state
{
    [self accui_setDefaultEmptyPageConfigItem:config forState:state];
}

+ (void)accui_setDefaultEmptyPageConfigBlock:(ACCUIKitViewControllerEmptyPageConfig * (^)(void))configBlock forState:(ACCUIKitViewControllerState)state {
    [self accui_setDefaultEmptyPageConfigItem:configBlock forState:state];
}

+ (void)accui_setDefaultEmptyPageConfigItem:(id)item forState:(ACCUIKitViewControllerState)state
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        acc_defaultConfigDict = [NSMutableDictionary dictionary];
    });
    acc_defaultConfigDict[@(state)] = item;
}

+ (void)accui_setInformativeLabelTranslationBlock:(ACCUIKitEmptyPageInformativeTranslationBlock)translationBlock
{
    acc_informativeLabelTranslationBlock = translationBlock;
}

- (NSString *)acc_translateInformativeLabel:(NSString *)input
{
    return acc_informativeLabelTranslationBlock ? acc_informativeLabelTranslationBlock(input):input;
}

- (ACCUIKitViewControllerEmptyPageConfig *)accui_emptyPageConfigForState:(ACCUIKitViewControllerState)state
{
    return nil;
}

- (void)accui_viewDidLayoutSubviews
{
    [self accui_viewDidLayoutSubviews];
    UIView *view = objc_getAssociatedObject(self, @selector(accui_emptyPageContainerView));
    UIEdgeInsets insets = [self accui_emptyPageEdgeInsets];
    ACCMasUpdate(view, {
        make.top.equalTo(self.view).offset(insets.top);
        make.left.equalTo(self.view).offset(insets.left);
        make.right.equalTo(self.view).offset(-insets.right);
        make.bottom.equalTo(self.view).offset(-insets.bottom);
    });
}

// Default configurations
- (ACCUIKitViewControllerEmptyPageConfig *)_accui_emptyPageConfigForState:(ACCUIKitViewControllerState)state
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ACCUIKitViewControllerEmptyPageConfig *defaultErrorConfig = [[ACCUIKitViewControllerEmptyPageConfig alloc] init];
        defaultErrorConfig.titleText = ACCLocalizedString(@"com_mig_no_network_connection_oy8muk", @"网络连接错误");
        defaultErrorConfig.informativeText = ACCLocalizedString(@"com_mig_no_internet_connection_connect_to_the_internet_and_try_again_mecacu",@"请检查网络连接后重试");
        defaultErrorConfig.iconImage = [UIImage acc_imageWithName:@"emptyPageImage"];
        defaultErrorConfig.primaryButtonTitle = ACCLocalizedString(@"com_mig_refresh",@"重试");
        defaultErrorConfig.style = ACCUIKitViewControllerEmptyPageStyleB;
        defaultErrorConfig.backgroundColor = ACCResourceColor(ACCUIColorBGContainer);
        defaultErrorConfig.titleTextColor = ACCResourceColor(ACCUIColorTextPrimary);
        defaultErrorConfig.informativeTextColor = ACCResourceColor(ACCUIColorTextSecondary);
        
        ACCUIKitViewControllerEmptyPageConfig *defaultEmptyConfig = [[ACCUIKitViewControllerEmptyPageConfig alloc] init];
        defaultEmptyConfig.titleText = ACCLocalizedString(@"info_item_list_empty",@"暂无内容");
        defaultEmptyConfig.informativeText = ACCLocalizedString(@"poi_later",@"稍后查看");
        defaultEmptyConfig.iconImage = [UIImage acc_imageWithName:@"emptyPageImage"];
        defaultEmptyConfig.primaryButtonTitle = ACCLocalizedString(@"refresh_str",@"刷新");
        defaultEmptyConfig.style = ACCUIKitViewControllerEmptyPageStyleC;
        defaultEmptyConfig.backgroundColor = ACCResourceColor(ACCUIColorBGContainer);
        defaultEmptyConfig.titleTextColor = ACCResourceColor(ACCUIColorTextPrimary);
        defaultEmptyConfig.informativeTextColor = ACCResourceColor(ACCUIColorTextSecondary);
        if (!acc_informativeLabelTranslationBlock) {
            [UIViewController accui_setInformativeLabelTranslationBlock:^NSString *(NSString *string) {
                  return ACCLocalizedCurrentString(string);
            }];
        }
        acc_fallbackConfigDict = @{@(ACCUIKitViewControllerStateEmpty): defaultEmptyConfig,
                               @(ACCUIKitViewControllerStateError): defaultErrorConfig,
                               };
    });
    ACCUIKitViewControllerEmptyPageConfig *config = [self accui_emptyPageConfigForState:state];

    id configOrBlock = acc_defaultConfigDict[@(state)];
    if (configOrBlock && ![configOrBlock isKindOfClass:[ACCUIKitViewControllerEmptyPageConfig class]]) {
        ACCUIKitViewControllerEmptyPageConfig * (^configBlock)(void) = configOrBlock;
        acc_defaultConfigDict[@(state)] = configBlock();
        NSAssert([acc_defaultConfigDict[@(state)] isKindOfClass:[ACCUIKitViewControllerEmptyPageConfig class]], @"Block return object must be ACCUIKitViewControllerEmptyPageConfig!");
    }

    ACCUIKitViewControllerEmptyPageConfig *defaultConfig = acc_defaultConfigDict[@(state)];
    ACCUIKitViewControllerEmptyPageConfig *fallbackConfig = acc_fallbackConfigDict[@(state)];
    
    if (!config.backgroundColor && CGColorGetAlpha(self.view.backgroundColor.CGColor) >= 0.5) {
        if (!config) {
            config = [[ACCUIKitViewControllerEmptyPageConfig alloc] init];
        }
        config.backgroundColor = [self.view.backgroundColor colorWithAlphaComponent:1];
    }
    
    if (config.backgroundColor) {
        CIColor *color = [CIColor colorWithCGColor:config.backgroundColor.CGColor];
        if (color.red == 1 && color.green == 1 && color.blue == 1) {
            if (!config.titleTextColor) {
                config.titleTextColor = ACCResourceColor(ACCUIColorConstTextPrimary);
            }
            if (!config.informativeTextColor) {
                config.informativeTextColor = ACCResourceColor(ACCUIColorConstTextSecondary);
            }
            if (!config.buttonTitleColor) {
                config.buttonTitleColor = ACCResourceColor(ACCUIColorConstTextPrimary);
            }
            if (!config.buttonBorderColor) {
                config.buttonBorderColor = ACCResourceColor(ACCUIColorConstBGInput);
            }
        }
    }
    
    if (config) {
        if (!config.iconImage) {
            config.iconImage = defaultConfig.iconImage;
        }
        if (!config.titleText.length) {
            config.titleText = defaultConfig.titleText;
        }
        if (!config.informativeText.length) {
            config.informativeText = defaultConfig.informativeText;
        }
        if (!config.primaryButtonTitle.length) {
            config.primaryButtonTitle = defaultConfig.primaryButtonTitle;
        }
        if (config.style == ACCUIKitViewControllerEmptyPageStyleNotDetermined) {
            config.style = defaultConfig.style;
        }
        if (!config.backgroundColor) {
            config.backgroundColor = defaultConfig.backgroundColor;
        }
        if (!config.titleTextColor) {
            config.titleTextColor = defaultConfig.titleTextColor;
        }
        if (!config.informativeTextColor) {
            config.informativeTextColor = defaultConfig.informativeTextColor;
        }
        if (!config.buttonTitleColor) {
            config.buttonTitleColor = defaultConfig.buttonTitleColor;
        }
        if (!config.appendixViewGenerator) {
            config.appendixViewGenerator = defaultConfig.appendixViewGenerator;
        }
        if (!config.customImageViewGenerator) {
            config.customImageViewGenerator = defaultConfig.customImageViewGenerator;
        }
        if (config.templateType == ACCUIKitViewControllerEmptyPageTemplateUndefined) {
            config.templateType = defaultConfig.templateType;
        }
    } else {
        config = defaultConfig;
    }
    
    if (config) {
        if (!config.iconImage) {
            config.iconImage = fallbackConfig.iconImage;
        }
        if (!config.titleText.length) {
            config.titleText = fallbackConfig.titleText;
        }
        if (!config.informativeText.length) {
            config.informativeText = fallbackConfig.informativeText;
        }
        if (!config.primaryButtonTitle.length) {
            config.primaryButtonTitle = fallbackConfig.primaryButtonTitle;
        }
        if (config.style == ACCUIKitViewControllerEmptyPageStyleNotDetermined) {
            config.style = fallbackConfig.style;
        }
        if (!config.backgroundColor) {
            config.backgroundColor = fallbackConfig.backgroundColor;
        }
        if (!config.titleTextColor) {
            config.titleTextColor = fallbackConfig.titleTextColor;
        }
        if (!config.informativeTextColor) {
            config.informativeTextColor = fallbackConfig.informativeTextColor;
        }
        if (!config.buttonTitleColor) {
            config.buttonTitleColor = fallbackConfig.buttonTitleColor;
        }
        if (!config.appendixViewGenerator) {
            config.appendixViewGenerator = fallbackConfig.appendixViewGenerator;
        }
        if (!config.customImageViewGenerator) {
            config.customImageViewGenerator = fallbackConfig.customImageViewGenerator;
        }
    } else {
        config = fallbackConfig;
    }
    
    return config;
}

// Extended properties
- (ACCUIKitViewControllerState)accui_viewControllerState
{
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (void)setAccui_viewControllerState:(ACCUIKitViewControllerState)accui_viewControllerState
{
    objc_setAssociatedObject(self, @selector(accui_viewControllerState), @(accui_viewControllerState), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self accui_emptyPageReload];
}

- (UIView *)accui_emptyPageBelowView
{
    return nil;
}

- (void)accui_emptyPageReload
{
    [self.accui_emptyPageContainerView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    switch (self.accui_viewControllerState) {
        case ACCUIKitViewControllerStateNormal: {
            [self.accui_emptyPageContainerView removeFromSuperview];
        }
            break;
        case ACCUIKitViewControllerStateEmpty:
        case ACCUIKitViewControllerStateEmptyShouldLogin:
        case ACCUIKitViewControllerStateEmptyReachedMaximum:
        case ACCUIKitViewControllerStateEmptyHarmfulCategory:
        case ACCUIKitViewControllerStateNoMusicFeedback:
        case ACCUIKitViewControllerStateNoMusicFeedbackNoImage:
        case ACCUIKitViewControllerStateError: {
            UIColor *customBackgroundColor = [self _accui_emptyPageConfigForState:self.accui_viewControllerState].backgroundColor;
            if (customBackgroundColor) {
                self.accui_emptyPageContainerView.backgroundColor = customBackgroundColor;
            }
            UIView *belowView = [self accui_emptyPageBelowView];
            if (belowView) {
                [self.view insertSubview:self.accui_emptyPageContainerView belowSubview:belowView];
            } else {
                [self.view addSubview:self.accui_emptyPageContainerView];
            }
            UIEdgeInsets insets = [self accui_emptyPageEdgeInsets];
            ACCMasReMaker(self.accui_emptyPageContainerView, {
                make.top.equalTo(self.view).offset(insets.top);
                make.left.equalTo(self.view).offset(insets.left);
                make.right.equalTo(self.view).offset(-insets.right);
                make.bottom.equalTo(self.view).offset(-insets.bottom);
            });
            UIView *lastView = nil;
            ACCUIKitViewControllerEmptyPageConfig *config = [self _accui_emptyPageConfigForState:self.accui_viewControllerState];
            switch ([self _accui_emptyPageConfigForState:self.accui_viewControllerState].style) {
                case ACCUIKitViewControllerEmptyPageStyleA: {
                    lastView = (config.templateType != ACCUIKitViewControllerEmptyPageTemplateNew ? [self accui_setupConstrainsForStyleA] : [self accui_setupConstrainsForI18NForStyleA]);
                }
                    break;
                case ACCUIKitViewControllerEmptyPageStyleB: {
                    lastView = (config.templateType != ACCUIKitViewControllerEmptyPageTemplateNew ? [self accui_setupConstrainsForStyleB] : [self accui_setupConstrainsForI18NForStyleB]);
                }
                    break;
                case ACCUIKitViewControllerEmptyPageStyleC: {
                    lastView = (config.templateType != ACCUIKitViewControllerEmptyPageTemplateNew ? [self accui_setupConstrainsForStyleC] : [self accui_setupConstrainsForI18NForStyleC]);
                }
                    break;
                case ACCUIKitViewControllerEmptyPageStyleD: {
                    lastView = (config.templateType != ACCUIKitViewControllerEmptyPageTemplateNew ? [self accui_setupConstrainsForStyleD] : [self accui_setupConstrainsForI18NForStyleD]);
                }
                    break;
                case ACCUIKitViewControllerEmptyPageStyleE: {
                    lastView = (config.templateType != ACCUIKitViewControllerEmptyPageTemplateNew) ? [self accui_setupConstrainsForStyleE] : [self accui_setupConstrainsForI18NForStyleE];
                }
                    break;
                case ACCUIKitViewControllerEmptyPageStyleF: {
                    //E,F均为两行文字，统一一下
                    lastView = (config.templateType != ACCUIKitViewControllerEmptyPageTemplateNew ? [self accui_setupConstrainsForStyleF] : [self accui_setupConstrainsForI18NForStyleE]);
                }
                    break;
                    
                default:
                    break;
            }

            UIView *appendix = config.appendixViewGenerator ? config.appendixViewGenerator() : nil;
            if (lastView && appendix) {
                [self.accui_emptyPageContainerView addSubview:appendix];
                ACCMasMaker(appendix, {
                    make.top.equalTo(lastView.mas_bottom).offset(20);
                    make.centerX.equalTo(self.accui_emptyPageContainerView);
                });
            }
            break;
        }
            
        default:
            break;
    }
}

// getters
- (NSMutableDictionary<NSNumber *,NSNumber *> *)accui_emptyPageStyles
{
    NSMutableDictionary *styles = objc_getAssociatedObject(self, _cmd);
    if (!styles) {
        styles = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, styles, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return styles;
}

- (UIView *)accui_emptyPageContainerView
{
    UIView *view = objc_getAssociatedObject(self, _cmd);
    if (!view) {
        view = [[UIView alloc] init];
        objc_setAssociatedObject(self, _cmd, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return view;
}

- (UIImageView *)accui_emptyPageImageView
{
    UIImageView *imageView = objc_getAssociatedObject(self, _cmd);
    if (!imageView) {
        imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        objc_setAssociatedObject(self, _cmd, imageView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return imageView;
}

- (UILabel *)accui_emptyPageTitleLabel
{
    UILabel *label = objc_getAssociatedObject(self, _cmd);
    if (!label) {
        label = [[UILabel alloc] init];
        label.numberOfLines = 0;
        label.font = [ACCFont() systemFontOfSize:17 weight:ACCFontWeightMedium];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = ACCResourceColor(ACCUIColorTextPrimary);
        objc_setAssociatedObject(self, _cmd, label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return label;
}

- (YYLabel *)accui_emptyPageInformativeLabel
{
    YYLabel *label = objc_getAssociatedObject(self, _cmd);
    if (!label) {
        label = [[YYLabel alloc] init];
        label.font =  [ACCFont() systemFontOfSize:14];
        label.alpha = 0.75;
        label.numberOfLines = 0;
        label.preferredMaxLayoutWidth = self.view.bounds.size.width - 64;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = ACCResourceColor(ACCUIColorTextPrimary);
        objc_setAssociatedObject(self, _cmd, label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return label;
}

- (UIButton *)accui_emptyPagePrimaryButton
{
    UIButton *button = objc_getAssociatedObject(self, _cmd);
    if (!button) {
        button = [[ACCUISelectedAlphaButton alloc] init];
        button.backgroundColor = ACCResourceColor(ACCUIColorPrimary);
        [button setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse) forState:UIControlStateNormal];
        button.titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
        button.titleEdgeInsets = UIEdgeInsetsMake(11.5, 16, 12.5, 16);
        button.layer.cornerRadius = 2;
        [button addTarget:self action:@selector(accui_emptyPagePrimaryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(self, _cmd, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return button;
}

- (UIView *)accui_emptyPageGroupView {
    UIView *view = objc_getAssociatedObject(self, _cmd);
    if (!view) {
        view = [[UIView alloc] init];
        objc_setAssociatedObject(self, _cmd, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return view;
}

- (UIView *)accui_emptyPageView
{
    return self.accui_emptyPageContainerView;
}

- (UIView *)accui_setupConstrainsForStyleA {
    UIView *lastView = [self accui_setupConstrinsForPrimaryButtonLastView:[self accui_setupConstrainsForStyleC]];
    
    self.accui_emptyPagePrimaryButton.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
    [self.accui_emptyPagePrimaryButton setTitleColor:[self _accui_emptyPageConfigForState:self.accui_viewControllerState].buttonTitleColor ?: ACCResourceColor(ACCUIColorConstTextInverse) forState:UIControlStateNormal];
    self.accui_emptyPagePrimaryButton.layer.borderWidth = 0;
    
    return lastView;
}

- (UIView *)accui_setupConstrainsForI18NForStyleA {
    UIView *lastView = [self accui_setupConstrinsForPrimaryButtonLastView:[self accui_setupConstrainsForI18NForStyleC]];

    //增加了按钮高度
    ACCMasUpdate(self.accui_emptyPageGroupView, {
        //高度补偿
        make.top.equalTo(self.accui_emptyPageContainerView.mas_bottom).multipliedBy(acc_newStyleHeaderDistanceMultiplier).offset(-acc_newStyleHeaderDistanceMultiplier * acc_newStylePlaceHolderComponentHeight).priorityLow();
        make.top.greaterThanOrEqualTo(self.accui_emptyPageContainerView.mas_top).offset(acc_newStylePlaceHolderTopMinMargin);
    });

    ACCMasUpdate(self.accui_emptyPagePrimaryButton, {
        make.bottom.equalTo(self.accui_emptyPageContainerView.mas_bottom).multipliedBy(acc_newStyleFooterDistanceMultiplier).offset((1 - acc_newStyleFooterDistanceMultiplier) * acc_newStylePlaceHolderComponentHeight).priorityHigh();
        make.bottom.lessThanOrEqualTo(self.accui_emptyPageContainerView).offset(-acc_newStylePlaceHolderBottomMinMargin);
    });

    self.accui_emptyPagePrimaryButton.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
    [self.accui_emptyPagePrimaryButton setTitleColor:[self _accui_emptyPageConfigForState:self.accui_viewControllerState].buttonTitleColor ?: ACCResourceColor(ACCUIColorConstTextInverse) forState:UIControlStateNormal];
    self.accui_emptyPagePrimaryButton.layer.borderWidth = 0;

    return lastView;
}

- (UIView *)accui_setupConstrainsForStyleB {
    return [self accui_setupConstrinsForPrimaryButtonLastView:[self accui_setupConstrainsForStyleC]];
}

- (UIView *)accui_setupConstrainsForI18NForStyleB {
    UIView *lastView = [self accui_setupConstrinsForPrimaryButtonLastView:[self accui_setupConstrainsForI18NForStyleC]];
    //增加了按钮高度
    ACCMasUpdate(self.accui_emptyPageGroupView, {
        //高度补偿
        make.top.equalTo(self.accui_emptyPageContainerView.mas_bottom).multipliedBy(acc_newStyleHeaderDistanceMultiplier).offset(-acc_newStyleHeaderDistanceMultiplier * acc_newStylePlaceHolderComponentHeight).priorityLow();
        make.top.greaterThanOrEqualTo(self.accui_emptyPageContainerView.mas_top).offset(acc_newStylePlaceHolderTopMinMargin);
    });

    ACCMasUpdate(self.accui_emptyPagePrimaryButton, {
        make.bottom.equalTo(self.accui_emptyPageContainerView.mas_bottom).multipliedBy(acc_newStyleFooterDistanceMultiplier).offset((1 - acc_newStyleFooterDistanceMultiplier) * acc_newStylePlaceHolderComponentHeight).priorityHigh();
        make.bottom.lessThanOrEqualTo(self.accui_emptyPageContainerView).offset(-acc_newStylePlaceHolderBottomMinMargin);
    });
    return lastView;
}

- (UIView *)accui_setupConstrinsForPrimaryButtonLastView:(UIView *)lastView
{
    [self.accui_emptyPageContainerView addSubview:self.accui_emptyPagePrimaryButton];
    ACCUIKitViewControllerEmptyPageConfig *config = [self _accui_emptyPageConfigForState:self.accui_viewControllerState];
    [self.accui_emptyPagePrimaryButton setTitle:config.primaryButtonTitle forState:UIControlStateNormal];
    
    ACCMasMaker(self.accui_emptyPagePrimaryButton, {
        make.bottom.equalTo(self.accui_emptyPageContainerView.mas_bottom).multipliedBy(0.8).priorityMedium();
        make.top.greaterThanOrEqualTo(lastView.mas_bottom).offset(40);
        make.width.greaterThanOrEqualTo(@231);
        make.width.lessThanOrEqualTo(@311);
        make.height.equalTo(@44);
        make.centerX.equalTo(self.accui_emptyPageContainerView);
    });
    //没有对应的constColor
    self.accui_emptyPagePrimaryButton.backgroundColor = config.buttonBackgroundColor ? : ACCResourceColor(ACCUIColorBGContainer2);
    [self.accui_emptyPagePrimaryButton setTitleColor:config.buttonTitleColor ?:  ACCResourceColor(ACCUIColorTextPrimary) forState:UIControlStateNormal];

    self.accui_emptyPagePrimaryButton.layer.borderColor = (config.buttonBorderColor ?: ACCResourceColor(ACCUIColorLineSecondary2)).CGColor;
    self.accui_emptyPagePrimaryButton.layer.borderWidth = 1;
    
    return self.accui_emptyPagePrimaryButton;
}

- (UIView *)accui_setupConstrainsForStyleC {
    ACCUIKitViewControllerEmptyPageConfig *config = [self _accui_emptyPageConfigForState:self.accui_viewControllerState];
    UIView *customView = config.customImageViewGenerator ? config.customImageViewGenerator() : nil;
    if (!customView) {
        customView = self.accui_emptyPageImageView;
        self.accui_emptyPageImageView.image = [self _accui_emptyPageConfigForState:self.accui_viewControllerState].iconImage;
    }
    
    [self.accui_emptyPageContainerView addSubview:customView];
    [self.accui_emptyPageContainerView addSubview:self.accui_emptyPageTitleLabel];
    [self.accui_emptyPageContainerView addSubview:self.accui_emptyPageInformativeLabel];
    
    self.accui_emptyPageTitleLabel.text = config.titleText;
    self.accui_emptyPageTitleLabel.textColor = config.titleTextColor;
    [self acc_setLinkAttributedStringIfNeeded];
    ACCMasMaker(customView, {
        make.top.equalTo(self.accui_emptyPageContainerView.mas_bottom).multipliedBy(0.2);
        make.width.equalTo(@(240));
        make.height.equalTo(@(160));
        make.centerX.equalTo(self.accui_emptyPageContainerView);
    });
    
    ACCMasMaker(self.accui_emptyPageTitleLabel, {
        make.top.equalTo(customView.mas_bottom).offset(32);
        make.left.greaterThanOrEqualTo(self.accui_emptyPageContainerView).offset(32);
        make.right.lessThanOrEqualTo(self.accui_emptyPageContainerView).offset(-32);
        make.centerX.equalTo(self.accui_emptyPageContainerView);
    });
    
    ACCMasMaker(self.accui_emptyPageInformativeLabel, {
        make.top.equalTo(self.accui_emptyPageTitleLabel.mas_bottom).offset(12);
        make.left.greaterThanOrEqualTo(self.accui_emptyPageContainerView).offset(32);
        make.right.lessThanOrEqualTo(self.accui_emptyPageContainerView).offset(-32);
        make.centerX.equalTo(self.accui_emptyPageContainerView);
    });
    
    return self.accui_emptyPageInformativeLabel;
}

- (UIView *)accui_setupConstrainsForI18NForStyleC {
    ACCUIKitViewControllerEmptyPageConfig *config = [self _accui_emptyPageConfigForState:self.accui_viewControllerState];
    UIView *customView = config.customImageViewGenerator ? config.customImageViewGenerator() : nil;
    if (!customView) {
        customView = self.accui_emptyPageImageView;
        self.accui_emptyPageImageView.image = [self _accui_emptyPageConfigForState:self.accui_viewControllerState].iconImage;
    }
    //增加组合组件来定高
    [self.accui_emptyPageContainerView addSubview:self.accui_emptyPageGroupView];
    [self.accui_emptyPageGroupView addSubview:customView];
    [self.accui_emptyPageGroupView addSubview:self.accui_emptyPageTitleLabel];
    [self.accui_emptyPageGroupView addSubview:self.accui_emptyPageInformativeLabel];

    self.accui_emptyPageTitleLabel.text = config.titleText;
    self.accui_emptyPageTitleLabel.textColor = config.titleTextColor;
    [self acc_setLinkAttributedStringIfNeeded];
    ACCMasMaker(self.accui_emptyPageGroupView, {
        //高度补偿,styleC下，空白部分2：3
        make.top.equalTo(self.accui_emptyPageContainerView.mas_bottom).multipliedBy(acc_newStyleHeaderDistanceMultiplier).offset(-acc_newStyleHeaderDistanceMultiplier * acc_newStylePlaceHolderComponentHeightWithNoButton).priorityHigh();
        make.top.greaterThanOrEqualTo(self.accui_emptyPageContainerView).offset(acc_newStylePlaceHolderTopMinMargin);
        make.bottom.lessThanOrEqualTo(self.accui_emptyPageContainerView).offset(-acc_newStylePlaceHolderBottomMinMargin);
        make.left.equalTo(self.accui_emptyPageContainerView).offset(32.5);
        make.right.equalTo(self.accui_emptyPageContainerView).offset(-32.5);
        make.height.equalTo(@(acc_newStylePlaceHolderComponentHeightWithNoButton));

    });
    ACCMasMaker(customView, {
        make.top.centerX.equalTo(self.accui_emptyPageGroupView);
        make.height.width.equalTo(@(acc_newStylePlaceHolderImageLength));
    });

    ACCMasMaker(self.accui_emptyPageTitleLabel, {
        make.top.equalTo(customView.mas_bottom).offset(24);
        make.centerX.equalTo(self.accui_emptyPageGroupView);
        make.left.greaterThanOrEqualTo(self.accui_emptyPageGroupView);
        make.right.lessThanOrEqualTo(self.accui_emptyPageGroupView);
    });

    ACCMasMaker(self.accui_emptyPageInformativeLabel, {
        make.top.equalTo(self.accui_emptyPageTitleLabel.mas_bottom).offset(12);
        make.centerX.equalTo(self.accui_emptyPageGroupView);
        make.left.greaterThanOrEqualTo(self.accui_emptyPageGroupView);
        make.right.lessThanOrEqualTo(self.accui_emptyPageGroupView);
    });

    if (ACC_isEmptyString(config.titleText)) {
        //C下特殊处理标题为空的场合
        [self.accui_emptyPageTitleLabel removeFromSuperview];
        ACCMasReMaker(self.accui_emptyPageInformativeLabel, {
            make.top.equalTo(customView.mas_bottom).offset(24);
            make.centerX.equalTo(self.accui_emptyPageGroupView);
            make.left.greaterThanOrEqualTo(self.accui_emptyPageGroupView);
            make.right.lessThanOrEqualTo(self.accui_emptyPageGroupView);
        });
    }

    return self.accui_emptyPageInformativeLabel;
}

- (UIView *)accui_setupConstrainsForStyleE {
    ACCUIKitViewControllerEmptyPageConfig *config = [self _accui_emptyPageConfigForState:self.accui_viewControllerState];
    [self.accui_emptyPageContainerView addSubview:self.accui_emptyPageTitleLabel];
    [self.accui_emptyPageContainerView addSubview:self.accui_emptyPageInformativeLabel];
    
    self.accui_emptyPageTitleLabel.text = config.titleText;
    self.accui_emptyPageTitleLabel.textColor = config.titleTextColor;
    [self acc_setLinkAttributedStringIfNeeded];
    ACCMasMaker(self.accui_emptyPageTitleLabel, {
        make.top.equalTo(self.accui_emptyPageContainerView.mas_bottom).multipliedBy(0.3);
        make.left.greaterThanOrEqualTo(self.accui_emptyPageContainerView).offset(32);
        make.right.lessThanOrEqualTo(self.accui_emptyPageContainerView).offset(-32);
        make.centerX.equalTo(self.accui_emptyPageContainerView);
    });

    ACCMasMaker(self.accui_emptyPageInformativeLabel, {
        make.top.equalTo(self.accui_emptyPageTitleLabel.mas_bottom).offset(12);
        make.left.greaterThanOrEqualTo(self.accui_emptyPageContainerView).offset(32);
        make.right.lessThanOrEqualTo(self.accui_emptyPageContainerView).offset(-32);
        make.centerX.equalTo(self.accui_emptyPageContainerView);
    });

    return self.accui_emptyPageInformativeLabel;
}

- (UIView *)accui_setupConstrainsForI18NForStyleE {
    //增加组合组件来定高
    ACCUIKitViewControllerEmptyPageConfig *config = [self _accui_emptyPageConfigForState:self.accui_viewControllerState];
    [self.accui_emptyPageContainerView addSubview:self.accui_emptyPageGroupView];
    [self.accui_emptyPageGroupView addSubview:self.accui_emptyPageTitleLabel];
    [self.accui_emptyPageGroupView addSubview:self.accui_emptyPageInformativeLabel];

    self.accui_emptyPageTitleLabel.text = config.titleText;
    self.accui_emptyPageTitleLabel.textColor = config.titleTextColor;
    if (config.informativeLabelAlpha != nil) {
        self.accui_emptyPageInformativeLabel.alpha = [config.informativeLabelAlpha doubleValue];
    } else {
        self.accui_emptyPageInformativeLabel.alpha = 0.75;
    }
    [self acc_setLinkAttributedStringIfNeeded];
    ACCMasMaker(self.accui_emptyPageGroupView, {
        //高度补偿,styleC下，空白部分2：3
        make.top.equalTo(self.accui_emptyPageContainerView.mas_bottom).multipliedBy(acc_newStyleHeaderDistanceMultiplier).offset(-acc_newStyleHeaderDistanceMultiplier * acc_newStylePlaceHolderComponentHeightWithNoImageNoButton).priorityHigh();
        make.top.greaterThanOrEqualTo(self.accui_emptyPageContainerView).offset(acc_newStylePlaceHolderTopMinMargin);
        make.bottom.lessThanOrEqualTo(self.accui_emptyPageContainerView).offset(-acc_newStylePlaceHolderBottomMinMargin);

        make.left.equalTo(self.accui_emptyPageContainerView).offset(32.5);
        make.right.equalTo(self.accui_emptyPageContainerView).offset(-32.5);
        make.height.equalTo(@(acc_newStylePlaceHolderComponentHeightWithNoImageNoButton));
    });

    ACCMasMaker(self.accui_emptyPageTitleLabel, {
        make.top.centerX.equalTo(self.accui_emptyPageGroupView);
        make.left.greaterThanOrEqualTo(self.accui_emptyPageGroupView);
        make.right.lessThanOrEqualTo(self.accui_emptyPageGroupView);
    });

    ACCMasMaker(self.accui_emptyPageInformativeLabel, {
        make.top.equalTo(self.accui_emptyPageTitleLabel.mas_bottom).offset(12);
        make.centerX.equalTo(self.accui_emptyPageGroupView);
        make.left.greaterThanOrEqualTo(self.accui_emptyPageGroupView);
        make.right.lessThanOrEqualTo(self.accui_emptyPageGroupView);
    });

    return self.accui_emptyPageInformativeLabel;
}

- (UIView *)accui_setupConstrainsForStyleF {
    ACCUIKitViewControllerEmptyPageConfig *config = [self _accui_emptyPageConfigForState:self.accui_viewControllerState];
    [self.accui_emptyPageContainerView addSubview:self.accui_emptyPageInformativeLabel];
    [self.accui_emptyPageContainerView addSubview:self.accui_emptyPageTitleLabel];
    
    self.accui_emptyPageTitleLabel.text = config.titleText;
    self.accui_emptyPageTitleLabel.textColor = config.titleTextColor;
    [self acc_setLinkAttributedStringIfNeeded];

    ACCMasMaker(self.accui_emptyPageTitleLabel, {
        make.leading.equalTo(self.accui_emptyPageContainerView).offset(32);
        make.trailing.equalTo(self.accui_emptyPageContainerView).offset(-32);
        make.top.equalTo(self.accui_emptyPageContainerView).offset(40);
        make.centerX.equalTo(self.accui_emptyPageContainerView);
    });
    ACCMasMaker(self.accui_emptyPageInformativeLabel, {
        make.top.equalTo(self.accui_emptyPageContainerView).offset(80);
        make.left.greaterThanOrEqualTo(self.accui_emptyPageContainerView).offset(32);
        make.right.lessThanOrEqualTo(self.accui_emptyPageContainerView).offset(-32);
        make.centerX.equalTo(self.accui_emptyPageContainerView);
    });
    
    return self.accui_emptyPageInformativeLabel;
}

- (UIView *)accui_setupConstrainsForStyleD {
    return [self accui_setupConstrinsForPrimaryButtonLastView:[self accui_setupConstrainsForStyleE]];
}

- (UIView *)accui_setupConstrainsForI18NForStyleD {
    UIView *lastView = [self accui_setupConstrinsForPrimaryButtonLastView:[self accui_setupConstrainsForI18NForStyleE]];
    //增加了按钮高度
    ACCMasUpdate(self.accui_emptyPageGroupView, {
        //190 = 146组件 + 44 的按钮
        make.top.equalTo(self.accui_emptyPageContainerView.mas_bottom).multipliedBy(acc_newStyleHeaderDistanceMultiplier).offset(-acc_newStyleHeaderDistanceMultiplier * acc_newStylePlaceHolderComponentHeightWithNoImage).priorityHigh();
    });

    ACCMasUpdate(self.accui_emptyPagePrimaryButton, {
        make.bottom.equalTo(self.accui_emptyPageContainerView.mas_bottom).multipliedBy(acc_newStyleFooterDistanceMultiplier).offset((1 - acc_newStyleFooterDistanceMultiplier) * acc_newStylePlaceHolderComponentHeightWithNoImage).priorityHigh();
        make.bottom.lessThanOrEqualTo(self.accui_emptyPageContainerView).offset(-acc_newStylePlaceHolderBottomMinMargin);
    });
    return lastView;
}

- (void)accui_emptyPagePrimaryButtonTapped:(UIButton *)sender
{
    
}
- (UIEdgeInsets)accui_emptyPageEdgeInsets
{
    return UIEdgeInsetsZero;
}

- (void)acc_setLinkAttributedStringIfNeeded
{
    ACCUIKitViewControllerEmptyPageConfig *config = [self _accui_emptyPageConfigForState:self.accui_viewControllerState];
    self.accui_emptyPageInformativeLabel.text = [self acc_translateInformativeLabel:config.informativeText];
    self.accui_emptyPageInformativeLabel.textColor = config.informativeTextColor;
    if (config.linkBlock && config.linkRange.location != NSNotFound && config.linkRange.length != 0) {
        if (config.informativeLabelAlpha != nil) {
            self.accui_emptyPageInformativeLabel.alpha = [config.informativeLabelAlpha doubleValue];
        } else {
            self.accui_emptyPageInformativeLabel.alpha = 0.75;
        }
        NSMutableAttributedString *informativeText = [[NSMutableAttributedString alloc] initWithString:[self acc_translateInformativeLabel:config.informativeText]];
        informativeText.yy_color = config.informativeTextColor;
        informativeText.yy_font  =  [ACCFont() systemFontOfSize:14];
        informativeText.yy_alignment = NSTextAlignmentCenter;
        if ([informativeText string].length <= config.linkRange.location || [informativeText string].length <= config.linkRange.location + config.linkRange.length - 1) {
            //额外的越界处理，服务端下发语种为英文，且被客户端翻译，range不对了
            return;
        }
        @weakify(self);
        [informativeText yy_setTextHighlightRange:config.linkRange color:config.informativeHighlightColor ?: ACCResourceColor(ACCUIColorLink2) backgroundColor:[UIColor clearColor] tapAction:^(UIView * _Nonnull containerView, NSAttributedString * _Nonnull text, NSRange range, CGRect rect) {
            @strongify(self);
            if (config.linkBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    config.linkBlock(self);
                });
            }
        }];
        if (config.informativeHighlightFont) {
            [informativeText addAttribute:NSFontAttributeName value:config.informativeHighlightFont range:config.linkRange];
        }
        self.accui_emptyPageInformativeLabel.attributedText = informativeText;
    }
}

@end
