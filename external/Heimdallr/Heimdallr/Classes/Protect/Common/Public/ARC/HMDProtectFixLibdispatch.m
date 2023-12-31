//
//  HMDProtectFixLibdispatch.m
//  Heimdallr
//
//  Created by maniackk on 2021/8/5.
//

#import "HMDProtectFixLibdispatch.h"
#include <BDFishhook/BDFishhook.h>
#include <mach-o/dyld.h>
#include <stdatomic.h>
#import "HMDExceptionTrackerConfig.h"
#import "Heimdallr+Private.h"
#import "HMDUserDefaults.h"
#import "HeimdallrModule.h"
#import "HMDALogProtocol.h"

#define kSourceCount 2000

static dispatch_queue_t callBackQueue;

static dispatch_queue_t cffdQueue;
static const char* cffdQueueLabel = "com.apple.CFFileDescriptor";
static dispatch_source_t source[kSourceCount];
static BOOL isCreateSource = false;

#define kHMDProtectCFFDQueueConfig  @"kHMDProtectCFFDQueueConfig"

static dispatch_queue_t
(*ori_dispatch_queue_create)(const char *_Nullable label,
        dispatch_queue_attr_t _Nullable attr);

inline static void queueRetainSource(void) {
    if (isCreateSource)
    {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"exchange many times");
        return;
    }
    for (int i = 0; i < kSourceCount; i++) {
        source[i] = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, cffdQueue);
    }
    isCreateSource = true;
}

static dispatch_queue_t
new_dispatch_queue_create(const char *_Nullable label,
        dispatch_queue_attr_t _Nullable attr)
{
    if (!cffdQueue && label && (strcmp(cffdQueueLabel, label) == 0)) {
        if (ori_dispatch_queue_create) {
            cffdQueue = ori_dispatch_queue_create(label, attr);
            queueRetainSource();
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"exchange success %p", cffdQueue);
            return cffdQueue;
        }
    }
    if (ori_dispatch_queue_create)
    {
        return ori_dispatch_queue_create(label, attr);
    }
    return NULL;
}


@implementation HMDProtectFixLibdispatch

+ (instancetype)sharedInstance {
    static HMDProtectFixLibdispatch *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDProtectFixLibdispatch alloc] init];
    });
    return instance;
}

- (void)fixGCDCrash {
    if ([self isProtectCFFDQueue]) {
        [self exchangeQueueMethod];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveConfigNotification:) name:HMDConfigManagerDidUpdateNotification object:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[HMDInjectedInfo defaultInfo] setCustomFilterValue:@(cffdQueue?1:0) forKey:@"cffdQueue"];
        });
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)exchangeQueueMethod {
    static atomic_flag token;
    if (atomic_flag_test_and_set_explicit(&token, memory_order_release)) {
        return;
    }
    if (callBackQueue) {
        return;
    }
    callBackQueue = dispatch_queue_create("com.heimdallr.exchangeGCDMethod", DISPATCH_QUEUE_SERIAL);
    _dyld_register_func_for_add_image(image_add_callback);
}

static void image_add_callback (const struct mach_header *mh, intptr_t vmaddr_slide) {
    dispatch_async(callBackQueue, ^{
        struct bd_rebinding r[] = {
            {"dispatch_queue_create",(void *)new_dispatch_queue_create,(void **)&ori_dispatch_queue_create}};
        bd_rebind_symbols_image((void *)mh, vmaddr_slide, r, sizeof(r)/sizeof(struct bd_rebinding));
    });
}

#pragma mark - get config

- (void)receiveConfigNotification:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSDictionary class]]) {
        NSArray *appIDs = notification.object[HMDConfigManagerDidUpdateAppIDKey];
        HMDConfigManager *updatedConfigManager = notification.object[HMDConfigManagerDidUpdateConfigKey];
        if (appIDs.count && updatedConfigManager.appID && [appIDs containsObject:updatedConfigManager.appID]) {
            [self storeProtectCFFDQueueConfig:updatedConfigManager.appID];
        }
    }
}

- (void)storeProtectCFFDQueueConfig:(NSString *)appID
{
    HMDExceptionTrackerConfig *exceptionConfig;
    if (appID) {
        HMDHeimdallrConfig *config = [[HMDConfigManager sharedInstance] remoteConfigWithAppID:appID];
        NSArray *modules = config.activeModulesMap.allValues;
        for (HMDModuleConfig *config in modules) {
            id<HeimdallrModule> module = [config getModule];
            if ([[module moduleName] isEqualToString:kHMDModuleProtectorName]) {
                exceptionConfig = (HMDExceptionTrackerConfig *)config;
                break;
            }
        }
    }
    [[HMDUserDefaults standardUserDefaults] removeObjectForKey:kHMDProtectCFFDQueueConfig];
    if (exceptionConfig) {
        NSArray *keyList = exceptionConfig.systemProtectList;
        BOOL isProtect = NO;
        if (keyList && [keyList isKindOfClass:[NSArray class]] && keyList.count > 0) {
            for (NSString *protect_type in keyList) {
                if ([protect_type isKindOfClass:[NSString class]] && (protect_type.length > 0) && [protect_type isEqualToString:@"CFFileDescriptor"]) {
                    isProtect = YES;
                    break;
                }
            }
        }
        [[HMDUserDefaults standardUserDefaults] setBool:isProtect forKey:kHMDProtectCFFDQueueConfig];
    }
}

- (BOOL)isProtectCFFDQueue {
    id flag = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:kHMDProtectCFFDQueueConfig];
    if([flag isKindOfClass:[NSNumber class]]) {
        return [flag boolValue];
    }
    return NO;
}

@end
