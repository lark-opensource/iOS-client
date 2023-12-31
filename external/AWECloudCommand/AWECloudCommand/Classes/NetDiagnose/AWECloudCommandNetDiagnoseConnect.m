//
//  AWECloudCommandNetDiagnoseConnect.m
//  AWELive
//
//  Created by songxiangwu on 2018/4/16.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWECloudCommandNetDiagnoseConnect.h"
#import "AWECloudCommandNetDiagnoseSimplePing.h"

#import <netdb.h>
#import <sys/socket.h>

@interface AWECloudCommandNetDiagnoseConnect () <AWECloudCommandSimplePingDelegate>

@property (nonatomic, strong) AWECloudCommandNetDiagnoseSimplePing *pinger;
@property (nonatomic, assign) NSInteger currentLoop;
@property (nonatomic, assign) NSInteger maxLoop;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, assign) NSTimeInterval startTS;

@end

@implementation AWECloudCommandNetDiagnoseConnect

- (void)startPingWithHost:(NSString *)host maxLoop:(NSInteger)maxLoop
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentLoop = 1;
        self.maxLoop = maxLoop;
        if (!self.pinger) {
            self.pinger = [[AWECloudCommandNetDiagnoseSimplePing alloc] initWithHostName:host];
        }
        self.pinger.delegate = self;
        [self.pinger start];
    });
}

- (void)stop
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.pinger stop];
        self.pinger = nil;
        self.currentLoop = self.maxLoop + 1;
    });
}

- (void)_sendPing
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeourtFired) object:nil];
    
    if (self.currentLoop > self.maxLoop) {
        self.pinger = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishPing)]) {
            [self.delegate didFinishPing];
        }
    } else {
        self.startTS = [[NSDate date] timeIntervalSince1970];
        self.currentLoop++;
        [self performSelector:@selector(_timeourtFired) withObject:nil afterDelay:3];
        [self.pinger sendPingWithData:nil];
    }
}

- (void)_timeourtFired
{
    NSString *log = [NSString stringWithFormat:@"ping: timeout %@", self.address];
    [self _pingCallbackWithLog:log];
    [self _sendPing];
}

- (void)_pingCallbackWithLog:(NSString *)log
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didAppendPingLog:)]) {
        [self.delegate didAppendPingLog:log];
    }
}

- (void)simplePing:(AWECloudCommandNetDiagnoseSimplePing *)pinger didStartWithAddress:(NSData *)address
{
    if (address) {
        self.address = [self.class _displayAddressForAddress:address];
    }
    [self _sendPing];
}

- (void)simplePing:(AWECloudCommandNetDiagnoseSimplePing *)pinger didFailWithError:(NSError *)error
{
    NSString *log = [NSString stringWithFormat:@"%ld ping failed: %@", (long)self.currentLoop, [self.class _failLogForError:error]];
    [self _pingCallbackWithLog:log];
    if (self.address.length) {
        [self _sendPing];
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishPing)]) {
            [self.delegate didFinishPing];
        }
        [self stop];
    }
}

- (void)simplePing:(AWECloudCommandNetDiagnoseSimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber
{
}

- (void)simplePing:(AWECloudCommandNetDiagnoseSimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error
{
    if (error) {
        NSString *log = [NSString stringWithFormat:@"%ld send failed: %@", (long)self.currentLoop, [self.class _failLogForError:error]];
        [self _pingCallbackWithLog:log];
    }
    [self _sendPing];
}

- (void)simplePing:(AWECloudCommandNetDiagnoseSimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber
{
    long long duration = ([[NSDate date] timeIntervalSince1970] - self.startTS) * 1000;
    NSString *log = [NSString stringWithFormat:@"receive %lu bytes from %@ sequence=#%u time=%lldms", (unsigned long)packet.length, self.address, sequenceNumber, duration];
    [self _pingCallbackWithLog:log];
    [self _sendPing];
}

- (void)simplePing:(AWECloudCommandNetDiagnoseSimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
{
    NSString *log = [NSString stringWithFormat:@"receive unexpected packet from %@ sequence=#%ld", self.address, (long)self.currentLoop];
    [self _pingCallbackWithLog:log];
    [self _sendPing];
}

+ (NSString *)_displayAddressForAddress:(NSData *)address
{
    int err;
    NSString *result;
    char hostStr[NI_MAXHOST];
    result = nil;
    if (address != nil) {
        err = getnameinfo([address bytes], (socklen_t)[address length], hostStr, sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
        if (err == 0) {
            result = [NSString stringWithCString:hostStr encoding:NSASCIIStringEncoding];
        }
    }
    return result;
}

+ (NSString *)_failLogForError:(NSError *)error
{
    NSString *result;
    NSNumber *failureNum;
    int failure;
    const char *failureStr;
    result = nil;
    if ([[error domain] isEqual:(NSString *)kCFErrorDomainCFNetwork] && ([error code] == kCFHostErrorUnknown)) {
        failureNum = [[error userInfo] objectForKey:(id)kCFGetAddrInfoFailureKey];
        if ([failureNum isKindOfClass:[NSNumber class]]) {
            failure = [failureNum intValue];
            if (failure != 0) {
                failureStr = gai_strerror(failure);
                if (failureStr != NULL) {
                    result = [NSString stringWithUTF8String:failureStr];
                }
            }
        }
    }
    if (result == nil) {
        result = [error localizedFailureReason];
    }
    if (result == nil) {
        result = [error localizedDescription];
    }
    if (result == nil) {
        result = [error description];
    }
    return result;
}

@end
