//
//  TSPKDetectPipeline.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/28.
//

#import "TSPKDetectPipeline.h"

#import "TSPKEntryManager.h"
#import "TSPKConfigs.h"
#import "TSPrivacyKit/TSPrivacyKitConstants.h"
#import <TSPrivacyKit/NSObject+TSDeallocAssociate.h>
#import "TSPKEvent.h"
#import "TSPKEventManager.h"
#import <PNSServiceKit/PNSBacktraceProtocol.h>
#import <PNSServiceKit/PNSQueryIdProtocol.h>

@implementation TSPKDetectPipeline

+ (NSString *_Nullable)pipelineType
{
    NSAssert(false, @"should override by subclass");
    return nil;
}

+ (NSString *_Nullable)entryType
{
    return [self pipelineType];
}

+ (NSString *_Nullable)dataType
{
    NSAssert(false, @"should override by subclass");
    return @"";
}

+ (NSArray<NSString *> *)stubbedAPIs
{
    NSArray * apis = [[self stubbedClassAPIs] arrayByAddingObjectsFromArray:[self stubbedInstanceAPIs]];
    return apis;
}

+ (NSArray<NSString *> *)stubbedCAPIs
{
    return @[];
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return @[];
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[];
}

+ (NSString *)stubbedClass
{
    return nil;
}

+ (TSPKStoreType)storeType
{
    return TSPKStoreTypeNone;
}

+ (void)preload
{
    NSAssert(false, @"should override by subclass");
}

+ (BOOL)isEntryDefaultEnable
{
    return YES;
}

/// priority: pipeline type > data type
/// etc...
/// for example, if dataType enable, but pipeline disable, sdk will do nothing.
+ (BOOL)entryEnable
{
    NSNumber *isPipelineEnable = [[TSPKConfigs sharedConfig] isPipelineEnable:[self pipelineType]];
    NSNumber *isDataTypeEnable = [[TSPKConfigs sharedConfig] isDataTypeEnable:[self dataType]];
    
    if (isPipelineEnable == nil && isDataTypeEnable == nil) {
        return [self isEntryDefaultEnable];
    }
    
    if (isPipelineEnable != nil) {
        return [isPipelineEnable boolValue];
    }
    
    
    if (isDataTypeEnable != nil) {
        return [isDataTypeEnable boolValue];
    }
    
    return NO;
}

- (TSPKEntryUnitModel *_Nullable)entryModel
{
    TSPKEntryUnitModel *model = [TSPKEntryUnitModel new];
    model.entryIdentifier = [[self class] entryType];
    model.initAction = ^{
        [[self class] preload];
    };
    model.storeType = [[self class] storeType];
    model.pipelineType = [[self class] pipelineType];
    model.dataType = [[self class] dataType];
    model.apis = [[self class] stubbedAPIs];
    model.cApis = [[self class] stubbedCAPIs];
    model.clazzName = [[self class] stubbedClass];
    return model;
}

- (BOOL)deferPreload
{
    return NO;
}

#pragma mark - map

+ (NSInteger)downgradeApiStartId
{
    return 0;
}

+ (TSPKHandleResult *_Nullable)handleAPIAccess:(NSString *_Nullable)api {
    return [self handleAPIAccess:api className:nil params:nil];
}

+ (TSPKHandleResult *_Nullable)handleAPIAccess:(NSString *_Nullable)api className:(NSString *)className {
    return [self handleAPIAccess:api className:className params:nil];
}

+ (TSPKHandleResult *_Nullable)handleAPIAccess:(NSString *_Nullable)api
                                     className:(NSString *_Nullable)className
                                        params:(NSDictionary *_Nullable)params {
    return [self handleAPIAccess:api className:className params:params customHandleBlock:nil];
}

+ (TSPKHandleResult *_Nullable)handleAPIAccess:(NSString *_Nullable)api
                                     className:(NSString *)className
                                        params:(NSDictionary *_Nullable)params
                             customHandleBlock:(void (^ _Nullable)(TSPKAPIModel *_Nonnull apiModel))customHandleBlock {
    TSPKAPIModel *apiModel = [TSPKAPIModel new];
    apiModel.pipelineType = [self pipelineType];
    apiModel.apiMethod = api;
    apiModel.apiClass = className;
    apiModel.entryToken = className ? [NSString stringWithFormat:@"%@_%@", className, api] : api;
    apiModel.dataType = [self dataType];
    apiModel.apiClass = className;
    apiModel.params = params;
    if ([[TSPKConfigs sharedConfig] enableUploadStack]) {
        NSNumber *apiId = [PNS_GET_INSTANCE(PNSQueryIdProtocol) queryIdWithToken:apiModel.entryToken];
        if ([[TSPKConfigs sharedConfig] isEnableUploadStackWithApiId:apiId]) {
            apiModel.backtraces = [PNS_GET_INSTANCE(PNSBacktraceProtocol) getBacktracesWithSkippedDepth:0 needAllThreads:NO];
        }
    }
    if (customHandleBlock) {
        customHandleBlock(apiModel);        
    }
    
    return [[TSPKEntryManager sharedManager] didEnterEntry:[self entryType] withModel:apiModel];
}

