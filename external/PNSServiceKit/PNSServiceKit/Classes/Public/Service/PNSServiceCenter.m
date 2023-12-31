//
//  PNSServiceCenter.m
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/14.
//

#import "PNSServiceCenter.h"
#import "PNSServiceCenter+private.h"
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <pthread/pthread.h>

#ifndef __LP64__
typedef struct mach_header PNSMachHeader;
#else
typedef struct mach_header_64 PNSMachHeader;
#endif

static pthread_rwlock_t instanceRWLock = PTHREAD_RWLOCK_INITIALIZER;

static pthread_rwlock_t classRWLock = PTHREAD_RWLOCK_INITIALIZER;

@interface PNSServiceCenter()

@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *instanceProtocolMap;

@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *classProtocolMap;

@end

@implementation PNSServiceCenter

+ (instancetype)sharedInstance {
    static PNSServiceCenter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.instanceProtocolMap = [[NSMutableDictionary alloc] init];
        self.classProtocolMap = [[NSMutableDictionary alloc] init];
        [self _loadCompileServiceIfNeeded];
    }
    
    return self;
}

- (void)bindClass:(Class)cls toProtocol:(Protocol *)protocol {
    if (![cls conformsToProtocol:protocol]) {
        return;
    }
    
    [self safeSetClass:cls forKey:NSStringFromProtocol(protocol)];
}

- (void)bindInstance:(id)instance toProtocol:(Protocol *)protocol {
    if (![instance conformsToProtocol:protocol]) {
        return;
    }
    
    [self safeSetInstance:instance forKey:NSStringFromProtocol(protocol)];
}

- (nullable id)getInstance:(Protocol *)protocol {
    if (!protocol) {
        return nil;
    }
    
    NSString *protocolName = NSStringFromProtocol(protocol);
    id instance = [self safeGetInstanceForKey:protocolName];
    
    if (!instance) {
        Class cls = [self safeGetClassForKey:protocolName];
        instance = [[cls alloc] init];
        
        if (instance) {
            [self safeSetInstance:instance forKey:protocolName];
        }
    }
    
    return instance;
}

- (Class)getClass:(Protocol *)protocol {
    if (!protocol) {
        return nil;
    }
    
    return [self safeGetClassForKey:NSStringFromProtocol(protocol)];;
}

- (void)_loadCompileServiceIfNeeded {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        NSInteger imageCount = _dyld_image_count();
        for (uint32_t idx = 0; idx < imageCount; idx++) {
            PNSMachHeader *header = (PNSMachHeader *)_dyld_get_image_header(idx);
            [self _parseCompileServicePair:header];
        }
    });
}

- (void)_parseCompileServicePair:(PNSMachHeader *)header {
    unsigned long size = 0;
    _pns_service_info *data = (_pns_service_info *)getsectiondata(header, "__DATA", PNS_SERVICE_SECTION, &size);
    if (size == 0) return;
    NSUInteger count = size / sizeof(_pns_service_info);
    if (count == 0) return;
    
    for (NSInteger idy = 0; idy < count; idy++) {
        _pns_service_info pair = data[idy];

        if (pair.protocol == 0 || pair.cls == 0) {
            continue;
        }

        NSString *protocolName = [[NSString alloc] initWithUTF8String:pair.protocol];
        NSString *className = [[NSString alloc] initWithUTF8String:pair.cls];
        Class cls = NSClassFromString(className);
        
        if (cls && protocolName) {
            [self.classProtocolMap setObject:cls forKey:protocolName];
        }
    }
}

- (void)safeSetClass:(Class)class forKey:(NSString *)key {
    pthread_rwlock_wrlock(&classRWLock);
    [self.classProtocolMap setValue:class forKey:key];
    pthread_rwlock_unlock(&classRWLock);
}

- (Class)safeGetClassForKey:(NSString *)key {
    pthread_rwlock_rdlock(&classRWLock);
    Class cls = [self.classProtocolMap objectForKey:key];
    pthread_rwlock_unlock(&classRWLock);
    return cls;
}

- (void)safeSetInstance:(id)instance forKey:(NSString *)key {
    pthread_rwlock_wrlock(&instanceRWLock);
    [self.instanceProtocolMap setValue:instance forKey:key];
    pthread_rwlock_unlock(&instanceRWLock);
}

- (nullable id)safeGetInstanceForKey:(NSString *)key {
    pthread_rwlock_rdlock(&instanceRWLock);
    Class cls = [self.instanceProtocolMap objectForKey:key];
    pthread_rwlock_unlock(&instanceRWLock);
    return cls;
}

@end
