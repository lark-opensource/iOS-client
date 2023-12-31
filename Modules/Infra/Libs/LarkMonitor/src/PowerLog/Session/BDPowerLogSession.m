//
//  BDPowerLogSession.m
//  Jato
//
//  Created by yuanzhangjing on 2022/7/26.
//

#import "BDPowerLogSession.h"
#import "BDPowerLogSession+Private.h"
#import "BDPowerLogUtility.h"
#import "BDPowerLogManager+Private.h"
#import "BDPowerLogInternalSession.h"
#import <zlib.h>
typedef enum : NSUInteger {
    BDPowerLogSessionStateNone = 0,
    BDPowerLogSessionStateBegin,
    BDPowerLogSessionStateEnd,
    BDPowerLogSessionStateDrop,
} BDPowerLogSessionState;

@interface BDPowerLogSession()
{
    long long _begin_ts;
    long long _end_ts;
    long long _begin_sys_ts;
    long long _end_sys_ts;
    BDPowerLogSessionState _state;
    NSString *_sessionID;
    NSMutableDictionary *_customFilters;
    NSLock *_filtersLock;
    NSLock *_internalSessionLock;
    BDPowerLogInternalSession *_internalSession;
    dispatch_source_t _timer;
    NSLock *_timerLock;
}
@property(nonatomic,copy,readwrite) NSString *sessionName;
@property (nonatomic,weak) id<BDPowerLogInternalSessionDelegate> delegate;
@property(nonatomic, copy, readwrite) BDPowerLogSessionConfig *config;
@end
@implementation BDPowerLogSession

- (instancetype)init {
    if (self = [super init]) {
        _config = [[BDPowerLogSessionConfig alloc] init];
        _state = BDPowerLogSessionStateNone;
        _sessionID = [[NSUUID UUID] UUIDString];
        _customFilters = [NSMutableDictionary dictionary];
        _filtersLock = [[NSLock alloc] init];
        _internalSessionLock = [[NSLock alloc] init];
        _timerLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)setAutoUpload:(BOOL)autoUpload {
    _config.autoUpload = autoUpload;
}

- (BOOL)autoUpload {
    return _config.autoUpload;
}

- (void)setIgnoreBackground:(BOOL)ignoreBackground {
    _config.ignoreBackground = ignoreBackground;
}

- (BOOL)ignoreBackground {
    return _config.ignoreBackground;
}

- (void)setUploadWhenAppStateChanged:(BOOL)uploadWhenAppStateChanged {
    _config.uploadWhenAppStateChanged = uploadWhenAppStateChanged;
}

- (BOOL)uploadWhenAppStateChanged {
    return _config.uploadWhenAppStateChanged;
}

- (void)setUploadWithExtraData:(BOOL)uploadWithExtraData {
    _config.uploadWithExtraData = uploadWithExtraData;
}

- (BOOL)uploadWithExtraData {
    return _config.uploadWithExtraData;
}

- (instancetype)initWithName:(NSString *)name {
    if (self = [self init]) {
        self.sessionName = name;
    }
    return self;
}

+ (instancetype)sessionWithName:(NSString *)name {
    return [[BDPowerLogSession alloc] initWithName:name];
}

- (BDPowerLogInternalSession *)internalSessionWithLock {
    [_internalSessionLock lock];
    BDPowerLogInternalSession *internalSession = _internalSession;
    [_internalSessionLock unlock];
    return internalSession;
}

- (void)addCustomEvent:(NSDictionary *)event {
    [[self internalSessionWithLock] addCustomEvent:event];
    BDPowerLogInfo(@"add custom event %@",event);
}

- (void)beginEvent:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (params) {
        [dict addEntriesFromDictionary:params];
    }
    [dict setValue:@"begin" forKey:@"state"];
    [self addEvent:event params:dict];
}

- (void)endEvent:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (params) {
        [dict addEntriesFromDictionary:params];
    }
    [dict setValue:@"end" forKey:@"state"];
    [self addEvent:event params:dict];
}

