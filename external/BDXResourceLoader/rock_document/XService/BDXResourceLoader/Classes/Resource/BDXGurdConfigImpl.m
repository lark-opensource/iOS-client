//
//  BDXDefaultGurdConfigDelegate.m
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import "BDXGurdConfigImpl.h"

static NSString *const kDInHouseAccessKey = @"2d15e0aa4fe4a5c91eb47210a6ddf467";

@implementation BDXGurdConfigImpl

- (NSString *)accessKey
{
    if (self.accessKeyName) {
        return self.accessKeyName;
    }
    return kDInHouseAccessKey;
}

- (BOOL)isNetworkDelegateEnabled
{
    return YES;
}

- (BOOL)isBusinessDomainEnabled
{
    return YES;
}

- (NSString *)platformDomain
{
    if (self.platformDomainName) {
        return self.platformDomainName;
    }
    return @"";
}

@end
