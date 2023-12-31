//
//  TSPKLocalNetworkOfNetdbPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKLocalNetworkOfNetdbPipeline.h"
#include <BDFishhook/BDFishhook.h>
#include <arpa/inet.h>
#include <netdb.h>
#import "TSPKFishhookUtils.h"

static NSString *const gethostbynameStr = @"gethostbyname";
static NSString *const gethostbyname2Str = @"gethostbyname2";
static NSString *const gethostbyaddrStr = @"gethostbyaddr";
static NSString *const getnameinfoStr = @"getnameinfo";
static NSString *const getipnodebyaddrStr = @"getipnodebyaddr";
static NSString *const getipnodebynameStr = @"getipnodebyname";
static NSString *const socketConnectStr = @"connect";

#pragma mark - gethostbyname

static struct hostent *(*tspk_old_gethostbyname)(const char *);

struct hostent *tspk_new_gethostbyname(const char *hostName)
{
    @autoreleasepool {
        if (!hostName) {
            return tspk_old_gethostbyname(hostName);
        }
        
        NSString *networkAddress = [[NSString alloc] initWithCString:hostName encoding:NSUTF8StringEncoding];
        
        TSPKHandleResult *result = [TSPKLocalNetworkOfNetdbPipeline handleAPIAccess:gethostbynameStr networkAddress:networkAddress];
        
        if (result.action == TSPKResultActionFuse) {
            return NULL;
        } else {
            return tspk_old_gethostbyname(hostName);
        }
    }
}

#pragma mark - gethostbyname2

static struct hostent *(*tspk_old_gethostbyname2)(const char *, int);

struct hostent *tspk_new_gethostbyname2(const char *hostName, int af)
{
    @autoreleasepool {
        if (!hostName) {
            return tspk_old_gethostbyname2(hostName, af);
        }
        
        NSString *networkAddress = [[NSString alloc] initWithCString:hostName encoding:NSUTF8StringEncoding];
        
        TSPKHandleResult *result = [TSPKLocalNetworkOfNetdbPipeline handleAPIAccess:gethostbyname2Str networkAddress:networkAddress];
        
        if (result.action == TSPKResultActionFuse) {
            return NULL;
        } else {
            return tspk_old_gethostbyname2(hostName, af);
        }
    }
}

#pragma mark - gethostbyaddr

static struct hostent *(*tspk_old_gethostbyaddr)(const void *, socklen_t, int);

struct hostent *tspk_new_gethostbyaddr(const void *addr, socklen_t len, int type)
{
    @autoreleasepool {
        char str[INET6_ADDRSTRLEN];
        const char *ptr = inet_ntop(type, addr, str, sizeof(str));
        
        if (!ptr) {
            return tspk_old_gethostbyaddr(addr, len, type);
        }
        
        NSString *networkAddress = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
        
        TSPKHandleResult *result = [TSPKLocalNetworkOfNetdbPipeline handleAPIAccess:gethostbyaddrStr networkAddress:networkAddress];
        
        if (result.action == TSPKResultActionFuse) {
            return NULL;
        } else {
            return tspk_old_gethostbyaddr(addr, len, type);
        }
    }
}

#pragma mark - getnameinfo

static int (*tspk_old_getnameinfo)(const struct sockaddr * __restrict, socklen_t,
                                  char * __restrict, socklen_t, char * __restrict,
                                  socklen_t, int);

int tspk_new_getnameinfo(const struct sockaddr * __restrict socketAddress,
                        socklen_t sockLen,
                        char * __restrict host,
                        socklen_t hostLen,
                        char * __restrict server,
                        socklen_t serverLen,
                        int flags)
{
    @autoreleasepool {
        if (!socketAddress) {
            return tspk_old_getnameinfo(socketAddress,sockLen, host, hostLen, server, serverLen, flags);
        }
        
        struct sockaddr_in *addr_in = (struct sockaddr_in *)socketAddress;
        char * addr = inet_ntoa(addr_in->sin_addr);
        if (!addr) {
            return tspk_old_getnameinfo(socketAddress,sockLen, host, hostLen, server, serverLen, flags);
        }
        
        NSString *networkAddress = [[NSString alloc] initWithCString:addr encoding:NSUTF8StringEncoding];
        
        TSPKHandleResult *result = [TSPKLocalNetworkOfNetdbPipeline handleAPIAccess:getnameinfoStr networkAddress:networkAddress];
        
        if (result.action == TSPKResultActionFuse) {
            return EAI_FAIL;
        } else {
            return tspk_old_getnameinfo(socketAddress,sockLen, host, hostLen, server, serverLen, flags);
        }
    }
}

#pragma mark - getipnodebyaddr

static struct hostent *(*tspk_old_getipnodebyaddr)(const void *, size_t, int, int *);

