//
//  BDPSettingsManager.m
//  Timor
//
//  Created by 张朝杰 on 2019/7/11.
//


#import "BDPSDKConfig.h"
#import "BDPSettingsManager.h"
#import "BDPTimorClient.h"
//#import "BDPUserAgent.h"
#import "BDPUtils.h"
//#import "BDPVersionManager.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <objc/runtime.h>
#import <pthread.h>
#import <sys/utsname.h>
#import <ECOInfra/BDPLog.h>

// 两次请求settings的时间最小间隔, 5分钟. 不是每5分钟1次..淡定
#define MIN_REQUEST_INTERVAL 5 * 60

static NSString *const kBDPSettingsManagerSettingsKey = @"kBDPSettingsManagerSettingsKey";
static NSString *const kBDPSettingsManagerCtxInfosKey = @"kBDPSettingsManagerCtxInfosKey";


@interface BDPSettingsManager ()

@property (nonatomic, copy) NSDictionary *settings;
@property (nonatomic, assign) BOOL requesting;
@property (nonatomic, assign) BOOL succeedRequest;

@property (nonatomic, strong) NSMutableArray<void(^)(NSError *)> *completionArray;
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDPSettingsUpdateHandler> *updateHandlers;

/// 上次请求settings的cpu时间
@property (nonatomic, assign) NSTimeInterval lastRequestCPUTime;

@property (nonatomic, strong) id observerToken;

@end

@implementation BDPSettingsManager {
    pthread_rwlock_t rwlock;
}

+ (instancetype)sharedManager {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = self.new;
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.requesting = NO;
        self.succeedRequest = NO;
        self.completionArray = NSMutableArray.new;
        pthread_rwlock_init(&rwlock, NULL);
        
        [self setupDefaultSettings];
    }
    return self;
}

- (void)dealloc {
    if (self.observerToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.observerToken];
    }
}

- (void)setupDefaultSettings {
    // 默认配置的注册, 采用单例创建时, 懒注册
    // 其他时机如+load、小程序TimorClient初始化、+initilize, 都不如真正访问单例时创建更好
    SEL defaultSettingsSEL = NSSelectorFromString(@"defaultSettings"); // 反射解除对自己类别的耦合，同时调用类别的IMP
    if (defaultSettingsSEL) {
        Method defaultSettingsMethod = class_getClassMethod([self class], defaultSettingsSEL);
        if (defaultSettingsMethod) {
            IMP imp = method_getImplementation(defaultSettingsMethod);
            if (imp) {
                [self registerSettings:((NSDictionary* (*)(id, SEL))imp)([self class], defaultSettingsSEL)];
            }
        }
    }
}

- (void)setupObserver {
    WeakSelf;
    self.observerToken =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) { // 每次从后台回前台, 尝试更新一下Settings, 尽管首次启动也会触发, 但有请求间隔时间的限制, 不会有问题
        StrongSelfIfNilReturn;
        [self updateSettingsByForce:nil];
    }];
}

+ (NSMutableDictionary *)mergeWithNewSettings:(nullable NSDictionary<NSString *, id> *)newSettings exsitSettings:(nullable NSDictionary<NSString *, id> *)exsitSettings {
    NSMutableDictionary<NSString *, id> *mutableExsitSettings = [[self class] mutableDictionaryFromDictionary:exsitSettings];
    // iterate new settings
    for (NSString *key in newSettings) {
        // check string
        if (![key isKindOfClass:[NSString class]] || key.length == 0) {
            continue;
        }
        NSMutableDictionary<NSString *, id> *mutableTempSettings = mutableExsitSettings;
        // calculate count of levels
        NSArray<NSString *> *keySplit = [key componentsSeparatedByString:@"."];
        NSUInteger keySplitCount = keySplit.count;
        // iterate settings to the lowest level
        for (int i = 0; i < keySplitCount - 1; i++) {
            NSString *partKey = keySplit[i];
            // make sure mutable dict
            mutableTempSettings[partKey] = [self mutableDictionaryFromDictionary:mutableTempSettings[partKey]];

            // continue next iteration
            mutableTempSettings = mutableTempSettings[partKey];
        }
        // set new setting to the  to the lowest level
        mutableTempSettings[keySplit[keySplitCount - 1]] = newSettings[key];
    }
    return mutableExsitSettings;
}

