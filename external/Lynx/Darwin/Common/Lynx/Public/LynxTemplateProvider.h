// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXTEMPLATEPROVIDER_H_
#define DARWIN_COMMON_LYNX_LYNXTEMPLATEPROVIDER_H_

#import <Foundation/Foundation.h>
typedef void (^LynxTemplateLoadBlock)(NSData* data, NSError* error);

/**
 * A helper class for load template
 */
@protocol LynxTemplateProvider <NSObject>

- (void)loadTemplateWithUrl:(NSString*)url onComplete:(LynxTemplateLoadBlock)callback;

@end

#endif  // DARWIN_COMMON_LYNX_LYNXTEMPLATEPROVIDER_H_
