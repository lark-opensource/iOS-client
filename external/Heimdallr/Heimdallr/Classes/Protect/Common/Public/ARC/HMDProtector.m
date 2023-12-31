//
//  HMDProtector.m
//  Heimdallr
//
//  Created by fengyadong on 2018/4/9.
//

#include "hmd_debug.h"
#include <sys/sysctl.h>
#import "HMDProtector.h"
#import "HMDProtector+Private.h"
#import "HMDProtectUnrecognizedSelector.h"
#import "HMDProtectContainers.h"
#import "HMDProtectKVO.h"
#import "HMDProtectKVC.h"
#import "HMDProtectNSAssert.h"
#import "HMDProtectNSNotification.h"
#import "HMDProtectUserDefaults.h"
#import "HMDAppleBacktracesLog.h"
#import "hmd_try_catch_detector.h"
#import "HMDDynamicCall.h"
#import "HMDExceptionTracker.h"
#import "HMDProtectNano.h"
//#import "HMDProtectQosOverCommit.h"
#import "HMDGCD.h"
#import "HMDWeakRetainDeallocating.h"


#pragma mark - 默认配置信息

#pragma mark try-catch 和 cload 默认配置

BOOL HMDProtectIgnoreCloudSettings = NO;

/**
 * 在tob业务上，为了避免用户歧义和不必要的沟通成本，这里两个开关默认为YES
 *
 * ignore_try_catch = NO 的话会上报很多的误报，实际不会崩，但是被安全起点报上来，用户肯定会质疑；
 * ignore_duplicate = NO 的话会一直重复上报很多同样的问题，浪费资源
 */
#if RANGERSAPM

BOOL HMDProtectDefaultIgnoreDuplicate = YES;
BOOL HMDProtectDefaultIgnoreTryCatch = YES;

#else

#ifdef DEBUG
BOOL HMDProtectDefaultIgnoreDuplicate = YES;
BOOL HMDProtectDefaultIgnoreTryCatch = YES;
#else
BOOL HMDProtectDefaultIgnoreDuplicate = NO;
BOOL HMDProtectDefaultIgnoreTryCatch = NO;
#endif

#endif

BOOL HMDProtectIgnoreTryCatch = NO;

#pragma mark 同时处理 capture 上限配置

/* Protected by mtx begin */
#define DefaultSerialQueueCaptureProcessLimit 10
#define SerialQueueCaptureProcessLimitMax 100
static pthread_mutex_t accessProcessCountMutex = PTHREAD_MUTEX_INITIALIZER;
static NSUInteger currentSerialQueueProcessCount = 0;
static NSUInteger serialQueueCaptureProcessLimit = DefaultSerialQueueCaptureProcessLimit;
/* Protected by mtx end */

@interface HMDProtector ()
@property(atomic, strong) NSArray<NSString *>* _Nonnull ignoreKVOObserverPrefix;
@end

@implementation HMDProtector {
    // protectionControlLock_ 是只属于 - currentProtectionCollection & - asyncSwitchProtection 同步消息
    NSLock *_protectionControlLock;
    // callbackData 数据逻辑
    // Dictionary
    //     NSString block 标识符
    //     HMDExceptionCatchBlock 对应 block
    // Unique: protection & indentifer
    NSMutableDictionary<NSString *, HMDExceptionCatchBlock> *_callbackData;
    dispatch_queue_t _serialQueue;
    BOOL _isCustomCatchValid;
}

@dynamic currentProcessCaptureLimit;

@synthesize currentProtectionCollection = _currentProtectionCollection; // 禁止除 - currentProtectionCollection & - asyncSwitchProtection 以外访问

#pragma mark - Initialization

+ (instancetype)sharedProtector {
    static HMDProtector *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDProtector alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _currentProtectionCollection = HMDProtectionTypeNone;
        _callbackData = [NSMutableDictionary dictionary];
        _protectionControlLock = [[NSLock alloc] init];
        _ignoreKVOObserverPrefix = @[@"RAC", @"_FBKVO", @"_YYText"];
        _ignoreDuplicate = HMDProtectDefaultIgnoreDuplicate;
        HMDProtectIgnoreTryCatch = HMDProtectDefaultIgnoreTryCatch;
        // 默认忽略这两个第三方框架
        _serialQueue = dispatch_queue_create("com.heimdallr.protect", DISPATCH_QUEUE_SERIAL);
        if (NSClassFromString(@"HMDProtectCatch") != NULL) {
            _isCustomCatchValid = YES;
            DC_OB(DC_CL(HMDProtectCatch, sharedInstance), registCallback:, ^(NSException *exp, NSDictionary *info) {
                [self respondToCustomCatchException:exp info:info];
            });
        }
        else {
            _isCustomCatchValid = NO;
        }
    }
    return self;
}

