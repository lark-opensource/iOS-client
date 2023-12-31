//
//  HMDSessionTracker.m
//  Heimdallr
//
//  Created by fengyadong on 2018/2/8.
//

#import "HMDSessionTracker.h"
#import "HMDRecordStore.h"
#import "HMDRecordStoreObject.h"
#import "HMDDiskUsage.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
#import "HMDStoreIMP.h"
#import "HMDInjectedInfo.h"
#import "HeimdallrUtilities.h"
#import "HMDALogProtocol.h"
#include <stdatomic.h>
#import "HMDGCD.h"
#import "NSArray+HMDSafe.h"


#import "HMDUploadHelper.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDNetworkHelper.h"
#import "HMDFileTool.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString *kHMDDefaultSessionID;     // eternal sessionID during the lifetime of current application launch

NSString * const kHMDApplicationSessionIDDidChange = @"HMDApplicationSessionIDDidChange";

static NSString *const kLastTimeEternalSessionIDFileName = @"Heimdallr_LastTimeEternalSessionID";

@interface HMDSessionTracker ()<HMDApplicationSessionUpdate> {
    CFTimeInterval _startTimestamp;
}
@property (atomic, strong) HMDApplicationSession *currentSession;
@property (atomic, strong) NSDictionary *lastestSessionDicAtLastLaunch;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) dispatch_queue_t outdateQueryQueue;
@property (atomic, assign, readwrite) BOOL isRunning;
@property (nonatomic, strong, readwrite) HMDRecordStore *store;

@property (nonatomic, assign) NSTimeInterval lastUpdateTime; // 记录最近一次cache的时间
@property (nonatomic, strong) NSArray *cacheSessionsTimestamp; // 缓存数据库中取出的session timestamp
@end

@interface HMDApplicationSession (Private)
@property (atomic, readwrite) NSString *eternalSessionID;
@end

@implementation HMDSessionTracker

// current session对应的sessionID(业务方未传入时)
- (NSString *)eternalSessionID {
    return kHMDDefaultSessionID;
}

// 读取上次APP启动的EternalSessionID
- (NSString * _Nullable)lastTimeEternalSessionID {
    static NSString *lastTimeEternalSessionID;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *lastTimeEternalSessionIDFilePath = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:kLastTimeEternalSessionIDFileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:lastTimeEternalSessionIDFilePath]) {
            lastTimeEternalSessionID = [NSString stringWithContentsOfFile:lastTimeEternalSessionIDFilePath encoding:NSUTF8StringEncoding error:nil];
        }
    });
    return lastTimeEternalSessionID;
}

+ (void)initialize {
    if (self == [HMDSessionTracker class]) {
        kHMDDefaultSessionID = [[NSUUID UUID] UUIDString];
    }
}

+ (instancetype)sharedInstance {
    static HMDSessionTracker* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDSessionTracker alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.currentSession = [[HMDApplicationSession alloc] init];
        self.currentSession.sessionID = [HMDInjectedInfo defaultInfo].sessionID ?: kHMDDefaultSessionID;
        self.currentSession.eternalSessionID = [self eternalSessionID];
        self.currentSession.delegate = self;
        
        self.sessionQueue = dispatch_queue_create("com.hmd.heimdallr.session", DISPATCH_QUEUE_SERIAL);
        self.outdateQueryQueue = dispatch_queue_create("com.hmd.heimdallr.session.outdate", DISPATCH_QUEUE_SERIAL);
        if (!hermas_enabled()) {
            self.store = [HMDRecordStore shared];
        }
        
        // setup:isruning标志为TRUE；将currentsession写入文件
        [self setup];
        
        // 将APP启动的enternalSessionID写入文件
        [self updateLastTimeEternalSessionIDFile];
        
        if (!_startTimestamp) {
            _startTimestamp = [[NSDate date] timeIntervalSince1970];
        }
        
        [self addObserverForInjectedInfo];
    }
    
    return self;
}

- (void)updateLastTimeEternalSessionIDFile{
    [self lastTimeEternalSessionID]; // 读取lastTimeEternalSessionID
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 更新lastTimeEternalSessionID
        NSString *lastTimeEternalSessionIDFilePath = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:kLastTimeEternalSessionIDFileName];
        [self.currentSession.eternalSessionID writeToFile:lastTimeEternalSessionIDFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    });
}

