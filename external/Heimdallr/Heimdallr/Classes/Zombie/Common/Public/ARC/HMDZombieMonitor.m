//
//  HMDZombieMonitor.m
//  ZombieDemo
//
//  Created by Liuchengqing on 2020/3/2.
//  Copyright © 2020 Liuchengqing. All rights reserved.
//

#import "HMDZombieMonitor.h"
#import "HMDZombieHandle.h"
#import "HMDZombieObject.h"
#include <dlfcn.h>
#import <objc/runtime.h>
#import "HMDWeakProxy.h"
#include <mach-o/dyld.h>
#import "Heimdallr+Private.h"
#import "HMDZombieTrackerConfig.h"
#import "HMDUserDefaults.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDZombieQueue.h"
#import <pthread/pthread.h>
#import "HMDMacro.h"

//#define ZombieCheckLog
#ifdef ZombieCheckLog
#define ZombieLog(...) HMDPrint(__VA_ARGS__)
#else
#define ZombieLog(...)
#endif

#define kHMDZombieConfig  @"kHMDZombieConfig"

#if TARGET_OS_OSX && __x86_64__
    // 64-bit Mac - tag bit is LSB
#   define HMD_ZOMBIE_OBJC_MSB_TAGGED_POINTERS 0
#else
    // Everything else - tag bit is MSB
#   define HMD_ZOMBIE_OBJC_MSB_TAGGED_POINTERS 1
#endif

#if HMD_ZOMBIE_OBJC_MSB_TAGGED_POINTERS
#   define HMD_ZOMBIE_OBJC_TAG_MASK (1ULL<<63)
#else
#   define HMD_ZOMBIE_OBJC_TAG_MASK 1
#endif

static void (*orig_CFNonObjCRelease)(CFTypeRef cf);


static NSInteger const kMaxCacheOjbjectCount = 80 * 1024;
static NSInteger const kMaxCacheMemorySize = 10 * 1024 * 1024;

static void zombieHookMethod(void);
static void zombie_set_instance_imp(Class cls, SEL sourceSelector, SEL targetSelector);

// 只在default type下使用
static NSArray<NSString *> *hmd_zombie_default_blocklist_names(void) {
    static NSArray *_blocklist = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 与老逻辑保持一致, 添加OSLog相关（调用频繁，降低开销）
        _blocklist = @[@"NSBundle", @"CALayer", @"NSUserDefaults",
                       @"OS_xpc_serializer", @"OS_xpc_string", @"OS_xpc_data", @"OS_xpc_uuid", @"OS_xpc_dictionary", @"OS_xpc_uint64", @"OS_dispatch_data",@"OS_xpc_object", @"OS_xpc_payload"];
    });
    return _blocklist;
}

// hook CF object，例如__NSCFArray的release在CF中实现，无法通过直接hook 拦截 NonObjCRelease
static NSArray<NSString *> *hmd_zombie_default_NonObjCRelease_names(void) {
    static NSArray *_nonObjC = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _nonObjC = @[
                     @"__NSCFString", @"__NSCFAttributedString", @"NSCFAttributedString",
                     @"__NSCFArray", @"NSCFArray", @"__NSCFDictionary", @"NSCFDictionary",
                     @"__NSCFSet", @"__NSCFCharacterSet", @"NSCFCharacterSet",
                     @"__NSCFNumber", @"__NSCFBoolean", @"__NSCFError", @"NSCFError",
                     @"__NSCFData", @"NSCFData", @"__NSCFTimer", @"NSCFTimer", @"__NSCFCalendar", @"__NSCFLocale",
                     @"__NSCFOutputStream", @"NSCFOutputStream", @"__NSCFInputStream", @"NSCFInputStream",
                     ];
    });
    return _nonObjC;
}

static inline bool hmd_zombie_objc_isTaggedPointer(const void *ptr) {
    bool result =  ((intptr_t)ptr & HMD_ZOMBIE_OBJC_TAG_MASK) == HMD_ZOMBIE_OBJC_TAG_MASK;
    return result;
}


@interface HMDZombieMonitor()

@property (nonatomic, assign) CFMutableSetRef checkList;

@property (nonatomic, assign) CFMutableSetRef checkBacklist;

@property (nonatomic, assign) BOOL isMonitor;

