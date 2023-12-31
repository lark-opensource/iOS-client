//
//  HMDUserException.m
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/4/1.
//

#import "HMDUserExceptionTracker.h"
#import "HMDAppleBacktracesLog.h"
#import "HMDDebugRealConfig.h"
#import "HMDDiskUsage.h"
#import "HMDExceptionReporter.h"
#import "HMDMacro.h"
#import "HMDMemoryUsage.h"
#import "HMDNetworkHelper.h"
#import "HMDSessionTracker.h"
#import "HMDStoreCondition.h"
#import "HMDStoreIMP.h"
#import "HMDThreadBacktrace+Private.h"
#import "HMDThreadSafeDictionary.h"
#import "HMDUserExceptionConfig.h"
#import "HMDUserExceptionRecord.h"
#import "Heimdallr+Private.h"
#import "Heimdallr.h"
#import "HMDExceptionReporter.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "hmd_thread_backtrace.h"
#import "HMDGCD.h"
#import "HMDInjectedInfo+NetworkSchedule.h"
#if RANGERSAPM
#import "RangersInjectedInfo_Private.h"
#import "pthread_extended.h"
#import "HMDUserExceptionConfig_RangersAPM.h"
#import "HMDUserExceptionParameter_RangersAPM.h"
#import "HMDUserExceptionTracker_RangersAPM.h"
#import "RangersAPMUserExceptionErrorDefinition.h"
#else
#import "HMDUserExceptionErrorDefinition.h"
#endif

#import "HMDHermasHelper.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// Utility
#import "HMDMacroManager.h"
// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDServerStateService.h"
#import "HMDURLSettings.h"

#define DEFAULT_USER_EXCEPTION_UPLOAD_LIMIT 5
#define DEFAULT_USER_EXCEPTION_MAX_THREADS_COUNT 500

#define USER_EXCEPTION_CALLBACK_ERROR(callback, logtype, reason_str) \
if (callback) {\
    NSError *error = [NSError errorWithDomain:HMDUserExceptionErrorDomain\
                                         code:logtype\
                                     userInfo:@{@"reason" : reason_str}];\
    callback(error);\
}\

NSString *const     kEnableUserExceptionTracker = @"enable_user_exception_monitor";
#if RANGERSAPM
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
#endif

@interface HMDUserExceptionTracker () <HMDExceptionReporterDataProvider> {
    NSArray<HMDStoreCondition *> *_andConditions;
    HMDThreadSafeDictionary *     _timestampMap;
    dispatch_queue_t              _userExceptionQueue;
}

@property(nonatomic, assign) NSUInteger maxUploadCount;
@property(atomic, strong) NSDictionary *typeBlockList;
@property(nonatomic, strong) NSArray<NSString *> *typeAllowList;
@property (nonatomic, assign) BOOL addNetScheduleNoti;
#if RANGERSAPM
@property(nonatomic, strong) NSArray *appIDs;
#endif

@property(nonatomic, strong) HMInstance *instance;
@end

@implementation HMDUserExceptionTracker

SHAREDTRACKER(HMDUserExceptionTracker);

- (instancetype)init {
    if (self = [super init]) {
        _timestampMap       = [[HMDThreadSafeDictionary alloc] init];
        _userExceptionQueue = dispatch_queue_create("com.heimdallr.userexception", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [[HMEngine sharedEngine] instanceWithModuleId:kModuleUserExceptionName aid:[HMDInjectedInfo defaultInfo].appID];
    }
    return _instance;
}


- (void)dealloc {
    @try {
        if (self.addNetScheduleNoti) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kHMDNetworkScheduleNotification object:nil];
        }
    } @catch (NSException *exception) {

    }
}

#pragma mark - <HeimdallrModule>

- (void)start{
    [super start];
    [HMDDebugLogger printLog:@"UserException-Monitor start successfully!"];
}

- (void)updateConfig:(HMDUserExceptionConfig *)config {
#if RANGERSAPM
    if (!self.appIDs || [config.currentAppID isEqualToString:[HMDInjectedInfo defaultInfo].appID]) {
#endif
        [super updateConfig:config];
        self.maxUploadCount = config.maxUploadCount;
        self.typeBlockList = config.typeBlockList;
        self.typeAllowList = config.typeAllowList;
#if RANGERSAPM
        self.appIDs = [[HMDConfigManager sharedInstance] userExceptionAppIDs];
    }
#endif
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDUserExceptionRecord class];
}

- (BOOL)exceptionDataSource {
    return YES;
}

- (BOOL)needSyncStart {
    return NO;
}

- (NSError *)checkIfAvailableForType:(NSString *)type {
    return [self checkIfAvailableForType:type appID:nil];
}

