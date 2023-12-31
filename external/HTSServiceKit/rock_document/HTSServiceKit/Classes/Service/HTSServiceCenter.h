//
//  HTSServiceCenter.h
//  LiveStreaming
//
//  Created by denggang on 16/7/13.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTSService.h"
#import "HTSServiceKitDefines.h"
#import "HTSCompileTimeServiceManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface HTSServiceCenter : NSObject

@property (nonatomic, class) BOOL debugAssertOn;

+ (HTSServiceCenter *)defaultCenter;

- (instancetype)init NS_DEPRECATED_IOS(1_0, 1_0, "Please use defaultCenter");

- (nullable id)getService:(Class)cls;
- (nullable id)getProtocolService:(Protocol *)protocol;
- (nullable Class)getStatelessProtocolService:(Protocol *)protocol;
- (Class)getClassFromProtocol:(Protocol *)protocol;

- (void)removeService:(Class)cls;

- (void)bindClass:(Class)cls toProtocol:(Protocol *)protocol;
- (void)unbindProtocol:(Protocol *)protocol;

- (void)callEnterBackground NS_DEPRECATED_IOS(1_0, 1_0, "Please use HTSModule");
- (void)callEnterForeground NS_DEPRECATED_IOS(1_0, 1_0, "Please use HTSModule");
- (void)callTerminate NS_DEPRECATED_IOS(1_0, 1_0, "Please use HTSModule");
- (void)callServiceMemoryWarning NS_DEPRECATED_IOS(1_0, 1_0, "Please use HTSModule");
- (void)callClearData NS_DEPRECATED_IOS(1_0, 1_0, "Please use HTSModule");

#ifndef HTS_SERVICE
#define HTS_SERVICE

FOUNDATION_EXTERN id hts_get_protocol(Protocol *prot);
FOUNDATION_EXTERN Class hts_get_class(Protocol *prot);
FOUNDATION_EXTERN id hts_get_service(Class clz);
FOUNDATION_EXTERN id hts_get_service(Class clz);

FOUNDATION_EXTERN void hts_bind_protocol(Class clz, Protocol *prot);
FOUNDATION_EXTERN void hts_unbind_protocol(Protocol *prot);
FOUNDATION_EXTERN void hts_remove_service(Class clz);

#define GET_PROTOCOL(obj) ( (NSObject<obj> *)hts_get_protocol(@protocol(obj)) )

#define GET_CLASS(obj) ((Class<obj>)hts_get_class(@protocol(obj)))

#define GET_SERVICE(obj) ( (obj*) hts_get_service([obj class]) )

#define BIND_PROTOCOL(obj) \
+ (void)load { hts_bind_protocol(self.class, @protocol(obj));}

#define UNBIND_PROTOCOL(obj) ( hts_unbind_protocol(@protocol(obj)) )

#define REMOVE_SERVICE(obj) ( hts_remove_service([obj class]) )

#endif

#if DEBUG
#define SK_NSAssert(condition, desc, ...) if(HTSServiceCenter.debugAssertOn){ NSAssert(condition, desc, __VA_ARGS__);}
#else
#define SK_NSAssert(condition, desc, ...)
#endif


@end

NS_ASSUME_NONNULL_END