#pragma mark - Property

- (NSUInteger)currentProcessCaptureLimit {
    int lock_rst = pthread_mutex_lock(&accessProcessCountMutex);
    NSUInteger value = serialQueueCaptureProcessLimit;
    if (lock_rst == 0) pthread_mutex_unlock(&accessProcessCountMutex);
    return value;
}

- (void)setCurrentProcessCaptureLimit:(NSUInteger)newCaptureProcessLimit {
    int lock_rst = pthread_mutex_lock(&accessProcessCountMutex);
    if(newCaptureProcessLimit > serialQueueCaptureProcessLimit) {
        if(newCaptureProcessLimit > SerialQueueCaptureProcessLimitMax)
            newCaptureProcessLimit = SerialQueueCaptureProcessLimitMax;
        serialQueueCaptureProcessLimit = newCaptureProcessLimit;
    }   // can only increase without decrease
    if (lock_rst == 0) pthread_mutex_unlock(&accessProcessCountMutex);
}

- (BOOL)ignoreTryCatch {
    return HMDProtectIgnoreTryCatch;
}

- (void)setIgnoreTryCatch:(BOOL)ignoreTryCatch {
    HMDProtectIgnoreTryCatch = ignoreTryCatch;
}

- (BOOL)ignoreCloudSettings {
    return HMDProtectIgnoreCloudSettings;
}

- (void)setIgnoreCloudSettings {
    if (!HMDProtectIgnoreCloudSettings) {
        HMDProtectIgnoreCloudSettings = YES;
        HMDExceptionTracker_connectWithProtector_if_need();
    }
}

- (HMDProtectionType)currentProtectionCollection {
    [_protectionControlLock lock];
    HMDProtectionType collection = _currentProtectionCollection;
    [_protectionControlLock unlock];
    return collection;
}

#pragma mark - Public

#if RANGERSAPM
- (void)setArrayCreateMode:(NSUInteger)arrayCreateMode {
    _arrayCreateMode = arrayCreateMode;
    HMD_Protect_Container_arrayCreateMode = _arrayCreateMode;
}
#endif

- (void)turnProtectionsOn:(HMDProtectionType)protectionType {
    HMDProtectionType changeToProtectionCollection = (HMDProtectionType)(protectionType & HMDProtectionTypeAll);
    changeToProtectionCollection = (HMDProtectionType)(self.currentProtectionCollection | changeToProtectionCollection);
    [self switchProtectionTo:changeToProtectionCollection];
}

- (void)turnProtectionOff:(HMDProtectionType)protectionType {
    HMDProtectionType changeToProtectionCollection = (HMDProtectionType)(protectionType & HMDProtectionTypeAll);
    changeToProtectionCollection = (HMDProtectionType)(self.currentProtectionCollection & ~changeToProtectionCollection);
    [self switchProtectionTo:changeToProtectionCollection];
}

- (void)switchProtection:(HMDProtectionType)protectionType {
    HMDProtectionType changeToProtectionCollection = (HMDProtectionType)(protectionType & HMDProtectionTypeAll);
    [self switchProtectionTo:changeToProtectionCollection];
}

- (void)enableNanoCrashProtect {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HMD_Protect_toggle_Nano_protection();
    });
}

- (void)enableQosOverCommitProtect {
    // disable QosOverCommitProtect
}

- (void)enableAssertProtect {
    HMD_Protect_toggle_NSAssert_protection(^(HMDProtectCapture * _Nonnull capture) {
        [self respondToCapture:capture];
    });
}

- (void)disableAssertProtect {
    HMD_Protect_toggle_NSAssert_protection(nil);
}

- (void)enableWeakRetainDeallocating {
    HMD_Protect_toggle_weakRetainDeallocating_protection(^(HMDProtectCapture * _Nonnull capture) {
        [self respondToCapture:capture];
    });
}

- (void)disableWeakRetainDeallocating {
    HMD_Protect_toggle_weakRetainDeallocating_protection(nil);
}

