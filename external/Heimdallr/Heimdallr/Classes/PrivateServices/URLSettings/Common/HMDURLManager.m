//
//  HMDURLManager.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/23.
//

#import "HMDURLManager.h"
// Utility
#import "HMDMacro.h"
#import "NSArray+HMDSafe.h"

@implementation HMDURLManager

+ (NSString *)URLWithProvider:(id<HMDURLProvider>)provider forAppID:(NSString *)appID {
    return [self URLWithProvider:provider tryIndex:0 forAppID:appID];
}

+ (NSString *)URLWithProvider:(id<HMDURLProvider>)provider tryIndex:(NSUInteger)index forAppID:(NSString *)appID {
    return [self URLWithHostProvider:provider pathProvider:provider tryIndex:index forAppID:appID];
}

+ (NSString *)URLWithHostProvider:(id<HMDURLHostProvider>)hostProvider pathProvider:(id<HMDURLPathProvider>)pathProvider forAppID:(NSString *)appID {
    return [self URLWithHostProvider:hostProvider pathProvider:pathProvider tryIndex:0 forAppID:appID];
}

+ (NSString *)URLWithHostProvider:(id<HMDURLHostProvider>)hostProvider pathProvider:(id<HMDURLPathProvider>)pathProvider tryIndex:(NSUInteger)index forAppID:(NSString *)appID {
    NSString *host = [self _hostWithProvider:hostProvider atIndex:index forAppID:appID];
    NSString *path = [self _pathWithProvider:pathProvider forAppID:appID];
    NSString *url = [self _URLWithHost:host path:path];
    return url;
}

+ (NSArray<NSString *> *)hostsWithProvider:(id<HMDURLHostProvider>)provider forAppID:(NSString *)appID {
    NSArray<NSString *> *hosts = nil;
    if ([provider respondsToSelector:@selector(URLHostProviderConfigHosts:)]) {
        hosts = [provider URLHostProviderConfigHosts:appID];
    }
    if (hosts.count == 0 && [provider respondsToSelector:@selector(URLHostProviderInjectedHosts:)]) {
        hosts = [provider URLHostProviderInjectedHosts:appID];
    }
    if (hosts.count == 0 && [provider respondsToSelector:@selector(URLHostProviderDefaultHosts:)]) {
        hosts = [provider URLHostProviderDefaultHosts:appID];
    }
    if (HMDIsEmptyArray(hosts)) {
        return nil;
    }
    return hosts;
}

+ (NSString *)_hostWithProvider:(id<HMDURLHostProvider>)provider atIndex:(NSUInteger)index forAppID:(NSString *)appID {
    NSArray<NSString *> *hosts = [self hostsWithProvider:provider forAppID:appID];
    if (hosts.count > 0) {
        index = index % hosts.count;
    }
    NSString *host = [hosts hmd_objectAtIndex:index class:[NSString class]];
    if (HMDIsEmptyString(host)) {
        return nil;
    }
    return host;
}

+ (NSString *)_pathWithProvider:(id<HMDURLPathProvider>)provider forAppID:(NSString *)appID {
    NSString *path = nil;
    if ([provider respondsToSelector:@selector(URLPathProviderURLPath:)]) {
        path = [provider URLPathProviderURLPath:appID];
    }
    if (HMDIsEmptyString(path)) {
        return nil;
    }
    return path;
}

+ (NSString *)_URLWithHost:(NSString *)host path:(NSString *)path {
    if (host == nil || path == nil) {
        return nil;
    }
    if ([path hasPrefix:@"http"]) {
        return path;
    }
    NSString *baseURL;
    if ([host hasPrefix:@"http"]) {
        baseURL = host;
    } else {
        baseURL = [NSString stringWithFormat:@"https://%@", host];
    }
    if ([path hasPrefix:@"/"]) {
        return [NSString stringWithFormat:@"%@%@", baseURL, path];
    } else {
        return [NSString stringWithFormat:@"%@/%@", baseURL, path];
    }
}

@end
