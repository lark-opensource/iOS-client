//
//  BDImageUserDefaults.m
//  BDWebImage
//
//  Created by 陈奕 on 2020/5/21.
//

#import "BDImageUserDefaults.h"

static NSTimeInterval const kBDISynchronizeInterval = 0.5;
static NSString *const kBDImageUserDefaultsName = @"com.image.cache.defaults";

@interface BDImageUserDefaults ()

/// Equivalent to the suite name for NSUserDefaults.
@property(readonly) CFStringRef appNameRef;

@property(atomic) BOOL isPreferenceFileExcluded;

@end

@implementation BDImageUserDefaults {
    // The application name is the same with the suite name of the NSUserDefaults, and it is used for
    // preferences.
    CFStringRef _appNameRef;
}

+ (BDImageUserDefaults *)standardUserDefaults
{
    static BDImageUserDefaults *standardUserDefaults;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        standardUserDefaults = [[BDImageUserDefaults alloc] init];
    });
    return standardUserDefaults;
}

- (instancetype)init
{
    return [self initWithSuiteName:nil];
}

- (instancetype)initWithSuiteName:(nullable NSString *)suiteName
{
    self = [super init];

    NSString *name = [suiteName copy];

    if (self) {
        _appNameRef =(__bridge_retained CFStringRef) (name.length ? name : kBDImageUserDefaultsName);
    }

    return self;
}

- (void)dealloc
{
    // If we're using a custom `_appNameRef` it needs to be released. If it's a constant, it shouldn't
    // need to be released since we don't own it.
    if (CFStringCompare(_appNameRef, kCFPreferencesCurrentApplication, 0) != kCFCompareEqualTo) {
        CFRelease(_appNameRef);
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(synchronize)
                                               object:nil];
}

- (nullable id)objectForKey:(NSString *)defaultName
{
    NSString *key = [defaultName copy];
    if (![key isKindOfClass:[NSString class]] || !key.length) {
        return nil;
    }
    return (__bridge_transfer id)CFPreferencesCopyAppValue((__bridge CFStringRef)key, _appNameRef);
}

- (void)setObject:(nullable id)value forKey:(NSString *)defaultName
{
    NSString *key = [defaultName copy];
    if (![key isKindOfClass:[NSString class]] || !key.length) {
        return;
    }
    if (!value) {
        CFPreferencesSetAppValue((__bridge CFStringRef)key, NULL, _appNameRef);
        [self scheduleSynchronize];
        return;
    }
    BOOL isAcceptableValue = [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] ||
    [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]] ||
    [value isKindOfClass:[NSDate class]] || [value isKindOfClass:[NSData class]];
    if (!isAcceptableValue) {
        return;
    }

    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFStringRef)value, _appNameRef);
    [self scheduleSynchronize];
}

- (void)removeObjectForKey:(NSString *)key
{
    [self setObject:nil forKey:key];
}

#pragma mark - Getters

- (NSInteger)integerForKey:(NSString *)defaultName
{
    NSNumber *object = [self objectForKey:defaultName];
    return object.integerValue;
}

- (float)floatForKey:(NSString *)defaultName
{
    NSNumber *object = [self objectForKey:defaultName];
    return object.floatValue;
}

- (double)doubleForKey:(NSString *)defaultName
{
    NSNumber *object = [self objectForKey:defaultName];
    return object.doubleValue;
}

- (BOOL)boolForKey:(NSString *)defaultName
{
    NSNumber *object = [self objectForKey:defaultName];
    return object.boolValue;
}

- (nullable NSString *)stringForKey:(NSString *)defaultName
{
    return [self objectForKey:defaultName];
}

- (nullable NSArray *)arrayForKey:(NSString *)defaultName
{
    return [self objectForKey:defaultName];
}

- (nullable NSDictionary<NSString *, id> *)dictionaryForKey:(NSString *)defaultName
{
    return [self objectForKey:defaultName];
}

#pragma mark - Setters

- (void)setInteger:(NSInteger)integer forKey:(NSString *)defaultName
{
    [self setObject:@(integer) forKey:defaultName];
}

- (void)setFloat:(float)value forKey:(NSString *)defaultName
{
    [self setObject:@(value) forKey:defaultName];
}

- (void)setDouble:(double)doubleNumber forKey:(NSString *)defaultName
{
    [self setObject:@(doubleNumber) forKey:defaultName];
}

- (void)setBool:(BOOL)boolValue forKey:(NSString *)defaultName
{
    [self setObject:@(boolValue) forKey:defaultName];
}

#pragma mark - Save data

- (void)synchronize
{
    CFPreferencesAppSynchronize(_appNameRef);
}

#pragma mark - Clear data

- (NSString *)filePathForPreferencesName:(NSString *)preferencesName
{
    if (!preferencesName.length) {
        return @"";
    }

    // User Defaults exist in the Library directory, get the path to use it as a prefix.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSArray *components = @[
        paths.lastObject, @"Preferences", [preferencesName stringByAppendingPathExtension:@"plist"]
    ];
    return [NSString pathWithComponents:components];
}

- (void)removePreferenceFileWithSuiteName:(NSString *)suiteName
{
    NSString *path = [self filePathForPreferencesName:suiteName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [fileManager removeItemAtPath:path error:NULL];
        });
    }
}

#pragma mark - Private methods

- (void)scheduleSynchronize
{
  // Synchronize data using a timer so that multiple set... calls can be coalesced under one
  // synchronize.
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(synchronize)
                                             object:nil];
  // This method may be called on multiple queues (due to set... methods can be called on any queue)
  // synchronize can be scheduled on different queues, so make sure that it does not crash. If this
  // instance goes away, self will be released also, no one will retain it and the schedule won't be
  // called.
  [self performSelector:@selector(synchronize)
             withObject:nil
             afterDelay:kBDISynchronizeInterval];
}

@end
