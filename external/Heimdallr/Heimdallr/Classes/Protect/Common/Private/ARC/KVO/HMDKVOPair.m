//
//  HMDKVOPair.m
//  CLT
//
//  Created by sunrunwang on 2019/3/27.
//  Copyright © 2019 sunrunwang. All rights reserved.
//
// 非线程安全 [由Center管理]
// 依赖: KVO 线程安全

#import "HMDKVOPair.h"
#import "HMDProtectKVO.h"
#import "HMDALogProtocol.h"
#import "HMDProtect_Private.h"
#import "HMDObjectAnalyzer.h"
#import <malloc/malloc.h>
#import "HMDTaggedPointerAnalyzer.h"

/*!@function object_getClass_unsafe
 * @discussion 获得一个 OC 对象的 Class，如果该对象不是 OC 的，那么可能获取到脏数据
 */
static inline void * _Nullable non_taggedpointer_object_getClass_unsafe(void * _Nullable object);

#pragma mark - HMDKVOPair

@implementation HMDKVOPair

/// 如果该方法返回 nil 证明类型检查失败
- (instancetype)initWithObserver:(__kindof NSObject  * _Nonnull)observer
                         keypath:(NSString * _Nonnull)keyPath
                         options:(NSKeyValueObservingOptions)option
                         context:(void * _Nullable)context {
    if(self = [super init]) {
        _HMDObserver = observer;
        _HMDObserverClass = object_getClass(observer);
        _HMDObserverPtr = (__bridge void *)observer;
        _HMDKeyPath = [keyPath copy];
        _HMDOption = option;
        _HMDContext = context;
        _HMDObserverSize = malloc_size(_HMDObserverPtr);
        _actived = NO;
        _crashed = NO;
    }
    
    return self;
}

#pragma mark - Public

- (void)activeWithObservee:(NSObject *)observee {
    if(_actived) {
        return;
    }
    
    if(observee) {
        _actived = YES;
        [observee HMDP_addObserver:self forKeyPath:_HMDKeyPath options:_HMDOption context:_HMDContext];
    }
}

- (void)deactiveWithObservee:(NSObject *_Nullable)observee {
    if(_actived && observee) {
        [observee HMDP_removeObserver:self forKeyPath:_HMDKeyPath];
        _actived = NO;
    }
}

