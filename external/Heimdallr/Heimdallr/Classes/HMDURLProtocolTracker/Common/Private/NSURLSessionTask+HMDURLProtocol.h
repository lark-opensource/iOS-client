//
//  NSURLSessionTask+HMDURLProtocol.h
//  Heimdallr
//
//  Created by fengyadong on 2019/2/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSessionTask (HMDURLProtocol)

@property (nonatomic, strong) NSThread *hmdThread;
@property (nonatomic, strong) NSArray *hmdModes;

- (void)hmdPerformBlock:(dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END
