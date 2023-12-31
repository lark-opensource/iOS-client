//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNX_TEMPLATE_BUNDLE_H_
#define DARWIN_COMMON_LYNX_LYNX_TEMPLATE_BUNDLE_H_

@interface LynxTemplateBundle : NSObject

- (instancetype _Nullable)initWithTemplate:(nonnull NSData*)tem;
- (NSString* _Nullable)errorMsg;

/**
 * get ExtraInfo of a `template.js`
 * the `template.js` in defined in pageConfig as a object with key "extraInfo"
 *
 * @return ExtraInfo of LynxTemplate
 */
- (NSDictionary* _Nullable)extraInfo;

@end

#endif  // DARWIN_COMMON_LYNX_LYNX_TEMPLATE_BUNDLE_H_