@property (nonatomic, strong, readwrite)HMDZombieTrackerConfig *zombieConfig;

@property (nonatomic, strong)HMDZombieQueue *zombieQueue;

@end


@implementation HMDZombieMonitor

bool CheckHookOC(Class cls,SEL sel){
    Dl_info info;
    Method method = class_getInstanceMethod(cls, sel);
    if(!method){
        method = class_getClassMethod(cls, sel);
    }
    IMP imp = method_getImplementation(method);
    if(!dladdr((void*)imp, &info)){
        return true;
    }
    if(strcmp(info.dli_fname, _dyld_get_image_name(0)) == 0){
        return true;
    }
    // /usr/lib/libobjc.A.dylib
    return false;
}

+ (BOOL)canExchangeDeallocMethod {
    bool objcHooked = CheckHookOC([NSObject class], sel_registerName("dealloc"));
    bool proxyHooked = CheckHookOC([NSProxy class], sel_registerName("dealloc"));
    if (objcHooked || proxyHooked) {
        NSAssert(NO, @"promise zombie first hook dealloc method");
        return false;
    }
    return true;
}

+ (void)exchangeDeallocMethod {
    zombie_set_instance_imp([NSObject class], sel_registerName("dealloc"), sel_registerName("hmd_originDealloc"));
    zombie_set_instance_imp([NSObject class], sel_registerName("hmd_zombieDealloc"), sel_registerName("dealloc"));

    zombie_set_instance_imp([NSProxy class], sel_registerName("dealloc"), sel_registerName("hmd_originDealloc"));
    zombie_set_instance_imp([NSProxy class], sel_registerName("hmd_zombieDealloc"), sel_registerName("dealloc"));
}

+ (void)load {
    HMDZombieTrackerConfig *zombieConfig = [HMDZombieMonitor getZombieConfig];
    if (zombieConfig) {
        bool canHook = [self canExchangeDeallocMethod];
        if (canHook) {
            [HMDZombieMonitor sharedInstance].zombieConfig = zombieConfig;
            [HMDZombieMonitor sharedInstance].monitorType = HMDZombieTypeDefault;
            [HMDZombieHandle setupVariable];
            HMDZombieMonitor.sharedInstance.needMonitorCFObject = zombieConfig.monitorCFObj;
            [[HMDZombieMonitor sharedInstance] startMonitor];
            [self exchangeDeallocMethod];
        }
    }
}

+ (void)initialize {
    // dlsym内部会加锁，且dyld相关操作会触发dealloc，如果dlsym放在锁内，一定概率会造成死锁
    orig_CFNonObjCRelease = (void(*)(CFTypeRef))dlsym(RTLD_DEFAULT, "_CFNonObjCRelease");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance {
    static HMDZombieMonitor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [HMDZombieMonitor new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.isMonitor = NO;
        self.crashWhenDetectedZombie = YES;
        self.needMonitorCFObject = NO;
        self.zombieQueue = [[HMDZombieQueue alloc] init];
        _maxCacheSize = kMaxCacheMemorySize;
        _maxCacheCount = kMaxCacheOjbjectCount;
        self.zombieQueue.maxCacheSize = self.maxCacheSize * 0.6;
        self.zombieQueue.maxCacheCount = self.maxCacheCount * 0.6;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveConfigNotification:) name:HMDConfigManagerDidUpdateNotification object:nil];
    }
    return self;
}

- (void)setMaxCacheSize:(NSUInteger)maxCacheSize {
    _maxCacheSize = maxCacheSize;
    self.zombieQueue.maxCacheSize = _maxCacheSize * 0.8;
}

- (void)setMaxCacheCount:(NSUInteger)maxCacheCount {
    _maxCacheCount = maxCacheCount;
    self.zombieQueue.maxCacheCount = _maxCacheCount * 0.8;
}

