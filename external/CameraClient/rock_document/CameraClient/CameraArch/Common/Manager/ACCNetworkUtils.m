//
//  ACCNetworkUtils.m
//  CamearClient
//
//  Created by xiaojuan on 2020/7/6.
//

#import "ACCNetworkUtils.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <netdb.h>
#import <arpa/inet.h>

@implementation ACCNetworkUtils
+ (NSString *)getIPFromURLList:(NSArray *)urlArray
{
    NSMutableString *ipString = @"".mutableCopy;
    
    for (NSString *urlString in urlArray) {
        NSURL *url = [NSURL URLWithString:urlString];
        
        if (url.host) {
            NSArray *ipArray = [self getIPArrayFromHost:url.host];
            [ipString appendFormat:@"%@:%@;",url.host,[ipArray componentsJoinedByString:@","]?:@""];
        }
    }
    
    return ipString;
}

+ (NSArray *)getIPArrayFromHost:(NSString *)host
{
    NSString *portStr = [NSString stringWithFormat:@"%hu", (short)80];
    struct addrinfo hints, *res, *p;
    void *addr;
    char ipstr[INET6_ADDRSTRLEN];
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    int gai_error = getaddrinfo([host UTF8String], [portStr UTF8String], &hints, &res);
    if (!gai_error) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        p = res;
        while (res) {
            addr = NULL;
            if (res->ai_family == AF_INET) {
                struct sockaddr_in *ipv4 = (struct sockaddr_in *)res->ai_addr;
                addr = &(ipv4->sin_addr);
            } else if (res->ai_family == AF_INET6) {
                struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)res->ai_addr;
                addr = &(ipv6->sin6_addr);
            }
            if (addr) {
                const char *ip = inet_ntop(res->ai_family, addr, ipstr, sizeof(ipstr));
                [arr acc_addObject:[NSString stringWithUTF8String:ip]];
            }
            res = res->ai_next;
        }
        freeaddrinfo(p);
        return arr;
    } else {
        return nil;
    }
}

@end