- (void)addObserverForInjectedInfo {
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"sessionID"
                                       options:0
                                       context:nil];
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"userID"
                                       options:0
                                       context:nil];
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"userName"
                                       options:0
                                       context:nil];
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"email"
                                       options:0
                                       context:nil];
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"filters"
                                       options:0
                                       context:nil];
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"customContext"
                                       options:0
                                       context:nil];
}

- (void)dealloc {
    [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"sessionID"];
    [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"userID"];
    [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"userName"];
    [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"email"];
    [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"filters"];
    [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"customContext"];
}

+ (HMDApplicationSession *)currentSession {
    return [HMDSessionTracker sharedInstance].currentSession;
}

+ (NSString *)rootPath {
    NSString *heimdallrPath  = [HeimdallrUtilities heimdallrRootPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:heimdallrPath]) {
        hmdCheckAndCreateDirectory(heimdallrPath);
    }
    return [NSString stringWithFormat:@"%@/hermas", heimdallrPath];
}

- (CFTimeInterval) startTimetag {
    return self.currentSession.timestamp;
}

- (void)setup {
    self.isRunning = YES;
    
    if (hermas_enabled()) {
        [HMDSessionTracker latestSessionDicAtLastLaunch];
        [self recordSession:self.currentSession sessionIDChanged:NO isSetUp:YES];
    } else {
        [self recordSession:self.currentSession sessionIDChanged:NO];
    }
    
}

- (void)recordSession:(HMDApplicationSession *)session sessionIDChanged:(BOOL)isChanged isSetUp:(BOOL)isSetUp {
    NSString *sessionID;
    if(isChanged) sessionID = [HMDInjectedInfo defaultInfo].sessionID;
    
    NSTimeInterval time = NSDate.date.timeIntervalSince1970;
    
    hmd_safe_dispatch_async(self.sessionQueue, ^{
        HMDApplicationSession *session = self.currentSession;
        if(isChanged && sessionID != nil)
            session.sessionID = sessionID;
        if (isSetUp) {
            session.timestamp = time;
            double freeDisk = [HMDDiskUsage getFreeDiskSpace]/HMD_MB;
            session.freeDisk = freeDisk;
            NSMutableDictionary *custom = [NSMutableDictionary dictionaryWithCapacity:3];
            [custom setValue:[HMDInjectedInfo defaultInfo].userID forKey:@"user_id"];
            [custom setValue:[HMDInjectedInfo defaultInfo].scopedUserID forKey:@"scoped_user_id"];
            [custom setValue:[HMDInjectedInfo defaultInfo].userName forKey:@"user_name"];
            [custom setValue:[HMDInjectedInfo defaultInfo].email forKey:@"email"];
            [custom addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].customContext];
            session.customParams = custom;
            session.filters = [HMDInjectedInfo defaultInfo].filters;
        }
        if (hermas_enabled()) {
            [[HMEngine sharedEngine] updateSessionRecordWith:[session dictionaryValue]];
        } else {
            [self.store.database insertObject:session into:[HMDApplicationSession tableName]];
        }
        if(isChanged && sessionID != nil)
            [[NSNotificationCenter defaultCenter] postNotificationName:kHMDSessionIDChangeNotification object:self];
    });
}

- (void)didUpdateWithSessionDic:(NSDictionary *)sessionDic {
    if (!sessionDic || !self.isRunning) {
        return;
    }
    
    hmd_safe_dispatch_async(self.sessionQueue, ^{
        [[HMEngine sharedEngine] updateSessionRecordWith:sessionDic];
    });
}


