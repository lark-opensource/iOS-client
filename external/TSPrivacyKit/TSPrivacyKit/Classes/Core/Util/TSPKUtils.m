//
//  TSPKUtils.m
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/16.
//

#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKConfigs.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDModel/BDModel.h>
#import <PNSServiceKit/PNSServiceCenter.h>
#import <PNSServiceKit/PNSLoggerProtocol.h>
#import "TSPKHostEnvProtocol.h"
#import "TSPrivacyKitConstants.h"
#include <sys/sysctl.h>

static NSString * const TSPKReturnTypeInt = @"int";
static NSString * const TSPKReturnTypeDouble = @"double";
static NSString * const TSPKReturnTypeFloat = @"float";
NSString * const TSPKReturnTypeNSString = @"NSString";
NSString * const TSPKReturnTypeNSArray = @"NSArray";
NSString * const TSPKReturnTypeNSNumber = @"NSNumber";
NSString * const TSPKReturnTypeNSUUID = @"NSUUID";
NSString * const TSPKReturnTypeNSURL = @"NSURL";


@implementation TSPKUtils

+ (NSString *_Nonnull)appendUnitName:(NSString *_Nonnull)unitName toRouter:(NSString *_Nonnull)router
{
    NSString *newRouter = nil;
    if ([router length] > 0) {
        newRouter = [NSString stringWithFormat:@"%@-%@", router, unitName];
    } else {
        newRouter = unitName;
    }
    return newRouter;
}

+ (NSString *_Nonnull)decodeBase64String:(NSString *_Nonnull)encodeString;
{
    return [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:encodeString options:0] encoding:NSUTF8StringEncoding];
}

+ (void)exectuteOnMainThread:(void (^)(void))block
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (NSString *_Nullable)topVCName
{
    NSAssert([NSThread isMainThread], @"should use in main thread");
    UIViewController *vc = nil;
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (window.isKeyWindow) {
            vc = window.rootViewController;
            break;
        }
    }
    UIViewController *topVC = [self topViewControllerForController:vc];
    return [topVC ts_className];
}

+ (UIViewController *)topViewControllerForController:(UIViewController *)rootViewController
{
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *) rootViewController;
        return [self topViewControllerForController:[navigationController.viewControllers lastObject]];
    }
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabController = (UITabBarController *) rootViewController;
        return [self topViewControllerForController:tabController.selectedViewController];
    }
    if ([rootViewController isKindOfClass:[UIViewController class]] && rootViewController.presentedViewController) {
        return [self topViewControllerForController:rootViewController.presentedViewController];
    }
    return rootViewController;
}

+ (NSString *_Nonnull)version
{
    return @"0.3.0";
}

+ (NSString *_Nonnull)settingVersion
{
    return [[TSPKConfigs sharedConfig] settingVersion];
}

+ (NSString *_Nullable)appStatusString {
    return [self appStatusWithDefault:@"unknown"];
}

+ (NSString *_Nullable)appStatusWithDefault:(NSString * _Nullable)defaultVal {
    if ([NSThread isMainThread] == false) {
        //        NSAssert(false, @"should call appStatusString method in mainthread");
        return defaultVal;
    }
    
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state == UIApplicationStateActive) {
        return @"active";
    }
    if (state == UIApplicationStateInactive) {
        return @"inactive";
    }
    if (state == UIApplicationStateBackground) {
        return @"background";
    }
    return defaultVal;
}

+ (NSTimeInterval)getRelativeTime {
    if ([[TSPKConfigs sharedConfig] isRelativeTimeEnable]) {
        return [self getIncrementTime];
    }
    return [self getUnixTime];
}

+ (NSTimeInterval)getRelativeTimeWithMillisecond {
    return [TSPKUtils getRelativeTime] * 1000.0;
}

+ (NSTimeInterval)getUnixTime {
    return [[NSDate date] timeIntervalSince1970];
}

+ (NSTimeInterval)getServerTime {
    id<TSPKHostEnvProtocol> hostEnv = PNS_GET_INSTANCE(TSPKHostEnvProtocol);
    if ([hostEnv respondsToSelector:@selector(currentServerTime)]) {
        return [hostEnv currentServerTime];
    } else {
        return 0;
    }
}

+ (NSString *_Nullable)concateClassName:(NSString *_Nullable)className method:(NSString *_Nullable)method {
    if (className) {
        return [NSString stringWithFormat:@"%@:%@", className, method];
    } else {
        return [NSString stringWithFormat:@"%@", method];
    }
}

+ (NSString *_Nullable)concateClassName:(NSString *_Nullable)className method:(NSString *_Nullable)method joiner:(NSString *)joiner {
    return [[self concateClassName:className method:method] stringByReplacingOccurrencesOfString:@":" withString:joiner];
}

