//
//  LKCExceptionBase.m
//  LarkMonitor
//
//  Created by sniperj on 2019/12/31.
//

#import "LKCExceptionBase.h"

@interface LKCExceptionBase()

@property (atomic, assign, readwrite) BOOL isRunning;
@property (atomic, strong, readwrite) LKCustomExceptionConfig *config;

@end

@implementation LKCExceptionBase

- (void)end {
    self.isRunning = NO;
}

- (void)start {
    self.isRunning = YES;
}

- (void)updateConfig:(nonnull LKCustomExceptionConfig *)config {
    self.config = config;
}

@end
