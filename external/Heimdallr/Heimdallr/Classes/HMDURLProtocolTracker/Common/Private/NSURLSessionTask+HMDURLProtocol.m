//
//  NSURLSessionTask+HMDURLProtocol.m
//  Heimdallr
//
//  Created by fengyadong on 2019/2/11.
//

#import "NSURLSessionTask+HMDURLProtocol.h"
#import <objc/runtime.h>

@implementation NSURLSessionTask (HMDURLProtocol)

- (NSThread *)hmdThread {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setHmdThread:(NSThread *)hmdThread {
    objc_setAssociatedObject(self, @selector(hmdThread), hmdThread, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)hmdModes {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setHmdModes:(NSArray *)hmdModes {
    objc_setAssociatedObject(self, @selector(hmdModes), hmdModes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)hmdPerformBlock:(dispatch_block_t)block {
    NSAssert(self.hmdThread != nil,@"Thread is inconsistent.");
    [self performSelector:@selector(hmdPerformBlockOnClientThread:) onThread:self.hmdThread withObject:[block copy] waitUntilDone:NO modes:self.hmdModes];
}

- (void)hmdPerformBlockOnClientThread:(dispatch_block_t)block {
    NSAssert([NSThread currentThread] == self.hmdThread,@"Thread is inconsistent.");
    if (block) {
        block();
    }
}

@end