struct hostent *tspk_new_getipnodebyaddr(const void *addr,
                            size_t len,
                            int af,
                            int *error_num)
{
    @autoreleasepool {
        char str[INET6_ADDRSTRLEN];
        const char *ptr = inet_ntop(af, addr, str, sizeof(str));
        
        if (!ptr) {
            return tspk_old_getipnodebyaddr(addr, len, af, error_num);
        }
        
        NSString *networkAddress = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
        
        TSPKHandleResult *result = [TSPKLocalNetworkOfNetdbPipeline handleAPIAccess:getipnodebyaddrStr networkAddress:networkAddress];

        if (result.action == TSPKResultActionFuse) {
            return NULL;
        } else {
            return tspk_old_getipnodebyaddr(addr, len, af, error_num);
        }
    }
}

#pragma mark - getipnodebyname

static struct hostent *(*tspk_old_getipnodebyname)(const char *, int, int, int *);

struct hostent *tspk_new_getipnodebyname(const char *name,
                                        int af,
                                        int flags,
                                        int *error_num)
{
    @autoreleasepool {
        if (!name) {
            return tspk_old_getipnodebyname(name, af, flags, error_num);
        }
        
        NSString *networkAddress = [[NSString alloc] initWithCString:name encoding:NSUTF8StringEncoding];
        
        TSPKHandleResult *result = [TSPKLocalNetworkOfNetdbPipeline handleAPIAccess:getipnodebynameStr networkAddress:networkAddress];
        
        if (result.action == TSPKResultActionFuse) {
            return NULL;
        } else {
            return tspk_old_getipnodebyname(name, af, flags, error_num);
        }
    }
}

#pragma mark - connect

static int (*tspk_old_connect)(int, const struct sockaddr *, socklen_t);

int tspk_new_connect(int socketId, const struct sockaddr * socketAddr, socklen_t len)
{
    @autoreleasepool {
        if (!socketAddr) {
            return tspk_old_connect(socketId, socketAddr, len);
        }
        
        struct sockaddr_in *addr_in = (struct sockaddr_in *)socketAddr;
        char * addr = inet_ntoa(addr_in->sin_addr);
        if (!addr) {
            return tspk_old_connect(socketId, socketAddr, len);
        }
        
        NSString *networkAddress = [[NSString alloc] initWithCString:addr encoding:NSUTF8StringEncoding];
        
        TSPKHandleResult *result = [TSPKLocalNetworkOfNetdbPipeline handleAPIAccess:socketConnectStr networkAddress:networkAddress];
        
        if (result.action == TSPKResultActionFuse) {
            return -1;
        } else {
            return tspk_old_connect(socketId, socketAddr, len);
        }
    }
}

@implementation TSPKLocalNetworkOfNetdbPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineLocalNetworkOfNetdb;
}

+ (NSArray<NSString *> * _Nullable)stubbedCAPIs
{
    return @[gethostbynameStr, gethostbyname2Str, gethostbyaddrStr, getnameinfoStr, getipnodebyaddrStr, getipnodebynameStr, socketConnectStr];
}

+ (NSString *)stubbedClass
{
    return nil;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        struct bd_rebinding gethostbyname2Method;
        gethostbyname2Method.name = [gethostbyname2Str UTF8String];
        gethostbyname2Method.replacement = tspk_new_gethostbyname2;
        gethostbyname2Method.replaced = (void *)&tspk_old_gethostbyname2;
        
        struct bd_rebinding gethostbyaddrMethod;
        gethostbyaddrMethod.name = [gethostbyaddrStr UTF8String];
        gethostbyaddrMethod.replacement = tspk_new_gethostbyaddr;
        gethostbyaddrMethod.replaced = (void *)&tspk_old_gethostbyaddr;
        
        struct bd_rebinding gethostbynameMethod;
        gethostbynameMethod.name = [gethostbynameStr UTF8String];
        gethostbynameMethod.replacement = tspk_new_gethostbyname;
        gethostbynameMethod.replaced = (void *)&tspk_old_gethostbyname;
        
        struct bd_rebinding getnameinfoMethod;
        getnameinfoMethod.name = [getnameinfoStr UTF8String];
        getnameinfoMethod.replacement = tspk_new_getnameinfo;
        getnameinfoMethod.replaced = (void *)&tspk_old_getnameinfo;
        
        struct bd_rebinding getipnodebyaddrMethod;
        getipnodebyaddrMethod.name = [getipnodebyaddrStr UTF8String];
        getipnodebyaddrMethod.replacement = tspk_new_getipnodebyaddr;
        getipnodebyaddrMethod.replaced = (void *)&tspk_old_getipnodebyaddr;
        
        struct bd_rebinding getipnodebynameMethod;
        getipnodebynameMethod.name = [getipnodebynameStr UTF8String];
        getipnodebynameMethod.replacement = tspk_new_getipnodebyname;
        getipnodebynameMethod.replaced = (void *)&tspk_old_getipnodebyname;
        
        struct bd_rebinding connectMethod;
        connectMethod.name = [socketConnectStr UTF8String];
        connectMethod.replacement = tspk_new_connect;
        connectMethod.replaced = (void *)&tspk_old_connect;

        struct bd_rebinding rebs[] = {
            gethostbyname2Method, gethostbyaddrMethod, gethostbynameMethod,
            getnameinfoMethod, getipnodebyaddrMethod, getipnodebynameMethod,
            connectMethod
        };
        tspk_rebind_symbols(rebs, 7);
    });
}

@end
