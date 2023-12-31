//
//  AWEComposerBeautyTopBarCollectionViewCell+Accessibility.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/7/18.
//

#import "AWEComposerBeautyTopBarCollectionViewCell+Accessibility.h"

@implementation AWEComposerBeautyTopBarCollectionViewCell (Accessibility)

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    return self.titleLabel.text;
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton;
}

@end
