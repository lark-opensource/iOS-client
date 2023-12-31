//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxClassAliasDefines.h"
#import "LynxConverter.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxConverter (UI)

+ (COLOR_CLASS *)toUIColor:(id)value;

// TODO (xiamengfei.moonface): move to iOS folder
#if TARGET_OS_IPHONE
+ (UIAccessibilityTraits)toAccessibilityTraits:(id)value;
#endif

@end

NS_ASSUME_NONNULL_END
