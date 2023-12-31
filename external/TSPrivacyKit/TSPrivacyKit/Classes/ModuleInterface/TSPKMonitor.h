//
//  TSPKMonitor.h
//  TSPrivacyKit-Pods-Aweme
//
//  Created by bytedance on 2021/8/24.
//

#import <Foundation/Foundation.h>
#import "TSPKSubscriber.h"
#import "TSPKBaseEvent.h"
#import "TSPKReporter.h"
#import <TSPrivacyKit/TSPrivacyKitConstants.h>

typedef NS_ENUM(NSUInteger, TSPKLoadTaskStatus) {
    TSPKLoadTaskStatusUnInit,
    TSPKLoadTaskStatusInProgress,
    TSPKLoadTaskStatusDone
};

extern NSString *_Nonnull const TSPKPrivacyMonitorKey;

@class TSPKDetectPipeline;
@class TSPKMonitorBuilder;

/*
 SDK Doc: https://bytedance.feishu.cn/wiki/wikcnY0svR6VhhA5yAuZwsc3Qze#
*/
@interface TSPKMonitor : NSObject

@property (nonatomic) TSPKLoadTaskStatus loadTaskStatus;

#pragma mark - set reporter
+ (void)registerCustomCanReportBuilder:(TSPKCustomCanReportBuilder _Nullable)builder;

#pragma mark - set config
/**
 setting doc：https://bytedance.feishu.cn/wiki/wikcnY0svR6VhhA5yAuZwsc3Qze#cV1gQs
 */

/// Used to set config about monitor - it should be acquired from server
+ (void)setMonitorConfig:(nullable NSDictionary *)config;

#pragma mark - pipeline

/// Used to hook API
/// eg: TSPKWritePasteboardPipeline includes all write pasteboard API Hook
// will remove, when sdk execution was based on rule engine
+ (void)registerDetectPipeline:(TSPKDetectPipeline *_Nonnull)detectPipeline;
+ (NSArray <NSString *> *_Nonnull)enabledPipelineTypes;

#pragma mark - subscriber
/**
 Please refer to https://bytedance.feishu.cn/wiki/wikcnY0svR6VhhA5yAuZwsc3Qze#9TdK0C
 */

+ (void)registerSubsciber:(nullable id<TSPKSubscriber>)subscriber onEventType:(TSPKEventType)eventType;
+ (void)unregisterSubsciber:(nullable id<TSPKSubscriber>)subscriber onEventType:(TSPKEventType)eventType;

#pragma mark - Context

/// cancel detect task in some context
+ (void)setContextBlock:(TSPKFetchDetectContextBlock _Nonnull)contextBlock forApiType:(NSString *_Nonnull)apiType;

#pragma mark - Biz start&stop using camera&audio
/**
 Please refer to https://bytedance.feishu.cn/wiki/wikcnY0svR6VhhA5yAuZwsc3Qze#KzfMtE
 */
/// Must call before start camera
+ (void)markCameraStartWithCaseId:(nonnull NSString *)caseId description:(nullable NSString *)description;
/// Must call after stop camera
+ (void)markCameraStopWithCaseId:(nonnull NSString *)caseId description:(nullable NSString *)description;
/// Must call before start audio
+ (void)markAudioStartWithCaseId:(nonnull NSString *)caseId description:(nullable NSString *)description;
/// Must call after stop audio
+ (void)markAudioStopWithCaseId:(nonnull NSString *)caseId description:(nullable NSString *)description;

#pragma mark - Backtraces

+ (void)saveCustomCallBacktraceWithPipelineType:(nonnull NSString *)pipelineType;

#pragma mark - start

/// Init of Monitor SDK
/// should call it after prepare work is done
+ (void)start;

/// Init of Monitor SDK
/// should call it after prepare work is done.
/// @param builder customize monitor's setup.
+ (void)startWithPolicyDecisionBuilder:(nullable TSPKMonitorBuilder *)builder;

#pragma mark - signal

/// add signal to manager, in order to help attribute issue
/// - Parameters:
///   - signalType: refer to TSPKSignalType
///   - permissionType: equal to dataType
///   - content: info releated to signal
+ (void)addSignalWithType:(NSUInteger)signalType
            permissionType:(nonnull NSString *)permissionType
                  content:(nonnull NSString *)content;

/// add signal to manager, in order to help attribute issue
/// - Parameters:
///   - signalType: refer to TSPKSignalType
///   - permissionType: equal to dataType
///   - content: info releated to signal
///   - extraInfo: info releated to signal except content
+ (void)addSignalWithType:(NSUInteger)signalType
           permissionType:(nonnull NSString*)permissionType
                  content:(nonnull NSString*)content
                extraInfo:(nullable NSDictionary*)extraInfo;

/// get signal flow with permissionType
/// - Parameter permissionType: equal to dataType
+ (nullable NSArray *)signalFlowWithPermissionType:(nonnull NSString *)permissionType;

/// get pair signal flow, signal_start_time, signal_end_time without instance address
/// - Parameter permissionType: equal to dataType
+ (nullable NSDictionary *)pairSignalInfoWithPermissionType:(nonnull NSString *)permissionType
                                             needFormatTime:(BOOL)needFormatTime;

@end
