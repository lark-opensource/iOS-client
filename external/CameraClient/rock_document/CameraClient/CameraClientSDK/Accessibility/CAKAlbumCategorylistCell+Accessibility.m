//
//  CAKAlbumCategorylistCell+Accessibility.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/7/18.
//

#import "CAKAlbumCategorylistCell+Accessibility.h"

#import <CreativeKit/ACCLanguageProtocol.h>

@implementation CAKAlbumCategorylistCell (Accessibility)

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    if (self.isSelected) {
        return [NSString stringWithFormat:@"%@%@",  ACCLocalizedCurrentString(@"com_mig_selected_8i1pf2"), self.titleLabel.text ?: @""];
    } else {
        return [NSString stringWithFormat:@"%@%@",  ACCLocalizedCurrentString(@"com_mig_unselected"), self.titleLabel.text ?: @""];
    }
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitImage;
}

@end
