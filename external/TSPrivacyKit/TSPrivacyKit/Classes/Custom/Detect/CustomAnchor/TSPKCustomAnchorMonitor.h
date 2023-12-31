//Copyright © 2021 Bytedance. All rights reserved.

#import <Foundation/Foundation.h>

@interface TSPKCustomAnchorMonitor : NSObject

+ (nonnull instancetype)shared;

- (void)markCameraStartWithCaseId:(nonnull NSString *)caseId description:(nullable NSString *)description;
- (void)markCameraStopWithCaseId:(nonnull NSString *)caseId description:(nullable NSString *)description;
- (void)markAudioStartWithCaseId:(nonnull NSString *)caseId description:(nullable NSString *)description;
- (void)markAudioStopWithCaseId:(nonnull NSString *)caseId description:(nullable NSString *)description;

@end
