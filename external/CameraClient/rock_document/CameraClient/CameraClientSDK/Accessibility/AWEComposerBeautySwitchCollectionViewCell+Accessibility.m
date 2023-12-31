//
//  AWEComposerBeautySwitchCollectionViewCell+Accessibility.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/7/18.
//

#import "AWEComposerBeautySwitchCollectionViewCell+Accessibility.h"

@implementation AWEComposerBeautySwitchCollectionViewCell (Accessibility)

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.switchLabel.text;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

@end
