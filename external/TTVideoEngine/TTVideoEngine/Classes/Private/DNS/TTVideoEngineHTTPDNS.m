//
//  TTVideoEngineHTTPDNS.m
//  Pods
//
//  Created by guikunzhi on 16/12/4.
//
//

#import "TTVideoEngineHTTPDNS.h"
#import "TTVideoEngineNetwork.h"
#import "TTVideoEngineDNSCache.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineEnvConfig.h"

static NSString * serverIP = @""; // not use
@interface TTVideoEngineHTTPDNS ()

@property (nonatomic, strong) TTVideoEngineNetwork *networkSession;
@property (nonatomic, assign) TTVideoEngineDnsType hostDnsType;

@end

@implementation TTVideoEngineHTTPDNS

+ (void)setHttpDNSServerIP:(NSString *)serverIp
{
    serverIP = serverIp;
}

- (void)dealloc {
    [_networkSession invalidAndCancel];
    _networkSession = nil;
}

- (instancetype)initWithHostname:(NSString *)hostname andType:(TTVideoEngineDnsType)type{
    if (self = [super initWithHostname:hostname]) {
        _networkSession = [[TTVideoEngineNetwork alloc] initWithTimeout:5.0];
        _hostDnsType = type;
    }
    return self;
}

- (void)start {
    NSString *dnsHost = TTVideoEngineEnvConfig.dnsTTHost;
    if (dnsHost == nil || dnsHost.length < 1) {
        [self notifyError:[NSError errorWithDomain:kTTVideoErrorDomainHTTPDNS
                                              code:TTVideoEngineErrorParameterNull
                                          userInfo:@{@"info":@"dns host is null. pod subspec is wrong"}]];
        return;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@%@",dnsHost, self.hostname];
    @weakify(self)
    [self.networkSession configTaskWithURL:[NSURL URLWithString:url]
                                completion:^(id  _Nullable jsonObject, NSError * _Nullable error) {
        @strongify(self)
        if (!self) {
            return;
        }
        
        [self handleResponse:jsonObject error:error];
    }];
    
    [self.networkSession resume];
}

- (void)cancel {
    [self.networkSession cancel];
}

- (void)handleResponse:(id)jsonObj error:(NSError *)error {
    if (!error) {
        if (![jsonObj isKindOfClass:[NSDictionary class]]) {
            [self notifyError:[NSError errorWithDomain:kTTVideoErrorDomainHTTPDNS code:TTVideoEngineErrorParsingResponse userInfo:nil]];
            return;
        }
        
        NSArray *ips = [jsonObj objectForKey:@"ips"];
        if (ips.count == 0) {
            [self notifyError:[NSError errorWithDomain:kTTVideoErrorDomainHTTPDNS code:TTVideoEngineErrorResultEmpty userInfo:nil]];
        }
        else {
            TTVideoRunOnMainQueue(^{
                [[TTVideoEngineDNSCache shareCache] cacheHost:self.hostname respondJson:jsonObj];
                NSString *ip = ips[0];
                NSRange range = [ip rangeOfString:@":"];
                if (range.location != NSNotFound && ![ip hasPrefix:@"["]) {
                    ip = [NSString stringWithFormat:@"[%@]",ip];
                }
                if (self.delegate && [self.delegate respondsToSelector:@selector(parser:didFinishWithAddress:error:)]) {
                    [self.delegate parser:self didFinishWithAddress:ip error:nil];
                }
            }, NO);
        }
    }
    else {
        error = [NSError errorWithDomain:kTTVideoErrorDomainHTTPDNS code:error.code userInfo:error.userInfo];
        [self notifyError:error];
    }
}

- (void)notifyError:(NSError *)error {
    TTVideoRunOnMainQueue(^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(parser:didFinishWithAddress:error:)]) {
            [self.delegate parser:self didFinishWithAddress:nil error:error];
        }
    }, NO);
}

@end
