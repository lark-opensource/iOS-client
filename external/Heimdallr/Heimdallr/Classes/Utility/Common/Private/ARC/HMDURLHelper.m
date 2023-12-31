//
//  HMDURLHelper.m
//  Heimdallr
//
//  Created by liuhan.6985.lh on 2023/9/6.
//

#import "HMDURLHelper.h"
#import "HMDMacro.h"

@implementation HMDURLHelper

+ (NSString *)URLWithHost:(NSString *)host path:(NSString *)path {
    if (HMDIsEmptyString(path)) {
        return nil;
    }
    if ([path hasPrefix:@"http"]) {
        return [path copy];
    }
    if (HMDIsEmptyString(host)) {
        return nil;
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

+ (NSString *)URLWithString:(NSString *)string {
    if (HMDIsEmptyString(string)) {
        return nil;
    }
    if ([string hasPrefix:@"http"]) {
        return [string copy];
    }
    return [NSString stringWithFormat:@"https://%@", string];
}

@end