+ (TSPKHandleResult *_Nullable)handleAPIAccess:(id _Nullable)arg1Inst AspectInfo:(TSPKAspectModel *_Nullable)aspectInfo
{
    TSPKAPIModel *apiModel = [TSPKAPIModel new];
    apiModel.pipelineType = aspectInfo.pipelineType;
    apiModel.apiId = aspectInfo.apiId;
    apiModel.apiMethod = aspectInfo.methodName;
    apiModel.apiClass = aspectInfo.klassName;
    apiModel.entryToken = aspectInfo.klassName ? [NSString stringWithFormat:@"%@_%@", aspectInfo.klassName, aspectInfo.methodName] : aspectInfo.methodName;
    apiModel.apiUsageType = (TSPKAPIUsageType)aspectInfo.apiUsageType;
    apiModel.dataType = aspectInfo.dataType;
    apiModel.instance = (NSObject *)arg1Inst;
    if([arg1Inst isKindOfClass:[NSObject class]]){
        apiModel.hashTag = [arg1Inst ts_hashTag];
    }
    
    TSPKHandleResult *ret = [[TSPKEntryManager sharedManager] didEnterEntry:aspectInfo.registerEntryType withModel:apiModel];
    return ret;
}

+ (void)forwardCallInfoWithMethod:(NSString *)method
                        className:(NSString *)className
                          apiType:(NSString *)apiType
                     apiUsageType:(TSPKAPIUsageType)apiUsageType
                          hashTag:(NSString *)hashTag
                    beforeOrAfter:(BOOL)beforeOrAfterCall
                      isCustomApi:(BOOL)isCustomApi {
    TSPKAPIModel *apiModel = [TSPKAPIModel new];
    apiModel.pipelineType = apiType;
    apiModel.apiMethod = method;
    apiModel.apiUsageType = apiUsageType;
    apiModel.hashTag = hashTag;
    apiModel.apiClass = apiModel.pipelineType;
    apiModel.entryToken = className ? [NSString stringWithFormat:@"%@_%@", className, method] : method;
    apiModel.beforeOrAfterCall = beforeOrAfterCall;
    apiModel.isCustomApi = isCustomApi;
    
    TSPKEvent *event = [TSPKEvent new];
    event.eventType = TSPKEventTypeReleaseAPICallInfo;
    
    TSPKEventData *eventData = [TSPKEventData new];
    eventData.apiModel = apiModel;
    event.eventData = eventData;
    
    [TSPKEventManager dispatchEvent:event];
}

+ (void)forwardCallInfoWithMethod:(NSString *)method
                        className:(NSString *)className
                     apiUsageType:(TSPKAPIUsageType)apiUsageType
                          hashTag:(NSString *)hashTag
                    beforeOrAfter:(BOOL)beforeOrAfterCall {
    [self forwardCallInfoWithMethod:method
                          className:className
                            apiType:[self pipelineType]
                       apiUsageType:apiUsageType
                            hashTag:hashTag
                      beforeOrAfter:beforeOrAfterCall
                        isCustomApi:NO];
}

+ (void)forwardCallInfoWithMethod:(nonnull NSString *)method
                          apiType:(nonnull NSString *)apiType
                     apiUsageType:(TSPKAPIUsageType)apiUsageType
                      isCustomApi:(BOOL)isCustomApi {
    [self forwardCallInfoWithMethod:method
                          className:nil
                            apiType:apiType
                       apiUsageType:apiUsageType
                            hashTag:@""
                      beforeOrAfter:YES
                        isCustomApi:isCustomApi];
}

+ (void)forwardBizCallInfoWithMethod:(NSString *)method
                             apiType:(NSString *)apiType
                            dataType:(NSString *)dataType
                        apiUsageType:(TSPKAPIUsageType)apiUsageType
                             bizLine:(NSString *)bizLine
{
    TSPKAPIModel *apiModel = [TSPKAPIModel new];
    apiModel.pipelineType = apiType;
    apiModel.apiMethod = method;
    apiModel.apiUsageType = apiUsageType;
    apiModel.bizLine = bizLine;
    apiModel.dataType = dataType;
    
    TSPKEvent *event = [TSPKEvent new];
    event.eventType = TSPKEventTypeReleaseAPIBizCallInfo;
    
    TSPKEventData *eventData = [TSPKEventData new];
    eventData.apiModel = apiModel;
    event.eventData = eventData;
    
    [TSPKEventManager dispatchEvent:event];
}

@end
