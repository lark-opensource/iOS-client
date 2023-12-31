//
//  HMDServerStateChecker.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/6/10.
//

#import "HMDServerStateChecker.h"
#include <stdatomic.h>
// Utility
#import "HMDMacro.h"
#import "HMDUserDefaults.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "pthread_extended.h"
// DeviceInfo
#import "HMDInjectedInfo.h"
// HMDAlogProtocol
#import "HMDALogProtocol.h"
// Network
#import "HMDNetworkManager.h"
#import "HMDNetworkReqModel.h"
#import "HMDUploadHelper.h"
// URLSettings
#import "HMDURLManager.h"
#import "HMDURLSettings.h"

NSString * const HMDDropPerfomanceDataNotification = @"HMDDropPerfomanceDataNotification";
NSString * const HMDDropPerfomanceAllDataNotification = @"HMDDropPerfomanceAllDataNotification";

NSString * const HMDMaxNextAvailableTimeInterval = @"HMDMaxNextAvailableTimeInterval";

static NSTimeInterval const shortDelayTimeUnit = 15.f;      // 短避退 以15秒为单位
static NSTimeInterval const longDelayTimeUnit  = 300.f;     // 长避退 以300秒为单位

static NSTimeInterval maxNextAvailableTimeInterval = -1;

dispatch_queue_t quotaCheckerQueue;

@interface HMDServerStateChecker () <HMDURLProvider>

@end

@implementation HMDServerStateChecker {
    HMDReporter _reporter;
    NSString *_identifierAviaibletime;
    NSString *_identifierServerState;
    NSTimeInterval _nextAviaibleTimeInterval;
    NSUInteger _currentSleepCount;
    NSInteger _currentSleepValueForException;
    NSString *_redirectHost;
    pthread_rwlock_t _rwlock;
    NSTimeInterval _nextQuotaInterval;
    HMDServerState _lastServerState;
    BOOL _dropData;
    BOOL _dropAllData;
    NSString *_aid;
}

- (instancetype)initWithReporter:(HMDReporter)reporter forApp:(NSString *)aid {
    if (self = [super init]) {
        pthread_rwlock_init(&_rwlock, NULL);
        _reporter = reporter;
        _aid = aid;
        _identifierAviaibletime = [NSString stringWithFormat:@"nextAviaibleIntervalKey_%tu_%@", reporter, aid];
        _identifierServerState = [NSString stringWithFormat:@"lastServerStateKey_%tu_%@", reporter, aid];
        NSNumber *interval = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:_identifierAviaibletime];
        NSNumber *lastServerState = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:_identifierServerState];
        if ([interval isKindOfClass:[NSNumber class]]) {
            _nextAviaibleTimeInterval = [interval doubleValue];
        } else {
            _nextAviaibleTimeInterval = -1;
        }
        if ([lastServerState isKindOfClass:[NSNumber class]]) {
            _lastServerState = [lastServerState intValue];
        } else {
            _lastServerState = HMDServerStateUnknown;
        }
        if ((_lastServerState & HMDServerStateDropAllData) == HMDServerStateDropAllData ||
            (_lastServerState & HMDServerStateDropData) == HMDServerStateDropData) {
            if (_nextAviaibleTimeInterval != -1 && [[NSDate date] timeIntervalSince1970] < _nextAviaibleTimeInterval) {
                // quota 状态为 drop all data / drop data时，在长退避周期，客户端不生产数据
                _dropData = YES;
                if ((_lastServerState & HMDServerStateDropAllData) == HMDServerStateDropAllData) {
                    // quota 状态为drop all data时，在长退避周期，客户端删除历史数据
                    _dropAllData = YES;
                }
            }
        }
        
        _currentSleepCount = 0;
        _currentSleepValueForException = -1;
        _redirectHost = nil;
        _nextQuotaInterval = -1;
        
        static dispatch_once_t once_token;
        dispatch_once(&once_token, ^{
            quotaCheckerQueue = dispatch_queue_create("com.heimdallr.QuotaChecker", DISPATCH_QUEUE_SERIAL);
        });
        // 长退避周期结束，此时需要检查quota状态，并更新本地容灾策略
        if (_nextAviaibleTimeInterval != -1 && [[NSDate date] timeIntervalSince1970] >= _nextAviaibleTimeInterval) {
            dispatch_async(quotaCheckerQueue, ^{
                [self _updateStateFromServer];
            });
        }
    }
    return self;
}

