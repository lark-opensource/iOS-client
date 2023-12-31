//
//  HTSCompileTimeServiceManager.m
//  HTSServiceKit
//
//  Created by Huangwenchen on 2020/4/28.
//

#import "HTSCompileTimeServiceManager.h"
#import "HTSMacro.h"
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import "HTSServiceCenter.h"
#import "HTSAppMode.h"

#ifndef __LP64__
typedef struct mach_header HTSMachHeader;
#else
typedef struct mach_header_64 HTSMachHeader;
#endif

//protocol name -> class name
static NSMutableDictionary<NSString *,Class>* _defaultModeCompileTimeHash;
static NSMutableDictionary<NSString *,Class>* _currentModeCompileTimeHash;

static void _parseCompileServicePairInMachO(HTSMachHeader *mh,const char *segment, NSMutableDictionary<NSString *,Class>* container){
    unsigned long size = 0;
    _hts_service_pair * data = (_hts_service_pair *)getsectiondata(mh,segment, _HTS_SERVICE_SECTION, &size);
    if (size == 0)  return;
    uint32_t count = size / sizeof(_hts_service_pair);
    if (count == 0) return;
    for (NSInteger idy = 0; idy < count; idy++) {
        _hts_service_pair pair = data[idy];
#if __has_feature(address_sanitizer)
        if(pair.protocol == 0 || pair.cls == 0) {
            continue;
        }
#endif
        NSString * protocolName = [[NSString alloc] initWithUTF8String:pair.protocol];
        NSString * className = [[NSString alloc] initWithUTF8String:pair.cls];
        Protocol * protocol = NSProtocolFromString(protocolName);
        Class cls = NSClassFromString(className);
#if DEBUG
        if (!protocolName) {
            [NSException raise:@"HTSServiceInvalidException" format:@"Invalid protocol: %@",protocolName];
        }
        if (!cls) {
            [NSException raise:@"HTSServiceInvalidException" format:@"Invalid class: %@",className];
        }
        if (![cls conformsToProtocol:protocol] || ![cls conformsToProtocol:@protocol(HTSService)]) {
            [NSException raise:@"HTSServiceInvalidException" format:@"Class %@ not conforms to protocol %@ or HTSService",className,protocolName];
        }
        if ([container objectForKey:protocolName] != nil) {
            Class lastClass = [container objectForKey:protocolName];
            [NSException raise:@"HTSServiceInvalidException" 
                        format:@"Protocol %@ bind twice. Last class: %@, current class %@",protocolName,lastClass,cls];
        }
#endif
        if (cls && protocolName) {
            [container setObject:cls forKey:protocolName];
        }
    }
}

// Does not support lazy load framework
static void _loadCompileTimeServicePair(void) __attribute__((no_sanitize("address")))
{
    _defaultModeCompileTimeHash = [[NSMutableDictionary alloc] init];
    _currentModeCompileTimeHash = [[NSMutableDictionary alloc] init];
    NSInteger imageCount = _dyld_image_count();
    BOOL isInDefaultMode = HTSIsDefaultBootMode();
    const char *segment_name = HTSSegmentNameForCurrentMode();
    for (uint32_t idx = 0; idx < imageCount; idx++) {
        HTSMachHeader * mh = (HTSMachHeader *)_dyld_get_image_header(idx);
        if (isInDefaultMode) {
            _parseCompileServicePairInMachO(mh, _HTS_SEGMENT, _currentModeCompileTimeHash);
        }else{
            _parseCompileServicePairInMachO(mh, segment_name, _currentModeCompileTimeHash);
            _parseCompileServicePairInMachO(mh, _HTS_SEGMENT, _defaultModeCompileTimeHash);
        }
    }    
}

//Need caller to insure thread safe
FOUNDATION_EXPORT Class HTSCompileServiceForProtocol(Protocol *protocol)
{
    if (!protocol) return nil;
    NSString * protocolName = NSStringFromProtocol(protocol);
    if (!protocolName) return nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _loadCompileTimeServicePair();
    });
    Class cls = [_currentModeCompileTimeHash objectForKey:protocolName];
    if (!cls && !HTSIsDefaultBootMode() && (HTSGetCurrentModeServicePolicy() == HTSAppModeServiceDowngradeToDefault)) {
        cls = [_defaultModeCompileTimeHash objectForKey:protocolName];
    }
    return cls;
}
 
//Need caller to insure thread safe
FOUNDATION_EXPORT Class HTSRemoveCompileServiceForProtocol(Protocol * protocol)
{
    Class cls = HTSCompileServiceForProtocol(protocol);
    if (!cls) return nil;
    [_currentModeCompileTimeHash removeObjectForKey:NSStringFromProtocol(protocol)];
    [_defaultModeCompileTimeHash removeObjectForKey:NSStringFromProtocol(protocol)];
    return cls;
}

