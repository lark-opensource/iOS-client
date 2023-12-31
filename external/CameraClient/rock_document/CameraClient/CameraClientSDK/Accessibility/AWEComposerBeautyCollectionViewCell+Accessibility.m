//
//  AWEComposerBeautyCollectionViewCell+Accessibility.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/7/18.
//

#import "AWEComposerBeautyCollectionViewCell+Accessibility.h"

@implementation AWEComposerBeautyCollectionViewCell (Accessibility)

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
