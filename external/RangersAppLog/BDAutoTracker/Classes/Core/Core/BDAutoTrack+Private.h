//
//  BDAutoTrack+Private.h
//  Pods-BDAutoTracker_Example
//
//  Created by bob on 2019/6/4.
//

#import "BDAutoTrack.h"
#import "BDCommonDefine.h"
#import "BDAutoTrackDataCenter.h"
#import "BDAutoTrackProfileReporter.h"
#import "BDAutoTrackALinkActivityContinuation.h"
#import "BDAutoTrackEncryptionDelegate.h"
#import "BDroneMonitorAgent.h"
#import "RangersLogManager.h"
#import "BDAutoTrackEventGenerator.h"
#import "BDAutoTrackNetworkManager.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackABConfig.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackIdentifier.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrack (Private)

@property (class) id<BDAutoTrackEncryptionDelegate> bdEncryptor;

@property (nonatomic, readonly) RangersLogManager *logger;

@property (nonatomic, readonly) BDAutoTrackEventGenerator *eventGenerator;

@property (nonatomic, readonly) BDAutoTrackNetworkManager *networkManager;

@property (nonatomic, readonly) BDAutoTrackRemoteSettingService *remoteConfig;

@property (nonatomic, readonly) BDAutoTrackLocalConfigService *localConfig;

@property (nonatomic, readonly) BDAutoTrackABConfig *abTester;

@property (nonatomic, strong) BDAutoTrackIdentifier *identifier;


@property (nonatomic, readonly) BDroneMonitorAgent *monitorAgent;
@property (nonatomic, readonly) BDAutoTrackConfig *config;
@property (nonatomic, readonly) NSLock *syncLocker;
@property (nonatomic, strong) NSMutableSet *ignoredPageClasses;
@property (nonatomic, strong) NSMutableSet *ignoredClickViewClasses;

@property (nonatomic, strong) BDAutoTrackDataCenter *dataCenter;
@property (nonatomic, assign) BOOL showDebugLog;
@property (nonatomic, assign) BOOL gameModeEnable;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, readonly, strong) BDAutoTrackALinkActivityContinuation *alinkActivityContinuation API_UNAVAILABLE(macos);

@property (nonatomic, copy) BDAutoTrackEventPolicy (^eventHandler)(BDAutoTrackDataType type, NSString *event, NSMutableDictionary<NSString *, id> *properties);
@property (nonatomic, assign) NSUInteger eventHandlerTypes;

@property (nonatomic, copy) void(^eventBlock)(BDAutoTrackEventStatus eventStatus, BDAutoTrackEventAllType eventType, NSString *eventName, NSDictionary<NSString *, id> *properties);

/// Profile事件上报器. 实现在+Profile.m中
@property (nonatomic, strong) BDAutoTrackProfileReporter *profileReporter;

/*! @abstract Define custom encryption method (or custom encryption key)
 @discussion SDK不持有该对象。传入前须确保该对象在SDK使用期间不被释放，请勿传入临时对象。
 SDK will not hold the delegate. Please ensure the delegate's liveness during SDK's usage. Do not pass temporary object.
 */
@property (nonatomic, weak) id<BDAutoTrackEncryptionDelegate> encryptionDelegate;

+ (NSArray<BDAutoTrack *> *)allTrackers;

+ (void)trackUIEventWithData:(NSDictionary *)data;

+ (void)trackLaunchEventWithData:(NSMutableDictionary *)data;

+ (void)trackTerminateEventWithData:(NSMutableDictionary *)data;

+ (void)trackPlaySessionEventWithData:(NSDictionary *)data;

- (void)flushWithTimeInterval:(NSInteger)flushTimeInterval;

- (void)setAppTouchPoint:(NSString *)appTouchPoint;

- (BOOL)registerAvalible;

@end

NS_ASSUME_NONNULL_END
