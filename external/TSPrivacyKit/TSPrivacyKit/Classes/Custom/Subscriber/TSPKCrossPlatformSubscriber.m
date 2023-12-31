//Copyright © 2021 Bytedance. All rights reserved.

#import "TSPKCrossPlatformSubscriber.h"
#import <TSPrivacyKit/TSPKEvent.h>
#import "TSPKHostEnvProtocol.h"
#import "TSPKUtils.h"
#import "TSPKReporter.h"
#import "TSPKUploadEvent.h"
#import "TSPKLogger.h"
#import "TSPrivacyKitConstants.h"
#import <PNSServiceKit/PNSServiceCenter.h>
#import <PNSServiceKit/PNSBacktraceProtocol.h>

static NSString * const TSPKReportCallMethodPrefix = @"PrivacyMethod";
static NSString * const TSPKCrossPlatform = @"CrossPlatform";
static NSString * const TSPKCrossPlatformCallingTypeKey = @"crpCallingType";
static NSString * const TSPKCrossPlatformCallingInfoKey = @"crpCallingInfo";

@interface TSPKCrossPlatformModel : NSObject

@property (nonatomic, assign) NSTimeInterval timeRange;
@property (nonatomic, copy) NSArray *apiTypes;

@end

@implementation TSPKCrossPlatformModel

@end

@interface TSPKCrossPlatformSubscriber ()

@property (nonatomic, strong) TSPKCrossPlatformModel *model;

@end

@implementation TSPKCrossPlatformSubscriber

#pragma mark - TSPKSubscriber

- (TSPKHandleResult *_Nullable)hanleEvent:(TSPKEvent *)event
{
    NSArray *validInfos = [self extractValidCrossPlatformInfos:event];
    
    if (validInfos.count == 0) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"cross platform hanleEvent validInfos is nil"];

        return nil;
    }
    
    NSString *crpCallingEventsStr = [self callingInfoStringWithArray:validInfos];
    
    TSPKUploadEvent *uploadEvent = [TSPKUploadEvent new];
    
    // backtraces
    if (event.eventData.apiModel.backtraces.count == 0) {
        uploadEvent.backtraces = [PNS_GET_INSTANCE(PNSBacktraceProtocol) getBacktracesWithSkippedDepth:0 needAllThreads:NO];
    }
    
    uploadEvent.eventName = [self eventNameWithEvent:event.eventData];
    
    // filterParams
    uploadEvent.filterParams = [self filterParamsWithEvent:event.eventData].mutableCopy;
    
    // params
    uploadEvent.params = [self paramsWithEvent:event.eventData crpCallingEventsStr:crpCallingEventsStr].mutableCopy;
    
    [TSPKUtils exectuteOnMainThread:^{
        // add url if exists
        NSString *topWebVCUrl = [PNS_GET_INSTANCE(TSPKHostEnvProtocol) urlIfTopIsWebViewController];
        if(topWebVCUrl){
            uploadEvent.params[@"url"] = topWebVCUrl;
        }
        
        // Report data to Slardar, needn't to write extra alog
        [[TSPKReporter sharedReporter] report:uploadEvent];
    }];

    return nil;
}

- (NSString *)uniqueId
{
    return NSStringFromSelector(_cmd);
}

- (BOOL)canHandelEvent:(TSPKEvent *)event
{
    [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"cross platform enter check canHandleEvent event %@", event.eventData.apiModel.pipelineType]];
    
    if (event.eventType != TSPKEventTypeAccessEntryResult) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"cross platform check access entry return"];
        return NO;
    }
    
    if (![self isEnable]) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"cross platform settings model nil"];
        return NO;
    }
    
    NSString *currentAPIType = event.eventData.apiModel.pipelineType;
    
    if (![self.model.apiTypes containsObject:currentAPIType]) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"cross platform not interested api"];
        return NO;
    }
    
    if (event.eventData.apiModel.isNonsenstive) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"cross platform api not senstive"];

        return NO;
    }
    
    // check if upload is blocked
    id<TSPKHostEnvProtocol> hostEnv = PNS_GET_INSTANCE(TSPKHostEnvProtocol);

    if (![hostEnv respondsToSelector:@selector(isEventBlocked:)]) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"cross platform hostEnv not respondTO isEventBlocked"];

        return NO;
    }
    
    NSString *eventName = [self eventNameWithEvent:event.eventData];

    if ([hostEnv isEventBlocked:eventName]) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"cross platform event blocked"];
        return NO;
    }
    
    return YES;
}

