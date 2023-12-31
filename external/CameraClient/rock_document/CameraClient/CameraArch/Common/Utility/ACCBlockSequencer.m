//
//  ACCBlockSequencer.m
//  CameraClient-Pods-Aweme
//
//  Created by yanjianbo on 2021/5/23.
//

#import "ACCBlockSequencer.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>

@interface ACCBlockSequencer()

@property (nonatomic, strong) NSMutableArray<ACCSeqBlock> *blocks;
@property (nonatomic,   copy) ACCSeqNextBlock completionBlock;
@property (nonatomic,   copy) ACCSeqErrorBlock errorBlock;
@end

@implementation ACCBlockSequencer

- (instancetype)init
{
    if (self = [super init]){
        _blocks = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

+ (instancetype)sequencerWithBlock:(ACCSeqBlock)block
{
    __auto_type seq = [ACCBlockSequencer new];
    [seq then:block];
    return seq;
}

- (instancetype)then:(ACCSeqBlock)block
{
    [_blocks btd_addObject:block];
    return self;
}

- (instancetype)completion:(ACCSeqNextBlock)block
{
    _completionBlock = block;
    return self;
}

- (instancetype)error:(ACCSeqErrorBlock)block
{
    _errorBlock = block;
    return self;
}

- (void)run
{
    [self runWithResult:nil];
}

- (void)runWithResult:(id)result
{
    /// fast throw error
    if ([result isKindOfClass:NSError.class] && self.errorBlock){
        self.errorBlock(result);
        [self stop];
        return;
    }

    __auto_type next = self.blocks.firstObject;
    if (!next){
        if (self.completionBlock){
            self.completionBlock(result);
        }
        [self stop];
        return;
    }


    [self.blocks btd_removeObjectAtIndex:0];
    
    next(result, ^(id res){
        if (!self) {
            return;
        }
        [self runWithResult:res];
    });

}

- (void)stop
{
    [self.blocks removeAllObjects];
    self.errorBlock = nil;
    self.completionBlock = nil;
}
@end