- (NSError *)checkIfAvailableForType:(NSString *)type appID:(NSString *)appID {
    if (!self.isRunning) {
        return [NSError errorWithDomain:HMDUserExceptionErrorDomain
                                   code:HMDStaticUserExceptionFailTypeNotWorking
                               userInfo:@{@"reason" : @"HMDUserExceptionTracker is not working"}];
    }

    if (!type) {
        NSAssert(NO, @"The type of customized exception cannot be nil!");
        return [NSError errorWithDomain:HMDUserExceptionErrorDomain
                                   code:HMDStaticUserExceptionFailTypeMissingType
                               userInfo:@{@"reason" : @"ExceptionType is required"}];
    }
    
#if !RANGERSAPM
    if (self.typeAllowList && [self.typeAllowList isKindOfClass:NSArray.class] && [self.typeAllowList containsObject:type])
    {
        // 白名单上的自定义异常，不限流
        return nil;
    }

    if ([_timestampMap objectForKey:type]) {
        NSTimeInterval preTimestamp     = (NSTimeInterval)((NSNumber *)_timestampMap[type]).doubleValue;
        NSTimeInterval currentTimestamp = CACurrentMediaTime();
        NSTimeInterval interval         = currentTimestamp - preTimestamp;
        if ((interval) < 60) {
            return [NSError
                errorWithDomain:HMDUserExceptionErrorDomain
                           code:HMDStaticUserExceptionFailTypeExceedsLimiting
                       userInfo:@{
                           @"reason" : [NSString
                               stringWithFormat:@"ExceptionType %@ exceeds the limit of no more one record in one minute", type]
                       }];
        }
    }
    
    NSDictionary* blockList = self.typeBlockList;
    if (blockList && [blockList isKindOfClass:[NSDictionary class]] && blockList.count > 0) {
        BOOL isBlock = [blockList hmd_boolForKey:type];
        // 命中表示 blockList 过滤
        if (isBlock) {
            return [NSError errorWithDomain:HMDUserExceptionErrorDomain
                                                     code:HMDStaticUserExceptionFailTypeBlockList
                                                 userInfo:@{@"reason" : @"exceptionType is in block list"}];
        }
    }
#else
    if (![self.appIDs containsObject:appID]) {
        return [NSError errorWithDomain:HMDUserExceptionErrorDomain
                                   code:RangersAPMUserExceptionFailTypeNotWorking
                               userInfo:@{@"reason" : @"exception tracker module is not working"}];
    }
    
    pthread_mutex_lock(&mutex);
    NSDictionary *appDict = [_timestampMap objectForKey:appID];
    if (appDict) {
        if ([appDict objectForKey:type]) {
            NSTimeInterval preTimestamp     = (NSTimeInterval)((NSNumber *)appDict[type]).doubleValue;
            NSTimeInterval currentTimestamp = CACurrentMediaTime();
            NSTimeInterval interval         = currentTimestamp - preTimestamp;
            if ((interval) > 60) {
                _timestampMap[appID][type] = @(currentTimestamp);
            } else {
                pthread_mutex_unlock(&mutex);
                return [NSError
                        errorWithDomain:HMDUserExceptionErrorDomain
                        code:RangersAPMUserExceptionFailTypeExceedsLimiting
                        userInfo:@{
                            @"reason" : [NSString
                                         stringWithFormat:@"type %@ exceeds the limit of no more one record in one minute", type]
                        }];
                ;
            }
        } else {
            _timestampMap[appID][type] = @(CACurrentMediaTime());
        }
    } else {
        NSMutableDictionary *types = [[NSMutableDictionary alloc] init];
        types[type] = @(CACurrentMediaTime());
        _timestampMap[appID] = types;
    }
    pthread_mutex_unlock(&mutex);
#endif

    return nil;
}

- (void)trackThreadLogWithParameter:(HMDUserExceptionParameter *)parameter
                               callback:(HMDUserExceptionCallback _Nullable)callback {
#if RANGERSAPM
    NSString *appID = parameter.appID;
#else
    NSString *appID = nil;
#endif
    if (![self checkException:parameter.exceptionType appID:appID callback:callback]) {
        return;
    }
    parameter.logType = HMDLogUserException;
    if (!parameter.needAllThreads && !parameter.isGetMainThread && parameter.keyThread == 0){
        USER_EXCEPTION_CALLBACK_ERROR(callback, HMDStaticUserExceptionFailTypeParamsMissing, @"thread info missing")
        return;
    }
    if (!HMD_IS_DEBUG) {
        parameter.needDebugSymbol = NO;
    }
    [HMDAppleBacktracesLog getAsyncThreadLogByParameter:parameter callback:^(BOOL success, NSString * _Nonnull log, int async_times) {
        if (log) {
            NSString *appLog = [NSString stringWithFormat:@"UserExceptionType:%@\n%@", parameter.exceptionType, log];
            hmd_safe_dispatch_async(self->_userExceptionQueue, ^{
              [self didCollectOneExceptionRecordIfAvailable:parameter.exceptionType
                                                        log:appLog
                                                      title:nil
                                                   subTitle:nil
                                                     symbol:YES
                                                addressList:nil
                                                    filters:parameter.filters
                                               customParams:parameter.customParams
                                              viewHierarchy:nil
                                                 asyncTimes:async_times
                                             aggregationKey:parameter.aggregationKey
                                                      appID:appID
                                                   callback:callback];
            });
        } else {
            USER_EXCEPTION_CALLBACK_ERROR(callback, HMDStaticUserExceptionFailTypeLog, @"get stack log failed")
        }
    }];
    GCC_FORCE_NO_OPTIMIZATION
}

- (NSArray<HMDThreadBacktrace *> *)getBacktracesWithParameter:(HMDUserExceptionParameter *)parameter {
#if !RANGERSAPM
    parameter.logType = HMDLogUserException;
    NSArray<HMDThreadBacktrace *> *backtraces = [NSArray new];
    if (!parameter.needAllThreads && !parameter.isGetMainThread && parameter.keyThread == 0){
        return backtraces;
    }
    if (!HMD_IS_DEBUG) {
        parameter.needDebugSymbol = NO;
    }
    if (parameter.needAllThreads) {
        backtraces = [HMDThreadBacktrace backtraceOfAllThreadsWithParameter:parameter];
        return backtraces;
    } else {
        HMDThreadBacktrace *backtrace = [HMDThreadBacktrace backtraceOfThreadWithParameter:parameter];
        if (backtrace != nil) {
            backtraces = @[backtrace];
        }
    }
    return backtraces;
#else
    return nil;
#endif
}

- (void)trackThreadLogWithBacktraceParameter:(HMDUserExceptionParameter *)parameter
                                    callback:(HMDUserExceptionCallback _Nullable)callback {
#if !RANGERSAPM
    if (!(parameter.backtraces && [parameter.backtraces isKindOfClass:[NSArray class]] && parameter.backtraces.count > 0)) {
        USER_EXCEPTION_CALLBACK_ERROR(callback, HMDStaticUserExceptionFailTypeLog, @"get stack log failed")
        return;
    }
    
    __block BOOL isValidBTs = YES;
    [parameter.backtraces enumerateObjectsUsingBlock:^(HMDThreadBacktrace * _Nonnull bt, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![bt isKindOfClass:[HMDThreadBacktrace class]]) {
            NSAssert(NO, @"The element of parameter backtraces must be HMDThreadBacktrace!");
            *stop = YES;
            isValidBTs = NO;
        }
    }];
    if (!isValidBTs) {
        USER_EXCEPTION_CALLBACK_ERROR(callback, HMDStaticUserExceptionFailTypeLog, @"get stack log failed")
        return;
    }
    
    if (![self checkException:parameter.exceptionType callback:callback]) {
        return;
    }
    parameter.logType = HMDLogUserException;
    hmd_safe_dispatch_async(_userExceptionQueue, ^{
        __block int async_times = 0;
        [parameter.backtraces enumerateObjectsUsingBlock:^(HMDThreadBacktrace * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.crashed) {
                async_times = obj.async_times;
                *stop = true;
            }
        }];
        NSString *log = [HMDAppleBacktracesLog logWithBacktraces:parameter.backtraces
                                                            type:HMDLogUserException
                                                       exception:nil
                                                          reason:nil];
        if (log) {
            NSString * appleLog = [NSString stringWithFormat:@"UserExceptionType:%@\n%@", parameter.exceptionType, log];
            [self didCollectOneExceptionRecordIfAvailable:parameter.exceptionType
                                                      log:appleLog
                                                    title:nil
                                                 subTitle:nil
                                                   symbol:YES
                                              addressList:nil
                                                  filters:parameter.filters
                                             customParams:parameter.customParams
                                            viewHierarchy:nil
                                               asyncTimes:async_times
                                           aggregationKey:parameter.aggregationKey
                                                 callback:callback];
        }else {
            USER_EXCEPTION_CALLBACK_ERROR(callback, HMDStaticUserExceptionFailTypeLog, @"get stack log failed")
        }
        
    });
