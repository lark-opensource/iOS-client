//
//  IESGurdKitUtil.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/3/5.
//

#import "IESGurdKitUtil.h"

#import <objc/runtime.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "IESGeckoKit+Private.h"
#import "IESGurdKit+Experiment.h"
#import "UIDevice+IESGeckoKit.h"

#import <ZstdDecompressKit/NSData+ZstdDecompression.h>

NSString *IESGurdPollingLevel1Group = @"lv_1";
NSString *IESGurdPollingLevel2Group = @"lv_2";
NSString *IESGurdPollingLevel3Group = @"lv_3";

NSArray<NSString *> *IESGurdPollingLevelGroups (void)
{
    static NSArray<NSString *> *groups = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        groups = @[ IESGurdPollingLevel1Group,
                    IESGurdPollingLevel2Group,
                    IESGurdPollingLevel3Group ];
    });
    return groups;
}

static NSDictionary *IESGurdClientStaticParams (void)
{
    static NSDictionary *staticParams = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        
        NSString *localeIdentifier = [[NSLocale currentLocale] objectForKey:NSLocaleIdentifier];
        localeIdentifier = [[localeIdentifier componentsSeparatedByString:@"_"] lastObject] ?: @"unknown";
        params[@"region"] = localeIdentifier;
        params[@"os"] = @(1);
        params[@"sdk_version"] = IESGurdKitSDKVersion() ?: @"unknown";
        
        staticParams = [params copy];
    });
    return staticParams;
}

static void IESGurdClientAppendDynamicParams (NSMutableDictionary *params)
{
    IESGurdKit *instance = IESGurdKitInstance;
    params[@"aid"] = @(instance.appId.integerValue);
    params[@"app_version"] = instance.appVersion ? : @"unknown";
    NSString *deviceID = instance.deviceID;
    if (deviceID.length == 0 && instance.getDeviceID) {
        deviceID = instance.getDeviceID();
    }
    params[@"device_id"] = deviceID ? : @"unknown";
}

#pragma mark - Base

NSDictionary *IESGurdClientCommonParams (void)
{
    static NSDictionary *staticParams = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params addEntriesFromDictionary:IESGurdClientStaticParams()];
        
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        if (appName) {
            appName = [appName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        } else {
            appName = @"unknown";
        }
        params[@"app_name"] = appName;
        params[@"os_version"] = [[UIDevice currentDevice] systemVersion] ? : @"unknown";
        params[@"device_platform"] =
        ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? @"ipad" : @"iphone";
        params[@"device_model"] = [UIDevice ies_machineModel] ?: @"unknown";
        
        staticParams = [params copy];
    });
    
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:staticParams];
    IESGurdClientAppendDynamicParams(result);
    return [result copy];
}

NSDictionary *IESGurdClientBasicParams (void)
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:IESGurdClientStaticParams()];
    result[@"aid"] = @(IESGurdKitInstance.appId.integerValue);
    return [result copy];
}

NSString *IESGurdPollingPriorityString (IESGurdPollingPriority priority)
{
    NSString *priorityString = @"unknown";
    switch (priority) {
        case IESGurdPollingPriorityLevel1: {
            priorityString = @"lv_1";
            break;
        }
        case IESGurdPollingPriorityLevel2: {
            priorityString = @"lv_2";
            break;
        }
        case IESGurdPollingPriorityLevel3: {
            priorityString = @"lv_3";
            break;
        }
        case IESGurdPollingPriorityNone: {
            break;
        }
    }
    return priorityString;
}

#pragma mark - Hook

static void IESGurdKitHookMethod(Class targetClass, SEL originalSEL, SEL swizzledSEL) {
    Method originMethod = class_getInstanceMethod(targetClass, originalSEL);
    Method swizzledMethod = class_getInstanceMethod(targetClass, swizzledSEL);
    if (class_addMethod(targetClass,
                        originalSEL,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(targetClass,
                            swizzledSEL,
                            method_getImplementation(originMethod),
                            method_getTypeEncoding(originMethod));
    } else {
        method_exchangeImplementations(originMethod, swizzledMethod);
    }
}

void IESGurdKitHookInstanceMethod(Class targetClass, SEL originalSEL, SEL swizzledSEL) {
    IESGurdKitHookMethod(targetClass, originalSEL, swizzledSEL);
}

void IESGurdKitHookClassMethod(Class targetClass, SEL originalSEL, SEL swizzledSEL) {
    IESGurdKitHookMethod(objc_getMetaClass(class_getName(targetClass)), originalSEL, swizzledSEL);
}

#pragma mark - Queue

dispatch_queue_t IESGurdKitCreateSerialQueue(const char *label)
{
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
    return dispatch_queue_create(label, attr);
}

dispatch_queue_t IESGurdKitCreateConcurrentQueue(const char *_Nullable label)
{
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_DEFAULT, 0);
    return dispatch_queue_create(label, attr);
}

#pragma mark - NSCoding

void IESGurdKitKeyedArchive (id rootObject, NSString *path)
{
    BOOL didArchive = NO;
    if (@available(iOS 11.0, *)) {
        if ([NSKeyedArchiver respondsToSelector:@selector(archivedDataWithRootObject:requiringSecureCoding:error:)]) {
            @try {
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rootObject requiringSecureCoding:YES error:nil];
                [data writeToFile:path atomically:YES];
            } @catch (NSException *exception) {
                
            }
            didArchive = YES;
        }
    }
    if (!didArchive) {
        @try {
            [NSKeyedArchiver archiveRootObject:rootObject toFile:path];
        } @catch (NSException *exception) {
            
        }
    }
}

id IESGurdKitKeyedUnarchiveObject (NSString *path, NSArray *classes)
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data.length == 0) {
        return nil;
    }
    
    id object = nil;
    
    BOOL didUnarchived = NO;
    if (@available(iOS 11.0, *)) {
        if ([NSKeyedUnarchiver respondsToSelector:@selector(unarchivedObjectOfClasses:fromData:error:)]) {
            @try {
                NSError *error = nil;
                object = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:classes]
                                                             fromData:data
                                                                error:&error];
            } @catch (NSException *exception) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            }
            didUnarchived = YES;
        }
    }
    if (!didUnarchived) {
        @try {
            object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        } @catch (NSException *exception) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
    }
    
    return object;
}

BOOL decompressFile (NSString *_Nonnull src, NSString *_Nonnull dest, NSString **_Nonnull errorMsg)
{
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:src]) {
        *errorMsg = [NSString stringWithFormat:@"decompressFile failed, src not exist:%@", src];
        return NO;
    }
    if ([manager fileExistsAtPath:dest]) {
        [manager removeItemAtPath:dest error:nil];
    }

    NSData *data = [manager contentsAtPath:src];
    if (!data) {
        *errorMsg = [NSString stringWithFormat:@"decompressFile failed, read file error:%@", src];
        return NO;
    }
    
    if ([IESGurdKit useNewDecompressZstd]) {
        BOOL result = [data zstd_decompressToFileName:dest];
        if (!result) {
            *errorMsg = [NSString stringWithFormat:@"decompressFile failed:%@", src];
            return NO;
        }
    } else {
        NSData *result = [data zstd_decompress];
        if (!result) {
            *errorMsg = [NSString stringWithFormat:@"decompressFile failed, create decompress data error:%@", src];
            return NO;
        }

        if (![manager createFileAtPath:dest contents:result attributes:nil]) {
            *errorMsg = [NSString stringWithFormat:@"decompressFile failed, write file error:%@", src];
            return NO;
        };
    }

    return YES;
}
