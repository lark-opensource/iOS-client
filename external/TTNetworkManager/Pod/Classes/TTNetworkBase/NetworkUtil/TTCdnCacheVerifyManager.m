#import "TTCdnCacheVerifyManager.h"
#import "TTNetworkManagerMonitorNotifier.h"
#import "TTReqFilterManager.h"
#import "TTNetworkManagerLog.h"
#import "pthread.h"

#define HEADER_VERIFY_KEY           @"x-tt-verify-id"   // header key，Used for server identification and return as is

#define VERIFY_ACCESSIBLE           1
#define VERIFY_SUCCESS              2
#define VERIFY_FAIL                 3

/**
 * Regular matching rules
 */
@interface Regex : NSObject
@property (nonatomic, strong) NSPredicate *predicate;

- (id)initWithPattern:(NSString*) pattern;

@end

@implementation Regex

- (id)initWithPattern:(NSString*) pattern {
    self = [super init];
    
    if (self) {
        self.predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    }
    
    return self;
}
    
- (BOOL)isMatch:(NSURL *)url {
    if ((url == nil) || (url.host == nil) || (self.predicate == nil)) {
        return NO;
    }
    
    NSString *matchStr = url.host;
    
    if (url.path != nil) {
        matchStr = [matchStr stringByAppendingString:url.path];
    }
    @try {
        return [self.predicate evaluateWithObject:matchStr];
    } @catch(NSException *error) {
        LOGD(@"Cdn verify regex error %@", error);
    }
    return NO;
}

@end

@implementation TTCdnCacheVerifyManager {
    BOOL verifyEnabled;
    BOOL isAddFilter;
    NSMutableArray  *verifyRegexMutableArray;
    pthread_rwlock_t verifyRegexLock;
}
    
+ (instancetype)shareInstance {
    static id               singleton = nil;
    static dispatch_once_t  onceToken;
    
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}
    
- (id)init {
    self = [super init];
    
    if (self) {
        verifyEnabled = NO;
        isAddFilter = NO;
        verifyRegexMutableArray = [NSMutableArray array];
        pthread_rwlock_init(&verifyRegexLock, NULL);
    }
    
    return self;
}
    
- (void)onConfigChange  :(BOOL)enabled
        data            :(NSDictionary *)data {
    
    if (enabled) {
        NSMutableArray  *regexMutableArray = [[NSMutableArray alloc] init];
        id              ttnet_response_verify = [data objectForKey:@"ttnet_response_verify"];
        
        if (ttnet_response_verify && [ttnet_response_verify isKindOfClass:[NSArray class]]) {
            for (id regexRule in ((NSArray *)ttnet_response_verify)) {
                if (regexRule && [regexRule isKindOfClass:[NSString class]]) {
                    Regex *regex = [[Regex alloc] initWithPattern:regexRule];
                    [regexMutableArray addObject:regex];
                }
            }
            pthread_rwlock_wrlock(&verifyRegexLock);
            verifyRegexMutableArray = regexMutableArray;
            pthread_rwlock_unlock(&verifyRegexLock);
        }
        
        [self addCdnCacheVerifyRequestFilter];
        verifyEnabled = YES;
    } else {
        verifyEnabled = NO;
    }
}
    
- (BOOL)filterRule:(NSURL *)url {
    @try {
        pthread_rwlock_rdlock(&verifyRegexLock);
        for (Regex *regex in verifyRegexMutableArray) {
            if ([regex isMatch:url]) {
                return YES;
            }
        }
    } @finally {
        pthread_rwlock_unlock(&verifyRegexLock);
    }
    return NO;
}

- (void)addCdnCacheVerifyRequestFilter {
    @synchronized (self) {
        if (!isAddFilter) {
            isAddFilter = YES;
            
            BOOL rv = [[TTReqFilterManager shareInstance] addRequestFilterObject:[[TTRequestFilterObject alloc] initWithName:@"cdncache" requestFilterBlock:[self generateVerifyRequestFilterBlock]]];
            if (!rv) LOGE(@"cdncache addRequestFilterObject failed");
            
            rv = [[TTReqFilterManager shareInstance] addResponseChainFilterObject:[[TTResponseChainFilterObject alloc] initWithName:@"cdncache" responseChainFilterBlock:[self generateVerifyResponseChainFilterBlock]]];
            if (!rv) LOGE(@"cdncache addResponseChainFilterObject failed");
        }
    }
}
   
- (RequestFilterBlock)generateVerifyRequestFilterBlock {
    return ^(TTHttpRequest *request) {
        
        if (![self isVerifyEnabled]) {
            return;
        }
        
        if ([self filterRule:request.URL]) {
            [request setValue:[self generateVerifyValue] forHTTPHeaderField:HEADER_VERIFY_KEY];
        }
    };
}

/**
 *  Generate verify value
 */
- (NSString *)generateVerifyValue {
    return [[NSUUID UUID] UUIDString];;
}
    
- (ResponseChainFilterBlock)generateVerifyResponseChainFilterBlock {
    return ^(TTHttpRequest *request, TTHttpResponse *response, id data, NSError **responseError) {
        if (![self isVerifyEnabled]) {
            return;
        }
        
        if ((*responseError) == nil) {
            
            NSString *reqValue = [request valueForHTTPHeaderField:HEADER_VERIFY_KEY];
            
            if (reqValue != nil) {
                NSInteger    cdnVerifyValue;
                NSString     *rspValue = response.allHeaderFields[HEADER_VERIFY_KEY];
                
                if (rspValue == nil) {
                    cdnVerifyValue = VERIFY_ACCESSIBLE;
                } else if ([reqValue isEqualToString:rspValue]) {
                    cdnVerifyValue = VERIFY_SUCCESS;
                } else {
                    cdnVerifyValue = VERIFY_FAIL;
                    *responseError = [NSError errorWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeCdnCache userInfo:nil];
                }
                
                NSError *errorState = [NSError errorWithDomain:kTTNetworkErrorDomain code:cdnVerifyValue userInfo:nil];
                [[TTNetworkManagerMonitorNotifier defaultNotifier]
                 notifyCdnCacheVerifyResponse:response
                 forRequest  :request
                 errorState  :errorState];
            }
        }
    };
}
    
- (bool)isVerifyEnabled{
    return verifyEnabled;
}

- (void)dealloc {
    pthread_rwlock_destroy(&verifyRegexLock);
}

@end
