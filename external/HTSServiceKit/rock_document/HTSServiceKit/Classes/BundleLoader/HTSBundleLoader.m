//
//  HTSBundleLoader.m
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/17.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "HTSBundleLoader.h"
#include <mach-o/getsect.h>
#import "HTSLazyModuleDelegate.h"
#import "HTSBundleLoader+Private.h"
#import <pthread.h>
#import <ByteDanceKit/BTDMacros.h>

#if DEBUG
    #define hts_keywordify autoreleasepool {}
#else
    #define hts_keywordify try {} @catch (...) {}
#endif

#ifndef onExit
#define onExit \
    hts_keywordify __strong void(^block)(void) __attribute__((cleanup(blockCleanUp), unused)) = ^
#endif

#ifndef HTS_MUTEX_LOCK
#define HTS_MUTEX_LOCK(lock) \
    pthread_mutex_lock(&(lock)); \
    @onExit{ \
        pthread_mutex_unlock(&(lock)); \
    };
#endif


/// Bundle Loader暂时用不到，加了个糙版的全局锁
static pthread_mutex_t _lock = PTHREAD_MUTEX_INITIALIZER;

static inline NSString * _adaptedBundleName(NSString * name);
HTSMachHeader * HTSGetMachHeader(NSString * name);

@interface _HTSLazyBundle: NSObject

@property (assign, nonatomic) CFBundleRef bundleRef;
@property (strong, nonatomic) NSArray<id<HTSLazyModuleDelegate>> * moduleDelegates;
@property (assign, nonatomic) BOOL isUnloading;

@end

@implementation _HTSLazyBundle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isUnloading = NO;
    }
    return self;
}

@end

@interface HTSBundleLoader()

@property (strong, nonatomic) NSMutableDictionary<NSString *,_HTSLazyBundle *> * bundleTracker;

@end

@implementation HTSBundleLoader

+ (instancetype)sharedLoader{
    static dispatch_once_t onceToken;
    static HTSBundleLoader * _instance;
    dispatch_once(&onceToken, ^{
        _instance = [[HTSBundleLoader alloc] initPrivate];
    });
    return _instance;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        self.bundleTracker = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - load

+ (BOOL)loadName:(NSString *)name{
    return [[HTSBundleLoader sharedLoader] loadName:name];
}

- (BOOL)loadName:(NSString *)name{
    HTS_MUTEX_LOCK(_lock);
    if (!name) {
        return NO;
    }
    NSString * bundleName = _adaptedBundleName(name);
    NSString * path = [[NSBundle mainBundle].bundlePath stringByAppendingFormat:@"/Frameworks/%@",bundleName];
    NSURL * url = [[NSURL alloc] initWithString:path];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
       return NO;
    }
    if ([self.bundleTracker objectForKey:bundleName]) {
        return YES;
    }
    CFBundleRef ref = CFBundleCreate(kCFAllocatorDefault, (__bridge CFURLRef)url);
    BOOL res =  CFBundleLoadExecutable(ref);
    if (!res) {
        return NO;
    }
    _HTSLazyBundle * lazyBundle = [[_HTSLazyBundle alloc] init];
    HTSMachHeader * mh = HTSGetMachHeader(name);
    NSAssert(mh != nil, @"Fail to get macho header");
    size_t size = 0;
    const char ** data = (const char **)getsectiondata(mh,_HTS_SEGMENT, _HTS_LAZY_DELEGATE_SECTION, &size);
    unsigned long moduleCount = size / sizeof(const char *);
    NSMutableArray<id<HTSLazyModuleDelegate>> * lazyDelegates = [[NSMutableArray alloc] init];
    for (NSInteger idx = 0; idx < moduleCount; idx++) {
        const char * clsName = data[idx];
        Class cls = NSClassFromString([NSString stringWithUTF8String:clsName]);
        NSAssert(cls != nil, @"Fail to get module class");
        if (!cls) {
            continue;
        }
        id<HTSLazyModuleDelegate> delegate = [[cls alloc] init];
        [lazyDelegates addObject:delegate];
    }
    lazyBundle.moduleDelegates = lazyDelegates;
    [self.bundleTracker setObject:lazyBundle forKey:bundleName];
    for (id<HTSLazyModuleDelegate> delegate in lazyDelegates) {
        [delegate lazyModuleDidLoad];
    }
    if([self.delegate respondsToSelector:@selector(bundleLoader:didLoadBundle:)]){
        [self.delegate bundleLoader:self didLoadBundle:name];
    }
    return YES;
}

#pragma mark - unload

+ (void)unloadName:(NSString *)name{
    [[HTSBundleLoader sharedLoader] unloadName:name];
}

- (void)unloadName:(NSString *)name{
    HTS_MUTEX_LOCK(_lock);
    NSString * bundleName = _adaptedBundleName(name);
    _HTSLazyBundle * bundle;
    bundle = [self.bundleTracker objectForKey:bundleName];
    if (!bundle || bundle.isUnloading) {
        return;
    }
    bundle.isUnloading = YES;
    if ([self.delegate respondsToSelector:@selector(bundleLoader:willUnLoadName:)]) {
        [self.delegate bundleLoader:self willUnLoadName:name];
    }
    for (id<HTSLazyModuleDelegate> delegate in bundle.moduleDelegates) {
        [delegate lazyModuleWillUnload];
    }
    [self.bundleTracker removeObjectForKey:bundleName];
}


#pragma mark - Private

- (void *)pointerForBundleName:(NSString *)name symbolName:(NSString *)symbolName{
    HTS_MUTEX_LOCK(_lock);
    NSString * bundleName = _adaptedBundleName(name);
    void * pointer;
    _HTSLazyBundle * bundle = [self.bundleTracker objectForKey:bundleName];
    pointer = CFBundleGetDataPointerForName(bundle.bundleRef, (__bridge CFStringRef)symbolName);
    return pointer;
}

@end

#pragma mark - C API

void * HTSGetLazyPointer(NSString * bundleName, NSString * symbolName){
    return [[HTSBundleLoader sharedLoader] pointerForBundleName:bundleName symbolName:symbolName];
}

static inline NSString * _adaptedBundleName(NSString * name){
    NSString * res = name;
    if (![res hasSuffix:@".framework"]) {
        res = [res stringByAppendingString:@".framework"];
    }
    return res;
}

HTSMachHeader * HTSGetMachHeader(NSString * name){
    if (!name) {
        return NULL;
    }
    NSString * bundleName = _adaptedBundleName(name);
    NSString * targetPath = [[NSBundle mainBundle].bundlePath stringByAppendingFormat:@"/Frameworks/%@",bundleName];
    int32_t imageCount = _dyld_image_count();
    for (int32_t idx = 0; idx < imageCount; idx ++) {
        NSString * machoPath = [NSString stringWithUTF8String:_dyld_get_image_name(idx)];
        if ([machoPath isEqualToString:targetPath]) {
            return (HTSMachHeader *)_dyld_get_image_header(idx);
        }
    }
    return NULL;
}

void _HTSBundleLoaderLock(){
    pthread_mutex_lock(&_lock);
}

void _HTSBundleLoaderUnlock(){
    pthread_mutex_unlock(&_lock);
}
