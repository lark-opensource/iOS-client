//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxUI (Accessibility)
- (void)handleAccessibility:(UIView *)accessibilityAttachedCell
                 autoScroll:(BOOL)accessibilityAutoScroll;

- (NSString *)accessibilityText;

@end

NS_ASSUME_NONNULL_END