#endif
}

- (void)trackBaseExceptionWithBacktraceParameter:(HMDUserExceptionParameter *)parameter
                                        callback:(HMDUserExceptionCallback _Nullable)callback {
    if (parameter.title == nil || parameter.subTitle == nil) {
        NSAssert(NO, @"Both title and subTitle cannot be nil!");
        USER_EXCEPTION_CALLBACK_ERROR(callback, HMDStaticUserExceptionFailTypeParamsMissing, @"title & subTitle is nil")
    }
#if RANGERSAPM
    NSString *appID = parameter.appID;
#else
    NSString *appID = nil;
#endif
    
    if (![self checkException:parameter.exceptionType appID:appID callback:callback]) {
        return;
    }
    parameter.logType = HMDLogUserException;
    NSString *binaryImageLog;
    if (parameter.addressList != nil && parameter.addressList.count > 0) {
        HMDThreadBacktrace *mainThread = [HMDThreadBacktrace new];
        mainThread.crashed = YES;
        mainThread.name = @"main";
        mainThread.threadID = 10000;
        
        HMDThreadBacktrace *secondThread = [HMDThreadBacktrace new];
        secondThread.crashed = YES;
        secondThread.name = @"second";
        secondThread.threadID = 10001;
        
        //only more than two threads can generate binary image log
        if(mainThread && secondThread) {
            binaryImageLog = [HMDAppleBacktracesLog logWithBacktraces:@[mainThread,secondThread]
                                                                type:HMDLogUserException
                                                           exception:nil
                                                              reason:nil];
        }
    }
    
    hmd_safe_dispatch_async(_userExceptionQueue, ^{
        [self didCollectOneExceptionRecordIfAvailable:parameter.exceptionType
                                                  log:binaryImageLog
                                                title:parameter.title
                                             subTitle:parameter.subTitle
                                               symbol:NO
                                          addressList:parameter.addressList
                                              filters:parameter.filters
                                         customParams:parameter.customParams
                                        viewHierarchy:parameter.viewHierarchy
                                           asyncTimes:0
                                       aggregationKey:parameter.aggregationKey
                                                appID:appID
                                             callback:callback];
    });
}

#if RANGERSAPM
- (void)trackThreadLogWithExceptionParameter:(HMDUserExceptionParameter *)parameter callback:(HMDUserExceptionCallback)callback {
    if (!(parameter.exception && [parameter.exception isKindOfClass:[NSException class]])) {
        USER_EXCEPTION_CALLBACK_ERROR(callback, HMDStaticUserExceptionFailTypeLog, @"parameter.exception is not kind of NSException.")
        return;
    }
    
    if (![self checkException:parameter.exceptionType appID:parameter.appID callback:callback]) {
        return;
    }
    parameter.logType = HMDLogUserException;
    [HMDAppleBacktracesLog getLogByNSException:parameter.exception logType:HMDLogUserException callback:^(BOOL success, NSString *log) {
        if (log) {
            NSString *appleLog = [NSString stringWithFormat:@"UserExceptionType:%@\n%@", parameter.exceptionType, log];
            hmd_safe_dispatch_async(self->_userExceptionQueue, ^{
                NSMutableDictionary *joinedCustomParams = [NSMutableDictionary dictionaryWithDictionary:parameter.customParams];
                [joinedCustomParams addEntriesFromDictionary:parameter.exception.userInfo];
                parameter.customParams = [joinedCustomParams copy];
                [self didCollectOneExceptionRecordIfAvailable:parameter.exceptionType
                                                          log:appleLog
                                                        title:nil
                                                     subTitle:nil
                                                       symbol:YES
                                                  addressList:nil
                                                      filters:parameter.filters
                                                 customParams:parameter.customParams
                                                viewHierarchy:nil
                                                   asyncTimes:0
                                               aggregationKey:parameter.aggregationKey
                                                        appID:parameter.appID
                                                     callback:callback];
            });
        } else {
            if (callback) {
                NSError *error = [NSError errorWithDomain:HMDUserExceptionErrorDomain
                                                     code:RangersAPMUserExceptionFailTypeLog
                                                 userInfo:@{@"reason" : @"get stack log failed"}];
                callback(error);
            }
        }
    }];
}
#endif

- (void)trackAllThreadsLogExceptionType:(NSString *)exceptionType
                           skippedDepth:(NSUInteger)skippedDepth
                           customParams:(NSDictionary<NSString *, id> *)customParams
                                filters:(NSDictionary<NSString *, id> *)filters
                               callback:(HMDUserExceptionCallback)callback {
    [self _internalTrackExceptionWithType:exceptionType
                             skippedDepth:skippedDepth + 1
                                keyThread:(thread_t)hmdthread_self()
                           needAllThreads:YES
                             customParams:customParams
                                  filters:filters
                                 callback:callback];
    GCC_FORCE_NO_OPTIMIZATION
}

- (void)trackAllThreadsLogExceptionType:(NSString *)exceptionType
                              keyThread:(thread_t)keyThread
                           skippedDepth:(NSUInteger)skippedDepth
                           customParams:(NSDictionary<NSString *, id> *)customParams
                                filters:(NSDictionary<NSString *, id> *)filters
                               callback:(HMDUserExceptionCallback)callback {
    [self _internalTrackExceptionWithType:exceptionType
                             skippedDepth:skippedDepth + 1
                                keyThread:keyThread
                           needAllThreads:YES
                             customParams:customParams
                                  filters:filters
                                 callback:callback];
    GCC_FORCE_NO_OPTIMIZATION
}

