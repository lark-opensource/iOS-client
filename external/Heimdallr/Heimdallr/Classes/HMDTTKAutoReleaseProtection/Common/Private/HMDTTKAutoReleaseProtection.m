//
//  HMDTTAutoReleaseProtection.m
//  Heimdallr-_Dummy
//
//  Created by zhouyang11 on 2022/7/12.
//

#import "HMDTTKAutoReleaseProtection.h"
#import "HMDTTKAutoReleaseProtectionConfig.h"
#import <pthread/pthread.h>
#import <BDFishhook/BDFishhook.h>
#import "HMDKStingerExchangeManager.h"
#import "HMDFishhookQueue.h"
#import <Stinger/Stinger.h>
#import <mach-o/dyld.h>
/*

   //test code for autorelease protection

   static void setUp();
   static void protectMethodGroups(NSArray<NSArray<NSString *> *> *methodGroupArray);

   @interface TTKOOMProtectionTest : NSObject

 + (void)test;

   @end

   @implementation TTKOOMProtectionTest

   - (NSObject *)methodA
   {
    __autoreleasing NSObject *obj = [[NSObject alloc] init];
    return obj;
   }

   - (NSObject *)methodB
   {
    __autoreleasing NSObject *obj = [[NSObject alloc] init];
    return obj;
   }

   - (NSObject *)methodC
   {
    NSObject *obj = [self methodB];
    for (int i = 0; i < 100000; i++) {
        NSObject *obj = [self methodA];
        NSAssert(obj != nil, @"obj shouldn't be nil");
    }
    NSAssert(obj != nil, @"obj shouldn't be nil");
    return obj;
   }

   - (void)testProtectAutoreleasePoolWrappedMethod
   {
    for (int i = 0; i < 1000000; i++) {
        @autoreleasepool {
            NSObject *obj = [self methodA];
            NSAssert(obj != nil, @"obj shouldn't be nil");
        }
    }
   }

   - (void)testMultipleProtection
   {
    for (int i = 0; i < 1000000; i++) {
        NSObject *obj = [self methodA];
        NSObject *objb = [self methodB];
        NSAssert(obj != nil, @"obj shouldn't be nil");
        NSAssert(objb != nil, @"objb shouldn't be nil");

    }
   }

   - (void)testNestedProtection
   {
    for (int i = 0; i < 100; i++) {
        NSObject *obj = [self methodC];
        NSAssert(obj != nil, @"obj shouldn't be nil");
    }
   }

   - (void)testOutside
   {
    for (int i = 0; i < 1000000; i++) {
        NSObject *obj = [self methodA];
        NSAssert(obj != nil, @"obj shouldn't be nil");
    }
   }

 + (void)test
   {
    NSArray *methodGroups = @[
        @[
            @"-[TTKOOMProtectionTest testProtectAutoreleasePoolWrappedMethod]",
            @"-[TTKOOMProtectionTest methodA]"
        ],
        @[
            @"-[TTKOOMProtectionTest testMultipleProtection]",
            @"-[TTKOOMProtectionTest methodA]",
            @"-[TTKOOMProtectionTest methodB]"
        ],
        @[
            @"-[TTKOOMProtectionTest testNestedProtection]",
            @"-[TTKOOMProtectionTest methodA]",
            @"-[TTKOOMProtectionTest methodB]",
            @"-[TTKOOMProtectionTest methodC]"
        ],
    ];
    open_bdfishhook();
    setUp();
    protectMethodGroups(methodGroups);
    TTKOOMProtectionTest *test = [[TTKOOMProtectionTest alloc] init];
    [test testProtectAutoreleasePoolWrappedMethod];
    [test testMultipleProtection];
    [test testNestedProtection];
    [test testOutside];
   }

   @end

 */

/**
    sample setting json:
    this setting will enable autorelease protect for methodB & methodC when they are called inside methodA
   ```
   {
    "enable_open" : true,
    "method_group_array" : [
         "-[TTKOOMProtectionTest methodA]",
         "-[TTKOOMProtectionTest methodB],-[TTKOOMProtectionTest methodC]",
         "-[TTKOOMProtectionTest methodD],-[TTKOOMProtectionTest methodE],-[TTKOOMProtectionTest methodF]"
    ]
   }
   ```
 */


static const char* objc_autoreleasePoolPushSymbol = "objc_autoreleasePoolPush"; //@"b2JqY19hdXRvcmVsZWFzZVBvb2xQdXNo"
static const char* objc_autoreleasePoolPopSymbol = "objc_autoreleasePoolPop"; //@"b2JqY19hdXRvcmVsZWFzZVBvb2xQb3A="
void *(*orig_objc_autoreleasePoolPush)(void);
void(*orig_objc_autoreleasePoolPop)(void *);

