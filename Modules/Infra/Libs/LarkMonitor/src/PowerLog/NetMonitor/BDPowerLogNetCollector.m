//
//  BDPowerLogNetCollector.m
//  LarkMonitor
//
//  Created by ByteDance on 2022/9/12.
//

#import "BDPowerLogNetCollector.h"
#import "BDPowerLogManager.h"
#import "BDPowerLogUtility.h"
#import "NSURLSessionTask+BDPowerLog.h"
#import <TTNetworkManager/TTNetworkManagerMonitorNotifier.h>
#import <TTNetworkManager/TTPushManager.h>
#import <TTNetworkManager/TTPushMessageBaseObject.h>
#import <objc/runtime.h>
#import <TTNetworkManager/TTHttpRequest.h>
#import <TTNetworkManager/TTHttpResponse.h>
#import <stdatomic.h>
#import <Stinger/Stinger.h>
#import "BDPowerLogURLSessionMonitor.h"

@interface BDPowerLogNetCollector()<BDPowerLogURLSessionMonitorDelegate>
{
    atomic_llong _totalSendBytes;
    atomic_llong _totalRecvBytes;
    atomic_llong _totalNetCount;
}
@property (atomic, strong) BDPowerLogNetMetrics *lastNetMetrics;
@end

@implementation BDPowerLogNetCollector

- (instancetype)init {
    if (self = [super init]) {
        [self _hookWebSocket:NSClassFromString(@"SRWebSocket")];
        [self _hookWebSocket:NSClassFromString(@"RCTSRWebSocket")];
        
        //Push
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePushOnTrafficChanged:) name:kTTPushManagerOnTrafficChanged object:nil];
        //TTNet
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNetworkStartNotification:) name:kTTNetworkManagerMonitorStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNetworkFinishNotification:) name:kTTNetworkManagerMonitorFinishNotification object:nil];
                
        BDPowerLogURLSessionMonitor.sharedInstance.delegate = self;
    }
    return self;
}

#pragma mark - websocket

- (void)_handleWebSocket:(NSString *)url sendBytes:(NSUInteger)sendBytes recvBytes:(NSUInteger)recvBytes isHeartBeat:(BOOL)isHeartBeat {
    if (!_enable) {
        return;
    }
    long long ts = bd_powerlog_current_ts();
    BDPowerLogNetEvent *event = [[BDPowerLogNetEvent alloc] init];
    event.startTime = ts;
    event.endTime = ts;
    event.sysTime = bd_powerlog_current_sys_ts();
    event.isPush = YES;
    event.sendBytes = sendBytes;
    event.recvBytes = recvBytes;
    event.isHeartBeat = isHeartBeat;
#ifdef BD_POWERLOG_DEBUG
    event.info = url;
#endif
    [self addNetEvent:event];
}

- (void)_hookWebSocket:(Class)cls {
    if (cls) {
        NSError *error = nil;
        __weak BDPowerLogNetCollector *weakSelf = self;
        SEL sel1 = sel_registerName("_handleFrameWithData:opCode:");
        [cls st_hookInstanceMethod:sel1 withOptions:STOptionAfter usingBlock:^(id<StingerParams> params, NSData *frameData, NSInteger opcode){
            __strong BDPowerLogNetCollector *strongSelf = weakSelf;
            if (strongSelf) {
                NSString *url = nil;
#ifdef BD_POWERLOG_DEBUG
                url = [[[params slf] url] absoluteString];
#endif
                [strongSelf _handleWebSocket:url sendBytes:0 recvBytes:frameData.length isHeartBeat:(opcode == 0x9 || opcode == 0xA)];
            }
        } error:&error];
        SEL sel2 = sel_registerName("_sendFrameWithOpcode:data:");
        [cls st_hookInstanceMethod:sel2 withOptions:STOptionAfter usingBlock:^(id<StingerParams> params, NSInteger opcode, NSData *frameData){
            __strong BDPowerLogNetCollector *strongSelf = weakSelf;
            if (strongSelf) {
                NSString *url = nil;
#ifdef BD_POWERLOG_DEBUG
                url = [[[params slf] url] absoluteString];
#endif
                [strongSelf _handleWebSocket:url sendBytes:frameData.length recvBytes:0 isHeartBeat:(opcode == 0x9 || opcode == 0xA)];
            }
        } error:&error];
    }
}

