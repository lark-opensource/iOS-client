//
//  TSPKBacktraceStore.h
//  Musically
//
//  Created by ByteDance on 2022/8/26.
//

#import <Foundation/Foundation.h>

@interface TSPKBacktraceStore : NSObject

+ (nonnull instancetype)shared;

- (void)saveCustomCallBacktraceWithPipelineType:(nonnull NSString *)pipelineType;

- (nullable NSArray *)findMatchedBacktraceWithPipelineType:(nonnull NSString *)pipelineType beforeTimestamp:(NSTimeInterval)timestamp;

@end
