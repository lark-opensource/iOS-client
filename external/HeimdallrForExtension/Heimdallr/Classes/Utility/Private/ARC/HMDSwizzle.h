//
//  HMDSwizzle.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/3/6.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN bool hmd_swizzle_instance_method(Class cls, SEL originalSelector, SEL swizzledSelector);
FOUNDATION_EXTERN bool hmd_swizzle_instance_method_with_imp(Class cls, SEL originalSelector, SEL swizzledSelector, IMP swizzledIMP);
FOUNDATION_EXTERN bool hmd_swizzle_class_method(Class cls, SEL originalSelector, SEL swizzledSelector);
FOUNDATION_EXTERN bool hmd_swizzle_class_method_with_imp(Class cls, SEL originalSelector, SEL swizzledSelector, IMP swizzledIMP);
FOUNDATION_EXTERN BOOL hmd_isa_swizzle_instance(id obj, SEL originSEL, Method swizzledMethod, BOOL mockProtection);


/* 0.7.5 追加内容 */

FOUNDATION_EXTERN _Nullable Method hmd_classHasInstanceMethod(Class _Nullable aClass, SEL _Nonnull selector);
FOUNDATION_EXTERN _Nullable Method hmd_classHasClassMethod(Class _Nullable aClass, SEL _Nonnull selector);
FOUNDATION_EXTERN void hmd_mockClassTreeForInstanceMethod(Class _Nullable aClass, SEL _Nonnull originSEL, SEL _Nonnull mockSEL, id _Nonnull impBlock);
FOUNDATION_EXTERN void hmd_mockClassTreeForClassMethod(Class _Nullable aClass, SEL _Nonnull originSEL, SEL _Nonnull mockSEL, id _Nonnull impBlock);
FOUNDATION_EXTERN Class _Nonnull * _Nullable objc_getSubclasses(Class _Nullable aClass, size_t * _Nonnull num);
FOUNDATION_EXTERN Class _Nonnull * _Nullable objc_getAllSubclasses(Class _Nullable aClass, size_t * _Nonnull num);
FOUNDATION_EXTERN void hmd_insert_and_swizzle_instance_method (Class _Nullable originalClass, SEL _Nonnull originalSelector, Class _Nullable targetClass, SEL _Nonnull targetSelector);
FOUNDATION_EXTERN void hmd_insert_and_swizzle_class_method (Class _Nullable originalClass, SEL _Nonnull originalSelector, Class _Nullable targetClass, SEL _Nonnull targetSelector);
FOUNDATION_EXTERN _Nullable Method hmd_classSearchInstanceMethodUntilClass(Class _Nullable aClass, SEL _Nonnull selector, Class _Nullable untilClassExcluded);
FOUNDATION_EXTERN _Nullable Method hmd_classSearchClassMethodUntilClass(Class _Nullable aClass, SEL _Nonnull selector, Class _Nullable untilClassExcluded);

#ifndef HMD_Stringlization
#define HMD_Stringlization(x) HMD_Stringlization_Internal(x)
#define HMD_Stringlization_Internal(x) #x
#endif

#ifndef HMD_STICK
#define HMD_STICK(x, y) HMD_STICK_Internal(x, y)
#define HMD_STICK_Internal(x, y) x##y
#endif

#pragma mark - HMD mock method

/*  非常方便的 Swizzle 方法
 
    1. 在 NSArray 这样的类蔟上调用, 会影响到它的每一个 subClass
 
    2. 它的意义就是替换了每一个类的 sel (例如 stringWithString:) 方法
    创建了一个 MOCK_sel 存储原方法 (例如 MOKE_stringWithString:)
    然后用你写的 block 里的实现, 替换原方法实现 (例如 stringWithString:)
 
    3. block 的实现会用 objc rumtime implementation_withBlock
    所以 block 的参数类型: 返回类型相同, 但是只有 self 和 剩余参数,
    也就是不包含 SEL 的方法, 用 (stringWithString:) 举例
 
    HMD_mockClassTreeForClassMethod(NSString, stringWithString:,
 
        ^ NSString * (NSString * thisSelf, NSString *string) {
    
            你需要做任何自定义方法的时刻
 
            调回原方法, 你也可以不调回
            return [thisSelf MOKE_stringWithString:string];
 
        });
 
    4. HMD_mockClassTreeForClassMethod      替换 Class    方法
       HMD_mockClassTreeForInstanceMethod   替换 Instance 方法
 
    5. 当然原类是没有声明 MOCK_stringWithString: 方法的,
       所以要不你显式声明一下该方法但是不用定义, 调回该方法即可
       或者试试 #include <HMDDynamicCall.h> 妙哉 ~
 
       return DC_OB(thisSelf, MOKE_stringWithString:, string);
 */

#define HMD_mockClassTreeForClassMethod(class, sel, impBlock)                    \
({                                                                               \
    Class aClass = objc_getClass(HMD_Stringlization(class));                     \
    SEL real_sel = sel_registerName(HMD_Stringlization(sel));                    \
    SEL moke_sel = sel_registerName(HMD_Stringlization(HMD_STICK(MOCK_, sel)));  \
    hmd_mockClassTreeForClassMethod(aClass, real_sel, moke_sel, (impBlock));     \
})

#define HMD_mockClassTreeForInstanceMethod(class, sel, impBlock)                 \
({                                                                               \
    Class aClass = objc_getClass(HMD_Stringlization(class));                     \
    SEL real_sel = sel_registerName(HMD_Stringlization(sel));                    \
    SEL moke_sel = sel_registerName(HMD_Stringlization(HMD_STICK(MOCK_, sel)));  \
    hmd_mockClassTreeForInstanceMethod(aClass, real_sel, moke_sel, (impBlock));  \
})

NS_ASSUME_NONNULL_END
