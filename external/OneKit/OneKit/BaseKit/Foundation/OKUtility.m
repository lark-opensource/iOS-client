//
//  OKUtility.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "OKUtility.h"
#import <sys/sysctl.h>
#import <mach/mach_time.h>

@implementation OKUtility

+ (NSTimeInterval)currentInterval {
    return [[NSDate date] timeIntervalSince1970];
}

+ (long long)currentIntervalMS {
    return [self currentInterval] * 1000;
}

+ (NSCharacterSet *)URLQueryAllowedCharacterSet {
    static NSCharacterSet *characterSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *set = [NSMutableCharacterSet new];
        [set formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        [set addCharactersInString:@"$-_.+!*'(),"];
        characterSet = set;
    });

    return characterSet;
}


@end


uint64_t OK_CurrentMachTime() {
    return mach_absolute_time();
}

double OK_MachTimeToSecs(uint64_t time) {
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer /
    (double)timebase.denom / NSEC_PER_SEC;
}

BOOL OK_isValidDictionary(NSDictionary *value) {
    if (value == nil) {
        return NO;
    }
    
    if (![value isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    return value.count > 0;
}

BOOL OK_isValidArray(NSArray *value) {
    if (value == nil) {
        return NO;
    }
    
    if (![value isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    return value.count > 0;
}

BOOL OK_isValidString(NSString *value) {
    if (value == nil) {
        return NO;
    }
    
    if (![value isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    return value.length > 0;
}
