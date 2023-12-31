//
//  ACCBlockSequencer.m
//  CameraClient-Pods-Aweme
//
//  Created by yanjianbo on 2021/5/23.
//

#import <Foundation/Foundation.h>

typedef void(^ACCSeqNextBlock)(id res);
typedef void(^ACCSeqErrorBlock)(NSError *error);
typedef void(^ACCSeqBlock)(id res, ACCSeqNextBlock next);

@interface ACCBlockSequencer : NSObject

+ (instancetype)sequencerWithBlock:(ACCSeqBlock)block;
- (instancetype)then:(ACCSeqBlock)block;

/// for semantic, used for last normal step, only call once
- (instancetype)completion:(ACCSeqNextBlock)block;

/// called when next block pass a NSError object
- (instancetype)error:(ACCSeqErrorBlock)block;

- (void)run;
- (void)stop;
@end
