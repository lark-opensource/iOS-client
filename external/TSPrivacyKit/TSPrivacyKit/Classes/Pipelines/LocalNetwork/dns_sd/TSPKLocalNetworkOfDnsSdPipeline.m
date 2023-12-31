//
//  TSPKLocalNetworkOfDnsSdPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKLocalNetworkOfDnsSdPipeline.h"
#include <BDFishhook/BDFishhook.h>
#include <dns_sd.h>
#import "TSPKFishhookUtils.h"

static NSString *const DNSServiceGetAddrInfoStr = @"DNSServiceGetAddrInfo";
#pragma mark - DNSServiceGetAddrInfo

static DNSServiceErrorType (*tspk_old_DNSServiceGetAddrInfo)(
                                                     DNSServiceRef                    *sdRef,
                                                     DNSServiceFlags flags,
                                                     uint32_t interfaceIndex,
                                                     DNSServiceProtocol protocol,
                                                     const char                       *hostname,
                                                     DNSServiceGetAddrInfoReply callBack,
                                                     void                             *context
                                                     );

DNSServiceErrorType tspk_new_DNSServiceGetAddrInfo(
                                                  DNSServiceRef                    *sdRef,
                                                  DNSServiceFlags flags,
                                                  uint32_t interfaceIndex,
                                                  DNSServiceProtocol protocol,
                                                  const char                       *hostname,
                                                  DNSServiceGetAddrInfoReply callBack,
                                                  void                             *context
                                              )
{
    @autoreleasepool {
        if (!hostname) {
            return tspk_old_DNSServiceGetAddrInfo(sdRef, flags, interfaceIndex, protocol, hostname, callBack, context);
        }
        NSString *networkAddress = [[NSString alloc] initWithCString:hostname encoding:NSUTF8StringEncoding];
        
        TSPKHandleResult *result = [TSPKLocalNetworkOfDnsSdPipeline handleAPIAccess:DNSServiceGetAddrInfoStr networkAddress:networkAddress];
        
        if (result.action == TSPKResultActionFuse) {
            return -1;
        } else {
            return tspk_old_DNSServiceGetAddrInfo(sdRef, flags, interfaceIndex, protocol, hostname, callBack, context);
        }
    }
}

@implementation TSPKLocalNetworkOfDnsSdPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineLocalNetworkOfDnsSd;
}

+ (NSArray<NSString *> * _Nullable)stubbedCAPIs
{
    return @[DNSServiceGetAddrInfoStr];
}

+ (NSString *)stubbedClass
{
    return nil;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct bd_rebinding DNSServiceGetAddrInfoMethod;
        DNSServiceGetAddrInfoMethod.name = [DNSServiceGetAddrInfoStr UTF8String];
        DNSServiceGetAddrInfoMethod.replacement = tspk_new_DNSServiceGetAddrInfo;
        DNSServiceGetAddrInfoMethod.replaced = (void *)&tspk_old_DNSServiceGetAddrInfo;
        
        struct bd_rebinding rebs[] = {
            DNSServiceGetAddrInfoMethod
        };
        __attribute__((unused)) int flag = tspk_rebind_symbols(rebs, 1);
    });
}


@end