#pragma mark - NSURLSession

- (void)netEventGenerate:(BDPowerLogNetEvent *)netEvent {
    [self addNetEvent:netEvent];
}

#pragma mark - Push

- (void)handlePushOnTrafficChanged:(NSNotification *)notification {
    if (!_enable) {
        return;
    }
    long long sentBytes = [BD_DICT_GET_CLS(notification.userInfo,kTTPushManagerOnTrafficChangedUserInfoKeySentBytes,NSNumber) longLongValue];
    long long recvBytes = [BD_DICT_GET_CLS(notification.userInfo,kTTPushManagerOnTrafficChangedUserInfoKeyReceivedBytes,NSNumber) longLongValue];
    
    BOOL isHeartBeat = [BD_DICT_GET_CLS(notification.userInfo, kTTPushManagerOnTrafficChangedUserInfoKeyIsHeartBeatFrame, NSNumber) boolValue];
    long long ts = bd_powerlog_current_ts();
    BDPowerLogNetEvent *event = [[BDPowerLogNetEvent alloc] init];
    event.isPush = YES;
    event.isHeartBeat = isHeartBeat;
    event.startTime = ts;
    event.endTime = ts;
    event.sysTime = bd_powerlog_current_sys_ts();
    event.sendBytes = sentBytes;
    
    event.recvBytes = recvBytes;
#ifdef BD_POWERLOG_DEBUG
    event.info = BD_DICT_GET_CLS(notification.userInfo,kTTPushManagerOnTrafficChangedUserInfoKeyURL,NSString);
#endif
    [self addNetEvent:event];
}

#pragma mark - TTNet

+ (void)setTimestamp:(long long)timestamp forRequest:(TTHttpRequest *)request {
    objc_setAssociatedObject(request, @selector(timestampForRequest:), @(timestamp), OBJC_ASSOCIATION_RETAIN);
}

+ (long long)timestampForRequest:(TTHttpRequest *)request {
    return [objc_getAssociatedObject(request, @selector(timestampForRequest:)) longLongValue];
}

- (void)receiveNetworkStartNotification:(NSNotification *)notification {
    if (!_enable) {
        return;
    }
    TTHttpRequest *request = BD_DICT_GET_CLS(notification.userInfo, kTTNetworkManagerMonitorRequestKey, TTHttpRequest);
    [[self class] setTimestamp:bd_powerlog_current_ts() forRequest:request];
}

- (void)receiveNetworkFinishNotification:(NSNotification *)notification {
    if (!_enable) {
        return;
    }
    TTHttpRequest *request = BD_DICT_GET_CLS(notification.userInfo, kTTNetworkManagerMonitorRequestKey, TTHttpRequest);
    TTHttpResponse *response = BD_DICT_GET_CLS(notification.userInfo, kTTNetworkManagerMonitorResponseKey, TTHttpResponse);
    
    long long startTime = [self.class timestampForRequest:request];
    long long ts = bd_powerlog_current_ts();
    
    BDPowerLogNetEvent *event = [[BDPowerLogNetEvent alloc] init];
    event.startTime = startTime;
    event.endTime = ts;
    event.sysTime = bd_powerlog_current_sys_ts();
    event.sendBytes = request.HTTPBody.length;
    event.recvBytes = response.timinginfo.totalReceivedBytes;
#ifdef BD_POWERLOG_DEBUG
    event.info = request.URL.absoluteString;
#endif
    [self addNetEvent:event];
}

#pragma mark - calculate

- (void)addNetEvent:(BDPowerLogNetEvent *)netEvent {
    if (!_enable) {
        return;
    }
    
    if (!netEvent) {
        return;
    }
    
    atomic_fetch_add_explicit(&_totalSendBytes,netEvent.sendBytes,memory_order_release);
    
    atomic_fetch_add_explicit(&_totalRecvBytes,netEvent.recvBytes,memory_order_release);
    
    atomic_fetch_add_explicit(&_totalNetCount,1,memory_order_release);
    
    BDPL_DEBUG_LOG_TAG(NET, @"net event url %@ recv %lld send %lld",netEvent.info,netEvent.recvBytes,netEvent.sendBytes);
}

