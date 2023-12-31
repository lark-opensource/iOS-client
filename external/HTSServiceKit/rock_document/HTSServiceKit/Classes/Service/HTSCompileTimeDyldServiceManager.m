//
//  HTSCompileTimeServiceManager.m
//  HTSServiceKit
//
//  Created by chenxiancai on 2021/7/4.
//

#import "HTSCompileTimeDyldServiceManager.h"
#import "HTSMacro.h"
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import "HTSAppMode.h"
#import "HTSBundleLoader.h"
#import <pthread.h>

#ifndef __LP64__
typedef struct mach_header HTSMachHeader;
#else
typedef struct mach_header_64 HTSMachHeader;
#endif

//bundle name -> HTSCompileTimeServiceImplHash
static HTSCompileTimeBundleServiceImplHash* _compileTimeBundleServiceImplHash;
//bundle name -> HTSCompileTimeServiceClassHash
static HTSCompileTimeBundleServiceClassHash* _compileTimeBundleServiceClassHash;
//protocol name -> dylib name
static HTSCompileTimeServiceHash* _compileTimeServiceHash;

static pthread_mutex_t _compileTimeServicelock;

@interface HTSCompileTimeDyldServiceCenter  : NSObject
@end

@implementation HTSCompileTimeDyldServiceCenter
@end

static void _parseCompileServiceStructInMachO(HTSMachHeader *mh,const char *segment){
    unsigned long size = 0;
    _hts_dyld_service_struct * data = (_hts_dyld_service_struct *)getsectiondata(mh,segment, _HTS_DYLD_SERVICE_SECTION, &size);
    if (size == 0)  return;
    uint32_t count = size / sizeof(_hts_dyld_service_struct);
    if (count == 0) return;
    for (NSInteger idy = 0; idy < count; idy++) {
        _hts_dyld_service_struct value = data[idy];
#if __has_feature(address_sanitizer)
        if(value.protocol == 0 || value.bundle == 0) {
            continue;
        }
#endif
        NSString * protocolName = [[NSString alloc] initWithUTF8String:value.protocol];
        NSString * dylibName = [[NSString alloc] initWithUTF8String:value.bundle];
        if (dylibName.length == 0) {
            dylibName = _HTS_DYLD_MAIN_BUNDLE;
        }
#if DEBUG
        if (!protocolName) {
            [NSException raise:@"HTSServiceInvalidException" format:@"Invalid protocol: %@",protocolName];
        }
       
        if ([_compileTimeServiceHash objectForKey:protocolName] != nil) {
            [NSException raise:@"HTSServiceInvalidException"
                        format:@"Protocol %@ bind twice to one dynamic lib",protocolName];
        }
#endif
        if (protocolName && dylibName && dylibName.length > 0) {
            [_compileTimeServiceHash setObject:dylibName forKey:protocolName];
        }
    }
}

static BOOL _parseCompileServiceImplStructInMachO(NSString * bundleName, HTSMachHeader *mh,const char *segment){
    
    unsigned long size = 0;
    _hts_dyld_service_imp_struct * data = (_hts_dyld_service_imp_struct *)getsectiondata(mh,segment, _HTS_DYLD_SERVICE_IMPL_SECTION, &size);
    if (size == 0)  return NO;
    uint32_t count = size / sizeof(_hts_dyld_service_imp_struct);
    if (count == 0) return NO;
    
    if ([_compileTimeBundleServiceImplHash objectForKey:bundleName] != nil || [_compileTimeBundleServiceClassHash objectForKey:bundleName] != nil) {
#if DEBUG
        [NSException raise:@"HTSServiceInvalidException"
                    format:@"bundle %@ bind twice. ",bundleName];
#endif
        return YES;
    }

    HTSCompileTimeServiceImplHash * serviceImplHash = [[NSMutableDictionary alloc] init];
    HTSCompileTimeServiceClassHash * serviceClassHash = [[NSMutableDictionary alloc] init];

    for (NSInteger idy = 0; idy < count; idy++) {
        _hts_dyld_service_imp_struct value = data[idy];
#if __has_feature(address_sanitizer)
        if(value.protocol == 0 || value.clz == 0 || value.service_imp == 0) {
            continue;
        }
#endif
        NSString * protocolName = [[NSString alloc] initWithUTF8String:value.protocol];
        Protocol * protocol = NSProtocolFromString(protocolName);
        NSString * className = [[NSString alloc] initWithUTF8String:value.clz];
        Class cls = NSClassFromString(className);
        _hts_dyld_service_method serviceImpl = (_hts_dyld_service_method)value.service_imp;
#if DEBUG
        if (!protocolName) {
            [NSException raise:@"HTSServiceInvalidException" format:@"Invalid protocol: %@",protocolName];
        }

        if (!cls) {
            [NSException raise:@"HTSServiceInvalidException" format:@"Invalid class: %@",protocolName];
        }
        
        if (!bundleName) {
            [NSException raise:@"HTSServiceInvalidException" format:@"Invalid bundle : %@",bundleName];

        }
        
        if (![cls conformsToProtocol:protocol] || ![cls conformsToProtocol:@protocol(HTSService)]) {
            [NSException raise:@"HTSServiceInvalidException" format:@"Class %@ not conforms to protocol %@ or HTSService",protocolName,protocolName];
        }
#endif

        if (cls && protocolName) {
            [serviceClassHash setObject:cls forKey:protocolName];
        }
        
        if (cls && serviceImpl) {
            [serviceImplHash setObject:[NSValue valueWithPointer:value.service_imp] forKey:protocolName];
        }
    }
    
    pthread_mutex_lock(&_compileTimeServicelock);
    if ([serviceClassHash.allKeys count] > 0) {
        [_compileTimeBundleServiceClassHash setObject:serviceClassHash forKey:bundleName];
    }
    
    if ([serviceImplHash.allKeys count] > 0) {
        [_compileTimeBundleServiceImplHash setObject:serviceImplHash forKey:bundleName];
    }
    pthread_mutex_unlock(&_compileTimeServicelock);

    return YES;
}

