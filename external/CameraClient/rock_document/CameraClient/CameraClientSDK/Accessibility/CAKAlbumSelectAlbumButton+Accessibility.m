//
//  CAKAlbumSelectAlbumButton+Accessibility.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/7/18.
//

#import "CAKAlbumSelectAlbumButton+Accessibility.h"

@implementation CAKAlbumSelectAlbumButton (Accessibility)

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.leftLabel.text ?: @"";
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

@end
