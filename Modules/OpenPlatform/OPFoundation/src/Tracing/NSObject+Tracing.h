//
//  NSObject+TracingPerformSelector.h
//  Timor
//
//  Created by changrong on 2020/5/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject(Tracing)

/// 用于包裹tracing的perfomSelector
/// @param aSelector aSelector
/// @param arg arg
/// @param wait wait
- (void)bdp_tracingPerformSelectorOnMainThread:(SEL)aSelector withObject:(id)arg waitUntilDone:(BOOL)wait;

@end

NS_ASSUME_NONNULL_END