+ (NSMutableDictionary *)mutableDictionaryFromDictionary:(NSDictionary *)dict {
    // 传入nil时，需要创建一个新的字典，以供后面填入数据
    if (!dict) {
        return [NSMutableDictionary dictionary];
    }
    // 检查类型是否合法，当类型不合法时，丢掉这里的数据，并创建一个新的字典，以供后面填入数据
    if (![dict isKindOfClass:[NSDictionary class]]) {
        NSString *errorMessage = [NSString stringWithFormat:@"mutableDictionaryFromDictionary with wrong type: data(%@), type(%@)", dict, NSStringFromClass([dict class])];
        // 这里不能打log，因为BDPLogError会调用BDPTimorClient，而BDPTimorClient初始化时会调用BDPSettingsManager，导致循环调用而crash
        NSAssert(NO, errorMessage);
        return [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
    return mutableDict;
}

- (void)registerSettings:(NSDictionary *)defaultSettings {
    NSMutableDictionary * _defaultSettings = [[self class] mergeWithNewSettings:defaultSettings exsitSettings:nil];
    // lint:disable:next lark_storage_check
    NSDictionary *cacheSettings = [NSUserDefaults.standardUserDefaults dictionaryForKey:kBDPSettingsManagerSettingsKey]?:@{};
    [_defaultSettings addEntriesFromDictionary:cacheSettings];
    pthread_rwlock_wrlock(&rwlock);
    self.settings = _defaultSettings;
    pthread_rwlock_unlock(&rwlock);
}

- (void)addSettings:(NSDictionary *)defaultSettings {
    pthread_rwlock_wrlock(&rwlock);
    self.settings = [[self class] mergeWithNewSettings:defaultSettings exsitSettings:self.settings];
    pthread_rwlock_unlock(&rwlock);
}

- (void)observeUpdateForConfigName:(NSString *)configName withHandler:(BDPSettingsUpdateHandler)handler {
    if (!configName.length) {
        return;
    }
    pthread_rwlock_wrlock(&rwlock);
    self.updateHandlers[configName] = handler;
    pthread_rwlock_unlock(&rwlock);
}

/// 判断是否应该更新settings。兼容宿主Lark不需要更新setings的情况
- (BOOL)shouldNotUpdateSettingsData {
    if ([BDPTimorClient sharedClient].currentNativeGlobalConfiguration.shouldNotUpdateSettingsData) {
        return YES;
    }
    return NO;
}

- (void)updateSettingsIfNeed:(nullable void (^)(NSError *))completion {
    if (self.succeedRequest || [self shouldNotUpdateSettingsData]) {
        return !completion?:completion(nil);
    } else {
        [self updateSettingsByForce:completion];
    }
}

- (void)updateSettingsByForce:(nullable void (^)(NSError *))completion {
    if ([self shouldNotUpdateSettingsData]) {
        !completion ?: completion(nil);
        return;
    }
    // Lark shouldNotUpdateSettingsData 始终应为false
    NSAssert(NO, @"should not do this in app");
    BDPLogError(@"should not do this in app!!");
}

+ (void)clearCache {
#if DEBUG
    // lint:disable lark_storage_check
    [NSUserDefaults.standardUserDefaults removeObjectForKey:kBDPSettingsManagerSettingsKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:kBDPSettingsManagerCtxInfosKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    // lint:enable lark_storage_check
#endif
}

- (id)s_objectValueForKey:(BDPSettingsKey *)key {
    pthread_rwlock_rdlock(&rwlock);
    id value = self.settings;
    pthread_rwlock_unlock(&rwlock);
    for (NSString *k in [key componentsSeparatedByString:@"."]) {
        if (value && [value isKindOfClass:[NSDictionary class]]) {
            value = [value objectForKey:k];
        } else {
            return nil;
        }
    }
    return value;
}

- (BOOL)s_boolValueForKey:(BDPSettingsKey *)key {
    return [self s_integerValueForKey:key] != 0;
}

- (NSInteger)s_integerValueForKey:(BDPSettingsKey *)key {
    id value = [self s_objectValueForKey:key];
    return (value && ([value isKindOfClass:NSString.class] || [value isKindOfClass:NSNumber.class])) ? [value integerValue] : 0;
}

- (CGFloat)s_floatValueForKey:(BDPSettingsKey *)key {
    id value = [self s_objectValueForKey:key];
    return (value && ([value isKindOfClass:NSString.class] || [value isKindOfClass:NSNumber.class])) ? [value floatValue] : 0.f;
}

- (NSString *)s_stringValueForKey:(BDPSettingsKey *)key {
    id value = [self s_objectValueForKey:key];
    if (value && [value isKindOfClass:NSString.class]) {
        return value;
    } else if (value && [value isKindOfClass:NSNumber.class]) {
        return [value stringValue];
    } else {
        return nil;
    }
}

- (NSArray *)s_arrayValueForKey:(BDPSettingsKey *)key {
    id value = [self s_objectValueForKey:key];
    return (value && [value isKindOfClass:NSArray.class]) ? value : nil;
}

- (NSDictionary *)s_dictionaryValueForKey:(BDPSettingsKey *)key {
    id value = [self s_objectValueForKey:key];
    return (value && [value isKindOfClass:NSDictionary.class]) ? value : nil;
}

#pragma mark - LazyLoading
- (NSMutableDictionary<NSString *,BDPSettingsUpdateHandler> *)updateHandlers {
    if (!_updateHandlers) {
        _updateHandlers = [[NSMutableDictionary<NSString *,BDPSettingsUpdateHandler> alloc] init];
    }
    return _updateHandlers;
}
@end
