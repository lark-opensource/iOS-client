//
//  AWESlider+Accessibility.m
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/8/10.
//

#import "AWESlider+Accessibility.h"

@implementation AWESlider (Accessibility)

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (UIAccessibilityTraits) accessibilityTraits{
    return UIAccessibilityTraitAdjustable;
}

- (void)accessibilityIncrement
{
    self.value = MIN(self.maximumValue, self.value + (self.maximumValue - self.minimumValue) / 10);
    [self.delegate slider:self valueDidChanged:self.value];
}

- (void)accessibilityDecrement
{
    self.value = MAX(self.minimumValue, self.value - (self.maximumValue - self.minimumValue) / 10);
    [self.delegate slider:self valueDidChanged:self.value];
}

@end
