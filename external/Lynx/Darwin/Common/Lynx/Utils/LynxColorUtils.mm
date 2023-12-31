// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxColorUtils.h"
#include "css/css_color.h"

@implementation LynxColorUtils

+ (COLOR_CLASS*)convertNSStringToUIColor:(NSString*)value {
  if (value == nil) {
    return NULL;
  }
  std::string str = [value UTF8String];
  lynx::tasm::CSSColor color;
  if (lynx::tasm::CSSColor::Parse(str, color)) {
    return [COLOR_CLASS colorWithRed:((float)color.r_ / 255.0f)
                               green:((float)color.g_ / 255.0f)
                                blue:((float)color.b_ / 255.0f)
                               alpha:((float)color.a_)];
  }
  return NULL;
}

@end
