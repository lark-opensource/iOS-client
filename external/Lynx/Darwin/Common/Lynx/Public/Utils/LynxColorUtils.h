// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxClassAliasDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxColorUtils : NSObject

+ (nullable COLOR_CLASS*)convertNSStringToUIColor:(NSString*)value;

@end

NS_ASSUME_NONNULL_END
