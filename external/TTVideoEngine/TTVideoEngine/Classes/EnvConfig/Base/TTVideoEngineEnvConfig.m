//
//  TTVideoEngineEnvConfig.m

#import "TTVideoEngineEnvConfig.h"

static NSString *s_dnsTTHost = nil;
static NSString *s_dnsGoogleHost = nil;
static NSString *s_dnsServerHost = nil;
static NSString *s_boeHost = nil;
static NSString *s_testReachabilityHost = nil;

@implementation TTVideoEngineEnvConfig

+ (void)setDnsTTHost:(NSString *)dnsTTHost {
    s_dnsTTHost = dnsTTHost;
}

+ (NSString *)dnsTTHost {
    if (s_dnsTTHost != nil) {
        return s_dnsTTHost;
    }
    return TTVideoEngineDnsTTHostString;
}

+ (void)setDnsGoogleHost:(NSString *)dnsGoogleHost {
    s_dnsGoogleHost = dnsGoogleHost;
}

+ (NSString *)dnsGoogleHost {
    if (s_dnsGoogleHost != nil) {
        return s_dnsGoogleHost;
    }
    return TTVideoEngineDnsGoogleHostString;
}

+ (void)setDnsServerHost:(NSString *)dnsServerHost {
    s_dnsServerHost = dnsServerHost;
}

+ (NSString *)dnsServerHost {
    if (s_dnsServerHost != nil) {
        return s_dnsServerHost;
    }
    return TTVideoEngineDnsServerHostString;
}

+ (void)setBoeHost:(NSString *)boeHost {
    s_boeHost = boeHost;
}

+ (NSString *)boeHost {
    if (s_boeHost != nil) {
        return s_boeHost;
    }
    return TTVideoEngineBoeHostString;
}

+ (void)setTestReachabilityHost:(NSString *)testReachabilityHost {
    s_testReachabilityHost = testReachabilityHost;
}

+ (NSString *)testReachabilityHost {
    if (s_testReachabilityHost != nil) {
        return s_testReachabilityHost;
    }
    return TTVideoEngineTestReachabilityHostString;
}

@end
