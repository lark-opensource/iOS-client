//
//  BTDPingServices.m
//  STKitDemo
//
//  Created by SunJiangting on 15-3-9.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import "BTDPingServices.h"

@implementation BTDPingItem

- (NSString *)description
{
    NSString *desc = nil;
    switch (self.status) {
        case BTDPingStatusDidStart:
            desc = [NSString stringWithFormat:@"PING %@ (%@): %ld data bytes",self.originalAddress, self.IPAddress, (long)self.dateBytesLength];
            break;
            
        case BTDPingStatusDidReceivePacket:
            desc = [NSString stringWithFormat:@"%ld bytes from %@: icmp_seq=%ld ttl=%ld time=%.3f ms", (long)self.dateBytesLength, self.IPAddress, (long)self.ICMPSequence, (long)self.timeToLive, self.timeMilliseconds];
            break;
            
        case BTDPingStatusDidTimeout:
            desc = [NSString stringWithFormat:@"Request timeout for icmp_seq %ld", (long)self.ICMPSequence];
            break;
            
        case BTDPingStatusDidFailToSendPacket:
            desc = [NSString stringWithFormat:@"Fail to send packet to %@: icmp_seq=%ld", self.IPAddress, (long)self.ICMPSequence];
            break;
            
        case BTDPingStatusDidReceiveUnexpectedPacket:
            desc = [NSString stringWithFormat:@"Receive unexpected packet from %@: icmp_seq=%ld", self.IPAddress, (long)self.ICMPSequence];
            break;
            
        case BTDPingStatusError:
            desc = [NSString stringWithFormat:@"Can not ping to %@", self.originalAddress];
            break;
            
        default:
            break;
    }
    
    return desc;
}

+ (NSString *)statisticsWithPingItems:(NSArray *)pingItems
{
    //    --- ping statistics ---
    //    5 packets transmitted, 5 packets received, 0.0% packet loss
    //    round-trip min/avg/max/stddev = 4.445/9.496/12.210/2.832 ms
    NSString *address = [pingItems.firstObject originalAddress];
    __block NSInteger receivedCount = 0, allCount = 0;
    [pingItems enumerateObjectsUsingBlock:^(BTDPingItem *obj, NSUInteger idx, BOOL *stop) {
        if (obj.status != BTDPingStatusFinished && obj.status != BTDPingStatusError) {
            allCount ++;
            if (obj.status == BTDPingStatusDidReceivePacket) {
                receivedCount ++;
            }
        }
    }];
    
    NSMutableString *description = [NSMutableString stringWithCapacity:50];
    [description appendFormat:@"--- %@ ping statistics ---\n", address];
    
    CGFloat lossPercent = (CGFloat)(allCount - receivedCount) / MAX(1.0, allCount) * 100;
    [description appendFormat:@"%ld packets transmitted, %ld packets received, %.1f%% packet loss\n", (long)allCount, (long)receivedCount, lossPercent];
    return [description stringByReplacingOccurrencesOfString:@".0%" withString:@"%"];
}

@end

@interface BTDPingServices () <BTDSimplePingDelegate> {
    BOOL _hasStarted;
    BOOL _isTimeout;
    NSInteger   _repingTimes;
    NSInteger   _sequenceNumber;
    NSMutableArray *_pingItems;
}

@property(nonatomic, copy)   NSString   *address;
@property(nonatomic, strong) BTDSimplePing *simplePing;
@property(nonatomic, assign) NSInteger maximumPingTimes;

@property(nonatomic, strong)void(^callbackHandler)(BTDPingItem *item, NSArray *pingItems);
@property(nonatomic, strong)void(^finishHandler)(NSArray *pingItems);

@end

@implementation BTDPingServices

+ (BTDPingServices *)startPingAddress:(NSString *)address
                      callbackHandler:(void(^)(BTDPingItem *item, NSArray *pingItems))handler {
    BTDPingServices *services = [[BTDPingServices alloc] initWithAddress:address];
    services.callbackHandler = handler;
    [services startPing];
    return services;
}

+ (BTDPingServices *)startPingAddress:(NSString *)address
                    maximumPingTimes:(NSInteger)maximumPingTimes
                     callbackHandler:(void(^)(BTDPingItem *pingItem, NSArray *pingItems))handler
{
    BTDPingServices *services = [[BTDPingServices alloc] initWithAddress:address];
    services.callbackHandler = handler;
    services.maximumPingTimes = maximumPingTimes;
    [services startPing];
    return services;
}

+ (BTDPingServices *)startPingAddress:(NSString *)address
                    maximumPingTimes:(NSInteger)maximumPingTimes
                     callbackHandler:(void(^)(BTDPingItem *pingItem, NSArray *pingItems))handler
                       finishHandler:(void(^)(NSArray *pingItems))finishHandler
{
    BTDPingServices *services = [[BTDPingServices alloc] initWithAddress:address];
    services.callbackHandler = handler;
    services.finishHandler = finishHandler;
    services.maximumPingTimes = maximumPingTimes;
    [services startPing];
    return services;
}