- (void)trackCurrentThreadLogExceptionType:(NSString *)exceptionType
                              skippedDepth:(NSUInteger)skippedDepth
                              customParams:(NSDictionary<NSString *, id> *)customParams
                                   filters:(NSDictionary<NSString *, id> *)filters
                                  callback:(HMDUserExceptionCallback)callback {
    [self _internalTrackExceptionWithType:exceptionType
                             skippedDepth:skippedDepth + 1
                                keyThread:(thread_t)hmdthread_self()
                           needAllThreads:NO
                             customParams:customParams
                                  filters:filters
                                 callback:callback];
    GCC_FORCE_NO_OPTIMIZATION
}

- (void)trackMainThreadLogExceptionType:(NSString *)exceptionType
                           skippedDepth:(NSUInteger)skippedDepth
                           customParams:(NSDictionary<NSString *, id> *)customParams
                                filters:(NSDictionary<NSString *, id> *)filters
                               callback:(HMDUserExceptionCallback)callback {
    [self _internalTrackExceptionWithType:exceptionType
                             skippedDepth:skippedDepth + 1
                                keyThread:[HMDThreadBacktrace mainThread]
                           needAllThreads:NO
                             customParams:customParams
                                  filters:filters
                                 callback:callback];
    GCC_FORCE_NO_OPTIMIZATION
}

- (void)trackThreadLogExceptionType:(NSString *)exceptionType
                             thread:(thread_t)thread
                       skippedDepth:(NSUInteger)skippedDepth
                       customParams:(NSDictionary<NSString *, id> *)customParams
                            filters:(NSDictionary<NSString *, id> *)filters
                           callback:(HMDUserExceptionCallback)callback {
    [self _internalTrackExceptionWithType:exceptionType
                             skippedDepth:skippedDepth + 1
                                keyThread:thread
                           needAllThreads:NO
                             customParams:customParams
                                  filters:filters
                                 callback:callback];
    GCC_FORCE_NO_OPTIMIZATION
}

