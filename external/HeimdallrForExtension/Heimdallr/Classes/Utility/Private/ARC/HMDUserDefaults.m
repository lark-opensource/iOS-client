//
//  HMDUserDefaults.m
//  Pods
//
//  Created by xuminghao.eric on 2020/3/4.
//

#import "HMDUserDefaults.h"
#import "NSDictionary+HMDSafe.h"
#import "HeimdallrUtilities.h"
#import "NSObject+Validate.h"
#import "HMDGCD.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDAlogProtocol.h"

#define HMD_USER_DEFAULTS_SERIAL_QUEUE "com.heimdallr.HMDUserDefaults.access"
static NSString *const HMDUserDefaultsPathComponent = @"HMDUserDefaults";
static NSString *const HMDUserDefaultsSuiteName = @"apm.heimdallr.userdefaults";


@interface HMDUserDefaults ()

/// Equivalent to the suite name for NSUserDefaults.
@property(readonly) CFStringRef appNameRef;
/// set operation will use xpc_connection_send_message_with_reply_sync which may cause app stuck
/// so the set operation should be avoided to call in the main thread
@property(nonatomic, readonly) dispatch_queue_t serialSetQueue;

@end

@implementation HMDUserDefaults {
    // The application name is the same with the suite name of the NSUserDefaults, and it is used for preferences.
    CFStringRef _appNameRef;
    // lazy loading the history plist
    NSDictionary *_historyDic;
}

- (void)dealloc {
    // If we're using a custom `_appNameRef` it needs to be released. If it's a constant, it shouldn't
    // need to be released since we don't own it.
    if (CFStringCompare(_appNameRef, kCFPreferencesCurrentApplication, 0) != kCFCompareEqualTo) {
      CFRelease(_appNameRef);
    }
}

#pragma mark - singleton

+ (instancetype)standardUserDefaults {
    static HMDUserDefaults *standardUserDefaults = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        standardUserDefaults = [[super allocWithZone:NULL] init];
    });
    return standardUserDefaults;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)init {
    _serialSetQueue = dispatch_queue_create(HMD_USER_DEFAULTS_SERIAL_QUEUE, DISPATCH_QUEUE_SERIAL);
    return [self initWithSuiteName:HMDUserDefaultsSuiteName];
}

- (instancetype)initWithSuiteName:(nullable NSString *)suiteName {
    self = [super init];
    NSString *name = [suiteName copy];
    if (self) {
        // `kCFPreferencesCurrentApplication` maps to the same defaults database as
        // `[NSUserDefaults standardUserDefaults]`.
        _appNameRef = name.length ? (__bridge_retained CFStringRef)name : kCFPreferencesCurrentApplication;
      }
    return self;
}

#pragma mark - compatible with historical versions

- (NSDictionary *)sharedHistory {
    static NSDictionary *historyDic = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSString *directoryPath = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:HMDUserDefaultsPathComponent];
        
        NSString *historyPath = [[directoryPath stringByAppendingPathComponent:HMDUserDefaultsPathComponent] stringByAppendingPathExtension:@"plist"];
        
        if([[NSFileManager defaultManager] fileExistsAtPath: historyPath]) {
            historyDic = [NSDictionary dictionaryWithContentsOfFile:historyPath];
        }
    });
    return historyDic;
}


#pragma mark - fetch object

- (id)objectForKeyCompatibleWithHistory:(NSString *)defaultName {
    id object = [self objectForKey:defaultName];
    if(object || ![self sharedHistory]) {
        return object;
    }
    else {
        NSString *key = [defaultName copy];
        return [[self sharedHistory] hmd_objectForKey:key class:[NSString class]];
    }
}


- (id)objectForKey:(NSString *)defaultName {
    NSString *key = [defaultName copy];
    if (HMDIsEmptyString(key)) {
        return nil;
    }
    return (__bridge_transfer id)CFPreferencesCopyAppValue((__bridge CFStringRef)key, _appNameRef);
}

- (NSDictionary *)dictForKey:(NSString *)defaultName {
    return [self objectForKey:defaultName];
}

- (NSString *)stringForKey:(NSString *)defaultName {
    return [self objectForKey:defaultName];
}

- (BOOL)boolForKey:(NSString *)defaultName {
    id object = [self objectForKey:defaultName];
    if(object && [object isKindOfClass:[NSNumber class]]) {
        return [object boolValue];
    }
    else {
        return NO;
    }
}

- (NSInteger)integerForKey:(NSString *)defaultName {
    id object = [self objectForKey:defaultName];
    if(object && [object isKindOfClass:[NSNumber class]]) {
        return [object integerValue];
    }
    else {
        return 0;
    }
}

- (double)doubleForKey:(NSString *)defaultName {
    id object = [self objectForKey:defaultName];
    if(object && [object isKindOfClass:[NSNumber class]]) {
        return [object doubleValue];
    }
    else {
        return 0.0;
    }
}

#pragma mark - set object

- (void)setObject:(id)value forKey:(NSString *)defaultName {
    hmd_safe_dispatch_async(self.serialSetQueue, ^{
        NSString *key = [defaultName copy];
        if (HMDIsEmptyString(key)) {
            return;
        }
        if (!value) {
            CFPreferencesSetAppValue((__bridge CFStringRef)key, NULL, self->_appNameRef);
            return;
        }
        BOOL isAcceptableValue =
            [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] ||
            [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]] ||
            [value isKindOfClass:[NSDate class]];
        if (!isAcceptableValue) {
            return;
        }
        
        @try {
            CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFStringRef)value, self->_appNameRef);
        } @catch (NSException *exception) {
            if (hmd_log_enable()) {
                 HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Heimdallr userdefaults data can not be serialized with exception %@", exception.description);
            }
            return ;
        }
        
    });
}

- (void)setString:(NSString *)string forKey:(NSString *)defaultName {
    [self setObject:string forKey:defaultName];
}

- (void)setBool:(BOOL)boolValue forKey:(NSString *)defaultName {
    [self setObject:[NSNumber numberWithBool:boolValue] forKey:defaultName];
}

- (void)setInteger:(NSInteger)integer forKey:(NSString *)defaultName {
    [self setObject:[NSNumber numberWithInteger:integer] forKey:defaultName];
}

#pragma mark - removing objects

- (void)removeObjectForKey:(NSString *)defaultName {
    [self setObject:nil forKey:defaultName];
}

- (void)removeAllObjects {
    // On macOS, using `kCFPreferencesCurrentHost` will not set all the keys necessary to match
    // `NSUserDefaults`.
    hmd_safe_dispatch_async(self.serialSetQueue, ^{
        #if TARGET_OS_MAC
          CFStringRef host = kCFPreferencesAnyHost;
        #else
          CFStringRef host = kCFPreferencesCurrentHost;
        #endif  // TARGET_OS_OSX

        CFArrayRef keyList = CFPreferencesCopyKeyList(self->_appNameRef, kCFPreferencesCurrentUser, host);
        if (!keyList) return;
        CFPreferencesSetMultiple(NULL, keyList, self->_appNameRef, kCFPreferencesCurrentUser, host);
        CFRelease(keyList);
    });
}


@end