- (void)addIgnoreKVOObserverPrefix:(NSArray *)prefix {
    if (!(prefix && [prefix isKindOfClass:[NSArray class]] && prefix.count > 0)) {
        return;
    }
    
    // 添加时去重
    NSMutableSet *set = [NSMutableSet setWithArray:self.ignoreKVOObserverPrefix];
    [set addObjectsFromArray:prefix];
    self.ignoreKVOObserverPrefix = [set allObjects];
}

- (void)registerIdentifier:(NSString * _Nonnull)identifier withBlock:(HMDExceptionCatchBlock _Nonnull)block {
    NSParameterAssert(block != nil && identifier != nil);
    if(identifier == nil || block == nil) {
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        [self->_callbackData setObject:block forKey:identifier];
    });
}

- (void)removeRegistedBlockWithIdentifier:(NSString * _Nonnull)identifier {
    NSParameterAssert(identifier != nil);
    if(identifier == nil || ![identifier isKindOfClass:[NSString class]]) {
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        [self->_callbackData removeObjectForKey:identifier];
    });
}

- (void)catchMethodsWithNames:(NSArray<NSString *> *)names {
    if (_isCustomCatchValid) {
        DC_OB(DC_CL(HMDProtectCatch, sharedInstance), catchMethodsWithNames:, names);
    }
}

#pragma mark Dealing with crash

- (void)respondToCustomCatchException:(NSException *)exception info:(NSDictionary *)info {
    if (!(exception && info)) {
        return;
    }
    
    NSString *crashKey = info[@"crashKey"];
    NSMutableSet *crashKeySet = info[@"crashKeySet"];
    NSArray *backtraces = info[@"backtraces"];
    NSNumber *filterWithTopStack = info[@"filterWithTopStack"];
    HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
    capture.crashKey = crashKey;
    capture.crashKeySet = crashKeySet;
    capture.backtraces = backtraces;
    capture.filterWithTopStack = filterWithTopStack.boolValue;
    capture.protectType = HMDProtectionTypeNone;
    capture.protectTypeString = @"CustomCatch";
    [self respondToCapture:capture];
}

- (void)respondToNSExceptionPrevent:(NSException *)exception info:(NSDictionary *)info {
    if (!(exception && info)) {
        return;
    }
    NSString *crashKey = info[@"crashKey"];
    DEBUG_ASSERT(crashKey == nil || [crashKey isKindOfClass:NSString.class]);
    
    NSMutableSet *crashKeySet = info[@"crashKeySet"];
    DEBUG_ASSERT(crashKeySet == nil || [crashKeySet isKindOfClass:NSMutableSet.class]);
    
    NSArray *backtraces = info[@"backtraces"];
    DEBUG_ASSERT(backtraces == nil || [backtraces isKindOfClass:NSArray.class]);
    
    NSNumber *filterWithTopStack = info[@"filterWithTopStack"];
    DEBUG_ASSERT(filterWithTopStack == nil || [filterWithTopStack isKindOfClass:NSNumber.class]);
    
    NSDictionary<NSString *, NSString *> *customDictionary = info[@"custom"];
    DEBUG_ASSERT(customDictionary == nil || [customDictionary isKindOfClass:NSDictionary.class]);
    
    HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
    capture.crashKey = crashKey;
    capture.crashKeySet = crashKeySet;
    capture.backtraces = backtraces;
    capture.filterWithTopStack = filterWithTopStack.boolValue;
    capture.protectType = HMDProtectionTypeNone;
    capture.protectTypeString = @"CrashPrevent";
    capture.customDictionary = customDictionary;
    [self respondToCapture:capture];
}

- (void)respondToMachExceptionWithInfo:(NSDictionary *)info {
    NSArray *backtraces = (__kindof NSArray *)info[@"backtraces"];
    DEBUG_ASSERT([backtraces isKindOfClass:NSArray.class]);
    
    NSString * _Nullable scope = (__kindof NSString *)info[@"scope"];
    DEBUG_ASSERT([scope isKindOfClass:NSString.class]);
    
    HMDProtectCapture *capture = [HMDProtectCapture captureException:@"MACH_EXCEPTION" reason:@"crashed"];
    capture.protectType = HMDProtectionTypeNone;
    capture.protectTypeString = @"MachException";
    capture.backtraces = backtraces;
    capture.filterWithTopStack = NO;
    if(scope != nil) capture.customFilter = @{
        @"scope": scope?:@""
    };
    [self respondToCapture:capture];
}