- (instancetype)initWithAddress:(NSString *)address {
    self = [super init];
    if (self) {
        self.timeoutMilliseconds = 500;
        self.maximumPingTimes = 100;
        self.address = address;
        self.simplePing = [[BTDSimplePing alloc] initWithHostName:address];
        self.simplePing.addressStyle = BTDSimplePingAddressStyleAny;
        self.simplePing.delegate = self;
        _pingItems = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

- (void)startPing {
    _repingTimes = 0;
    _hasStarted = NO;
    [_pingItems removeAllObjects];
    [self.simplePing start];
}

- (void)reping {
    [self.simplePing stop];
    [self.simplePing start];
}

- (void)_timeoutActionFired {
    BTDPingItem *pingItem = [[BTDPingItem alloc] init];
    pingItem.ICMPSequence = _sequenceNumber;
    pingItem.originalAddress = self.address;
    pingItem.status = BTDPingStatusDidTimeout;
    [self.simplePing stop];
    [self _handlePingItem:pingItem];
}

- (void)_handlePingItem:(BTDPingItem *)pingItem {
    if (pingItem.status == BTDPingStatusDidReceivePacket || pingItem.status == BTDPingStatusDidTimeout) {
        [_pingItems addObject:pingItem];
    }
    if (_repingTimes < self.maximumPingTimes - 1) {
        if (self.callbackHandler) {
            self.callbackHandler(pingItem, [_pingItems copy]);
        }
        _repingTimes ++;
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(reping) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    } else {
        if (self.callbackHandler) {
            self.callbackHandler(pingItem, [_pingItems copy]);
        }
        
        if (self.finishHandler) {
            self.finishHandler([_pingItems copy]);
        }
        
        [self cancel];
    }
}

- (void)cancel {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeoutActionFired) object:nil];
    [self.simplePing stop];
    BTDPingItem *pingItem = [[BTDPingItem alloc] init];
    pingItem.status = BTDPingStatusFinished;
    [_pingItems addObject:pingItem];
    if (self.callbackHandler) {
        self.callbackHandler(pingItem, [_pingItems copy]);
    }
}

- (void)st_simplePing:(BTDSimplePing *)pinger didStartWithAddress:(NSData *)address {
    NSData *packet = [pinger packetWithPingData:nil];
    if (!_hasStarted) {
        BTDPingItem *pingItem = [[BTDPingItem alloc] init];
        pingItem.IPAddress = pinger.IPAddress;
        pingItem.originalAddress = self.address;
        pingItem.dateBytesLength = packet.length - sizeof(STICMPHeader);
        pingItem.status = BTDPingStatusDidStart;
        if (self.callbackHandler) {
            self.callbackHandler(pingItem, nil);
        }
        _hasStarted = YES;
    }
    [pinger sendPacket:packet];
    [self performSelector:@selector(_timeoutActionFired) withObject:nil afterDelay:self.timeoutMilliseconds / 1000.0];
}

// If this is called, the SimplePing object has failed.  By the time this callback is
// called, the object has stopped (that is, you don't need to call -stop yourself).

// IMPORTANT: On the send side the packet does not include an IP header.
// On the receive side, it does.  In that case, use +[SimplePing icmpInPacket:]
// to find the ICMP header within the packet.

- (void)st_simplePing:(BTDSimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    _sequenceNumber = sequenceNumber;
}

- (void)st_simplePing:(BTDSimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeoutActionFired) object:nil];
    _sequenceNumber = sequenceNumber;
    BTDPingItem *pingItem = [[BTDPingItem alloc] init];
    pingItem.ICMPSequence = _sequenceNumber;
    pingItem.originalAddress = self.address;
    pingItem.status = BTDPingStatusDidFailToSendPacket;
    [self _handlePingItem:pingItem];
}

- (void)st_simplePing:(BTDSimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeoutActionFired) object:nil];
    BTDPingItem *pingItem = [[BTDPingItem alloc] init];
    pingItem.ICMPSequence = _sequenceNumber;
    pingItem.originalAddress = self.address;
    pingItem.status = BTDPingStatusDidReceiveUnexpectedPacket;
//    [self _handlePingItem:pingItem];
}

- (void)st_simplePing:(BTDSimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet timeToLive:(NSInteger)timeToLive sequenceNumber:(uint16_t)sequenceNumber timeElapsed:(NSTimeInterval)timeElapsed {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeoutActionFired) object:nil];
    BTDPingItem *pingItem = [[BTDPingItem alloc] init];
    pingItem.IPAddress = pinger.IPAddress;
    pingItem.dateBytesLength = packet.length;
    pingItem.timeToLive = timeToLive;
    pingItem.timeMilliseconds = timeElapsed * 1000;
    pingItem.ICMPSequence = sequenceNumber;
    pingItem.originalAddress = self.address;
    pingItem.status = BTDPingStatusDidReceivePacket;
    [self _handlePingItem:pingItem];
}

- (void)st_simplePing:(BTDSimplePing *)pinger didFailWithError:(NSError *)error {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeoutActionFired) object:nil];
    [self.simplePing stop];
    
    BTDPingItem *errorPingItem = [[BTDPingItem alloc] init];
    errorPingItem.originalAddress = self.address;
    errorPingItem.status = BTDPingStatusError;
    if (self.callbackHandler) {
        self.callbackHandler(errorPingItem, [_pingItems copy]);
    }
    
    BTDPingItem *pingItem = [[BTDPingItem alloc] init];
    pingItem.originalAddress = self.address;
    pingItem.IPAddress = pinger.IPAddress ?: pinger.hostName;
    [_pingItems addObject:pingItem];
    pingItem.status = BTDPingStatusFinished;
    if (self.callbackHandler) {
        self.callbackHandler(pingItem, [_pingItems copy]);
    }
}
@end