- (void)_internalTrackExceptionWithType:(NSString *)exceptionType
                           skippedDepth:(NSUInteger)skippedDepth
                              keyThread:(thread_t)keyThread
                         needAllThreads:(BOOL)needAllThreads
                           customParams:(NSDictionary<NSString *, id> *)customParams
                                filters:(NSDictionary<NSString *, id> *)filters
                               callback:(HMDUserExceptionCallback)callback {
#if !RANGERSAPM
    @autoreleasepool {
        if (![self checkException:exceptionType callback:callback]) {
            return;
        }
        
        if (needAllThreads) {
            [HMDAppleBacktracesLog getAllThreadsLogByKeyThread:keyThread
                                                maxThreadCount:DEFAULT_USER_EXCEPTION_MAX_THREADS_COUNT skippedDepth:skippedDepth+1 logType:HMDLogUserException
                                                       suspend:NO
                                                     exception:nil
                                                        reason:nil
                                                      callback:^(BOOL success, NSString * _Nonnull log) {
                if (log) {
                    NSString *appLog = [NSString stringWithFormat:@"UserExceptionType:%@\n%@", exceptionType, log];
                    hmd_safe_dispatch_async(self->_userExceptionQueue, ^{
                      [self didCollectOneExceptionRecordIfAvailable:exceptionType
                                                                log:appLog
                                                              title:nil
                                                           subTitle:nil
                                                             symbol:YES
                                                        addressList:nil
                                                            filters:filters
                                                       customParams:customParams
                                                      viewHierarchy:nil
                                                         asyncTimes:0
                                                     aggregationKey:nil
                                                           callback:callback];
                    });
                }
                else {
                    if (callback) {
                        NSError *error = [NSError errorWithDomain:HMDUserExceptionErrorDomain
                                                             code:HMDStaticUserExceptionFailTypeLog
                                                         userInfo:@{@"reason" : @"get stack log failed"}];
                        callback(error);
                    }
                }
            }];
        }
        else {
            [HMDAppleBacktracesLog getThreadLogByThread:keyThread
                                           skippedDepth:skippedDepth+1
                                                logType:HMDLogUserException
                                                suspend:NO
                                              exception:nil
                                                 reason:nil
                                               callback:^(BOOL success, NSString * _Nonnull log) {
                if (log) {
                    NSString *appLog = [NSString stringWithFormat:@"UserExceptionType:%@\n%@", exceptionType, log];
                    hmd_safe_dispatch_async(self->_userExceptionQueue, ^{
                      [self didCollectOneExceptionRecordIfAvailable:exceptionType
                                                                log:appLog
                                                              title:nil
                                                           subTitle:nil
                                                             symbol:YES
                                                        addressList:nil
                                                            filters:filters
                                                       customParams:customParams
                                                      viewHierarchy:nil
                                                         asyncTimes:0
                                                     aggregationKey:nil
                                                           callback:callback];
                    });
                }
                else {
                    if (callback) {
                        NSError *error = [NSError errorWithDomain:HMDUserExceptionErrorDomain
                                                             code:HMDStaticUserExceptionFailTypeLog
                                                         userInfo:@{@"reason" : @"get stack log failed"}];
                        callback(error);
                    }
                }
            }];
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION
#endif
}

- (NSString *)getUserExceptionLogWithType:(NSString *)exceptionType
                             skippedDepth:(NSUInteger)skippedDepth
                                keyThread:(thread_t)keyThread
                           needAllThreads:(BOOL)needAllThreads
                                 callback:(HMDUserExceptionCallback)callback {
#if !RANGERSAPM
    NSString *appleLog = [NSString stringWithFormat:@"UserExceptionType:%@\n", exceptionType];
    @autoreleasepool {
        NSString *log = nil;
        if (needAllThreads) {
            log = [HMDAppleBacktracesLog getAllThreadsLogByKeyThread:keyThread
                                                      maxThreadCount:DEFAULT_USER_EXCEPTION_MAX_THREADS_COUNT skippedDepth:skippedDepth+1 logType:HMDLogUserException
                                                             suspend:NO
                                                           exception:nil
                                                              reason:nil];
        } else {
            log = [HMDAppleBacktracesLog getThreadLogByThread:keyThread
                                                 skippedDepth:skippedDepth+1
                                                      logType:HMDLogUserException
                                                      suspend:NO
                                                    exception:nil
                                                       reason:nil];
        }
        
        appleLog = [appleLog stringByAppendingString:log];
    }
    
    GCC_FORCE_NO_OPTIMIZATION
    return appleLog;
#else
    return nil;
#endif
}

- (void)trackUserExceptionWithType:(NSString *)exceptionType
                               Log:(NSString *)log
                      CustomParams:(NSDictionary<NSString *, id> *)customParams
                           filters:(NSDictionary<NSString *, id> *)filters
                          callback:(HMDUserExceptionCallback)callback {
#if !RANGERSAPM
    if (![self checkException:exceptionType callback:callback]) {
        return;
    }
    if (!log) {
        USER_EXCEPTION_CALLBACK_ERROR(callback, HMDStaticUserExceptionFailTypeLog, @"get stack log failed")
        return;
    }
    hmd_safe_dispatch_async(_userExceptionQueue, ^{
        [self didCollectOneExceptionRecordIfAvailable:exceptionType
                                                  log:log
                                                title:nil
                                             subTitle:nil
                                               symbol:YES
                                          addressList:nil
                                              filters:filters
                                         customParams:customParams
                                        viewHierarchy:nil
                                           asyncTimes:0
                                       aggregationKey:nil
                                             callback:callback];
    });
#endif
}

- (NSArray<HMDThreadBacktrace *> *)getBacktracesWithKeyThread:(thread_t)keyThread
                                                 skippedDepth:(NSUInteger)skippedDepth
                                               needAllThreads:(BOOL)needAllThreads {
    NSArray<HMDThreadBacktrace *> *backtraces = nil;
#if !RANGERSAPM
    if (needAllThreads) {
        backtraces = [HMDThreadBacktrace backtraceOfAllThreadsWithKeyThread:keyThread
                                                                symbolicate:NO
                                                                 
                                                               skippedDepth:skippedDepth+1
                                                                      
                                                                    suspend:NO
                                                               
                                                             maxThreadCount:DEFAULT_USER_EXCEPTION_MAX_THREADS_COUNT];
    }
    else {
        HMDThreadBacktrace *bt = [HMDThreadBacktrace backtraceOfThread:keyThread
                                                           symbolicate:NO
                                                          skippedDepth:skippedDepth+1
                                                               suspend:NO];
        if (bt) {
            backtraces = @[bt];
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION
#endif
    return backtraces;
}

- (void)trackUserExceptionWithType:(NSString *)exceptionType
                   backtracesArray:(NSArray<HMDThreadBacktrace *> *)backtraces
                      customParams:(NSDictionary<NSString *,id> *)customParams
                           filters:(NSDictionary<NSString *,id> *)filters
                          callback:(HMDUserExceptionCallback)callback {
#if !RANGERSAPM
    if (!(backtraces && [backtraces isKindOfClass:[NSArray class]] && backtraces.count > 0)) {
        if (callback) {
            NSError *error = [NSError errorWithDomain:HMDUserExceptionErrorDomain
                                                 code:HMDStaticUserExceptionFailTypeLog
                                             userInfo:@{@"reason" : @"get stack log failed"}];
            callback(error);
        }
        return;
    }
    
    __block BOOL isValidBTs = YES;
    [backtraces enumerateObjectsUsingBlock:^(HMDThreadBacktrace * _Nonnull bt, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![bt isKindOfClass:[HMDThreadBacktrace class]]) {
            NSAssert(NO, @"The element of parameter backtraces must be HMDThreadBacktrace!");
            *stop = YES;
            isValidBTs = NO;
        }
    }];
    if (!isValidBTs) {
        if (callback) {
            NSError *error = [NSError errorWithDomain:HMDUserExceptionErrorDomain
                                                 code:HMDStaticUserExceptionFailTypeLog
                                             userInfo:@{@"reason" : @"get stack log failed"}];
            callback(error);
        }
        return;
    }
    
    if (![self checkException:exceptionType callback:callback]) {
        return;
    }
    
    hmd_safe_dispatch_async(_userExceptionQueue, ^{
        NSString *log = [HMDAppleBacktracesLog logWithBacktraces:backtraces
                                                            type:HMDLogUserException
                                                       exception:nil
                                                          reason:nil];
        if (log) {
            NSString * appleLog = [NSString stringWithFormat:@"UserExceptionType:%@\n%@", exceptionType, log];
            [self didCollectOneExceptionRecordIfAvailable:exceptionType
                                                      log:appleLog
                                                    title:nil
                                                 subTitle:nil
                                                   symbol:YES
                                              addressList:nil
                                                  filters:filters
                                             customParams:customParams
                                            viewHierarchy:nil
                                               asyncTimes:0
                                           aggregationKey:nil
                                                 callback:callback];
        }else {
            USER_EXCEPTION_CALLBACK_ERROR(callback, HMDStaticUserExceptionFailTypeLog, @"get stack log failed")
            return;
        }
    });
#endif
}

- (void)trackUserExceptionWithExceptionType:(NSString *)exceptionType
                                      title:(NSString *)title
                                   subTitle:(NSString *)subTitle
                               customParams:(NSDictionary<NSString *,id> *)customParams
                                    filters:(NSDictionary<NSString *,id> *)filters
                                   callback:(HMDUserExceptionCallback)callback {
    [self trackUserExceptionWithExceptionType:exceptionType title:title subTitle:subTitle addressList:nil customParams:customParams filters:filters callback:callback];
}

- (void)trackUserExceptionWithExceptionType:(NSString *)exceptionType
                                      title:(NSString *)title
                                   subTitle:(NSString *)subTitle
                                addressList:(NSArray<HMDAddressUnit *> *)addressList
                               customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                                    filters:(NSDictionary<NSString *, id> *_Nullable)filters
                                   callback:(HMDUserExceptionCallback _Nullable)callback {
#if !RANGERSAPM
    if (title == nil || subTitle == nil) {
        NSAssert(NO, @"Both title and subTitle cannot be nil!");
        if (callback) {
            NSError *error = [NSError errorWithDomain:HMDUserExceptionErrorDomain
                                                 code:HMDStaticUserExceptionFailTypeParamsMissing
                                             userInfo:@{@"reason" : @"title & subTitle is nil"}];
            callback(error);
        }
        return;
    }
    
    if (![self checkException:exceptionType callback:callback]) {
        return;
    }
    
    NSString *binaryImageLog;
    if (addressList.count > 0) {
        HMDThreadBacktrace *mainThread = [HMDThreadBacktrace new];
        mainThread.crashed = YES;
        mainThread.name = @"main";
        mainThread.threadID = 10000;
        
        HMDThreadBacktrace *secondThread = [HMDThreadBacktrace new];
        secondThread.crashed = YES;
        secondThread.name = @"second";
        secondThread.threadID = 10001;
        
        //only more than two threads can generate binary image log
        if(mainThread && secondThread) {
            binaryImageLog = [HMDAppleBacktracesLog logWithBacktraces:@[mainThread,secondThread]
                                                                type:HMDLogUserException
                                                           exception:nil
                                                              reason:nil];
        }
    }
    
    hmd_safe_dispatch_async(_userExceptionQueue, ^{
        [self didCollectOneExceptionRecordIfAvailable:exceptionType
                                                  log:binaryImageLog
                                                title:title
                                             subTitle:subTitle
                                               symbol:NO
                                          addressList:addressList
                                              filters:filters
                                         customParams:customParams
                                        viewHierarchy:nil
                                           asyncTimes:0
                                       aggregationKey:nil
                                             callback:callback];
    });
#endif
}

- (void)didCollectOneExceptionRecordIfAvailable:(NSString *)type
                                            log:(NSString *)log
                                          title:(NSString *)title
                                       subTitle:(NSString *)subTitle
                                         symbol:(BOOL)needSymbol
                                    addressList:(NSArray<HMDAddressUnit *> *)addressList
                                        filters:(NSDictionary<NSString *, id> *)filters
                                   customParams:(NSDictionary<NSString *, id> *)customParams
                                  viewHierarchy:(NSDictionary *)viewHierarchy
                                     asyncTimes:(int)asyncTimes
                                 aggregationKey:(NSString *)aggregationKey
                                       callback:(HMDUserExceptionCallback)callback {
    [self didCollectOneExceptionRecordIfAvailable:type log:log title:title subTitle:subTitle symbol:needSymbol addressList:addressList filters:filters customParams:customParams viewHierarchy:viewHierarchy asyncTimes:asyncTimes aggregationKey:aggregationKey appID:nil callback:callback];
}

- (void)didCollectOneExceptionRecordIfAvailable:(NSString *)type
                                            log:(NSString *)log
                                          title:(NSString *)title
                                       subTitle:(NSString *)subTitle
                                         symbol:(BOOL)needSymbol
                                    addressList:(NSArray<HMDAddressUnit *> *)addressList
                                        filters:(NSDictionary<NSString *, id> *)filters
                                   customParams:(NSDictionary<NSString *, id> *)customParams
                                  viewHierarchy:(NSDictionary *)viewHierarchy
                                     asyncTimes:(int)asyncTimes
                                 aggregationKey:(NSString *)aggregationKey
                                          appID:(NSString *)appID
                                       callback:(HMDUserExceptionCallback)callback {
    BOOL needDrop = hermas_enabled() ? hermas_drop_data(kModuleUserExceptionName) : hmd_drop_data(HMDReporterUserException);
    if (needDrop) {
        NSError *error = [NSError errorWithDomain:HMDUserExceptionErrorDomain
                                             code:HMDStaticUserExceptionFailTypeDropData
                                         userInfo:@{@"reason" : @"server err, drop data"}];
        if (callback) callback(error);
        return;
    }
    // filter合法性校验
    NSMutableDictionary *validFilters = [NSMutableDictionary new];
    [filters enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
            [validFilters setValue:obj forKey:key];
        }
        else {
            NSAssert(NO, @"[Heimdallr] The key-value of filters must be NSString!");
            
            if ([key isKindOfClass:[NSNumber class]]) {
                key = [(NSNumber *)key stringValue];
            }
            else {
                key = [key description];
            }
            
            if ([obj isKindOfClass:[NSNumber class]]) {
                obj = [(NSNumber *)obj stringValue];
            }
            else {
                obj = [obj description];
            }
            
            [validFilters setValue:obj forKey:key];
        }
    }];
    
    if (asyncTimes) {
        //upload async times in filter
        [validFilters setValue:[@(asyncTimes) stringValue] forKey:@"hmd_async_stack_times"];
    }
    
    if (customParams && customParams.count>0 && ![NSJSONSerialization isValidJSONObject:customParams]) {
//        - Top level object is an NSArray or NSDictionary
//        - All objects are NSString, NSNumber, NSArray, NSDictionary, or NSNull
//        - All dictionary keys are NSStrings
//        - NSNumbers are not NaN or infinity
        NSAssert(NO, @"[Heimdallr] customParams must can be converted to JSON data!");
        NSMutableDictionary *validCustomParams = [NSMutableDictionary new];
        [customParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
                [validCustomParams setValue:obj forKey:key];
            }else {
                [validCustomParams setValue:[obj description] forKey:[key description]];
            }
        }];
        customParams = validCustomParams;
    }
    
    HMDUserExceptionRecord *record = [HMDUserExceptionRecord newRecord];
    record.type                    = [type copy];
    record.log                     = [log copy];
    record.title = [title copy];
    record.subTitle = [subTitle copy];
    record.needSymbolicate = needSymbol;
    record.addressList = [addressList valueForKey:@"unitToDict"];
    HMDLog(@"log:\n %@", log);
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    record.memoryUsage          = memoryBytes.appMemory / HMD_MB;
    record.freeMemoryUsage      = memoryBytes.availabelMemory / HMD_MB;
    record.freeDiskBlockSize    = [HMDDiskUsage getFreeDisk300MBlockSize];
    record.business             = [HMDInjectedInfo defaultInfo].business ?: @"unknown";
    record.access               = [HMDNetworkHelper connectTypeName];
    record.lastScene            = [HMDTracker getLastSceneIfAvailable];
    record.operationTrace       = [HMDTracker getOperationTraceIfAvailable];
    record.filters              = [validFilters copy];
    NSMutableDictionary *overallCustom =
        [NSMutableDictionary dictionaryWithDictionary:customParams] ?: [NSMutableDictionary dictionary];
    if ([HMDInjectedInfo defaultInfo].userID)
        [overallCustom setValue:[HMDInjectedInfo defaultInfo].userID forKey:@"user_id"];
    if ([HMDInjectedInfo defaultInfo].scopedUserID)
        [overallCustom setValue:[HMDInjectedInfo defaultInfo].scopedUserID forKey:@"scoped_user_id"];
    if ([HMDInjectedInfo defaultInfo].userName)
        [overallCustom setValue:[HMDInjectedInfo defaultInfo].userName forKey:@"user_name"];
    if ([HMDInjectedInfo defaultInfo].email)
        [overallCustom setValue:[HMDInjectedInfo defaultInfo].email forKey:@"email"];
