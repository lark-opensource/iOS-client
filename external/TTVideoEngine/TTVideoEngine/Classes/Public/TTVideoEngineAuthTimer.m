//
//  AuthTimer.m
//  Pods
//
//  Created by wyf on 2018/11/13.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineAuthTimer.h"
#import "TTVideoEngine.h"
#import "TTVideoEngineKeys.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineUtilPrivate.h"
#import "NSTimer+TTVideoEngine.h"

static NSString * const PATTERN_HTTP_DATE = @"EEE, dd MMM yyy hh:mm:ss";
static NSString * const PATTERN_STS_EXPIRED_TIME = @"yyyy-MM-dd'T'HH:mm:ssZZZZ";
static long long const TIMEOUT_UPDATE_THRESHOLD_SEC = 10*60;

@implementation TTVideoEngineTimeCalibration
- (long long)getServerTime {
    if (_isCalibrated) {
        NSDate *nowDate = [NSDate date];
        long long nowTime = [[NSNumber numberWithDouble:nowDate.timeIntervalSince1970] longLongValue];
        return nowTime - _localTimeToCali + _serverTimeToCali;
    } else {
        return -1;
    }
}
- (NSString *)getServerTimeStr:(NSString *)pattern {
    NSDate *date = nil;
    long long curTime = [self getServerTime];
    if (curTime == -1) {
        date = [NSDate date];
    } else {
        date = [NSDate dateWithTimeIntervalSince1970:curTime];
    }
    if (self.dateFormatter == nil) {
        self.dateFormatter = [NSDateFormatter new];
    }
    self.dateFormatter.dateFormat = pattern;
    
    return [self.dateFormatter stringFromDate:date];
}
- (void)updateServerTime:(long long)STToCali localTime:(long long)LTToCali {
    if (STToCali <= 0) {
        return;
    }
    self.serverTimeToCali = STToCali;
    self.localTimeToCali = LTToCali;
    self.isCalibrated = YES;
}
@end


@implementation TTVideoEngineSTSAuth
- (instancetype)initWithSTS:(NSString *)ak sk:(NSString *)sk sessionToken:(NSString *)sessionToken expiredTime:(NSString *)expiredTime curTime:(NSString *)curTime {
    _authAK = ak;
    _authSK = sk;
    _authSessionToken = sessionToken;
    _authExpiredTime = expiredTime;
    _authExpiredTimeInLong = [TTVideoEngineAuthTimer getSeconds:expiredTime Pattern:PATTERN_STS_EXPIRED_TIME];
    _curServerTime = curTime;
    _curServerTimeInLong = [TTVideoEngineAuthTimer getSeconds:curTime Pattern:PATTERN_STS_EXPIRED_TIME];
    
    NSTimeInterval nowtime = [[NSDate date] timeIntervalSince1970];
    _curLocalTimeInLong = [[NSNumber numberWithDouble:nowtime] longLongValue];
    return self;
}
- (long long)getServerTime {
    if (_curServerTimeInLong > 0) {
        NSTimeInterval nowtime = [[NSDate date] timeIntervalSince1970];
        return [[NSNumber numberWithDouble:nowtime] longLongValue] - _curLocalTimeInLong + _curServerTimeInLong;
    }
    return -1;
}
- (NSString *)toString {
    NSDictionary *stsDic = [NSDictionary dictionaryWithObjectsAndKeys:_authAK,TTVIDEOENGINE_AUTH_AK, _authSK,TTVIDEOENGINE_AUTH_SK, _authSessionToken,TTVIDEOENGINE_AUTH_SESSIONTOKEN, _authExpiredTime,TTVIDEOENGINE_AUTH_EXPIREDTIME, nil];
    NSData *tmpData = [NSJSONSerialization dataWithJSONObject:stsDic options:0 error:nil];
    return [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
}
@end


@interface TTVideoEngineAuthTimer ()
@property (nonatomic, strong) TTVideoEngineTimeCalibration *timeCalibration;
@property (nonatomic, strong) TTVideoEngineSTSAuth *stsAuth;
@property (nonatomic, strong) NSRunLoop *currentRunLoop;
@property (nonatomic, strong) NSMutableDictionary *stsAuthDic;
@property (nonatomic, strong) NSMutableDictionary *stsTimerDic;
@property (nonatomic, weak) id <TTVideoEngineAuthTimerProtocol> delegate;
@property (nonatomic, assign) NSInteger continuousExpCount;
@end

@implementation TTVideoEngineAuthTimer

static TTVideoEngineAuthTimer *authTimerInstance;
static NSDateFormatter *dateFormatter;

- (void)dealloc {
    [self cancel];
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        authTimerInstance = [[TTVideoEngineAuthTimer alloc] init];
    });
    return authTimerInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _timeCalibration = [[TTVideoEngineTimeCalibration alloc] init];
        _currentRunLoop = [NSRunLoop currentRunLoop];
        _stsAuthDic = [[NSMutableDictionary alloc] init];
        _stsTimerDic = [[NSMutableDictionary alloc] init];
        _continuousExpCount = 0;
    }
    return self;
}