- (void)respondToCapture:(HMDProtectCapture * _Nonnull)capture {
#if RANGERSAPM
    if (!self.protectorUpload) {
        return;
    }
#endif
    
    if (!(capture && capture.backtraces && [capture.backtraces isKindOfClass:[NSArray class]] && capture.backtraces.count > 0)) {
        return;
    }
    
    BOOL canProcess = YES;
    int lock_rst = pthread_mutex_lock(&accessProcessCountMutex);
    if (currentSerialQueueProcessCount > serialQueueCaptureProcessLimit) {
        canProcess = NO;
    }
    else {
        canProcess = YES;
        currentSerialQueueProcessCount++;
    }
    
    if (lock_rst == 0) {
        pthread_mutex_unlock(&accessProcessCountMutex);
    }
    
    if (!canProcess) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"[Heimdallr][Protect][Busy]", @"Serial Queue too busy to process exception [%@][%@]", capture.protectTypeString, capture.reason);
        return;
    }
    
    hmd_safe_dispatch_async(_serialQueue, ^{
        
        // 是否开启去除重复取决于 _ignoreDuplicate 属性
        if (self->_ignoreDuplicate) {
            // 通过顶栈过滤
            if (capture.filterWithTopStack && capture.crashKey == nil) {
                HMDThreadBacktrace *crashBacktrace = nil;
                for (HMDThreadBacktrace *bt in capture.backtraces) {
                    if (bt.crashed) {
                        crashBacktrace = bt;
                        break;
                    }
                }
                
                uintptr_t topAddress = [crashBacktrace topAppAddress];
                if (topAddress != 0) {
                    // 主线程过滤main方法
                    if (crashBacktrace.threadID == hmdbt_main_thread) {
                        uintptr_t bottomAddress = [crashBacktrace bottomAppAddress];
                        if (topAddress == bottomAddress) {
                            topAddress = 0;
                        }
                    }
                    
                    // 只有存在App顶栈 && 顶栈不为main方法时才使用过滤策略
                    if (topAddress != 0) {
                        capture.crashKey = [NSNumber numberWithUnsignedLong:topAddress];
                    }
                }
            }
            
            if (capture.crashKeySet && capture.crashKey) {
                if ([capture.crashKeySet containsObject:capture.crashKey]) {
                    HMDALOG_PROTOCOL_WARN_TAG(@"[Heimdallr][Protect][Duplicate]" @"[%@][count:%lu][CrashKey:%@][Reason:%@]",
                                         capture.protectTypeString,
                                         (unsigned long)capture.crashKeySet.count,
                                         capture.crashKey,
                                         capture.reason);
                    
                    // 遇到重复数据时，计数递减
                    int lock_rst = pthread_mutex_lock(&accessProcessCountMutex);
                    currentSerialQueueProcessCount--;
                    if (lock_rst == 0) {
                        pthread_mutex_unlock(&accessProcessCountMutex);
                    }
                    
                    return;
                }
                else {
                    [capture.crashKeySet addObject:capture.crashKey];
                }
            }
        }
        
        capture.reason = [NSString stringWithFormat:@"[%@]%@", capture.protectTypeString, capture.reason];
        capture.log = [HMDAppleBacktracesLog logWithBacktraces:capture.backtraces
                                                          type:HMDLogExceptionProtect
                                                     exception:capture.exception
                                                        reason:capture.reason];
        
        id crashKey = capture.crashKey;
        
        if ([crashKey isKindOfClass:NSNumber.class]) {
            capture.crashKey = ((NSNumber *)crashKey).stringValue;
            NSMutableArray<NSString *>*crashKeyList = [[NSMutableArray alloc] initWithCapacity:capture.crashKeySet.count];
            for (NSNumber *num in capture.crashKeySet) {
                [crashKeyList addObject:num.stringValue];
            }
            
            capture.crashKeyList = [crashKeyList copy];
        }
        else if([crashKey isKindOfClass:NSString.class]){
            capture.crashKeyList = [NSArray arrayWithArray:capture.crashKeySet.allObjects];
        }
        
        NSArray *allBlocks = [self->_callbackData allValues];
        for(HMDExceptionCatchBlock callback in allBlocks) {
            callback(capture);
        }
        
        // 处理完一个Capture，则计数递减
        int lock_rst = pthread_mutex_lock(&accessProcessCountMutex);
        currentSerialQueueProcessCount--;
        if (lock_rst == 0) {
            pthread_mutex_unlock(&accessProcessCountMutex);
        }
    });
}