+ (instancetype)stateCheckerWithReporter:(HMDReporter)reporter {
    HMDServerStateChecker *checker = [[HMDServerStateChecker alloc] initWithReporter:reporter forApp:[HMDInjectedInfo defaultInfo].appID];
    return checker;
}

+ (instancetype)stateCheckerWithReporter:(HMDReporter)reporter forApp:(NSString *)aid {
    HMDServerStateChecker *checker = [[HMDServerStateChecker alloc] initWithReporter:reporter forApp:aid];
    return checker;
}

- (void)checkIfDegradedwithResponse:(id)maybeDictionary {
    if (HMDIsEmptyDictionary(maybeDictionary)) {
        return;
    }
    NSDictionary *result = [maybeDictionary hmd_dictForKey:@"result"];
    if (result == nil) {
        return;
    }
    NSInteger isCrashed = [result hmd_integerForKey:@"is_crash"];
    NSString *message = [result hmd_stringForKey:@"message"];
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    pthread_rwlock_wrlock(&_rwlock);
    if (isCrashed) {
        _nextAviaibleTimeInterval = currentTime + 30 * 60;
        _currentSleepValueForException = 30;
    } else {
        if (![message isEqualToString:@"success"]) {
            if (_currentSleepValueForException == -1) {
                _nextAviaibleTimeInterval = currentTime + 1 * 60; //休息1分钟
                _currentSleepValueForException = 1;
            } else if (_currentSleepValueForException == 1) {
                _nextAviaibleTimeInterval = currentTime + 5 * 60; //休息5分钟
                _currentSleepValueForException = 5;
            } else if (_currentSleepValueForException == 5) {
                _nextAviaibleTimeInterval = currentTime + 15 * 60; //休息15分钟
                _currentSleepValueForException = 15;
            } else if (_currentSleepValueForException == 15 || _currentSleepValueForException == 30) {
                _nextAviaibleTimeInterval = currentTime + 30 * 60; //休息30分钟
                _currentSleepValueForException = 30;
            }
        } else {
            _nextAviaibleTimeInterval = -1;
            _currentSleepValueForException = -1;
        }
    }
    NSTimeInterval timeToWrite = _nextAviaibleTimeInterval;
    pthread_rwlock_unlock(&_rwlock);
    
    [[HMDUserDefaults standardUserDefaults] setObject:@(timeToWrite) forKey:_identifierAviaibletime];
}