#if !RANGERSAPM
    if ([HMDInjectedInfo defaultInfo].customContext){
        [overallCustom addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].customContext];
    }
#endif
    record.customParams = [overallCustom copy];
    if (viewHierarchy){
        record.viewHierarchy = viewHierarchy;
    }
#if RANGERSAPM
    record.appID = appID ?: [HMDInjectedInfo defaultInfo].appID;
    if (![appID isEqualToString:[HMDInjectedInfo defaultInfo].appID]) {
        record.appVersion = [[RangersInjectedInfo defaultInfo] sdkVersionForSDKID:appID];
        NSMutableDictionary *filterWithHostAppID = [NSMutableDictionary dictionaryWithDictionary:record.filters] ?: [NSMutableDictionary dictionary];
        [filterWithHostAppID setValue:[[RangersInjectedInfo defaultInfo] hostAppIDForSDKID:appID] forKey:@"host_appid"];
        record.filters = [filterWithHostAppID copy];
    }
#endif
    if (aggregationKey) {
        record.aggregationKey = aggregationKey;
    }

    if (hermas_enabled()) {
        // 自定义异常实时上传
        [self updateRecordWithConfig:record];

        [self.instance recordData:record.reportDictionary priority:HMRecordPriorityHigh];

        if (callback) callback(nil);

    } else {
        [[HMDUserExceptionTracker sharedTracker]
            didCollectOneRecord:record
                   trackerBlock:^(BOOL flag) {
                     if (flag) {
                         [[HMDUserExceptionTracker sharedTracker] uploadUserExceptionLogIfNeeded];
                         if (callback) callback(nil);
                     } else {
                         NSError *error = [NSError errorWithDomain:HMDUserExceptionErrorDomain
                                                              code:HMDStaticUserExceptionFailTypeInsertFail
                                                          userInfo:@{@"reason" : @"failed to insert into database"}];
                         if (callback) callback(error);
                     }
        }];
    }
}

