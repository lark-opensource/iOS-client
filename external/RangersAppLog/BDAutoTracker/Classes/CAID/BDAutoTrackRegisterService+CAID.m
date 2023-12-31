//
//  BDAutoTrackRegisterService+CAID.m
//  RangersAppLog
//
//  Created by 朱元清 on 2021/2/24.
//

#import "BDAutoTrackRegisterService+CAID.h"
#import "BDAutoTrackDefaults.h"
#include <objc/runtime.h>
#import "NSDictionary+VETyped.h"

static void *kCaidKey = &kCaidKey;
static void *kPrevCaidKey = &kPrevCaidKey;
static NSString *const kAppLogCAIDKey       = @"kAppLogCAIDKey";
static NSString *const kAppLogPrevCAIDKey   = @"kAppLogPrevCAIDKey";

@implementation BDAutoTrackRegisterService (CAID)

- (void)setCaid:(NSString *)caid {
    objc_setAssociatedObject(self, kCaidKey, caid, OBJC_ASSOCIATION_COPY);
}

- (NSString *)caid {
    return objc_getAssociatedObject(self, kCaidKey);
}

- (void)setPrevCaid:(NSString *)prevCaid {
    objc_setAssociatedObject(self, kPrevCaidKey, prevCaid, OBJC_ASSOCIATION_COPY);
}

- (NSString *)prevCaid {
    return objc_getAssociatedObject(self, kPrevCaidKey);
}

- (void)extra_updateParametersWithResponse:(NSDictionary *)responseDic {
    NSString *caid1, *caid2;
    if ([responseDic isKindOfClass:NSDictionary.class]) {
        caid1 = [responseDic vetyped_stringForKey:@"caid1"];
        caid2 = [responseDic vetyped_stringForKey:@"caid2"];
    }
    self.caid = caid1;
    self.prevCaid = caid2;
}

- (void)extra_reloadParameters {
    NSString *caidKey = [self storageKeyWithPrefix:kAppLogCAIDKey];
    NSString *prevCaidKey = [self storageKeyWithPrefix:kAppLogPrevCAIDKey];
    BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
    self.caid = [defaults stringValueForKey:caidKey];
    self.prevCaid = [defaults stringValueForKey:prevCaidKey];
}

- (void)extra_saveAllID {
    NSString *caidKey = [self storageKeyWithPrefix:kAppLogCAIDKey];
    NSString *prevCaidKey = [self storageKeyWithPrefix:kAppLogPrevCAIDKey];
    BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
    [defaults setValue:self.caid forKey:caidKey];
    [defaults setValue:self.prevCaid forKey:prevCaidKey];
}

@end