- (HMDServerState)updateStateWithResult:(NSDictionary *)result statusCode:(NSInteger)statusCode {
    NSString *message = [result isKindOfClass:NSDictionary.class] ? [result hmd_stringForKey:@"message"] : @"";
    NSString *redirect = [result isKindOfClass:NSDictionary.class] ? [result hmd_stringForKey:@"redirect"] : @"";
    NSInteger delay = [result isKindOfClass:NSDictionary.class] ? [result hmd_integerForKey:@"delay"] : -1;
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    pthread_rwlock_wrlock(&_rwlock);
    HMDServerState errorCode = HMDServerStateUnknown;
    _dropData = NO; //默认新产生数据不丢弃
    _dropAllData = NO; //默认本地历史数据不丢弃
    
    // 成功
    if (statusCode >= 200 && statusCode <= 299 && [message isEqualToString:@"success"]) {
        _nextAviaibleTimeInterval = -1;
        _currentSleepCount = 0;
        errorCode = HMDServerStateSuccess;
    }
    
    // drop data: 服务端不接收数据；本地不产生数据；长避退策略；退避周期结束时，上报前调用接口check quota状态
    if ([message isEqualToString:@"drop data"]) {
        [self _longAvoidanceStrategyWithCurrentTime:currentTime];
        _dropData = YES;
        errorCode = errorCode | HMDServerStateDropData;
    }
    // drop all data: 服务端不接收数据；本地不产生数据，删除未上传的所有数据；长避退策略；退避周期结束时，上报前调用接口check quota状态
    else if ([message isEqualToString:@"drop all data"]) {
        [self _longAvoidanceStrategyWithCurrentTime:currentTime];
        _dropData = YES;
        _dropAllData = YES;
        errorCode = errorCode | HMDServerStateDropAllData;
    }
    // long escape: 服务端不接收数据；本地数据正常产生及保持；长避退策略；退避周期结束时，上报前调用接口check quota状态
    else if ([message isEqualToString:@"long escape"]) {
        [self _longAvoidanceStrategyWithCurrentTime:currentTime];
        errorCode = errorCode | HMDServerStateLongEscape;
    }
    // 延迟
    else if (delay > 0) {
        _nextAviaibleTimeInterval = currentTime + (double)delay;
        _currentSleepCount = 0;
        errorCode = errorCode | HMDServerStateDelay;
    }
    // 长避退:statusCode == 500-599；退避周期结束时，上报前调用接口check quota状态
    else if (statusCode > 499 && statusCode < 600) {
        [self _longAvoidanceStrategyWithCurrentTime:currentTime];
        errorCode = errorCode | HMDServerStateDelay;
    }
    // 短避退：连接超时等iOS系统网络错误
    // iOS 网络错误码 https://blog.csdn.net/qq_35139935/article/details/53067596
    else if (statusCode < 200 || statusCode > 499 || [message isEqualToString:@"ERR_TTNET_TRAFFIC_CONTROL_DROP"]) {
        [self _shortAvoidanceStrategyWithCurrentTime:currentTime];
        errorCode = errorCode | HMDServerStateDelay;
    }
    
    // 域名重定向
    if (redirect.length) {
        _redirectHost = redirect;
        errorCode = errorCode | HMDServerStateRedirect;
    } else {
        _redirectHost = nil;
    }
    
    _lastServerState = errorCode;
    NSTimeInterval timeToWrite = _nextAviaibleTimeInterval;
    pthread_rwlock_unlock(&_rwlock);
    
    [[HMDUserDefaults standardUserDefaults] setObject:@(timeToWrite) forKey:_identifierAviaibletime];
    [[HMDUserDefaults standardUserDefaults] setObject:@(errorCode) forKey:_identifierServerState];
    
    return errorCode;
}

- (BOOL)isServerAvailable {
    pthread_rwlock_rdlock(&_rwlock);
    NSTimeInterval timeInterval = _nextAviaibleTimeInterval;
    pthread_rwlock_unlock(&_rwlock);
    if (timeInterval != -1 && [[NSDate date] timeIntervalSince1970] < timeInterval) {
        return NO;
    }
    return YES;
}

- (BOOL)dropData {
    pthread_rwlock_rdlock(&_rwlock);
    NSTimeInterval timeInterval = _nextAviaibleTimeInterval;
    BOOL drapData = _dropData;
    pthread_rwlock_unlock(&_rwlock);
    //退避周期结束，查询quota状态，更新容灾策略，此次数据的容灾策略不变(异步操作，可能造成少量数据更新不及时问题)
    if (timeInterval != -1 && [[NSDate date] timeIntervalSince1970] >= timeInterval && [[NSDate date] timeIntervalSince1970] > _nextQuotaInterval) {
        dispatch_async(quotaCheckerQueue, ^{
            [self _updateStateFromServer];
        });
    }
    return drapData;
}

- (BOOL)dropAllData {
    pthread_rwlock_rdlock(&_rwlock);
    NSTimeInterval timeInterval = _nextAviaibleTimeInterval;
    BOOL drapAllData = _dropAllData;
    pthread_rwlock_unlock(&_rwlock);
    //退避周期结束，查询quota状态，更新容灾策略，此次数据的容灾策略不变(异步操作，可能造成少量数据更新不及时问题)
    if (timeInterval != -1 && [[NSDate date] timeIntervalSince1970] >= timeInterval && [[NSDate date] timeIntervalSince1970] > _nextQuotaInterval) {
        dispatch_async(quotaCheckerQueue, ^{
            [self _updateStateFromServer];
        });
    }
    return drapAllData;
}

- (NSString *)redirectHost {
    pthread_rwlock_rdlock(&_rwlock);
    NSString *host = _redirectHost;
    pthread_rwlock_unlock(&_rwlock);
    return host;
}

