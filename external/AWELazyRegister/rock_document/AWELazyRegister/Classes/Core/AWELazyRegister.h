//
//  AWELazyRegister.h
//  AWELazyRegister 
//
//  Created by liqingyao on 2019/11/4.
//  Copyright © 2019 liqingyao. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (*register_entry)(void);

typedef struct {
    const char * _Nonnull module;
    const char * _Nonnull key;
    register_entry _Nonnull func;
    const void * _Nonnull reserved;
} lazy_register_info2;


#define AWELazyRegisterSegment "__DATA"
#define AWELazyRegisterData "LazyRegData"

#define AWESTRING_PRIVATE(s) #s
#define AWESTRING(s) AWESTRING_PRIVATE(s)
#define AWECONCAT_PRIVATE(x,y) x##y
#define AWECONCAT(x,y) AWECONCAT_PRIVATE(x,y)
#define AWELazyRegisterEntry AWECONCAT(AWELazyRegisterEntry, __LINE__)
#define AWELazyRegisterInfo AWECONCAT(AWELazyRegisterInfo, __COUNTER__)
#define AWELazyRegisterUniqueKey AWESTRING(__FILE__ __LINE__)

#define AWELazyRegisterBlock(key, module) \
static void AWELazyRegisterEntry(void); \
__attribute((used, section(AWELazyRegisterSegment "," AWELazyRegisterData))) \
static lazy_register_info2 AWELazyRegisterInfo = \
{ \
    module, \
    key, \
    &AWELazyRegisterEntry, \
    0, \
}; \
static void AWELazyRegisterEntry(void)



// Deprecated - only for backward compatibility

typedef struct {
    const char * _Nonnull key;
    register_entry _Nonnull func;
} lazy_register_info;

typedef struct {
    char * _Nonnull module;
} lazy_register_module_info;

#define AWELazyRegisterHeader "LazyRegHeader"
#define AWELazyRegisterModuleInfo AWECONCAT(AWELazyRegisterModuleInfo, __COUNTER__)

#define AWELazyRegisterBlockDeprecated(key, sect) \
static void AWELazyRegisterEntry(void); \
__attribute((used, section(AWELazyRegisterSegment "," sect))) \
static lazy_register_info AWELazyRegisterInfo = \
{ \
    key, \
    &AWELazyRegisterEntry, \
}; \
static void AWELazyRegisterEntry(void)

#define AWELazyRegisterModule(module) \
__attribute((used, section(AWELazyRegisterSegment "," AWELazyRegisterHeader))) \
static lazy_register_module_info AWELazyRegisterModuleInfo = \
{ \
    module, \
};


NS_ASSUME_NONNULL_BEGIN

@interface AWELazyRegister : NSObject

#if INHOUSE_TARGET || DEBUG
+ (instancetype)sharedInstance;
@property (nonatomic, copy) BOOL (^debugIsolationRegisterBlock)(NSString *module, NSString *path);
#endif

+ (void)evaluateLazyRegisterForModule:(NSString *)module;
+ (void)evaluateLazyRegisterForKey:(NSString *)key ofModule:(NSString *)module;
+ (BOOL)canEvaluateLazyRegisterForKey:(NSString *)key ofModule:(NSString *)module;
+ (NSArray<NSString *> *)lazyRegisterKeysInModule:(NSString *)module;
+ (NSDictionary *)lazyRegisterRunLogParams;
@end

NS_ASSUME_NONNULL_END