- (void)setTag:(NSString *)projectTag {
    if (projectTag == nil) {
        return;
    }
    TTVideoRunOnMainQueue(^{
        [self.delegate onAuthExpired:self projectTag:projectTag];
    }, NO);
}

- (void)setAuth:(TTVideoEngineSTSAuth *)stsAuth projectTag:(NSString *)projectTag stopUpdate:(BOOL)stopUpdate {
    if (stsAuth == nil) {
        return;
    }
    @synchronized (self) {
        [_stsAuthDic setObject:stsAuth forKey:projectTag];
        if (stsAuth.curServerTimeInLong > 0) {
            [_timeCalibration updateServerTime:stsAuth.curServerTimeInLong localTime:stsAuth.curLocalTimeInLong];
        }
        if (stopUpdate) {
            return;
        }
        if (stsAuth.authExpiredTimeInLong > 0 && stsAuth.curServerTimeInLong > 0) {
            long long serverTime = [stsAuth getServerTime];
            long long timeToUpdate = stsAuth.authExpiredTimeInLong - serverTime - TIMEOUT_UPDATE_THRESHOLD_SEC;
            if (timeToUpdate <= 0) {
                _continuousExpCount++;
                if (_continuousExpCount > 3) {
                    return;
                }
            } else {
                _continuousExpCount = 0;
            }
            [self postUpdate:projectTag timeToUpdate:timeToUpdate];
        }
    }
}

- (TTVideoEngineSTSAuth *)getAuth:(NSString *)projectTag {
    @synchronized (self) {
        TTVideoEngineSTSAuth *tmpSTSAuth = [_stsAuthDic objectForKey:projectTag];
        if (tmpSTSAuth == nil) {
            [self postUpdate:projectTag timeToUpdate:0];
            return nil;
        }
        if (tmpSTSAuth.authExpiredTimeInLong > 0 && tmpSTSAuth.curServerTime) {
            long long tmpExpiredTime = tmpSTSAuth.authExpiredTimeInLong - [tmpSTSAuth getServerTime];
            if (tmpExpiredTime < (TIMEOUT_UPDATE_THRESHOLD_SEC - 30)) {
                [self postUpdate:projectTag timeToUpdate:0];
            }
        }
        return tmpSTSAuth;
    }
}

- (void)postUpdate:(NSString *)projectTag timeToUpdate:(long long)timeToUpdate {
    NSTimer *timer = [self.stsTimerDic objectForKey:projectTag];
    if (timer != nil && [timer isValid]) {
        [timer invalidate];
    }
    
    
    timer = [NSTimer ttvideoengine_scheduledNoRetainTimerWithTimeInterval:timeToUpdate/1000 target:self selector:@selector(notifyUpdate:) userInfo:projectTag repeats:NO];
    [self.currentRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)notifyUpdate:(NSTimer *)inTimer {
    NSString *projectTag = [inTimer userInfo];
    [self.delegate onAuthExpired:self projectTag:projectTag];
}

- (void)cancel {
    @synchronized (self) {
        for (NSString *key in self.stsTimerDic) {
            [[self.stsTimerDic objectForKey:key] invalidate];
        }
    }
}

- (void)setAuthTimerListener:(id <TTVideoEngineAuthTimerProtocol>)delegate {
    self.delegate = delegate;
}

+ (long long)getSeconds:(NSString *)timeStr Pattern:(NSString *)pattern {
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
    }
    dateFormatter.dateFormat = pattern;
    NSDate *tempDate = [dateFormatter dateFromString:timeStr];
    NSTimeInterval tempTime = tempDate.timeIntervalSince1970;
    return [[NSNumber numberWithDouble:tempTime] longLongValue];
}

@end
