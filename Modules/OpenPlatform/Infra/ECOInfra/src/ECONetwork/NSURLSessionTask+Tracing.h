//
//  NSURLSessionTask+Tracing.h
//  Timor
//
//  Created by changrong on 2020/9/16.
//

#import <Foundation/Foundation.h>
#import <ECOProbe/OPTrace.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSessionTask(Tracing)

@property (nonatomic, strong, readonly, nullable) OPTrace *trace;

- (void)bindTrace:(OPTrace *)trace;

@end

NS_ASSUME_NONNULL_END
