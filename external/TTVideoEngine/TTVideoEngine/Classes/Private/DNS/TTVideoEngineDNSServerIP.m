//
//  TTVideoEngineDNSServerIP.m
//  Pods
//
//  Created by wyf on 2019/7/5.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineDNSServerIP.h"
#import "TTVideoEngineCFHostDNS.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineEnvConfig.h"

#define UPDATE_PEROID 5*60

static NSString *serverIP;
static long long serverIPTime;
static TTVideoEngineDNSServerIP *dnsSIPInstance;
static BOOL isParsing = NO;

@implementation TTVideoEngineDNSServerIP

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dnsSIPInstance = [[TTVideoEngineDNSServerIP alloc] init];
    });
    return dnsSIPInstance;
}

+(void)updateDNSServerIP {
    NSString *serverHostString = TTVideoEngineEnvConfig.dnsServerHost;
    if (serverHostString == nil || serverHostString.length < 1) {
        return;
    }
    
    if (isParsing) {
        return;
    } else {
        isParsing = YES;
    }
    [self sharedInstance];
    if (([[NSDate date] timeIntervalSince1970] - serverIPTime) > UPDATE_PEROID) {
        TTVideoEngineCFHostDNS *parser = [[TTVideoEngineCFHostDNS alloc] initWithHostname:serverHostString];
        parser.delegate = dnsSIPInstance;
        [parser start];
    }
}

- (void)parser:(id)dns didFinishWithAddress:(NSString *)ipAddress error:(NSError *)error {
    isParsing = NO;
    
    if (ipAddress) {
        serverIP = ipAddress;
        serverIPTime = (long long)[[NSDate date] timeIntervalSince1970];
        TTVideoEngineLog(@"DNSServer ip:%@",serverIP);
    }
}


+(NSString *)getDNSServerIP {
    [self updateDNSServerIP];
    return serverIP;
}

@end