- (BOOL)checkException:(NSString *)type callback:(HMDUserExceptionCallback)callback {
    return [self checkException:type appID:nil callback:callback];
}

- (BOOL)checkException:(NSString *)type appID:(NSString *)appID callback:(HMDUserExceptionCallback)callback {
    NSError *error = [self checkIfAvailableForType:type appID:appID];
    if (error) {
        if (callback) {
            callback(error);
        }
        
        return NO;
    }
/**
 tob 没有暴露 checkIfAvailableForType: 接口，因此 checkIfAvailableForType: 这个接口唯一的调用方式就是通过此方法调用，所以不需要把时间验证的逻辑进行拆分
 */
#if !RANGERSAPM  //tob 没有暴露可上报性验证的接口，所以直接在 checkIfAvailableForType: 进行了
    if ([_timestampMap objectForKey:type]) {
        NSTimeInterval preTimestamp     = (NSTimeInterval)((NSNumber *)_timestampMap[type]).doubleValue;
        NSTimeInterval currentTimestamp = CACurrentMediaTime();
        NSTimeInterval interval         = currentTimestamp - preTimestamp;
        if ((interval) > 60) {
            _timestampMap[type] = @(currentTimestamp);
        }
    } else {
        _timestampMap[type] = @(CACurrentMediaTime());
    }
#endif
    return YES;
}

#pragma mark - upload

- (void)uploadUserExceptionLogIfNeeded {
    if (hermas_enabled()) {
        return;
    }

    HMDStopUpload exceptionStopUpload = [HMDInjectedInfo defaultInfo].exceptionStopUpload;
    if (exceptionStopUpload && exceptionStopUpload()) {
        return;
    }
    if ([[HMDInjectedInfo defaultInfo].disableNetworkRequest boolValue]) {
        if (!self.addNetScheduleNoti) {
            self.addNetScheduleNoti = YES;
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(recieveNetworkScheduleNotification:)
                                                         name:kHMDNetworkScheduleNotification
                                                       object:nil];
        }
        return;
    }
    [[HMDExceptionReporter sharedInstance] reportExceptionDataWithExceptionTypes:@[@(HMDUserExceptionType)]];
}

- (void)recieveNetworkScheduleNotification:(NSNotification *)notificaion {
    [self performanceActionOnTrackerAsyncQueue:^{
        [self uploadUserExceptionLogIfNeeded];
    }];
}

