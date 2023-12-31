//
//  TTVideoEngineDNSServerIP.h
//  Pods
//
//  Created by wyf on 2019/7/5.
//
#import "TTVideoEngineDNS.h"

#ifndef DNSServerIP_h
#define DNSServerIP_h
@interface TTVideoEngineDNSServerIP : NSObject<TTVideoEngineDNSProtocol>

+(void)updateDNSServerIP;

+(NSString *)getDNSServerIP;

@end

#endif /* DNSServerIP_h */
