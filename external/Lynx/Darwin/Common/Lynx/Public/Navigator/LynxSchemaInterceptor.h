//
//  LynxSchemaInterceptor.h
//

#ifndef DARWIN_COMMON_LYNX_NAVIGATOR_LYNXSCHEMAINTERCEPTOR_H_
#define DARWIN_COMMON_LYNX_NAVIGATOR_LYNXSCHEMAINTERCEPTOR_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LynxSchemaInterceptor <NSObject>

- (bool)intercept:(nonnull NSString *)schema withParam:(nonnull NSDictionary *)param;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_NAVIGATOR_LYNXSCHEMAINTERCEPTOR_H_
