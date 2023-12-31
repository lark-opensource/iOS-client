//
//  AWEAnimatedRecordButton+Accessibility.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/7/18.
//

#import "AWEAnimatedRecordButton+Accessibility.h"

#import <CreativeKit/ACCLanguageProtocol.h>

@implementation AWEAnimatedRecordButton (Accessibility)

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return ACCLocalizedString(@"shoot", @"record");
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

@end