- (void)addEvent:(NSString *)eventName params:(NSDictionary *)params {
    [[self internalSessionWithLock] addEvent:eventName params:params];
    BDPowerLogInfo(@"add custom event %@ %@",eventName, params);
}

- (void)addCustomFilter:(NSDictionary *)filter {
    [_filtersLock lock];
    [filter enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isKindOfClass:NSString.class] &&
            ([obj isKindOfClass:NSNumber.class] || [obj isKindOfClass:NSString.class])) {
            [_customFilters setValue:obj forKey:key];
        } else {
            NSAssert(NO, @"filter is not valid key:%@ value:%@",key,obj);
        }
    }];
    [_filtersLock unlock];
    BDPowerLogInfo(@"add custom filter %@",filter);
}

- (void)removeCustomFilter:(NSString *)key {
    if (key) {
        [_filtersLock lock];
        [_customFilters removeObjectForKey:key];
        [_filtersLock unlock];
        BDPowerLogInfo(@"remove custom filter for key : %@",key);
    }
}

- (void)startInternalSession {
    [_internalSessionLock lock];
    
    BDPowerLogInternalSession *endSession = nil;
    BDPowerLogInternalSession *session = self->_internalSession;
    int state = [session state];
    if (session && state == BDPowerLogSessionStateNone) {
        [session begin];
    } else {
        if (state == BDPowerLogSessionStateBegin) {
            [session end];
            [self upload:session];
            endSession = session;
        }
        session = [[BDPowerLogInternalSession alloc] init];
        [session begin];
        self->_internalSession = session;
    }
    
    [_internalSessionLock unlock];
    
    [self startTimer];

    if (endSession && self.delegate) {
        [self.delegate internalSessionDidEnd:self internalSession:endSession];
    }

    if (session && self.delegate) {
        [self.delegate internalSessionDidStart:self internalSession:session];
    }
}

- (void)stopInternalSession {
    [_internalSessionLock lock];
    BDPowerLogInternalSession *session = self->_internalSession;
    int state = [session state];
    if (session && state == BDPowerLogSessionStateBegin) {
        [session end];
        [self upload:session];
    }
    self->_internalSession = nil;
    [_internalSessionLock unlock];

    if (session && self.delegate) {
        [self.delegate internalSessionDidEnd:self internalSession:session];
    }
    
    [self stopTimer];
}

- (void)dropInternalSession {
    [_internalSessionLock lock];
    BDPowerLogInternalSession *session = self->_internalSession;
    self->_internalSession = nil;
    [_internalSessionLock unlock];

    if (session && self.delegate) {
        [self.delegate internalSessionDidEnd:self internalSession:session];
    }
    
    [self stopTimer];
}