#pragma mark - private method

- (BOOL)isEnable
{
    return self.model != nil;
}

- (NSString *)callingInfoStringWithArray:(NSArray *)validInfos
{
    __block NSString *crpCallingEventsStr = @"";
    
    [validInfos enumerateObjectsUsingBlock:^(NSDictionary *validInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        crpCallingEventsStr = [NSString stringWithFormat:@"%@%@", crpCallingEventsStr, @(idx + 1)];
        
        for (NSString *key in validInfo.allKeys) {
            NSString *newKey = nil;
            if ([key isEqualToString:@"method"]) {
                newKey = @"crpMethodName";
            }
            
            if ([key isEqualToString:@"url"]) {
                newKey = @"crpUrlLink";
            }
            
            if (newKey == nil) {
                continue;
            }
            
            crpCallingEventsStr = [NSString stringWithFormat:@"%@\n%@\n%@", crpCallingEventsStr, newKey, validInfo[key]];
        }
        
        if (idx < validInfos.count - 1) {
            crpCallingEventsStr = [NSString stringWithFormat:@"%@\n", crpCallingEventsStr];
        }
    }];
    
    return crpCallingEventsStr;
}

- (NSArray *)extractValidCrossPlatformInfos:(TSPKEvent *)event
{
    id<TSPKHostEnvProtocol> hostEnv = PNS_GET_INSTANCE(TSPKHostEnvProtocol);
    
    if (![hostEnv respondsToSelector:@selector(crossPlatformCallingInfos)]) {
        return nil;
    }
    
    NSArray *callingInfos = [hostEnv crossPlatformCallingInfos];
    
    if (callingInfos.count == 0) {
        return nil;
    }
    
    NSTimeInterval baseline =  event.eventData.timestamp - self.model.timeRange;
    
    NSInteger index = 0;
    for (index = callingInfos.count - 1; index >= 0; index--) {
        NSDictionary *info = callingInfos[index];
        NSTimeInterval infoTimestamp = [info[@"timestamp"] doubleValue];
        if (infoTimestamp < baseline) {
            break;
        }
    }
    
    NSMutableArray *validInfos = callingInfos.mutableCopy;
    
    if (index > 0) {
        [validInfos removeObjectsInRange:NSMakeRange(0, index + 1)];
    }
    
    if (validInfos.count == 0) {
        return nil;
    }
    
    return validInfos.copy;
}

- (NSString *)eventNameWithEvent:(TSPKEventData *)eventData
{
    return [NSString stringWithFormat:@"%@-%@", TSPKReportCallMethodPrefix, TSPKCrossPlatform];
}

- (NSDictionary *)filterParamsWithEvent:(TSPKEventData *)eventData
{
    NSMutableDictionary *filterParams = [NSMutableDictionary dictionaryWithDictionary:[eventData formatFilterDictionary]];
    filterParams[TSPKCrossPlatformCallingTypeKey] = TSPKCrossPlatformCallingType;
    filterParams[TSPKMonitorSceneKey] = TSPKCrossPlatformCallingType;
    
    return filterParams.copy;
}

- (NSDictionary *)paramsWithEvent:(TSPKEventData *)eventData crpCallingEventsStr:(NSString *)crpCallingEventsStr
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[eventData formatDictionary]];
    params[TSPKCrossPlatformCallingTypeKey] = TSPKCrossPlatformCallingType;
    params[TSPKCrossPlatformCallingInfoKey] = crpCallingEventsStr;
    params[TSPKMonitorSceneKey] = TSPKCrossPlatformCallingType;
    
    return params.copy;
}

#pragma mark - public method

- (void)setConfigs:(NSDictionary *)configs
{
    if (![configs isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    TSPKCrossPlatformModel *model = [TSPKCrossPlatformModel new];
    
    if (configs[@"APITimeRange"] && configs[@"APITypes"]) {
        model.timeRange = [configs[@"APITimeRange"] doubleValue];
        model.apiTypes = configs[@"APITypes"];
        self.model = model;
    }
}

@end
