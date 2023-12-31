//Copyright © 2021 Bytedance. All rights reserved.

#import <Foundation/Foundation.h>

@interface TSPKCustomAnchorReleaseDetectManager : NSObject

- (nullable instancetype)initWithPipelineType:(nonnull NSString *)pipelineType
                                    detectDelay:(NSTimeInterval)detectDelay
                                     detectTime:(NSInteger)detectTime;

- (void)markResourceStartWithCaseId:(nonnull NSString *)caseId description:(nullable NSString *)description;
- (void)markResourceStopWithCaseId:(nonnull NSString *)caseId description:(nullable NSString *)description;

@end