- (void)startTimer {
    [self stopTimer];
    [_timerLock lock];
    self->_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_timer(self->_timer, dispatch_time(DISPATCH_TIME_NOW, BD_POWERLOG_SESSION_MAX_TIME * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0);
    dispatch_source_set_event_handler(self->_timer, ^{
        [self startInternalSession];
    });
    dispatch_resume(self->_timer);
    [_timerLock unlock];
}

- (void)stopTimer {
    [_timerLock lock];
    if (self->_timer) {
        dispatch_cancel(self->_timer);
        self->_timer = NULL;
    }
    [_timerLock unlock];
}

- (void)begin {
    if (_state != BDPowerLogSessionStateNone) {
        NSAssert(NO, @"session state is not 0, state = %lu",(unsigned long)_state);
        return;
    }
    _state = BDPowerLogSessionStateBegin;
    _begin_ts = bd_powerlog_current_ts();
    _begin_sys_ts = bd_powerlog_current_sys_ts();
    [self startInternalSession];
    
    BDPowerLogInfo(@"%@ session begin",self.sessionName);
}

- (void)end {
    if (_state != BDPowerLogSessionStateBegin) {
        NSAssert(NO, @"session state is not 1, state = %lu",(unsigned long)_state);
        return;
    }
    _state = BDPowerLogSessionStateEnd;
    _end_ts = bd_powerlog_current_ts();
    _end_sys_ts = bd_powerlog_current_sys_ts();
    [self stopInternalSession];
    
    BDPowerLogInfo(@"%@ session end",self.sessionName);
}

- (void)drop {
    if (_state != BDPowerLogSessionStateBegin) {
        NSAssert(NO, @"session state is not 1, state = %lu",(unsigned long)_state);
        return;
    }
    _state = BDPowerLogSessionStateDrop;
    _end_ts = bd_powerlog_current_ts();
    _end_sys_ts = bd_powerlog_current_sys_ts();
    [self dropInternalSession];
    
    BDPowerLogInfo(@"%@ session drop",self.sessionName);
}

- (long long)totalTime {
    if (_state == BDPowerLogSessionStateBegin) {
        return bd_powerlog_current_sys_ts() - _begin_sys_ts;
    } else if (_state == BDPowerLogSessionStateEnd || _state == BDPowerLogSessionStateDrop) {
        return _end_sys_ts - _begin_sys_ts;
    } else {
        return 0;
    }
}

- (long long)internalSessionStartSysTime {
    return [[self internalSessionWithLock] beginSysTime];
}

- (void)upload:(BDPowerLogInternalSession *)internalSession {
    if (![BDPowerLogManager isRunning]) {
        return;
    }
    
    [_filtersLock lock];
    NSDictionary *customFilters =  _customFilters.copy;
    [_filtersLock unlock];
    [internalSession generateLogInfo:^(NSDictionary * _Nullable logInfo, NSDictionary * extra) {
        
        NSMutableDictionary *log = [logInfo mutableCopy];
        [log setValue:self->_sessionID forKey:@"parent_session_id"];
        [log setValue:self->_sessionName forKey:@"session_name"];
        
        if (customFilters) {
            [log addEntriesFromDictionary:customFilters];
        }
        
        [log setValue:@(self->_begin_ts) forKey:@"parent_session_start_ts"];
        [log setValue:@(self->_end_ts) forKey:@"parent_session_end_ts"];
                
        long long totalTime = [self totalTime];
        if (totalTime > 0) {
            [log setValue:@(totalTime) forKey:@"parent_session_duration"];
        }
        
        if (self.config.autoUpload) {
            [self _uploadLog:log extra:extra];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (self.logInfoCallback) {
                self.logInfoCallback(log,extra);
            }
        });
    }];
}

- (NSData * _Nullable)gzipData:(NSData *)data
{
    if ([data length] == 0) return data;
    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[data bytes];
    strm.avail_in = (uInt)[data length];
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
    do {
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy: 16384];
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([compressed length] - strm.total_out);
        deflate(&strm, Z_FINISH);
        
    } while (strm.avail_out == 0);
    deflateEnd(&strm);
    [compressed setLength: strm.total_out];
    return [NSData dataWithData:compressed];
}

- (void)_uploadLog:(NSDictionary *)logInfo extra:(NSDictionary *)extra {
    if(!self.config.uploadWithExtraData) {
        extra = nil;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            NSDictionary *uploadExtra = nil;
            if (extra != nil) {
                NSData *extraData = [NSJSONSerialization dataWithJSONObject:extra options:0 error:nil];
                NSData *extraGzipData = [self gzipData:extraData];
                NSString *extraBase64String = [extraGzipData base64EncodedStringWithOptions:0];
                if (extraBase64String.length > 0) {
                    uploadExtra = @{@"value":extraBase64String};
                }
                BDPowerLogInfo(@"%@ session upload log : %@ extra size : %.2fKB",self.sessionName,logInfo,extraBase64String.length/1024.0);
            } else {
                BDPowerLogInfo(@"%@ session upload log : %@",self.sessionName,logInfo);
            }
            if ([BDPowerLogManager.delegate respondsToSelector:@selector(uploadLogInfo:extra:)]) {
                [BDPowerLogManager.delegate uploadLogInfo:logInfo extra:uploadExtra];
            }
        } @catch (NSException *exception) {
            BDPowerLogInfo(@"%@ session upload exception %@",self.sessionName,exception);
        } @finally {

        }
    });
}

@end