#pragma mark - Private

// 说明: 开启逻辑核心控制函数, 不一定请求什么就开启什么, 根据现在是否已经开启/关闭(忽略这次请求), 是否该protection能开启/关闭(忽略这次请求)
// 参数 changeToPretectionCollection : 必须在 HMDProtectionTypeAll 范围里 由调用它的函数做这个操作
- (void)switchProtectionTo:(HMDProtectionType)changeToPretectionCollection {
    [_protectionControlLock lock];
    [self checkAndSwitchProtectorForType:HMDProtectionTypeUnrecognizedSelector collection:changeToPretectionCollection];
    [self checkAndSwitchProtectorForType:HMDProtectionTypeKVO collection:changeToPretectionCollection];
    [self checkAndSwitchProtectorForType:HMDProtectionTypeKVC collection:changeToPretectionCollection];
    [self checkAndSwitchProtectorForType:HMDProtectionTypeNotification collection:changeToPretectionCollection];
    [self checkAndSwitchProtectorForType:HMDProtectionTypeContainers collection:changeToPretectionCollection];
    [self checkAndSwitchProtectorForType:HMDProtectionTypeUserDefaults collection:changeToPretectionCollection];
    [_protectionControlLock unlock];
}

- (void)checkAndSwitchProtectorForType:(HMDProtectionType)type collection:(NSInteger)collection {
    if((_currentProtectionCollection & type) ^ (collection & type)) {
        // 开启
        if(collection & type) {
            __weak typeof(self) weakSelf = self;
            [self switchProtectorForType:type captureBlock:^(HMDProtectCapture * _Nonnull capture){
                __strong typeof(self) strongSelf = weakSelf;
                capture.protectType = type;
                capture.protectTypeString = [self protectionTypeForOptions:type];
                [strongSelf respondToCapture:capture];
            }];
            
            _currentProtectionCollection = _currentProtectionCollection | type;
        }
        // 关闭
        else {
            if ([self shouldClose:type]) {
                [self switchProtectorForType:type captureBlock:nil];
                _currentProtectionCollection = _currentProtectionCollection & ~type;
            }
        }
    }
}

- (void)switchProtectorForType:(HMDProtectionType)type captureBlock:(HMDProtectCaptureBlock)captureBlock {
    switch (type) {
        case HMDProtectionTypeUnrecognizedSelector:
            HMD_Protect_toggle_USEL_protection(captureBlock);
            break;
        case HMDProtectionTypeContainers:
            HMD_Protect_toggle_Container_protection(captureBlock);
            break;
        case HMDProtectionTypeNotification:
            HMD_Protect_toggle_Notification_protection(captureBlock);
            break;
        case HMDProtectionTypeKVO:
            HMD_Protect_toggle_KVO_protection(captureBlock);
            break;
        case HMDProtectionTypeKVC:
            HMD_Protect_toggle_KVC_protection(captureBlock);
            break;
        case HMDProtectionTypeUserDefaults:
            HMD_Protect_toggle_UserDefaults_protection(captureBlock);
            break;
        default:
            NSAssert(NO, @"[FATAL ERROR] Please preserve current environment"
                          " and contact Heimdallr developer ASAP.");
            break;
    }
}

- (BOOL)shouldClose:(HMDProtectionType)type {
    // Notification、KVO是通过中间对象桥接来实现野指针，存在启动间历史遗留问题，一旦开启当次启动无法关闭
    // 原理依赖OC方法交换都不允许一次运行期间从开到关，可能有死循环的风险
    return NO;
}

- (NSString *)protectionTypeForOptions:(HMDProtectionType)type {
    switch (type) {
        case HMDProtectionTypeUnrecognizedSelector:
            return @"UnSelector";
        case HMDProtectionTypeContainers:
            return @"Container";
        case HMDProtectionTypeNotification:
            return @"Notification";
        case HMDProtectionTypeKVO:
            return @"KVO";
        case HMDProtectionTypeKVC:
            return @"KVC";
        case HMDProtectionTypeUserDefaults:
            return @"UserDefaults";
        default:
            return @"Unknown";
    }
}

@end