#pragma mark - public

- (void)setEnableURLSessionMetrics:(BOOL)enableURLSessionMetrics {
    if (_enableURLSessionMetrics != enableURLSessionMetrics) {
        _enableURLSessionMetrics = enableURLSessionMetrics;
        BDPowerLogURLSessionMonitor.sharedInstance.enableURLSessionMetrics = enableURLSessionMetrics;
    }
}

- (void)setEnable:(BOOL)enable {
    if (_enable != enable) {
        _enable = enable;
        if (enable) {
            [BDPowerLogURLSessionMonitor.sharedInstance start];
        } else {
            [BDPowerLogURLSessionMonitor.sharedInstance stop];
        }
    }
}

- (NSDictionary *)collect {
    if (!_enable) {
        return nil;
    }
    NSMutableDictionary *ret = nil;
    
    BDPowerLogNetMetrics *netMetrics = [self currentNetMetrics];

    BDPowerLogNetMetrics *lastNetMetrics = self.lastNetMetrics;
    if (lastNetMetrics != nil) {
                
        ret = [NSMutableDictionary dictionary];
        ret.ts = netMetrics.timestamp;
        ret.sys_ts = netMetrics.sys_ts;
        ret.delta_time = netMetrics.sys_ts - lastNetMetrics.sys_ts;
                
        long long delta_net_count = netMetrics.reqCount - lastNetMetrics.reqCount;
        long long delta_send_bytes = netMetrics.sendBytes - lastNetMetrics.sendBytes;
        long long delta_recv_bytes = netMetrics.recvBytes - lastNetMetrics.recvBytes;
        
        BD_DICT_SET(ret, @"delta_net_count", @(delta_net_count));
        BD_DICT_SET(ret, @"delta_send_bytes", @(delta_send_bytes));
        BD_DICT_SET(ret, @"delta_recv_bytes", @(delta_recv_bytes));
        
        long long device_send_bytes = MAX(netMetrics.deviceSendBytes - lastNetMetrics.deviceSendBytes,0);
        long long device_recv_bytes = MAX(netMetrics.deviceRecvBytes - lastNetMetrics.deviceRecvBytes,0);
        BD_DICT_SET(ret, @"device_send_bytes", @(device_send_bytes));
        BD_DICT_SET(ret, @"device_recv_bytes", @(device_recv_bytes));
    }
    
    self.lastNetMetrics = netMetrics;

    return ret;
}

- (BDPowerLogNetMetrics *)currentNetMetrics {
    if (!_enable) {
        return nil;
    }
    BDPowerLogNetMetrics *netMetrics = [[BDPowerLogNetMetrics alloc] init];
    netMetrics.timestamp = bd_powerlog_current_ts();
    netMetrics.sys_ts = bd_powerlog_current_sys_ts();
    BDPowerLogNetMetrics *customNetMetrics = nil;
    if ([BDPowerLogManager.delegate respondsToSelector:@selector(collectNetMetrics)]) {
        customNetMetrics = [BDPowerLogManager.delegate collectNetMetrics];
        netMetrics.sendBytes += customNetMetrics.sendBytes;
        netMetrics.recvBytes += customNetMetrics.recvBytes;
        netMetrics.reqCount += customNetMetrics.reqCount;
    }
    
    netMetrics.sendBytes += atomic_load_explicit(&_totalSendBytes,memory_order_acquire);
    netMetrics.recvBytes += atomic_load_explicit(&_totalRecvBytes,memory_order_acquire);
    netMetrics.reqCount += atomic_load_explicit(&_totalNetCount,memory_order_acquire);
    
    bd_powerlog_net_info net_info;
    if (bd_powerlog_device_net_info(&net_info)) {
        netMetrics.deviceSendBytes = net_info.cellular_send + net_info.wifi_send;
        netMetrics.deviceRecvBytes = net_info.cellular_recv + net_info.wifi_recv;
    }

    return netMetrics;
}

@end
