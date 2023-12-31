//
//  HTSVideoFilterTableViewCell+Accessibility.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/7/18.
//

#import "HTSVideoFilterTableViewCell+Accessibility.h"

@implementation HTSVideoFilterTableViewCell (Accessibility)

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [self getEffectName];
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitNone;
}

@end
