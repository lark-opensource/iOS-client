// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxRawTextShadowNode.h"
#import "LynxComponentRegistry.h"
#import "LynxPropsProcessor.h"

@implementation LynxRawTextShadowNode

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_SHADOW_NODE("raw-text")
#else
LYNX_REGISTER_SHADOW_NODE("raw-text")
#endif

- (BOOL)isVirtual {
  return YES;
}

LYNX_PROP_SETTER("text", setText, id) {
  if (requestReset) {
    value = nil;
  }
  NSString *text = @"";
  if ([value isKindOfClass:[NSString class]]) {
    text = value;
  } else if ([value isKindOfClass:[@(NO) class]]) {
    // __NSCFBoolean is subclass of NSNumber, so this need to check first
    BOOL boolVallue = [value boolValue];
    text = boolVallue ? @"true" : @"false";
  } else if ([value isKindOfClass:[NSNumber class]]) {
    double conversionValue = [value doubleValue];
    NSString *doubleString = [NSString stringWithFormat:@"%lf", conversionValue];
    NSDecimalNumber *decNumber = [NSDecimalNumber decimalNumberWithString:doubleString];
    text = [decNumber stringValue];
    // remove scientific notation when display big num, such as "1.23456789012E11" to "123456789012"
    // NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    // formatter.numberStyle = kCFNumberFormatterNoStyle;
    //  text = [formatter stringFromNumber:[NSNumber numberWithDouble:[value doubleValue]]];
    //  text = [[NSDecimalNumber decimalNumberWithString:text] stringValue];
  }
  if (_text != text) {
    _text = text;
    [self setNeedsLayout];
  }
}

@end