#pragma - mark Avoidance

- (void)_shortAvoidanceStrategyWithCurrentTime:(NSTimeInterval)currentTime {
    // 30秒起，策略是指数级，2^N次，即 15*2,15*4,15*8,最高到 5分钟（15 * 2^5), 即5次后达到
    if (_currentSleepCount < 5) {
        _currentSleepCount++;
    }
    NSTimeInterval delay = MIN(300.f, ((1 << _currentSleepCount) * shortDelayTimeUnit));
    _nextAviaibleTimeInterval = currentTime + delay;
    //非线程安全，但是只需要一个模糊的退避时间来控制容灾模块的开关
    if (_nextAviaibleTimeInterval > maxNextAvailableTimeInterval) {
        maxNextAvailableTimeInterval = _nextAviaibleTimeInterval;
        [[HMDUserDefaults standardUserDefaults] setObject:@(maxNextAvailableTimeInterval) forKey:HMDMaxNextAvailableTimeInterval];
    }
}

- (void)_longAvoidanceStrategyWithCurrentTime:(NSTimeInterval)currentTime {
    // 5分钟起，倍数级，最高30分钟
    if (_currentSleepCount < 6) {
        _currentSleepCount++;
    }
    _nextAviaibleTimeInterval = currentTime + (double)_currentSleepCount * longDelayTimeUnit;
    //非线程安全，但是只需要一个模糊的退避时间来控制容灾模块的开关
    if (_nextAviaibleTimeInterval > maxNextAvailableTimeInterval) {
        maxNextAvailableTimeInterval = _nextAviaibleTimeInterval;
        [[HMDUserDefaults standardUserDefaults] setObject:@(maxNextAvailableTimeInterval) forKey:HMDMaxNextAvailableTimeInterval];
    }
}

- (void)_updateStateFromServer {
    //防止quota接口频繁请求
    if (_nextQuotaInterval != -1 && [[NSDate date] timeIntervalSince1970] < _nextQuotaInterval){
        return;
    }
    _nextQuotaInterval = [[NSDate date] timeIntervalSince1970] + shortDelayTimeUnit;
    NSString *uploadPath = [self _getReporterURLPath];
    if (!uploadPath) {
#if DEBUG
        NSAssert(NO, @"[heimdallr]You should register upload path for checker!");
#endif
        return;
    }
    NSString *requestURL = [HMDURLManager URLWithProvider:self forAppID:[HMDInjectedInfo defaultInfo].appID];
    if (requestURL == nil) {
        return;
    }
    id maybeDictionary = [HMDInjectedInfo defaultInfo].commonParams;
    if (!HMDIsEmptyDictionary(maybeDictionary)) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[HMDUploadHelper sharedInstance].headerInfo];
        [dic addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].commonParams];
        NSString *queryString = [dic hmd_queryString];
        requestURL = [NSString stringWithFormat:@"%@?%@", requestURL, queryString];
    } else {
        NSString *queryString = [[HMDUploadHelper sharedInstance].headerInfo hmd_queryString];
        
        requestURL = [NSString stringWithFormat:@"%@?%@", requestURL, queryString];
    }
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    [body setObject:@([_aid intValue]) forKey:@"aid"];
    [body setObject:@"iOS" forKey:@"os"];
    [body setObject:uploadPath forKey:@"path"];
    
    NSMutableDictionary * headerDict = [NSMutableDictionary dictionaryWithCapacity:2];
    [headerDict setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerDict setValue:@"application/json" forKey:@"Accept"];
    
    HMDNetworkReqModel *reqModel = [HMDNetworkReqModel new];
    reqModel.requestURL = requestURL;
    reqModel.method = @"POST";
    reqModel.headerField = [headerDict copy];
    reqModel.params = [body copy];
    reqModel.needEcrypt = NO;
    
    [[HMDNetworkManager sharedInstance] asyncRequestWithModel:reqModel callback:^(NSError *error, id maybeDictionary) {
        if([maybeDictionary isKindOfClass:NSDictionary.class]) {
            NSDictionary *result = nil;
            if ((result = [maybeDictionary hmd_dictForKey:@"result"]) != nil) {
                NSString *message;
                if((message = [result hmd_stringForKey:@"message"]) != nil) {
                    if ([message isEqualToString:@"success"]) {
                        NSString *quotaStatus = [result hmd_stringForKey:@"quota_status"];
                        if (quotaStatus != nil) {
                            [self _updateServerCheckerByQuota:quotaStatus];
                            return;
                        }
                    }
                }
            }
        }
        HMD_ALOG_PROTOCOL_ERROR_TAG("Heimdallr", "Request Quota Status API failed.")
    }];
}