// 设置监控类型
- (void)setMonitorType:(HMDZombieType)monitorType {
    _monitorType = monitorType;
    
    self.checkList = CFSetCreateMutable(NULL, 0, NULL);
    self.checkBacklist = CFSetCreateMutable(NULL, 0, NULL);
    for (NSString *name in hmd_zombie_default_NonObjCRelease_names()) {
        Class cls = NSClassFromString(name);
        if (cls) {
            CFSetAddValue(self.checkBacklist, (__bridge void *)cls);
        }
    }
    
    for (NSString *name in self.zombieConfig.monitorClassList) {
        Class cls = NSClassFromString(name);
        if (cls) {
            CFSetAddValue(self.checkList, (__bridge void *)cls);
        }
    }
    
    switch (monitorType) {
        case HMDZombieTypeAll:{
            break;
        }
        default:{
            for (NSString *name in hmd_zombie_default_blocklist_names()) {
                Class cls = NSClassFromString(name);
                if (cls) {
                    CFSetAddValue(self.checkBacklist, (__bridge void *)cls);
                }
            }
            break;
        }
    }
}

// 开启监控
- (void)startMonitor {
    // 标记
    self.isMonitor = YES;
    
    [self.zombieQueue createCacheZone];
    // 都准备好再hook
    zombieHookMethod();
    // 避免oom，安全气垫中加锁了，避免死锁
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(cleanupZombieCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

// filter blockList and allowList
- (BOOL)shouldMonitor:(Class)cls {
    if (cls == NULL) {
        return NO;
    }
    // backlist > checklist 默认checklist为空则全检查
    if (CFSetContainsValue(self.checkBacklist, (__bridge void *)cls)) {
        return NO;
    }
    if (CFSetGetCount(self.checkList) == 0) {
        return YES;
    }
    return CFSetContainsValue(self.checkList, (__bridge void *)cls);
}

- (void)receiveConfigNotification:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSDictionary class]]) {
        NSArray *appIDs = notification.object[HMDConfigManagerDidUpdateAppIDKey];
        HMDConfigManager *updatedConfigManager = notification.object[HMDConfigManagerDidUpdateConfigKey];
        if (appIDs.count && updatedConfigManager.appID && [appIDs containsObject:updatedConfigManager.appID]) {
            [self storeZombieConfig:updatedConfigManager.appID];
        }
    }
}

- (void)storeZombieConfig:(NSString *)appID
{
    HMDZombieTrackerConfig *zombieConfig;
    if (appID) {
        HMDHeimdallrConfig *config = [[HMDConfigManager sharedInstance] remoteConfigWithAppID:appID];
        NSArray *modules = config.activeModulesMap.allValues;
        for (HMDModuleConfig *config in modules) {
            id<HeimdallrModule> module = [config getModule];
            if ([[module moduleName] isEqualToString:kHMDModuleZombieDetector]) {
                zombieConfig = (HMDZombieTrackerConfig *)config;
                break;
            }
        }
    }
    [[HMDUserDefaults standardUserDefaults] removeObjectForKey:kHMDZombieConfig];
    if (zombieConfig && zombieConfig.enableOpen) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic hmd_setObject:@(zombieConfig.monitorCFObj) forKey:@"monitorCFObj"];
        [dic hmd_setObject:@(zombieConfig.maxZombieDeallocCount) forKey:@"maxZombieDeallocCount"];
        [dic hmd_setCollection:zombieConfig.classList forKey:@"classList"];
        [dic hmd_setCollection:zombieConfig.monitorClassList forKey:@"monitorClassList"];
        [dic hmd_setObject:@(zombieConfig.enableOpen) forKey:@"enable_open"];
        [[HMDUserDefaults standardUserDefaults] setObject:dic.copy forKey:kHMDZombieConfig];
    }
}

+ (HMDZombieTrackerConfig *)getZombieConfig
{
    HMDZombieTrackerConfig *zombieConfig;
    NSDictionary *dic = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:kHMDZombieConfig];
    if (dic) {
        zombieConfig = [[HMDZombieTrackerConfig alloc] init];
        NSArray *classList = [dic objectForKey:@"classList"];
        zombieConfig.classList = classList?:@[];
        NSArray *monitorClassList = [dic objectForKey:@"monitorClassList"];
        zombieConfig.monitorClassList = monitorClassList?:@[];
        
        zombieConfig.maxZombieDeallocCount = [dic hmd_intForKey:@"maxZombieDeallocCount"];
#ifdef DEBUG
        zombieConfig.monitorCFObj = [dic hmd_boolForKey:@"monitorCFObj"];
#endif
        zombieConfig.enableOpen = [dic hmd_boolForKey:@"enable_open"];
    }
    return zombieConfig;
}

