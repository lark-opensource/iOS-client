//
//  NSError+BDPExtension.m
//  Timor
//
//  Created by yinyuan on 2020/3/5.
//

#import "NSError+BDPExtension.h"
#import <ECOProbe/OPMonitorCode.h>
#import <ECOInfra/OPError.h>

@implementation NSError (BDPExtension)
#pragma - mark Public Methods
+ (OPError *)configOPError:(NSError *)error
               monitorCode:(OPMonitorCode *)monitorCode
      useCustomDescription:(BOOL)useCustomDescription
                  userInfo:(NSDictionary *)userInfo {
    if (useCustomDescription) {
        NSMutableDictionary *newUserInfo = userInfo.mutableCopy ? : [NSMutableDictionary dictionary];
        newUserInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"%@, domain: %@, code: %@", error.localizedDescription, error.domain, @(error.code)];
        return OPErrorNew(monitorCode, error, newUserInfo);
    }
    return OPErrorNew(monitorCode, error, userInfo);
}

+ (OPError *)configOPError:(NSError *)error
               monitorCode:(OPMonitorCode *)monitorCode
            appendUserInfo:(BOOL)appendUserInfo
                  userInfo:(NSDictionary *)userInfo {
    if (appendUserInfo) {
        return OPErrorNew(monitorCode, error, userInfo);
    }

    return OPErrorNew(monitorCode, error, nil);
}
@end