-(void)_updateServerCheckerByQuota:(NSString *)state {
    pthread_rwlock_wrlock(&_rwlock);
    // quota状态为“”，表示服务器状态正常，恢复数据生产，结束长退避策略
    if ([state isEqualToString:@""]) {
        _dropData = NO;
        _dropAllData = NO;
        _nextAviaibleTimeInterval = -1;
        _lastServerState = HMDServerStateSuccess;
        _currentSleepCount = 0;
    }
    // quota状态为“drop all data”，本地不生产数据，长退避策略升级
    else if ([state isEqualToString:@"drop all data"]) {
        if ((_lastServerState & HMDServerStateDropAllData) != HMDServerStateDropAllData) {
            //quota状态发生变化，长退避计数清零
            _currentSleepCount = 0;
        }
        _dropData = YES;
        _dropAllData = YES;
        [self _longAvoidanceStrategyWithCurrentTime:[[NSDate date] timeIntervalSince1970]];
        _lastServerState = HMDServerStateDropAllData;
    }
    //quota状态为“long escape”，本地生产数据，保存数据到db(需要防止oom)，长退避策略升级
    else if([state isEqualToString:@"long escape"]) {
        if ((_lastServerState & HMDServerStateLongEscape) != HMDServerStateLongEscape) {
            //quota状态发生变化，长退避计数清零
            _currentSleepCount = 0;
        }
        _dropData = NO;
        _dropAllData = NO;
        [self _longAvoidanceStrategyWithCurrentTime:[[NSDate date] timeIntervalSince1970]];
        _lastServerState = HMDServerStateLongEscape;
    }
    NSTimeInterval timeToWrite = _nextAviaibleTimeInterval;
    HMDServerState errorCode = _lastServerState;
    pthread_rwlock_unlock(&_rwlock);
    [[HMDUserDefaults standardUserDefaults] setObject:@(timeToWrite) forKey:_identifierAviaibletime];
    [[HMDUserDefaults standardUserDefaults] setObject:@(errorCode) forKey:_identifierServerState];
}

- (NSString *)_getReporterURLPath {
    switch (_reporter) {
        case HMDReporterCrash:
            return [HMDURLSettings crashUploadPath];
        case HMDReporterCloudCommandDebugReal:
        case HMDReporterPerformance:
            return [HMDURLSettings performanceUploadPath];
        case HMDReporterOpenTrace:
            return [HMDURLSettings tracingUploadPath];
        case HMDReporterException:
            return [HMDURLSettings exceptionUploadPath];
        case HMDReporterUserException:
            return [HMDURLSettings userExceptionUploadPath];
        case HMDReporterCrashEvent:
            return [HMDURLSettings crashEventUploadPath];
        case HMDReporterALog:
            return [HMDURLSettings fileUploadPath];
        case HMDReporterClassCoverage:
            return [HMDURLSettings classCoverageUploadPath];
        case HMDReporterMemoryGraph:
            return [HMDURLSettings memoryGraphUploadPath];
        case HMDReporterEvilMethod:
            return [HMDURLSettings evilMethodUploadPath];
        case HMDReporterCloudCommandFetchCommand:
            return [HMDURLSettings cloudCommandDownloadPath];
        case HMDReporterCloudCommandUpload:
            return [HMDURLSettings cloudCommandUploadPath];
        default:
            return nil;
    }
    return nil;
}

#pragma mark - HMDURLProvider

- (BOOL)shouldEncrypt {
    return NO;
}

- (NSArray<NSString *> *)URLHostProviderDefaultHosts:(NSString *)appID {
    return [HMDURLSettings configFetchDefaultHosts];
}

- (NSString *)URLPathProviderURLPath:(NSString *)appID {
    return [HMDURLSettings quotaStateCheckPath];
}

@end
