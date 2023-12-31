//
//  HMDDyld.m
//  Pods
//
//  Created by shenxy on 2022/8/26.
//

#import "HMDDyld.h"
#include <mach-o/loader.h>
#include <dlfcn.h>
#import "HMDInjectedInfo.h"
#import "HMDGCD.h"
#import "HMDGetImages.hpp"
#import "NSDictionary+HMDSafe.h"
#import "NSDictionary+HMDJSON.h"

static NSString * const kHMDAppDylibPath = @"AppDylibPath";

@implementation HMDDyld

+(void)saveAppDylibPath{
    std::vector<std::string> ret = getPreloadDylibPath();
    NSMutableArray *preload = NSMutableArray.array;
    for(std::string p : ret){
        NSString *eachImagePath = [NSString stringWithUTF8String:p.c_str()];
        NSRange range = [eachImagePath rangeOfString:@".app/"];
        if(range.location != NSNotFound){
            NSString *res = [eachImagePath substringFromIndex:range.location+range.length];
            [preload addObject:res];
        }
    }
    if ([HMDInjectedInfo defaultInfo].appGroupID && preload.count != 0) {
        NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[HMDInjectedInfo defaultInfo].appGroupID];
        NSURL *fileURL = [groupURL URLByAppendingPathComponent:kHMDAppDylibPath];
        NSMutableDictionary *res = [NSMutableDictionary dictionary];
        [res hmd_setObject:preload forKey:@"appImages"];
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        [res hmd_setObject:[NSNumber numberWithDouble:currentTime] forKey:@"time"];
        NSData *data = [res hmd_jsonData];
        [data writeToURL:fileURL atomically:YES];
    }
}

+(void)removeAppDylibPath{
    if ([HMDInjectedInfo defaultInfo].appGroupID) {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSURL *groupURL = [manager containerURLForSecurityApplicationGroupIdentifier:[HMDInjectedInfo defaultInfo].appGroupID];
        NSURL *fileURL = [groupURL URLByAppendingPathComponent:kHMDAppDylibPath];
        NSError *err;
        [manager removeItemAtURL:fileURL error:&err];
    }
}

@end
