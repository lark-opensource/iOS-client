//
//  ACCAsyncBlockOperation.m
//  CameraClient
//
//  Created by kuangjeon on 2020/2/6.
//

#import "ACCAsyncBlockOperation.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCAsyncBlockOperation ()
@property (nonatomic, copy) void(^block)(ACCAsyncBlockOperation *);
@end

@implementation ACCAsyncBlockOperation

- (instancetype)initWithBlock:(void(^)(ACCAsyncBlockOperation *asyncOp))block {
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

- (void)start {
    [super start];
    ACCBLOCK_INVOKE(self.block, self);
}

- (void)finish {
    [super finish];
    if (self.finished && self.finishBlock) {
        self.finishBlock(self);
    }
}


#pragma mark - Cancel

- (void)cancel {
    [super cancel];
    [self finish];
}

@end
