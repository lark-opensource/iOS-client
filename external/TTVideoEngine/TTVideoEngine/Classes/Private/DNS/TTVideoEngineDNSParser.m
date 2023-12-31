//
//  TTVideoEngineDNSParser.m
//  Pods
//
//  Created by guikunzhi on 16/12/2.
//
//

#import "TTVideoEngineDNSParser.h"
#import "TTVideoEngineHTTPDNS.h"
#import "TTVideoEngineCFHostDNS.h"
#import "TTVideoEngineDNSCache.h"
#import "TTVideoEngineDNSServerIP.h"
#import "TTVideoEngineUtilPrivate.h"

@interface TTVideoEngineDNSParser ()<TTVideoEngineDNSProtocol>

@property (nonatomic, strong) TTVideoEngineCFHostDNS *localDNS;
@property (nonatomic, strong) TTVideoEngineHTTPDNS *httpDNS;
@property (nonatomic, strong) TTVideoEngineDNSBase *currentDNS;
@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, assign) BOOL hasRetry;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) BOOL ipFromCache;
@property (nonatomic, assign) BOOL hasRecAndExpired;
@end

@implementation TTVideoEngineDNSParser

+ (void)setHTTPDNSServerIP:(NSString *)serverIP
{
    [TTVideoEngineHTTPDNS setHttpDNSServerIP:serverIP];
}

- (instancetype)initWithHostname:(NSString *)hostname {
    if (self = [super init]) {
        _hostname = hostname;
        _currentDNS = _localDNS;
        _isCancelled = NO;
        _index = 0;
        _ipFromCache = NO;
        _hasRecAndExpired = NO;
        _networkType = TTVideoEngineNetWorkStatusUnknown;
        _parserIndex = @[@(TTVideoEngineDnsTypeLocal),@(TTVideoEngineDnsTypeLocal)];
    }
    return self;
}

- (void)start {
    //抛出错误
    if (self.isCancelled) {
        return;
    }
    if(self.index >= [_parserIndex count]){
        return;
    }
    if (self.isForceReparse || !self.isUseDnsCache) {
        [self dnsParseAsync];
        return;
    }

    [TTVideoEngineDNSServerIP updateDNSServerIP];
    //判断网络是否变化,如果网络类型发生变化则重新解析dns。
    BOOL isClear = NO;
    TTVideoEngineDNSCache *ipCache = [TTVideoEngineDNSCache shareCache];

    if(_networkType != TTVideoEngineNetWorkStatusUnknown){
        if((_networkType != ipCache.networkType)){
            isClear = YES;
        }
    }else{
        TTVideoEngineLog(@"start:NetWork may hava some problems");
        isClear = YES;
    }
    //如果网络不一致会重置缓存，重新解析  或者当前网络状况不明，返回已有缓存
    if(isClear){
        [ipCache clearHost];
        [ipCache setNetworkType:_networkType];
        [self dnsParseAsync];
        return;
    }

    NSString *ip = [ipCache resolveHost:self.hostname];
    if(ip.length >0){
        if(![ipCache isCacheHostVaild:self.hostname andExpiredTime:self.expiredTimeSeconds]){
            _hasRecAndExpired = YES;
            [self dnsParseAsync];
        }
        _ipFromCache = YES;
        if ([self.delegate respondsToSelector:@selector(parser:didFinishWithAddress:error:)]) {
            [self.delegate parser:self didFinishWithAddress:ip error:nil];
            return;
        }
    }
    [self dnsParseAsync];
}

- (void)dnsParseAsync {
    if (_parserIndex != nil && ![_parserIndex isKindOfClass:[NSNull class]] && _index >= 0 && _index < _parserIndex.count){
        TTVideoEngineDnsType type = [_parserIndex[_index] integerValue];
        switch (type) {
            case TTVideoEngineDnsTypeLocal:
                _localDNS = [[TTVideoEngineCFHostDNS alloc] initWithHostname:_hostname];
                _localDNS.delegate = self;
                self.currentDNS = self.localDNS;
                break;
            case TTVideoEngineDnsTypeHttpAli:
                _httpDNS = [[TTVideoEngineHTTPDNS alloc] initWithHostname:_hostname andType:TTVideoEngineDnsTypeHttpTT];
                _httpDNS.delegate = self;
                self.currentDNS = self.httpDNS;
                break;
            case TTVideoEngineDnsTypeHttpTT:
                _httpDNS = [[TTVideoEngineHTTPDNS alloc] initWithHostname:_hostname andType:TTVideoEngineDnsTypeHttpTT];
                _httpDNS.delegate = self;
                self.currentDNS = self.httpDNS;
                break;
            default:
                break;
        }
    }
     [self.currentDNS start];
}

- (void)cancel {
    if (self.isCancelled) {
        return;
    }
    self.isCancelled = YES;
    [self.currentDNS cancel];
}

- (void)setIsHTTPDNSFirst:(BOOL)isHTTPDNSFirst
{
    if(isHTTPDNSFirst){
        _parserIndex = @[@(TTVideoEngineDnsTypeHttpTT),@(TTVideoEngineDnsTypeLocal)];
    }else{
        _parserIndex = @[@(TTVideoEngineDnsTypeLocal),@(TTVideoEngineDnsTypeHttpTT)];
    }
}

- (void)setIsDnsType:(NSInteger)mainDns backupDns:(NSInteger)backupDns
{
    _parserIndex = @[@(mainDns),@(backupDns)];
}

- (void)setForceReparse{
    _isForceReparse = YES;
}

- (NSString *)getTypeStr
{
    if (_parserIndex != nil && ![_parserIndex isKindOfClass:[NSNull class]] && _index >= 0 && _index < _parserIndex.count){
        if(_ipFromCache){
            return @"FromCache";
        }
        TTVideoEngineDnsType type = [_parserIndex[_index] integerValue];
        switch (type) {
            case TTVideoEngineDnsTypeLocal:
                return @"local";
            case TTVideoEngineDnsTypeHttpAli:
                return  @"HTTP Ali";
            case TTVideoEngineDnsTypeHttpTT:
                return  @"TT_HTTP";
            default:
                break;
        }
    }
    return @"";
}

#pragma mark -
#pragma mark TTDNSProtocol

- (void)parser:(TTVideoEngineDNSBase *)dns didFinishWithAddress:(NSString *)IPAddress error:(NSError *)error
{
    notifyIfCancelled(parserDidCancelled)
    
    if (![self isDelegateValid]) {
        return;
    }
    
    if (error) {
        if (self.hasRetry) {
            if(!_hasRecAndExpired || _isForceReparse){
                 [self.delegate parser:self didFinishWithAddress:nil error:error];
            }
        }
        else {
            self.hasRetry = YES;
            if ([self.delegate respondsToSelector:@selector(parser:didFailedWithError:)]) {
                if(!_hasRecAndExpired || _isForceReparse){
                    [self.delegate parser:self didFailedWithError:error];
                }
            }
            _index++;
            [self dnsParseAsync];
        }
    }
    else if(!_hasRecAndExpired || _isForceReparse){
        [self.delegate parser:self didFinishWithAddress:IPAddress error:nil];
    }
}

- (BOOL)isDelegateValid
{
    return self.delegate && [self.delegate conformsToProtocol:@protocol(TTVideoEngineDNSProtocol)];
}

@end
