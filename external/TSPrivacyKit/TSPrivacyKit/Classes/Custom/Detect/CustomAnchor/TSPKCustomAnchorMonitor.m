//Copyright © 2021 Bytedance. All rights reserved.

#import "TSPKCustomAnchorMonitor.h"
#import "TSPKEvent.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKCustomAnchorReleaseDetectManager.h"
#import "TSPKConfigs.h"
#import "TSPKLogger.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

static const NSTimeInterval defaultDetectDelay = 2;
static const NSInteger defaultDetectTime = 1;

@interface TSPKCustomAnchorMonitor ()

@property (nonatomic, strong) TSPKCustomAnchorReleaseDetectManager *cameraManager;
@property (nonatomic, strong) TSPKCustomAnchorReleaseDetectManager *audioOutputManager;
@property (nonatomic, strong) TSPKCustomAnchorReleaseDetectManager *audioAUGraphManager;

@end

@implementation TSPKCustomAnchorMonitor

+ (instancetype)shared
{
    static TSPKCustomAnchorMonitor *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TSPKCustomAnchorMonitor alloc] init];
    });
    return manager;
}

#pragma mark - public method

- (void)markCameraStartWithCaseId:(nonnull NSString *)caseId description:(NSString *)description{
    [self logBizCalledMethod:@"markCameraStart" caseId:caseId description:description];
    if ([self isEnableWithCaseId:caseId]) {
        [self.cameraManager markResourceStartWithCaseId:caseId description:description];
    } else {
        [self logFeatureDisabledWithCaseId:caseId];
    }
}

- (void)markCameraStopWithCaseId:(nonnull NSString *)caseId description:(NSString *)description {
    [self logBizCalledMethod:@"markCameraStop" caseId:caseId description:description];
    if ([self isEnableWithCaseId:caseId]) {
        [self.cameraManager markResourceStopWithCaseId:caseId description:description];
    } else {
        [self logFeatureDisabledWithCaseId:caseId];
    }
}

- (void)markAudioStartWithCaseId:(nonnull NSString *)caseId description:(NSString *)description {
    [self logBizCalledMethod:@"markAudioStart" caseId:caseId description:description];
    if ([self isEnableWithCaseId:caseId]) {
        [self.audioOutputManager markResourceStartWithCaseId:caseId description:description];
        [self.audioAUGraphManager markResourceStartWithCaseId:caseId description:description];
    } else {
        [self logFeatureDisabledWithCaseId:caseId];
    }
}

- (void)markAudioStopWithCaseId:(nonnull NSString *)caseId description:(NSString *)description {
    [self logBizCalledMethod:@"markAudioStop" caseId:caseId description:description];
    if ([self isEnableWithCaseId:caseId]) {
        [self.audioOutputManager markResourceStopWithCaseId:caseId description:description];
        [self.audioAUGraphManager markResourceStopWithCaseId:caseId description:description];
    } else {
        [self logFeatureDisabledWithCaseId:caseId];
    }
}

#pragma mark - log

- (void)logBizCalledMethod:(NSString *)method caseId:(NSString *)caseId description:(NSString *)description {
    [TSPKLogger logWithTag:TSPKLogCustomAnchorCheckTag message:[NSString stringWithFormat:@"Biz called %@ caseId:%@ description:%@", method, caseId, description]];
}

- (void)logFeatureDisabledWithCaseId:(NSString *)caseId {
    [TSPKLogger logWithTag:TSPKLogCustomAnchorCheckTag message:[NSString stringWithFormat:@"Feature Disabled caseId:%@", caseId]];
}

#pragma mark - others

- (BOOL)isEnableWithCaseId:(NSString *)caseId {
    NSDictionary *configs = [[TSPKConfigs sharedConfig] customAnchorConfigs];
    
    if (!configs) {
        return YES;
    }
    
    NSNumber *enableWrapper = [configs btd_numberValueForKey:@"Enabled"];
    if (enableWrapper && enableWrapper.boolValue == NO) {
        return NO;
    }

    NSArray *disableCaseIds = (NSArray *)[configs objectForKey:@"DisabledCaseIds"];
    NSSet *set = [NSSet setWithArray:disableCaseIds];
    if ([set containsObject:caseId]) {
        return NO;
    }
    
    return YES;
}

- (NSTimeInterval)detectDelay {
    NSDictionary *customAnchorConfigs = [[TSPKConfigs sharedConfig] customAnchorConfigs];
    
    NSString *key = @"DetectDelay";
    
    if (!customAnchorConfigs || !customAnchorConfigs[key]) {
        return defaultDetectDelay;
    }
    
    return [customAnchorConfigs[key] doubleValue];
}

- (NSInteger)detectTime {
    NSDictionary *customAnchorConfigs = [[TSPKConfigs sharedConfig] customAnchorConfigs];
    
    NSString *key = @"DetectTime";
    
    if (!customAnchorConfigs || !customAnchorConfigs[key]) {
        return defaultDetectTime;
    }
    
    return [customAnchorConfigs[key] integerValue];
}

#pragma mark - Lazy init

- (TSPKCustomAnchorReleaseDetectManager *)cameraManager {
    if (!_cameraManager) {
        _cameraManager = [[TSPKCustomAnchorReleaseDetectManager alloc] initWithPipelineType:TSPKPipelineVideoOfAVCaptureSession detectDelay:[self detectDelay] detectTime:[self detectTime]];
    }
    
    return _cameraManager;
}

- (TSPKCustomAnchorReleaseDetectManager *)audioOutputManager {
    if (!_audioOutputManager) {
        _audioOutputManager = [[TSPKCustomAnchorReleaseDetectManager alloc] initWithPipelineType:TSPKPipelineAudioOfAudioOutput detectDelay:[self detectDelay] detectTime:[self detectTime]];
    }
    
    return _audioOutputManager;
}

- (TSPKCustomAnchorReleaseDetectManager *)audioAUGraphManager {
    if (!_audioAUGraphManager) {
        _audioAUGraphManager = [[TSPKCustomAnchorReleaseDetectManager alloc] initWithPipelineType:TSPKPipelineAudioOfAUGraph detectDelay:[self detectDelay] detectTime:[self detectTime]];
    }
    
    return _audioAUGraphManager;
}

@end