#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"sessionID"]) {
        [self recordSession:self.currentSession sessionIDChanged:YES isSetUp:NO];
    }
    else if([keyPath isEqualToString:@"filters"]) {
        hmd_safe_dispatch_async(self.sessionQueue, ^{
            self.currentSession.filters = [HMDInjectedInfo defaultInfo].filters;
        });
    }
    else  {
        hmd_safe_dispatch_async(self.sessionQueue, ^{
            NSMutableDictionary *custom = [NSMutableDictionary dictionaryWithCapacity:3];
            [custom setValue:[HMDInjectedInfo defaultInfo].userID forKey:@"user_id"];
            [custom setValue:[HMDInjectedInfo defaultInfo].scopedUserID forKey:@"scoped_user_id"];
            [custom setValue:[HMDInjectedInfo defaultInfo].userName forKey:@"user_name"];
            [custom setValue:[HMDInjectedInfo defaultInfo].email forKey:@"email"];
            [custom addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].customContext];
            self.currentSession.customParams = custom;
        });
    }
}

# pragma todo deprecated
+ (HMDApplicationSession *)latestSessionAtLastLaunch {
    static HMDApplicationSession *latestSession = nil;
    static atomic_flag onceToken;
    
    if (!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        NSString *eternalSessionID = [[self sharedInstance] lastTimeEternalSessionID];
        if (eternalSessionID) {
            HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
            condition.key = @"eternalSessionID";
            condition.stringValue = eternalSessionID;
            condition.judgeType = HMDConditionJudgeEqual;

            NSArray<HMDApplicationSession *> *sessions =
                [[HMDRecordStore shared].database
                    getObjectsWithTableName:[HMDApplicationSession tableName]
                                      class:[HMDApplicationSession class]
                              andConditions:@[condition]
                               orConditions:nil
                           orderingProperty:@"localID"
                               orderingType:HMDOrderDescending];

            if (sessions != nil && sessions.count > 0)
                latestSession = sessions.firstObject;
        }
    }
    
    return latestSession;
}

