//
//  AWECloudCommandNetDiagnoseTraceRoute.m
//  AWELive
//
//  Created by songxiangwu on 2018/4/16.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWECloudCommandNetDiagnoseTraceRoute.h"
#import "AWECloudCommandNetDiagnoseAddressInfo.h"

#include <sys/time.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface AWECloudCommandNetDiagnoseTraceRoute ()

@property (nonatomic, assign) NSInteger maxTTL;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) NSInteger timeout;
@property (nonatomic, assign) NSInteger maxAttempts;
@property (atomic, assign) BOOL isRunning;

@end


@implementation AWECloudCommandNetDiagnoseTraceRoute

- (instancetype)initWithMaxTTL:(NSInteger)ttl timeout:(NSInteger)timeout maxAttempts:(NSInteger)attempts port:(NSInteger)port
{
    self = [super init];
    if (self) {
        _maxTTL = ttl;
        _port = port;
        _timeout = timeout;
        _maxAttempts = attempts;
    }
    return self;
}

- (BOOL)doTraceRoute:(NSString *)host
{
    //从name server获取server主机的地址
    NSArray *serverDNSs = [AWECloudCommandNetDiagnoseAddressInfo getDNSsWithDormain:host];
    if (!serverDNSs || serverDNSs.count <= 0) {
        [self _traceRouteCallbackWithLog:@"traceroute: could not get host address"];
        [self _didFinishTraceRoute];
        return NO;
    }
    
    NSString *ipAddr0 = [serverDNSs objectAtIndex:0];
    //设置server主机的套接口地址
    NSData *addrData = nil;
    BOOL isIPV6 = NO;
    if ([ipAddr0 rangeOfString:@":"].location == NSNotFound) {
        isIPV6 = NO;
        struct sockaddr_in nativeAddr4;
        memset(&nativeAddr4, 0, sizeof(nativeAddr4));
        nativeAddr4.sin_len = sizeof(nativeAddr4);
        nativeAddr4.sin_family = AF_INET;
        nativeAddr4.sin_port = htons(self.port);
        inet_pton(AF_INET, ipAddr0.UTF8String, &nativeAddr4.sin_addr.s_addr);
        addrData = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
    } else {
        isIPV6 = YES;
        struct sockaddr_in6 nativeAddr6;
        memset(&nativeAddr6, 0, sizeof(nativeAddr6));
        nativeAddr6.sin6_len = sizeof(nativeAddr6);
        nativeAddr6.sin6_family = AF_INET6;
        nativeAddr6.sin6_port = htons(self.port);
        inet_pton(AF_INET6, ipAddr0.UTF8String, &nativeAddr6.sin6_addr);
        addrData = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
    }
    
    struct sockaddr *destination;
    destination = (struct sockaddr *)[addrData bytes];
    
    //初始化套接口
    struct sockaddr fromAddr;
    int recv_sock;
    int send_sock;
    BOOL error = NO;
    self.isRunning = YES;
    
    //创建一个支持ICMP协议的UDP网络套接口（用于接收）
    
    if ((recv_sock = socket(destination->sa_family, SOCK_DGRAM, isIPV6?IPPROTO_ICMPV6:IPPROTO_ICMP)) < 0) {
        [self _traceRouteCallbackWithLog:@"traceroute: could not create receive socket"];
        [self _didFinishTraceRoute];
        return NO;
    }
    
    //创建一个UDP套接口（用于发送）
    if ((send_sock = socket(destination->sa_family, SOCK_DGRAM, 0)) < 0) {
        [self _traceRouteCallbackWithLog:@"traceroute: could not create send socket"];
        [self _didFinishTraceRoute];
        return NO;
    }
    
    // When a connection closes, by default, your process receives a SIGPIPE signal.
    // If your program does not handle or ignore this signal, your program will quit immediately.
    int nosigpipe = 1;
    setsockopt(send_sock, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, sizeof(nosigpipe));
    setsockopt(recv_sock, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, sizeof(nosigpipe));
    
    char *cmsg = "GET / HTTP/1.1\r\n\r\n";
    socklen_t n = sizeof(fromAddr);
    char buf[100];
    
    NSInteger ttl = 1;  // index sur le TTL en cours de traitement.
    NSInteger timeoutTTL = 0;
    BOOL icmp = NO;  // Positionné à true lorsqu'on reçoit la trame ICMP en retour.
    NSTimeInterval startTime;     // Timestamp lors de l'émission du GET HTTP
    NSTimeInterval delta;         // Durée de l'aller-retour jusqu'au hop.
    
    // On progresse jusqu'à un nombre de TTLs max.
    while (ttl <= self.maxTTL) {
        memset(&fromAddr, 0, sizeof(fromAddr));
        //设置sender 套接字的ttl
        if ((isIPV6? setsockopt(send_sock,IPPROTO_IPV6, IPV6_UNICAST_HOPS, &ttl, sizeof(ttl)):setsockopt(send_sock, IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl))) < 0) {
            error = YES;
            [self _traceRouteCallbackWithLog:@"traceroute: setsockopt failed"];
        }
        
        //每一步连续发送maxAttenpts报文
        icmp = false;
        NSMutableString *traceTTLLog = [[NSMutableString alloc] initWithCapacity:20];
        [traceTTLLog appendFormat:@"%ld\t", (long)ttl];
        NSString *hostAddress = @"***";
        for (int try = 0; try < self.maxAttempts; try ++) {
            startTime = [[NSDate date] timeIntervalSince1970];
            
            //发送成功返回值等于发送消息的长度
            ssize_t sentLen = sendto(send_sock, cmsg, sizeof(cmsg), 0, (struct sockaddr *)destination, isIPV6?sizeof(struct sockaddr_in6):sizeof(struct sockaddr_in));
            if (sentLen != sizeof(cmsg)) {
                NSLog(@"Error sending to server: %d %d", errno, (int)sentLen);
                error = true;
                [traceTTLLog appendFormat:@"*\t"];
            }
            
            long res = 0;
            //从（已连接）套接口上接收数据，并捕获数据发送源的地址。
            if (-1 == fcntl(recv_sock, F_SETFL, O_NONBLOCK)) {
                printf("fcntl socket error!\n");
                return -1;
            }
            /* set recvfrom from server timeout */
            struct timeval tv;
            fd_set readfds;
            tv.tv_sec = 1;
            tv.tv_usec = 0;  //设置了1s的延迟
            FD_ZERO(&readfds);
            FD_SET(recv_sock, &readfds);
            select(recv_sock + 1, &readfds, NULL, NULL, &tv);
            if (FD_ISSET(recv_sock, &readfds) > 0) {
                timeoutTTL = 0;
                if ((res = recvfrom(recv_sock, buf, 100, 0, (struct sockaddr *)&fromAddr, &n)) <
                    0) {
                    error = YES;
                    [traceTTLLog appendFormat:@"%s\t", strerror(errno)];
                } else {
                    icmp = YES;
                    delta = [[NSDate date] timeIntervalSince1970] - startTime;
                    
                    //将“二进制整数” －> “点分十进制，获取hostAddress和hostName
                    if (fromAddr.sa_family == AF_INET) {
                        char display[INET_ADDRSTRLEN] = {0};
                        inet_ntop(AF_INET, &((struct sockaddr_in *)&fromAddr)->sin_addr.s_addr, display, sizeof(display));
                        hostAddress = [NSString stringWithFormat:@"%s", display];
                    }
                    
                    else if (fromAddr.sa_family == AF_INET6) {
                        char ip[INET6_ADDRSTRLEN];
                        inet_ntop(AF_INET6, &((struct sockaddr_in6 *)&fromAddr)->sin6_addr, ip, INET6_ADDRSTRLEN);
                        hostAddress = [NSString stringWithUTF8String:ip];
                    }
                    
                    if (try == 0) {
                        [traceTTLLog appendFormat:@"%@\t\t", hostAddress];
                    }
                    [traceTTLLog appendFormat:@"%0.2fms\t", delta*1000];
                }
            } else {
                timeoutTTL++;
                break;
            }
            
            // On teste si l'utilisateur a demandé l'arrêt du traceroute
            @synchronized(self)
            {
                if (!self.isRunning) {
                    ttl = self.maxTTL;
                    icmp = YES;
                    break;
                }
            }
        }
        
        //输出报文,如果三次都无法监控接收到报文，跳转结束
        if (icmp) {
            [self _traceRouteCallbackWithLog:traceTTLLog];
        } else {
            //如果连续三次接收不到icmp回显报文
            if (timeoutTTL >= 4) {
                break;
            } else {
                [self _traceRouteCallbackWithLog:[NSString stringWithFormat:@"%ld\t********\t", (long)ttl]];
            }
        }
        
        if ([hostAddress isEqualToString:ipAddr0]) {
            break;
        }
        ttl++;
    }

    self.isRunning = NO;
    // On averti le delegate que le traceroute est terminé.
    [self _didFinishTraceRoute];
    return error;
}

- (void)stopTrace
{
    @synchronized(self) {
        self.isRunning = NO;
    }
}

- (BOOL)isTracingRoute
{
    return self.isRunning;
}

- (void)_traceRouteCallbackWithLog:(NSString *)log
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didAppendTraceRouteLog:)]) {
        [self.delegate didAppendTraceRouteLog:log];
    }
}

- (void)_didFinishTraceRoute
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishTraceRoute)]) {
        [self.delegate didFinishTraceRoute];
    }
}

@end
