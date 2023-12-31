//
//  TTVideoEngineDNSCache.m
//  Pods
//
//  Created by 钟少奋 on 2017/5/18.
//
// referrence from TTHTTPDNSManager

#import "TTVideoEngineDNSCache.h"
#import "NSArray+TTVideoEngine.h"
#import "NSDictionary+TTVideoEngine.h"

extern id checkNSNull(id obj);

@interface  TTVideoEngineDomainInfo : NSObject

@property (nonatomic, copy) NSString *host;
@property (nonatomic, strong) NSArray<NSString *> *ips;
@property (nonatomic, strong) NSNumber *ttl;
@property (nonatomic, strong) NSDate *requestDate;

- (NSString *)randomIP;
- (BOOL)isCacheValidNow:(NSInteger)expiredTime;

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict;

@end

@implementation  TTVideoEngineDomainInfo

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict
{
    if (!jsonDict){
        return nil;
    }
    
    self = [super init];
    if (self) {
        _host = checkNSNull(jsonDict[@"host"]);
        _ips = checkNSNull(jsonDict[@"ips"]);
        _ttl = checkNSNull(jsonDict[@"ttl"]);
    }
    return self;
}

- (NSString *)randomIP
{
    NSUInteger count = [self.ips count];
    if (count == 0) {
        return @"";
    }
    
    if (count == 1) {
        return self.ips[0];
    }
    
    NSUInteger index = (arc4random() % count);
    
    return [self.ips ttvideoengine_objectAtIndex:index];
}

- (BOOL)isCacheValidNow:(NSInteger)expiredTime
{
    NSDate *currentTime = [NSDate date];
    NSTimeInterval timeDifference = [currentTime timeIntervalSinceDate:self.requestDate];
    if(self.ttl.doubleValue == 0){
        self.ttl =[NSNumber numberWithInteger:expiredTime];
    }
    return timeDifference < self.ttl.doubleValue;
}

- (void)formateIfIsIpv6
{
    self.ips = [self.ips ttVideoEngine_map:^id(NSString *ip, NSUInteger idx) {
        NSString *resultIp = ip;
        NSRange range = [ip rangeOfString:@":"];
        if (range.location != NSNotFound && ![ip hasPrefix:@"["]) {
            resultIp = [NSString stringWithFormat:@"[%@]",ip];
        }
        return resultIp;
    }];
}

@end

@interface TTVideoEngineDNSCache ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, TTVideoEngineDomainInfo *> *resolvedDomainDic;

@end

@implementation TTVideoEngineDNSCache

+ (instancetype)shareCache
{
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.resolvedDomainDic = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString *)resolveHost:(NSString *)host
{
    if (!host || !host.length) return nil;
    
    NSString *ip = nil;
    TTVideoEngineDomainInfo *cache = nil;
    @synchronized (self) {
        cache = self.resolvedDomainDic[host];
    }
    if (cache) {
        ip = [cache randomIP];
    }
    return ip;
}

- (BOOL)cacheHost:(NSString *)host respondJson:(NSDictionary *)respondJson
{
    if (host == nil) {
        return NO;
    }
    
    BOOL result = NO;
    
    TTVideoEngineDomainInfo *domainInfo = [[TTVideoEngineDomainInfo alloc] initWithDictionary:respondJson];
    domainInfo.requestDate = [NSDate date];
    [domainInfo formateIfIsIpv6];
    if (domainInfo) {
        @synchronized (self) {
            self.resolvedDomainDic[host] = domainInfo;
        }
        result = YES;
    }
    return result;
}

- (void)clearHost
{
    @synchronized (self) {
        [self.resolvedDomainDic removeAllObjects];
    }
}

- (BOOL)isCacheHostVaild:(NSString *)host andExpiredTime:(NSInteger)expiredTime
{
    if(expiredTime == 0){
        expiredTime = 2*60;
    }
    TTVideoEngineDomainInfo *cache = nil;
    @synchronized (self) {
        cache = self.resolvedDomainDic[host];
    }
    if ([cache isCacheValidNow:expiredTime]) {
        return YES;
    }
    return NO;
}

- (void)setNetworkType:(TTVideoEngineNetWorkStatus)networkType{
    _networkType = networkType;
}

@end
