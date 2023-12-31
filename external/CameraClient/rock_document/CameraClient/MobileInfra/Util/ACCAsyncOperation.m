//
//  ACCAsyncOperation.m
//  CameraClient
//
//  Created by kuangjeon on 2020/2/6.
//

#import "ACCAsyncOperation.h"

@implementation ACCAsyncOperation

@synthesize ready = _ready;
@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)init {
    self = [super init];
    if (self) {
        _ready = YES;
        self.qualityOfService = NSQualityOfServiceDefault;
    }
    return self;
}


#pragma mark - Getter & Setter

- (BOOL)isAsynchronous {
    return YES;
}

- (void)setReady:(BOOL)ready {
    if (_ready != ready) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isReady))];
        _ready = ready;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isReady))];
    }
}

- (BOOL)isReady {
    return _ready;
}

- (void)setExecuting:(BOOL)executing {
    if (_executing != executing) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
        _executing = executing;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    }
}

- (BOOL)isExecuting {
    return _executing;
}

- (void)setFinished:(BOOL)finished {
    if (_finished != finished) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
        _finished = finished;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    }
}

- (BOOL)isFinished {
    return _finished;
}


#pragma mark - Control

- (void)start {
    if (!self.isExecuting) {
        self.ready = NO;
        self.executing = YES;
        self.finished = NO;
    }
}

- (void)finish {
    if (self.executing) {
        self.executing = NO;
        self.finished = YES;
    }
}

@end
