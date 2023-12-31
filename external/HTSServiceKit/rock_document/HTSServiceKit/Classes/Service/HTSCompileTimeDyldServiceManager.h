//
//  HTSCompileTimeServiceManager.h
//  HTSServiceKit
//
//  Created by chenxiancai on 2021/7/4.
//

#import "HTSMacro.h"
#import "metamacros.h"
#import <objc/runtime.h>
#import "HTSService.h"

#define _HTS_DYLD_SERVICE_SECTION                "__HTSDyServ"
#define _HTS_DYLD_SERVICE_IMPL_SECTION           "__HTSDyServImpl"
#define _HTS_DYLD_SERVICE_IMPL                   _HTS_CONCAT(__hts_dyld_service_impl_, __LINE__)
#define _HTS_DYLD_SERVICE_UNIQUE_VAR             _HTS_CONCAT(__hts_dyld_service_var_, __COUNTER__)
#define _HTS_DYLD_MAIN_BUNDLE                    @"_main_bundle_"


typedef struct{
    const char * bundle;
    const char * protocol;
}_hts_dyld_service_struct;

typedef struct{
    const char * clz;
    const char * protocol;
    void * service_imp;
}_hts_dyld_service_imp_struct;


typedef id(*_hts_dyld_service_method)(void);
typedef NSMutableDictionary<NSString *, NSValue *>  HTSCompileTimeServiceImplHash;
typedef NSMutableDictionary<NSString *, Class>      HTSCompileTimeServiceClassHash;
typedef NSMutableDictionary<NSString *, NSString *> HTSCompileTimeServiceHash;

typedef NSMutableDictionary<NSString *, HTSCompileTimeServiceImplHash *> HTSCompileTimeBundleServiceImplHash;
typedef NSMutableDictionary<NSString *, HTSCompileTimeServiceClassHash *> HTSCompileTimeBundleServiceClassHash;


#define HTS_PROTOCOL_FOR_EACH(INDEX, ARG) ARG,
#define _HTS_MUTIPLE_PROTOCOLS(...) metamacro_foreach(HTS_PROTOCOL_FOR_EACH,,__VA_ARGS__)
#define HTS_MUTIPLE_PROTOCOLS(...) _HTS_MUTIPLE_PROTOCOLS(__VA_ARGS__) NSObject

// For Service Register
#define HTS_REGISTER_SERVICE_METHOD_FOR_EACH(index, bundle_name, protocol_name)\
__attribute((used, section(_HTS_SEGMENT "," _HTS_DYLD_SERVICE_SECTION ))) static _hts_dyld_service_struct _HTS_DYLD_SERVICE_UNIQUE_VAR = \
{\
_HTS_TO_STRING(bundle_name),\
_HTS_TO_STRING(protocol_name),\
};\
@interface _HTS_CONCAT(protocol_name, _unused) : NSObject\
@end\
@implementation _HTS_CONCAT(protocol_name, _unused) \
@end

#define HTS_REGISTER_SERVICE_WITH_MUTIPLE_PROTOCOLS(bundle_name, ...) \
    metamacro_foreach_cxt(HTS_REGISTER_SERVICE_METHOD_FOR_EACH,,bundle_name,__VA_ARGS__)


// For Service Impl
#define HTS_BIND_SERVICE_IMPL_FOR_EACH(index, class_name, protocol_name)\
__attribute((used, section(_HTS_SEGMENT "," _HTS_DYLD_SERVICE_IMPL_SECTION ))) static _hts_dyld_service_imp_struct _HTS_DYLD_SERVICE_UNIQUE_VAR = \
{\
_HTS_TO_STRING(class_name),\
_HTS_TO_STRING(protocol_name),\
&_HTS_DYLD_SERVICE_IMPL,\
};

#define HTS_BIND_SERVICE_IMPL_WITH_MUTIPLE_PROTOCOLS(class_name, ...) \
    metamacro_foreach_cxt(HTS_BIND_SERVICE_IMPL_FOR_EACH,,class_name,__VA_ARGS__)

/**
 Register a service  at compile time
**/
#define HTSRegisterInstService(bundle_name, ...)\
HTS_REGISTER_SERVICE_WITH_MUTIPLE_PROTOCOLS(bundle_name, __VA_ARGS__)

#define HTSRegisterUniqService(bundle_name, ...)\
HTS_REGISTER_SERVICE_WITH_MUTIPLE_PROTOCOLS(bundle_name, __VA_ARGS__)

/**
 Bind a service  impl at compile time
**/
#define HTSBindInstService(class_name, ...)\
static id<HTS_MUTIPLE_PROTOCOLS(__VA_ARGS__)> _HTS_DYLD_SERVICE_IMPL(void);\
HTS_BIND_SERVICE_IMPL_WITH_MUTIPLE_PROTOCOLS(class_name, __VA_ARGS__)\
static id<HTS_MUTIPLE_PROTOCOLS(__VA_ARGS__)> _HTS_DYLD_SERVICE_IMPL(void)

#define HTSBindUniqService(class_name, ...)\
static id<HTS_MUTIPLE_PROTOCOLS(__VA_ARGS__)> _HTS_DYLD_SERVICE_IMPL(void);\
HTS_BIND_SERVICE_IMPL_WITH_MUTIPLE_PROTOCOLS(class_name, __VA_ARGS__)\
static id<HTS_MUTIPLE_PROTOCOLS(__VA_ARGS__)> _HTS_DYLD_SERVICE_IMPL(void)


FOUNDATION_EXTERN id htsGetService(Protocol * protocol);
FOUNDATION_EXTERN void htsUnbindService(Protocol * protocol);

/**
 get a service  at runtime
**/
#define HTSGetService(obj) ( (NSObject<obj> *)htsGetService(@protocol(obj)))

/**
 unbind a service  at runtime
**/
#define HTSUnbindService(obj) ( htsUnbindService(@protocol(obj)) )