- (NSArray *)getUserExceptionDataWithRecords:(NSArray<HMDUserExceptionRecord *> *)records {
    NSMutableArray *dataArray = [NSMutableArray array];

    for (HMDUserExceptionRecord *record in records) {
        
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
        long long timestamp = MilliSecond(record.timestamp);
        [dataValue setValue:@(timestamp) forKey:@"timestamp"];
        [dataValue setValue:kHMDUserExceptionEventType forKey:@"event_type"];
        [dataValue setValue:record.sessionID forKey:@"session_id"];
        [dataValue setValue:record.log forKey:@"stack"];
        [dataValue setValue:record.title forKey:@"title"];
        [dataValue setValue:record.subTitle forKey:@"subtitle"];
        [dataValue setValue:(record.needSymbolicate ? @(0) : @(1)) forKey:@"disable_symbolicate"];
        [dataValue setValue:@(record.inAppTime) forKey:@"inapp_time"];
        [dataValue setValue:record.type forKey:@"custom_exception_type"];
        [dataValue setValue:@(record.memoryUsage) forKey:@"memory_usage"];
        [dataValue setValue:@(record.freeDiskBlockSize) forKey:@"d_zoom_free"];
        [dataValue setValue:@(hmd_calculateMemorySizeLevel(((uint64_t)record.freeMemoryUsage)*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
        hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
        CGFloat          allMemory   = memoryBytes.totalMemory / HMD_MB;
        CGFloat freeMemoryRate = ((int)(record.freeMemoryUsage/allMemory*100))/100.0;
        [dataValue setValue:@(freeMemoryRate) forKey:HMD_Free_Memory_Percent_key];
        [dataValue setValue:record.business forKey:@"business"];
        [dataValue setValue:record.lastScene forKey:@"last_scene"];
        [dataValue setValue:record.operationTrace forKey:@"operation_trace"];
        [dataValue setValue:@(record.netQualityType) forKey:@"network_quality"];
#if !RANGERSAPM
        if (record.customParams.count > 0) {
            [dataValue setValue:record.customParams forKey:@"custom"];
        }
        if (record.filters.count > 0) {
            [dataValue setValue:record.filters forKey:@"filters"];
        }
#else
        NSMutableArray *allData = [NSMutableArray array];
        NSMutableDictionary *internalDict = [NSMutableDictionary dictionary];
        if (record.customParams.count > 0) {
            [internalDict setValue:record.customParams forKey:@"custom"];
        }
        if (record.filters.count > 0) {
            [internalDict setValue:record.filters forKey:@"filters"];
        }
        NSMutableDictionary *headerDict = [NSMutableDictionary dictionary];
        [headerDict hmd_setSafeObject:record.appID forKey:@"aid"];
        [headerDict hmd_setSafeObject:record.appVersion forKey:@"update_version_code"];
        [internalDict setValue:headerDict forKey:@"header"];
        [allData addObject:internalDict];
        
        [dataValue setValue:allData forKey:@"all_data"];
#endif
        if (record.addressList.count > 0) {
            [dataValue setValue:record.addressList forKey:@"custom_address_analysis"];
        }
        
        if (record.viewHierarchy) {
            [dataValue setObject:record.viewHierarchy forKey:@"view_hierarchy"];
        }

        if (record.aggregationKey) {
            [dataValue setObject:record.aggregationKey forKey:@"aggregation_key"];
        }

        [dataValue addEntriesFromDictionary:record.environmentInfo];

        [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:dataValue timestamp:timestamp eventType:kHMDUserExceptionEventType];
        
        [dataArray addObject:dataValue];
    }

    return [dataArray copy];
}

- (NSArray *)pendingDebugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config {
#if !RANGERSAPM
    if (![config checkIfAllowedDebugRealUploadWithType:kEnableUserExceptionTracker]) {
        return nil;
    }

    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key                = @"timestamp";
    condition1.threshold          = config.fetchStartTime;
    condition1.judgeType          = HMDConditionJudgeGreater;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key                = @"timestamp";
    condition2.threshold          = config.fetchEndTime;
    condition2.judgeType          = HMDConditionJudgeLess;

    NSArray<HMDStoreCondition *> *debugRealConditions = @[ condition1, condition2 ];

    NSArray<HMDUserExceptionRecord *> *records =
        [[Heimdallr shared].database getObjectsWithTableName:[[self storeClass] tableName]
                                                       class:[self storeClass]
                                               andConditions:debugRealConditions
                                                orConditions:nil
                                                       limit:config.limitCnt];

    NSArray *result = [self getUserExceptionDataWithRecords:records];

    return [result copy];
#else
    return nil;
#endif
}

- (void)cleanupExceptionDataWithConfig:(HMDDebugRealConfig *)config {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key                = @"timestamp";
    condition1.threshold          = config.fetchStartTime;
    condition1.judgeType          = HMDConditionJudgeGreater;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key                = @"timestamp";
    condition2.threshold          = config.fetchEndTime;
    condition2.judgeType          = HMDConditionJudgeLess;

    NSArray<HMDStoreCondition *> *debugRealConditions = @[ condition1, condition2 ];
    // 清空数据库
    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName]
                                          andConditions:debugRealConditions
                                           orConditions:nil
                                                  limit:config.limitCnt];
}

- (NSArray *)dealNotDebugRealPerformanceData {
#if !RANGERSAPM
    //目前对于有性能损耗的模块，没命中上报的用户本地不采集，因此之前上报时候的限制可以放开
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key                = @"timestamp";
    condition1.threshold          = 0;
    condition1.judgeType          = HMDConditionJudgeGreater;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key                = @"timestamp";
    condition2.threshold          = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType          = HMDConditionJudgeLess;

    _andConditions = @[ condition1, condition2 ];

    NSArray<HMDUserExceptionRecord *> *records =
        [[Heimdallr shared].database getObjectsWithTableName:[[self storeClass] tableName]
                                                       class:[self storeClass]
                                               andConditions:_andConditions
                                                orConditions:nil
                                                       limit:DEFAULT_USER_EXCEPTION_UPLOAD_LIMIT];
    if (records.count < self.maxUploadCount) {
        return nil;
    }

    NSArray *result = [self getUserExceptionDataWithRecords:records];
    return [result copy];
#else
    return nil;
#endif
}

- (long long)dbMaxSize {
    return 50;
}

#pragma mark - DataReporterDelegate
- (NSArray *)pendingExceptionData {
    if (hermas_enabled()) {
        return nil;
    }

    return [self dealNotDebugRealPerformanceData];
}

- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess {
    if (hermas_enabled()) {
        return;
    }

    if (isSuccess)
        [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName]
                                              andConditions:_andConditions
                                               orConditions:nil
                                                      limit:DEFAULT_USER_EXCEPTION_UPLOAD_LIMIT];
}

- (void)dropExceptionData {
    if (hermas_enabled()) {
        return;
    }
    [self dropExceptionDataIgnoreHermas];
}

- (void)dropExceptionDataIgnoreHermas {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key                = @"timestamp";
    condition1.threshold          = 0;
    condition1.judgeType          = HMDConditionJudgeGreater;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key                = @"timestamp";
    condition2.threshold          = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType          = HMDConditionJudgeLess;

    NSArray<HMDStoreCondition *> *conditions = @[ condition1, condition2 ];
    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName]
                                          andConditions:conditions
                                           orConditions:nil];
}

#pragma mark - reporter
#if RANGERSAPM
- (NSArray *)exceptionDataForAppID:(NSString *)appID {
    if (![self.heimdallr.config logTypeEnabled:kEnableUserExceptionTracker]) {
        return nil;
    }
    
    //目前对于有性能损耗的模块，没命中上报的用户本地不采集，因此之前上报时候的限制可以放开
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key                = @"timestamp";
    condition1.threshold          = 0;
    condition1.judgeType          = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key                = @"timestamp";
    condition2.threshold          = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType          = HMDConditionJudgeLess;
    
    HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
    condition3.key                = @"appID";
    condition3.stringValue        = appID;
    condition3.judgeType          = HMDConditionJudgeEqual;
    
    _andConditions = @[condition1, condition2, condition3];
    
    NSArray<HMDUserExceptionRecord *> *uploadRecords =
    [[Heimdallr shared].database getObjectsWithTableName:[[self storeClass] tableName]
                                                   class:[self storeClass]
                                           andConditions:_andConditions
                                            orConditions:nil
                                                   limit:DEFAULT_USER_EXCEPTION_UPLOAD_LIMIT];
    
    if (uploadRecords.count < self.maxUploadCount) {
        return nil;
    }
    
    NSArray *result = [self getUserExceptionDataWithRecords:uploadRecords];
    return [result copy];
}
#endif

- (HMDExceptionType)exceptionType
{
    return HMDUserExceptionType;
}

@end