static pthread_key_t TokenKey;
static pthread_key_t EnableProtectKey;

static BOOL hmd_protect_enabled(void)
{
    return (BOOL)pthread_getspecific(EnableProtectKey);
}

static void *hmd_autoreleasePoolPush(void)
{
    if (orig_objc_autoreleasePoolPush) {
        return orig_objc_autoreleasePoolPush();
    } else {
        return NULL;
    }
}

static void hmd_autoreleasePoolPop(void *token)
{
    /*
       Generally objc_autoreleasePoolPush & objc_autoreleasePoolPop should be called in LIFO order.
       for example, push1 push2, pop2, pop1
       But due to the protectMethod, the LIFO order may be broken.
       For example, push1, push2, pop1, pop2
       In this situation, pop1 will pop all pointers inserted into AutoreleasePoolPage, include the token inserted by push2.
       Then pop2 will refer to an address which has been deallocated, which will cause an EXC_BAD_ACCESS.
       We clear the token stored in Thread Specific Storage here.
       When the protectMethod was called again, the token has been erased, so the pop2 won't be executed.
       This prevent EXC_BAD_ACCESS to happen.
     */
    if (hmd_protect_enabled()) {
        pthread_setspecific(TokenKey, NULL);
    }
    if (orig_objc_autoreleasePoolPop) {
        orig_objc_autoreleasePoolPop(token);
    }
}

static void image_add_callback (const struct mach_header *mh, intptr_t vmaddr_slide) {
    dispatch_async(hmd_fishhook_queue(), ^{
        bd_rebind_symbols_image((void*)mh, vmaddr_slide, (struct bd_rebinding[1]){ objc_autoreleasePoolPopSymbol, hmd_autoreleasePoolPop, (void *)&orig_objc_autoreleasePoolPop }, 1);
    });
}

@interface HMDTTKAutoReleaseProtection()

@property (nonatomic, assign) BOOL protectionStarted;

@end

@implementation HMDTTKAutoReleaseProtection

+ (instancetype)sharedInstance {
    static HMDTTKAutoReleaseProtection* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDTTKAutoReleaseProtection alloc]init];
    });
    return instance;
}

- (void)start {
    [super start];
    if (self.protectionStarted == NO) {
        self.protectionStarted = YES;
        __auto_type config = (HMDTTKAutoReleaseProtectionConfig*)self.config;
        [self setUp];
        [self protectMethodGroups:config.methodGroupArray];
    }
}

- (void)setUp {
    pthread_key_create(&TokenKey, NULL);
    pthread_key_create(&EnableProtectKey, NULL);
    
    _dyld_register_func_for_add_image(image_add_callback);
    
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        bd_rebind_symbols_image((void*)_dyld_get_image_header(i), _dyld_get_image_vmaddr_slide(i), (struct bd_rebinding[1]){ objc_autoreleasePoolPushSymbol, hmd_autoreleasePoolPush, (void *)&orig_objc_autoreleasePoolPush }, 1);
        if (orig_objc_autoreleasePoolPush != NULL) {
            break;
        }
    }
}

- (void)protectMethodGroups:(NSArray<NSString *>*)methodGroupArray {
    for (NSString *methodGroupStr in methodGroupArray) {
        NSArray<NSString*>* methodGroup = [methodGroupStr componentsSeparatedByString:@","];
        if (methodGroup.count == 0) {
            return;
        }

        [methodGroup enumerateObjectsUsingBlock:^(NSString *_Nonnull methodString, NSUInteger idx, BOOL *_Nonnull stop) {
            if (![methodString isKindOfClass:[NSString class]]) {
                return;
            }
            if (idx == 0) {
                [[HMDKStingerExchangeManager sharedInstance] exchangeMethod:methodString block:^(id<StingerParams> params, void *rst) {
                    pthread_setspecific(EnableProtectKey, (void *)YES);
                    [params invokeAndGetOriginalRetValue:rst];
                    pthread_setspecific(EnableProtectKey, (void *)NO);
                }];
            } else {
                [[HMDKStingerExchangeManager sharedInstance] exchangeMethod:methodString block:^(id<StingerParams> params, void *rst) {
                    if (hmd_protect_enabled()) {
                        void *token = pthread_getspecific(TokenKey);
                        if (token != NULL) {
                            hmd_autoreleasePoolPop(token);
                        }
                        token = hmd_autoreleasePoolPush();
                        pthread_setspecific(TokenKey, token);
                    }
                    [params invokeAndGetOriginalRetValue:rst];
                }];
            }
        }];
    }
}
@end