// Does not support lazy load framework
static void _loadCompileTimeServiceStruct(void) __attribute__((no_sanitize("address")))
{
    _compileTimeServiceHash = [[HTSCompileTimeServiceHash alloc] init];
    NSInteger imageCount = _dyld_image_count();
    for (uint32_t idx = 0; idx < imageCount; idx++) {
        HTSMachHeader * mh = (HTSMachHeader *)_dyld_get_image_header(idx);
        _parseCompileServiceStructInMachO(mh, _HTS_SEGMENT);
    }    
}

static void _loadCompileTimeMainBundleServiceImplStruct(void) __attribute__((no_sanitize("address")))
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSInteger imageCount = _dyld_image_count();
        for (uint32_t idx = 0; idx < imageCount; idx++) {
            HTSMachHeader * mh = (HTSMachHeader *)_dyld_get_image_header(idx);
            if (_parseCompileServiceImplStructInMachO(_HTS_DYLD_MAIN_BUNDLE, mh, _HTS_SEGMENT)) {
                break;
            }
        }
    });
}


// support lazy load framework
static void _loadCompileTimeServiceImplStruct(NSString * bundleName) __attribute__((no_sanitize("address")))
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _compileTimeBundleServiceImplHash = [[HTSCompileTimeBundleServiceImplHash alloc] init];
        _compileTimeBundleServiceClassHash = [[HTSCompileTimeBundleServiceClassHash alloc] init];
        pthread_mutex_init(&_compileTimeServicelock, NULL);
    });
    if ([bundleName isEqualToString:_HTS_DYLD_MAIN_BUNDLE]) {
        _loadCompileTimeMainBundleServiceImplStruct();
    } else {
        HTSMachHeader * mh = HTSGetMachHeader(bundleName);
        if (mh) {
            _parseCompileServiceImplStructInMachO(bundleName, mh, _HTS_SEGMENT);
        }
    }
}

static NSString * _getCompileTimeServiceBundle(NSString * protocolName)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _loadCompileTimeServiceStruct();
    });
    NSString *bundleName = [_compileTimeServiceHash objectForKey:protocolName];
    _loadCompileTimeServiceImplStruct(bundleName);
    return bundleName;
}

id htsGetService(Protocol * protocol)
{
    if (!protocol) return nil;
    NSString * protocolName = NSStringFromProtocol(protocol);
    if (!protocolName) return nil;
    NSString *bundleName = _getCompileTimeServiceBundle(protocolName);

    id obj = nil;
    
    pthread_mutex_lock(&_compileTimeServicelock);
    
    HTSCompileTimeServiceImplHash * serviceImplHash = [_compileTimeBundleServiceImplHash objectForKey:bundleName];
    NSValue *pointerValue = [serviceImplHash objectForKey:protocolName];
    _hts_dyld_service_method pointer = (_hts_dyld_service_method)[pointerValue pointerValue];
    if (pointer != NULL) {
        obj = pointer();
    }
    pthread_mutex_unlock(&_compileTimeServicelock);
    
    return obj;
}

void htsUnbindService(Protocol * protocol)
{
    if (!protocol) return ;
    NSString * protocolName = NSStringFromProtocol(protocol);
    NSString *bundleName = [_compileTimeServiceHash objectForKey:protocolName];
    
    pthread_mutex_lock(&_compileTimeServicelock);
    
    HTSCompileTimeServiceClassHash * serviceClassHash = [_compileTimeBundleServiceClassHash objectForKey:bundleName];
    [serviceClassHash removeObjectForKey:protocolName];
    [_compileTimeBundleServiceClassHash setObject:serviceClassHash forKey:bundleName];
    
    HTSCompileTimeServiceImplHash * serviceImplHash = [_compileTimeBundleServiceImplHash objectForKey:bundleName];
    [serviceImplHash removeObjectForKey:protocolName];
    [_compileTimeBundleServiceImplHash setObject:serviceImplHash forKey:bundleName];
    
    pthread_mutex_unlock(&_compileTimeServicelock);
}