+ (NSDictionary *)latestSessionDicAtLastLaunch {
    if (hermas_enabled()) {
        static NSDictionary *latestSessionDic;
        static atomic_flag onceToken;
        if (!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
            latestSessionDic = [[HMEngine sharedEngine] getLatestSession:[self rootPath]];
        }
        return latestSessionDic;
    } else {
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
        CLANG_DIAGNOSTIC_PUSH
        CLANG_DIAGNOSTIC_IGNORE_DEPRECATED_DECLARATIONS
        HMDApplicationSession *latestSession = [HMDSessionTracker latestSessionAtLastLaunch];
        CLANG_DIAGNOSTIC_POP
        [dataValue setValue:@(latestSession.memoryUsage) forKey:@"memory_usage"];
        NSInteger freeDiskBlockSize = ceil(latestSession.freeDisk / 300);
        [dataValue setValue:@(freeDiskBlockSize) forKey:@"d_zoom_free"];
        [dataValue setValue:@(hmd_calculateMemorySizeLevel(((uint64_t)latestSession.freeMemory)*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
        
        if(latestSession.sessionID != nil) [dataValue setValue:latestSession.sessionID forKey:@"session_id"];
        else [dataValue setValue:@"" forKey:@"session_id"];
        
        if(latestSession.eternalSessionID != nil) [dataValue setValue:latestSession.eternalSessionID forKey:@"internal_session_id"];
        else [dataValue setValue:@"" forKey:@"internal_session_id"];
        
        [dataValue setValue:@(latestSession.timestamp) forKey:@"timestamp"];///原始数据，单位为秒
        [dataValue setValue:@(latestSession.duration) forKey:@"duration"];
        [dataValue setValue:latestSession.filters forKey:@"filters"];
        return [dataValue copy];
    }
}

- (void)recordSession:(HMDApplicationSession *)session sessionIDChanged:(BOOL)isChanged {
    NSString *sessionID;
    if(isChanged) sessionID = [HMDInjectedInfo defaultInfo].sessionID;
    
    NSTimeInterval time = NSDate.date.timeIntervalSince1970;
    
    hmd_safe_dispatch_async(self.sessionQueue, ^{
        HMDApplicationSession *session = self.currentSession;
        if(isChanged && sessionID != nil)
            session.sessionID = sessionID;
        session.timestamp = time;
        double freeDisk = [HMDDiskUsage getFreeDiskSpace]/HMD_MB;
        session.freeDisk = freeDisk;
        NSMutableDictionary *custom = [NSMutableDictionary dictionaryWithCapacity:3];
        [custom setValue:[HMDInjectedInfo defaultInfo].userID forKey:@"user_id"];
        [custom setValue:[HMDInjectedInfo defaultInfo].scopedUserID forKey:@"scoped_user_id"];
        [custom setValue:[HMDInjectedInfo defaultInfo].userName forKey:@"user_name"];
        [custom setValue:[HMDInjectedInfo defaultInfo].email forKey:@"email"];
        [custom addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].customContext];
        session.customParams = custom;
        session.filters = [HMDInjectedInfo defaultInfo].filters;
        [self.store.database insertObject:session into:[HMDApplicationSession tableName]];
        if(isChanged && sessionID != nil)
            [[NSNotificationCenter defaultCenter] postNotificationName:kHMDSessionIDChangeNotification object:self];
    });
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDApplicationSession class];
}

- (void)cleanupWithAndConditons:(NSArray<HMDStoreCondition *> *)andCondtions {
    [self cleanupWithAndConditions:andCondtions];
}

-(void)cleanupWithAndConditions:(NSArray<HMDStoreCondition *> *)andCondtions {
    // 当第一次 Heimdallr 拉不到配置时 会在 HMDConfigManager.config 就为空了
    // 所以 HMDConfigManager.config.cleanupConfig 就是空的
    if (andCondtions.count > 0) {
        NSString *tableName = [self.storeClass tableName];
        [self.store.database deleteObjectsFromTable:tableName
                                                     andConditions:andCondtions
                                                      orConditions:nil];
    } else {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDSessionTracker cleanup andCondtions cannot be nil!");
    }
}

- (BOOL)needStartupImmediatelly {
    return YES;
}

- (void)outdateSessionTimestampWithMaxCount:(NSInteger)maxCount interval:(NSTimeInterval)interval complete:(void(^)(NSTimeInterval))complete {
    if (!complete) {
        return;
    }
    
    hmd_safe_dispatch_async(self.outdateQueryQueue, ^{
        @autoreleasepool {
            NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
            // 使用老数据
            NSTimeInterval outdate = 0.f;
            if (currentTime - self.lastUpdateTime < interval) {
                if(self.cacheSessionsTimestamp.count > maxCount) {
                    NSInteger index = self.cacheSessionsTimestamp.count - maxCount - 1;
                    outdate = [[self.cacheSessionsTimestamp hmd_objectAtIndex:index] doubleValue];
                }
                complete(outdate);
                return;
            }
            // 更新数据
            self.lastUpdateTime = currentTime;
            NSArray<HMDApplicationSession *> *allSessions = [self getSessionsInAscendingOrder];
            NSMutableArray *timestampM = [NSMutableArray array];
            [allSessions enumerateObjectsUsingBlock:^(HMDApplicationSession * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [timestampM hmd_addObject:@(obj.timestamp)];
            }];
            self.cacheSessionsTimestamp = timestampM.copy;
            if(self.cacheSessionsTimestamp.count > maxCount) {
                NSInteger index = self.cacheSessionsTimestamp.count - maxCount - 1;
                outdate = [[self.cacheSessionsTimestamp hmd_objectAtIndex:index] doubleValue];
            }
            complete(outdate);
            return;
        }
    });
}

#pragma mark - HMDApplicationSessionUpdate-todo deprecated
- (void)didUpdateForProperty:(NSString *)property {
    if (!property || !self.isRunning)  return;
    
    hmd_safe_dispatch_async(self.sessionQueue, ^{
        HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
        condition.stringValue = self.currentSession.sessionID;
        condition.judgeType = HMDConditionJudgeEqual;
        condition.key = @"sessionID";
        
        [self.store.database updateRowsInTable:[HMDApplicationSession tableName]
                                        onProperty:property
                                     propertyValue:[self.currentSession valueForKey:property]
                                        withObject:self.currentSession
                                     andConditions:@[condition]
                                      orConditions:nil];
    });
}

#pragma mark Query-tode deprecated
- (NSArray<HMDApplicationSession*>*)getSessionsInAscendingOrder {
    return [self.store.database getObjectsWithTableName:[self.storeClass tableName]
                                                      class:self.storeClass
                                              andConditions:nil
                                               orConditions:nil
                                           orderingProperty:@"localID"
                                               orderingType:HMDOrderAscending];
}

@end