// current time - boot time, this relative time would keep the same when user update system time
+ (NSTimeInterval)getIncrementTime {
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    struct timeval now;
    struct timezone tz;
    gettimeofday(&now, &tz);
    double uptime = - 1;
    if(sysctl(mib, 2, &boottime, &size, NULL, 0) != - 1 && boottime.tv_sec!= 0) {
        uptime = now.tv_sec- boottime.tv_sec;
        uptime += (double)(now.tv_usec- boottime.tv_usec) / 1000000.0;
    }
    return uptime;
}

+ (void)assert:(BOOL)flag message:(NSString *)message {
    NSAssert(flag, message);
}

+ (void)logWithMessage:(id)logObj
{
    [self logWithTag:@"PrivacyCheckInfo" message:logObj];
}

+ (void)logWithTag:(NSString *)tag message:(id)logObj{
    NSString *json = [self jsonStringEncodeWithObj:logObj];
    
    if (!BTD_isEmptyString(json)) {
        PNSLogI(tag, @"%@", json);
    }
}

+ (id)createDefaultInstance:(NSString *)encodeType defalutValue:(NSString*)defaultVal{
    if (!encodeType || [encodeType isEqualToString:@""] || [encodeType isEqualToString:@"@"]) {
        return nil;
    } else if ([TSPKReturnTypeNSString isEqualToString:encodeType]) {
        return defaultVal;
    } else if ([TSPKReturnTypeNSArray isEqualToString:encodeType]) {
        return [defaultVal componentsSeparatedByString:@","] ?: nil;
    } else if ([TSPKReturnTypeNSNumber isEqualToString:encodeType]) {
        return defaultVal ?: nil;
    } else if ([TSPKReturnTypeNSUUID isEqualToString:encodeType]) {
        return [[NSUUID alloc] initWithUUIDString:defaultVal] ?: nil;
    } else if ([TSPKReturnTypeNSURL isEqualToString:encodeType]) {
        return [[NSURL alloc] initWithString:defaultVal] ?: nil;
    } else {
        Class kclass = NSClassFromString(encodeType);
        // if class exist, create it
        if (kclass) {
            return [kclass bd_modelWithJSON:defaultVal options:BDModelMappingOptionsNone];
        }
    }
    
    return nil;
}

+ (long long)createDefaultValue:(NSString *)encodeType defalutValue:(NSString*)defaultVal{
    if (!encodeType || [encodeType isEqualToString:@""]) {
        return 0;
    }
    
    if([encodeType isEqualToString:TSPKReturnTypeInt]){
        return (long long)[defaultVal integerValue];
    }else if([encodeType isEqualToString:TSPKReturnTypeDouble]){
        return (long long)[defaultVal doubleValue];
    }else if([encodeType isEqualToString:TSPKReturnTypeFloat]){
        return (long long)[defaultVal floatValue];
    }else{
        //unsupported type
    }
    return 0;
}

+ (NSString *)generateUUID {
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);

    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);

    NSString *uuid = [NSString stringWithString:(__bridge NSString *)uuid_string_ref];

    CFRelease(uuid_ref);

    CFRelease(uuid_string_ref);
    
    return uuid;
}

+ (NSInteger)appID {
    return [[UIApplication btd_appID] integerValue];
}

+ (nullable NSString *)jsonStringEncodeWithObj:(id)obj {
    NSString *json;
    if([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]]) {
            json = [obj btd_jsonStringEncoded];
        } else if ([obj isKindOfClass:[NSString class]]) {
            json = obj;
        } else {
            //TODO: invalid object need to convert to string
        }
    
    return json;
}

+ (nonnull NSError*)fuseError {
    return [NSError errorWithDomain:TSPKErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"refused by monitor sdk"}];    
}

+ (id)parseJsonStruct:(id)json {
    if ([json isKindOfClass:[NSDictionary class]]) {
        NSDictionary *confDict = (NSDictionary *)json;
        NSMutableDictionary *mutableConf = [NSMutableDictionary dictionary];
        for (NSString *key in confDict.allKeys) {
            [mutableConf setValue:[self parseJsonStruct:json[key]] forKey:key];
        }
        return mutableConf;
    } else if ([json isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [NSMutableArray array];
        for (id value in json) {
            [result addObject:[self parseJsonStruct:value]];
        }
        return result;
    } else if ([json isKindOfClass:[NSString class]]) {
        return @"string";
    } else if ([json isKindOfClass:[NSNumber class]]) {
        return @"number";
    }
    return @"Unknown";
    
}

+ (NSInteger)convertDoubleToNSInteger:(double)doubleValue {
    NSInteger integerValue = 0;
    if (doubleValue > NSIntegerMax) {
        integerValue = 0;
    } else if (doubleValue < NSIntegerMin) {
        integerValue = 0;
    } else {
        integerValue = doubleValue;
    }
    
    return integerValue;
}

@end