#pragma mark - Private

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(NSObject *)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    NSAssert([keyPath isEqualToString:_HMDKeyPath] && _HMDContext == context, @"[Heimdallr][Protector][FATAL ERROR] Please preserve current environment and contact Heimdallr developer ASAP.\n");
    // 注意：在当前上下文，不能做任何add/remove Observer操作
    if (_crashed) return;
    
    __strong __kindof NSObject *Observer = _HMDObserver;
    if (Observer) {
        [Observer observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    // Observer正在Deallocating，引用计数为0，但内存没有free，还可以响应事件
    size_t size = malloc_size(_HMDObserverPtr);
    if (size > 0 && size == _HMDObserverSize) {
        // 虽然这里是相同的 class，但是可能不再是原来那个对象咯，不过至少... 不会崩溃?
        HMDUnsafeClass _Nullable unsafe_class = non_taggedpointer_object_getClass_unsafe(_HMDObserverPtr);
        if (unsafe_class == (__bridge void *)_HMDObserverClass) {
            [(__bridge NSObject __kindof *)_HMDObserverPtr observeValueForKeyPath:keyPath ofObject:object change:change context:context];
            return;
        }
        
        if(HMDObjectAnalyzer_objectIsDeallocating_fast_unsafe(_HMDObserverPtr)) {
            
            HMDUnsafeClass super_class;
            if(HMDClassAnalyzer_unsafeClassGetSuperClass(unsafe_class, &super_class)) {
                DEBUG_ASSERT(VM_ADDRESS_CONTAIN(super_class));
                
                if(super_class == (__bridge void *)_HMDObserverClass) {
                    [(__bridge NSObject __kindof *)_HMDObserverPtr observeValueForKeyPath:keyPath
                                                                                 ofObject:object
                                                                                   change:change
                                                                                  context:context];
                    return;
                }
            }
        }
    }
    
    _crashed = YES;
    if (hmd_upper_trycatch_effective(0)) {
        return;
    }
    
    NSString *observeeClassName = NSStringFromClass([object class]);
    NSString *crashKey = [NSString stringWithFormat:@"[%@ observeValueForKeyPath:%@ ofObject:%@ change: context:%p]", observeeClassName, keyPath, observeeClassName, context];
    NSString *reason = [NSString stringWithFormat:@"[%@<Released> observeValueForKeyPath:%@ ofObject:%@<%p> change:%@ context:%p]", _HMDObserverClass, keyPath, observeeClassName, object, change, context];
    HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInternalInconsistencyException" reason:reason crashKey:crashKey];
    HMD_Protect_KVO_captureException(capture);
}


#pragma mark - Debug

#ifdef DEBUG

- (void)dealloc {
    if (@available(iOS 11.3, *)) {
        // iOS 11.3及以上版本，不会崩溃
        return;
    }
    
    if (_actived) {
        NSAssert(NO, @"[FATAL ERROR] Please preserve current environment and contact Heimdallr developer ASAP.\n");
    }
}

- (NSString *)description {
    
    return [NSString stringWithFormat:
            @"<HMDKeyValueObservingPair %p>\n"
                "\tobserver:%@\n"
                "\tkeypath:%@\n"
                "\toption:%lu\n"
                "\tcontext:%p\n"
                "\tactive:%s"
                "\tcreash:%s",
            self, _HMDObserver?:[NSString stringWithFormat:@"%@<released/releasing>", NSStringFromClass(_HMDObserverClass)], _HMDKeyPath,
            (unsigned long)_HMDOption, _HMDContext, _actived?"YES":"NO", _crashed?"YES":"NO"];
}

#endif

@end

#pragma mark - HMDKVOPairsInfo

@implementation HMDKVOPairsInfo

- (instancetype)initWithObservee:(NSObject *)observee {
    self = [super init];
    if (self) {
        _HMDObservee = observee;
        _HMDObserveeClass = object_getClass(observee);
        _HMDObserveePtr = (__bridge void *)observee;
        _pairList = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    // 数组释放时还有未释放的observer
    if (@available(iOS 11.3, *)) {
        // iOS 11.3及以上版本，不会崩溃
        return;
    }
    
    if (_pairList.count > 0) {
        NSMutableString *reason = nil;
        __kindof NSObject * current_observee = _HMDObservee;
        if (!current_observee) {
            current_observee = (__bridge id)_HMDObserveePtr;
        }
        
        NSString *observeeClassName = NSStringFromClass(_HMDObserveeClass);
        for (HMDKVOPair *pair in _pairList) {
            [pair deactiveWithObservee:current_observee];
            if (reason == nil) {
                reason = [[NSMutableString alloc] initWithFormat:@"An instance %p of class %@ was deallocated while key value observers were still registered with it. Current observation info: %@<%p> (\n", _HMDObserveePtr, _HMDObserveeClass, self.class, self];
            }
            
            [reason appendFormat:@"Observer: %@<%p>, Key path: %@, Options: %lu, Context: %p\n", pair.HMDObserverClass, pair.HMDObserverPtr, pair.HMDKeyPath, (unsigned long)pair.HMDOption, pair.HMDContext];
        }
        
        [reason appendString:@")"];
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ dealloc] with %lu observers", observeeClassName, (unsigned long)_pairList.count];
        HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInternalInconsistencyException" reason:[reason copy] crashKey:crashKey];
        HMD_Protect_KVO_captureException(capture);
    }
}

@end

static inline void * _Nullable non_taggedpointer_object_getClass_unsafe(void * _Nullable object) {
    DEBUG_ASSERT(HMDTaggedPointerAnalyzer_initialization() && !HMDTaggedPointerAnalyzer_isTaggedPointer(object));
    
    if(object == NULL) DEBUG_RETURN(NULL);
    uintptr_t *object_ptr = (uintptr_t *)object;
    #define ARM64E_ISA_MASK 0x007ffffffffffff8ULL;
    #define NONE_PAC_MASK   UINT64_C(0x0000000FFFFFFFFF)
    /*! @name arm64 的兼容性
     *  @discussion 我们明确这个写法在 arm64e 是可以生效的，那么我们考虑在 arm64 是否也能
     *  不得不承认在 arm64 上的 @p ISA_MASK( 0x0000000ffffffff8ULL ) 并不相同，取 ISA 的方式不能够兼容
     *  但是最后我们的 @p NONE_PAC_MASK 刚好兼容了这个逻辑，将 @p ISA_MASK 重新限定在 ARM64 的 @p ISA_MASK 范围
     */
    /*! @name arm64e 做了啥
     *  @code
     *      NSObject * objc_ptr = [NSObject new]
     *      uint64_t    raw_isa = * ((uint64_t *)objc_ptr)
     *      uint64_t    pac_isa = raw_isa & ISA_MASK
     *      uint64_t real_class = pac_isa & NONE_PAC_MASK
     *  @endcode
     *  @discussion @p objc_ptr 是这个对象的指针， @p raw_isa 是原始 isa 的值，我们首先与 @p ISA_MASK 交集
     *  就拿到了 @p pac_isa， 这个 isa 其实是用 @p objc_ptr 和 @p ISA_SIGNING_DISCRIMINATOR(0x6AE1) 加密的数据
     *  使用的方法是 @p pac_isa=ptrauth_sign_unauthenticated(real_class,ptrauth_key_process_independent_data,
     *  @p ptrauth_blend_discriminator(objc_ptr,0x6AE1))
     *  这里学到了个新知识，看起来目前 ARM64E 并非用全部的 upper bits 进行加密，还是只有部分参与进行加密而已
     *  因为它是 PAC 加密，无论有多复杂，其实直接 @p NONE_PAC_MASK 删掉就行，这里其实有些唠叨， @b 知其所以然
     */
    uintptr_t isa_masked = object_ptr[0] & ARM64E_ISA_MASK;
    uintptr_t isa_unsafe = isa_masked & NONE_PAC_MASK;
    return (void *)isa_unsafe;
}
