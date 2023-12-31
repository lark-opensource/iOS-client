//
//  UIView+ACCUITheme.m
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/9/23.
//

#import "UIView+ACCUITheme.h"
#import "UIView+ACCLayerColor.h"
#import "ACCUIThemeManager.h"
#import "ACCUIDynamicColor.h"
#import "NSAttributedString+ACCUIDynamicColor.h"

#import <objc/runtime.h>

@implementation UIView (ACCUITheme)

#pragma mark - class method
+ (NSDictionary<NSString *, NSArray<NSString *> *> *)acc_classRegisters
{
    return @{
        NSStringFromClass(UISlider.class):                   @[NSStringFromSelector(@selector(minimumTrackTintColor)),
                                                               NSStringFromSelector(@selector(maximumTrackTintColor)),
                                                               NSStringFromSelector(@selector(thumbTintColor))],
        NSStringFromClass(UISwitch.class):                   @[NSStringFromSelector(@selector(onTintColor)),
                                                               NSStringFromSelector(@selector(thumbTintColor)),],
        NSStringFromClass(UIActivityIndicatorView.class):    @[NSStringFromSelector(@selector(color)),],
        NSStringFromClass(UIProgressView.class):             @[NSStringFromSelector(@selector(progressTintColor)),
                                                               NSStringFromSelector(@selector(trackTintColor)),],
        NSStringFromClass(UIPageControl.class):              @[NSStringFromSelector(@selector(pageIndicatorTintColor)),
                                                               NSStringFromSelector(@selector(currentPageIndicatorTintColor)),],
        NSStringFromClass(UITableView.class):                @[NSStringFromSelector(@selector(backgroundColor)),
                                                               NSStringFromSelector(@selector(sectionIndexColor)),
                                                               NSStringFromSelector(@selector(sectionIndexBackgroundColor)),
                                                               NSStringFromSelector(@selector(sectionIndexTrackingBackgroundColor)),
                                                               NSStringFromSelector(@selector(separatorColor)),],
        NSStringFromClass(UINavigationBar.class):            @[NSStringFromSelector(@selector(barTintColor)),],
        NSStringFromClass(UIToolbar.class):                  @[NSStringFromSelector(@selector(barTintColor)),],
        NSStringFromClass(UITabBar.class):                   ({
            NSArray<NSString *> *result = nil;
            if (@available(iOS 10.0, *)) {
#ifdef IOS13_SDK_ALLOWED
                if (@available(iOS 13.0, *)) {
                    result = @[NSStringFromSelector(@selector(standardAppearance)),];
                } else {
#endif
                    result = @[NSStringFromSelector(@selector(barTintColor)),
                               NSStringFromSelector(@selector(unselectedItemTintColor)),
                               NSStringFromSelector(@selector(selectedImageTintColor)),];
#ifdef IOS13_SDK_ALLOWED
                }
#endif
            } else {
                result = @[NSStringFromSelector(@selector(barTintColor)),
                           NSStringFromSelector(@selector(selectedImageTintColor)),];
            }
            result;
        }),
        NSStringFromClass(UISearchBar.class):                        @[NSStringFromSelector(@selector(barTintColor))],
        NSStringFromClass(UIView.class):                             @[NSStringFromSelector(@selector(tintColor)),
                                                                       NSStringFromSelector(@selector(backgroundColor)),
                                                                       NSStringFromSelector(@selector(acc_layerBorderColor)),
                                                                       NSStringFromSelector(@selector(acc_layerBackgroundColor))],
    };
}

#pragma mark - public
- (void)acc_themeReload
{
    [self acc_themeDidChange];
    
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj acc_themeReload];
    }];
}

#pragma mark - privare

- (void)acc_themeDidChange
{
    if (!self.acc_themeColorMethods) {
        [self acc_registerThemeColorMethods];
    }
    
    [self.acc_themeColorMethods enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull getterString, NSString * _Nonnull setterString, BOOL * _Nonnull stop) {
        
        SEL getter = NSSelectorFromString(getterString);
        SEL setter = NSSelectorFromString(setterString);

        id value = [self performSelector:getter];
        
        if (!value) return;

        if ([value isKindOfClass:ACCUIDynamicColor.class]) {
            [self performSelector:setter withObject:UIColor.clearColor];
            [self performSelector:setter withObject:value];
        }
        
    }];
    
    [self acc_textColorDidChange];
}

- (void)acc_textColorDidChange
{
    static NSArray<Class> *needsDisplayClasses = nil;
    if (!needsDisplayClasses) needsDisplayClasses = @[UILabel.class, UITextField.class, UITextView.class, NSClassFromString(@"YYLabel")];
    [needsDisplayClasses enumerateObjectsUsingBlock:^(Class  _Nonnull class, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self isKindOfClass:class]) {
            UILabel *label = (UILabel *)self;
            NSAttributedString *attributedText = label.attributedText;
            BOOL textContainsDynamicColor = [attributedText acc_attributeContainsDynamicColor];
            if (textContainsDynamicColor) {
                label.attributedText = attributedText;
                [label setNeedsDisplay];
            } else {
                id color = label.textColor;
                if ([color isKindOfClass:ACCUIDynamicColor.class]) {
                    label.textColor = UIColor.clearColor;
                    label.textColor = color;
                }
            }
            *stop = YES;
        }
    }];
}

- (void)acc_registerThemeColorMethods
{
    NSDictionary<NSString *, NSArray<NSString *> *> *classRegisters = [self.class acc_classRegisters];
    
    [classRegisters enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull classString, NSArray<NSString *> * _Nonnull getters, BOOL * _Nonnull stop) {
        if ([self isKindOfClass:NSClassFromString(classString)]) {
            [self acc_registerThemeColorMethodsWithGetters:getters];
        }
    }];
}

- (void)acc_registerThemeColorMethodsWithGetters:(NSArray<NSString *> *)getters
{
    [getters enumerateObjectsUsingBlock:^(NSString * _Nonnull getterString, NSUInteger idx, BOOL * _Nonnull stop) {
        if (getterString.length > 0) {
            
            NSString *setterString = [NSString stringWithFormat:@"set%@%@:",[getterString substringToIndex:1].uppercaseString, [getterString substringFromIndex:1]];
            NSAssert([self respondsToSelector:NSSelectorFromString(getterString)], @"register theme color fails, %@ does not have method called %@", NSStringFromClass(self.class), getterString);
            NSAssert([self respondsToSelector:NSSelectorFromString(setterString)], @"register theme color fails, %@ does not have method called %@", NSStringFromClass(self.class), setterString);
            
            if (!self.acc_themeColorMethods) {
                self.acc_themeColorMethods = [[NSMutableDictionary alloc] init];
            }
            self.acc_themeColorMethods[getterString] = setterString;
        }
    }];
}

#pragma mark - property

- (NSMutableDictionary<NSString *,NSString *> *)acc_themeColorMethods
{
    return objc_getAssociatedObject(self, @selector(acc_themeColorMethods));
}

- (void)setAcc_themeColorMethods:(NSMutableDictionary<NSString *,NSString *> *)acc_themeColorMethods
{
    objc_setAssociatedObject(self, @selector(acc_themeColorMethods), acc_themeColorMethods, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
