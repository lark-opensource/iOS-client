//
//  BDPJSRunningThreadAsyncDispatchQueue.h
//  Timor
//
//  Created by dingruoshan on 2019/6/14.
//

#import <Foundation/Foundation.h>
#import "BDPJSRunningThread.h"

NS_ASSUME_NONNULL_BEGIN

// 如果代码执行在当前的dispatch queue，则不再dispatch_async，直接执行，否则async一次
@interface BDPJSRunningThreadAsyncDispatchQueue : NSObject
@property (nonatomic, strong, readonly) BDPJSRunningThread* thread;
@property (nonatomic, assign) BOOL enableAcceptAsyncCall;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithThread:(BDPJSRunningThread*)thread;

- (void)startThread:(BOOL)waitUntilStarted;
- (void)stopThread:(BOOL)waitUntilDone;

- (void)dispatchASync:(dispatch_block_t)blk;
- (void)removeAllAsyncDispatch;

@end

NS_ASSUME_NONNULL_END