#pragma mark - Cache

- (void)cacheZombieObj:(void * _Nonnull)zombieObj cfAllocator:(CFAllocatorRef _Nullable)cfAllocator backtrace:(const char * _Nullable)backtrace size:(size_t)size {
    if (__builtin_expect(self.isMonitor == NO || zombieObj == NULL, 0)) {
        return;
    }
    ZombieLog("cache-%p-%s\n", zombieObj, clsName);
    [self.zombieQueue storeObj:zombieObj cfAllocator:cfAllocator backtrace:backtrace size:size];
}

- (const char* _Nullable)getZombieBacktrace:(void * _Nonnull)obj {
    return [self.zombieQueue getBacktrace:obj];
}

// 内存⚠️释放所有缓存
- (void)cleanupZombieCache {
    [self.zombieQueue cleanupZombieCache];
}

@end

#pragma mark - HookDealloc
static void zombie_set_instance_imp(Class cls, SEL sourceSelector, SEL targetSelector) {
    Method sourceMethod = class_getInstanceMethod(cls, sourceSelector);
    if (sourceMethod) {
        class_replaceMethod(cls, targetSelector, method_getImplementation(sourceMethod), method_getTypeEncoding(sourceMethod));
    } else {
#ifdef DEBUG
        __builtin_trap();
#endif
    }
}

CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE
static BOOL isHookCFObject = NO;
CLANG_DIAGNOSTIC_POP
static void zombieHookMethod (void) {
#ifdef DEBUG
    // CF
    if (!HMDZombieMonitor.sharedInstance.needMonitorCFObject) {
        return;
    }
    if (orig_CFNonObjCRelease && !isHookCFObject) {
        isHookCFObject = YES;
        for (NSString *name in hmd_zombie_default_NonObjCRelease_names()) {
            Class cls = NSClassFromString(name);
            if (cls) {
                zombie_set_instance_imp(cls, sel_registerName("release"), sel_registerName("hmd_originRelease"));
                zombie_set_instance_imp(cls, sel_registerName("hmd_zombieRelease"), sel_registerName("release"));
            }
        }
    }
#endif
}

#pragma mark - NSObject Zombie

@interface NSObject (ZombieDetector)

@end


@implementation NSObject (ZombieDetector)

- (void)hmd_originDealloc {
    // 缓存原始实现
}

- (void)hmd_originRelease {
    // 缓存原始实现
}

- (void)hmd_zombieDealloc {
    if (hmd_zombie_objc_isTaggedPointer((__bridge const void *)(self))) {
        return;
    }
    
    //获取类
    Class cls = object_getClass(self);
    if ([HMDZombieMonitor.sharedInstance shouldMonitor:cls]) {
        // 处理失败调原有实现
        if (![HMDZombieHandle deallocHandle:self class:cls]) {
            [self hmd_originDealloc];
        }
    } else {
        [self hmd_originDealloc];
    }
}

- (oneway void)hmd_zombieRelease {
    ZombieLog("release-%p\n", self);
    if (isZombieClass((char *)class_getName(self.class))) {
        [self hmd_originRelease];
    }
    // 引用计数检查
    else if (CFGetRetainCount((__bridge CFTypeRef)self) != 1) {
        [self hmd_originRelease];
    }
    else {
        // 处理失败调原有实现
        if (![HMDZombieHandle cfNonObjCReleaseHandle:self]) {
            ZombieLog("not handle release-%p\n", self);
            [self hmd_originRelease];
        } else {
            ZombieLog("handle release-%p\n", self);
        }
    }
}

@end


#pragma mark - NSProxy Zombie
@interface NSProxy (ZombieDetector)

@end

@implementation NSProxy (ZombieDetector)

- (void)hmd_originDealloc {
    // 缓存原始实现
}

- (void)hmd_zombieDealloc {
    //获取类
    Class cls = object_getClass(self);
    if ([HMDZombieMonitor.sharedInstance shouldMonitor:cls]) {
        // 处理失败调原有实现
        if (![HMDZombieHandle deallocHandle:self class:cls]) {
            [self hmd_originDealloc];
        }
    } else {
        [self hmd_originDealloc];
    }
}

@end
