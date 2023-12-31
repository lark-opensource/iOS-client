//
//  TTVideoEngineCFHostDNS.m
//  Pods
//
//  Created by guikunzhi on 16/12/5.
//
//

#import "TTVideoEngineCFHostDNS.h"
#include <sys/types.h>
#include <sys/socket.h>
#import <netdb.h>
#import "TTVideoEngineDNSCache.h"
#import "TTVideoEngineUtilPrivate.h"

#define TTCFHostDNSTimePerRun   0.05

@interface TTVideoEngineCFHostDNS ()

@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, copy) NSString *ipAddress;
@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, assign) BOOL isUserCancel;
@property (nonatomic, assign) BOOL isSuccess;
@property (nonatomic, assign) NSUInteger maxCount;
@property (nonatomic, strong) NSError *error;

@end

@implementation TTVideoEngineCFHostDNS

- (void)dealloc {
    _isCancelled = YES;
}

- (instancetype)initWithHostname:(NSString *)hostname {
    if (self = [super initWithHostname:hostname]) {
        _timeout = 10.0;
    }
    return self;
}

- (void)start {
    self.maxCount = (NSUInteger)(self.timeout * 1.0/TTCFHostDNSTimePerRun);
    self.ipAddress = nil;
    self.isCancelled = NO;
    self.isUserCancel = NO;
    self.isSuccess = NO;
    [self performSelectorInBackground:@selector(parseDNS) withObject:nil];
}

- (void)cancel {
    self.isCancelled = YES;
    self.isUserCancel = YES;
}

- (void)notifyError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(parser:didFinishWithAddress:error:)]) {
            [self.delegate parser:self didFinishWithAddress:nil error:error];
        }
    });
}

- (void)notifySuccess:(NSString *)ipAddress {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(parser:didFinishWithAddress:error:)]) {
            NSArray<NSString *> *ips =[[NSArray alloc] initWithObjects:ipAddress, nil];
            NSDictionary * ipDic = @{@"ips":ips,@"ttl":@0,@"host":self.hostname};
            [[TTVideoEngineDNSCache shareCache] cacheHost:self.hostname respondJson:ipDic];
            [self.delegate parser:self didFinishWithAddress:ipAddress error:nil];
        }
    });
}

- (void)parseDNS {
    if (!self.hostname) {
        [self notifyError:[NSError errorWithDomain:kTTVideoErrorDomainLocalDNS code:TTVideoEngineErrorResultEmpty userInfo:@{@"info":@"hostname is null"}]];
        return;
    }
    // set up the CFHost object
    int count = 0;
    CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)self.hostname);
    CFHostClientContext ctx = {.info = (__bridge void*)self};
    CFHostSetClient(host, TTCFHostCallback, &ctx);
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    CFHostScheduleWithRunLoop(host, runloop, CFSTR("DNSResolverRunLoopMode"));
    // start the name resolution
    CFStreamError error;
    Boolean didStart = CFHostStartInfoResolution(host, kCFHostAddresses, &error);
    if (!didStart || error.error) {
        self.isCancelled = YES;
    }
    // run the run loop for 50ms at a time, always checking if we should cancel
    while(!self.isCancelled && !self.isSuccess) {
        CFRunLoopRunInMode(CFSTR("DNSResolverRunLoopMode"), TTCFHostDNSTimePerRun, true);
        count++;
        if (count >= self.maxCount) {
            self.isCancelled = YES;
        }
    }
    if (self.isSuccess) {
        Boolean hasBeenResolved;
        CFArrayRef addressArray = CFHostGetAddressing(host, &hasBeenResolved);
        if (hasBeenResolved && addressArray && [(__bridge NSArray*)addressArray count] > 0) {
            self.ipAddress = [self parseResult :(__bridge NSArray*)addressArray];
            [self notifySuccess:self.ipAddress];
        }
        else {
            self.isSuccess = NO;
            [self notifyError:[NSError errorWithDomain:kTTVideoErrorDomainLocalDNS code:TTVideoEngineErrorParsingResponse userInfo:nil]];
        }
    }
    else {
        NSError *error = self.error;
        if (!error) {
            error = [NSError errorWithDomain:kTTVideoErrorDomainLocalDNS code:self.isUserCancel ? TTVideoEngineErrorUserCancel : TTVideoEngineErrorTimeout userInfo:nil];
        }
        [self notifyError:error];
    }
    CFHostSetClient(host, NULL, NULL);
    CFHostUnscheduleFromRunLoop(host, runloop, CFSTR("DNSResolverRunLoopMode"));
    CFRelease(host);
}

- (NSString *)parseResult:(NSArray*)addresses {
    NSString *result = nil;
    if (addresses != nil) {
        for (NSData * address in addresses) {
            int err;
            char addrStr[NI_MAXHOST];
            assert([address isKindOfClass:[NSData class]]);
            
            const struct sockaddr *socketAddr = (const struct sockaddr *) [address bytes];
            err = getnameinfo(socketAddr, (socklen_t) [address length], addrStr, sizeof(addrStr), NULL, 0, NI_NUMERICHOST);
            if (err == 0) {
                NSString *ipStr = [NSString stringWithUTF8String:addrStr];
                if (socketAddr->sa_family == AF_INET6) {
                    return [NSString stringWithFormat:@"[%@]",ipStr];
                }
                return ipStr;
            }
            else {
                result = nil;
                break;
            }
        }
    }
    return result;
}

void TTCFHostCallback(CFHostRef theHost, CFHostInfoType typeInfo, const CFStreamError *error, void *info) {
    TTVideoEngineCFHostDNS *self = (__bridge TTVideoEngineCFHostDNS*)info;
    if (error->domain || error->error) {
        self.error = [NSError errorWithDomain:kTTVideoErrorDomainLocalDNS code:error->error userInfo:nil];
        self.isSuccess = NO;
        self.isCancelled = YES;
    }
    else {
        self.isSuccess = YES;
    }
}

@end
