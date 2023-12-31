//
//  HMDDynamicCall.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/4/23.
//  Copyright © 2019 Bill Sun. All rights reserved.
//

/**
 *
 * HMDDynamicCall 使用说明
 *
 * [支持的返回类型]
 * 除去下面声明的，所有类型, 对于常量和 struct 会包装为 NSNumber, NSValue, 当是 void 时候返回 nil
 * 不支持 bitField union 类型
 * 不支持 atomic 类型 <stdatomic.h> 和 <atomic>
 * 不支持 vector 类型
 *
 * [支持的传入参数]
 * 基本类型, 和基本 struct 类型 [受到 GNU 局限]
 * 仅支持 NSRange, CGPoint, CGSize, CGRect
 *
 * [警告必读 ⚠️]
 * HMDDynamicCall 无法检查【你传入的参数列表是正确的类型】从而会导致 CRASH 而且不易发现
 * HMDDynamicCall【不会帮助你类型转换】因为它也不知道你调用的方法的参数类型
 * 比如 double 类型, 不可以写成 666 这样的整数类型
 * 像是 long   类型, 不可以写成 666 这样的 int 类型, 需要 666L 或者 (long)666
 *
 * 如果你了解 C 语言的默认整值提升(default integer promotion) 可以在一定程度上简化书写
 * 如果你不了解, (explict-cast-type)value 全部用类型转换, 能保证不会出错
 *
 * 在 Objective-C ARC 环境下的对象引用的指针(以及再指针) 需要注意其内存管理模式的传递
 * 匹配调用方法的 ARC 管理模式, 默认隐式类型为 __autoreleasing
 *
 * 在方法命名约束方面 请严格遵守 alloc new copy mutableCopy 所属于的 selector Class
 * 具有的 ns_returns_retained 属性
 *
 * [调用方法 例子]
 * HMDDynamicCallClass(NSString, stringWithString:, @"hello boy")
 * 根据类名, 动态调用类方法, 如果类存在且实现了该方法
 *
 * HMDDynamicCallObject(@"hello", stringByAppendingString:, @"boy")
 * 动态调用对象方法, 如果对象存在且实现了该方法
 *
 * CaDynamicExpectedType(@"hello china", NSString)
 * 检查返回类型, 如果是希望类型, 返回相同, 否则为 nil；传入的 Class 可以不导入头文件
 * ( 返回类型为 id )
 *
 * CADynamicIsClass(@(10086), NSNumber)
 * 检查返回类型, 如果是希望类型, 返回相同, 否则为 nil；传入的 Class 需要导入头文件
 * ( 返回类型为 class )
 *
 * [简化书写]
 * DC_OB
 * DC_CL    这是上面调用的简写版本
 * DC_ET
 * DC_IS
 *
 */

#ifndef HMDDynamicCall_h
#define HMDDynamicCall_h

#include <objc/message.h>
#include <objc/runtime.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    extern id _Nullable HMDDynamicCall(id _Nullable object, SEL _Nullable aSEL, ...);

    extern bool HMDDynamicCallIsSelectorReturnsRetained(SEL _Nonnull aSEL);
    
#ifdef __cplusplus
}
#endif

#define HMDDynamicCallObject(object, selector, ...)                                 \
({                                                                                  \
SEL aSEL = sel_registerName(#selector);                                             \
id result = HMDDynamicCall((object), aSEL, ## __VA_ARGS__);                         \
result;                                                                             \
})

#define HMDDynamicCallClass(class, selector, ...)                                   \
({                                                                                  \
SEL aSEL = sel_registerName(#selector);                                             \
Class aClass = objc_getClass(#class);                                               \
id result = HMDDynamicCall(aClass, aSEL, ## __VA_ARGS__);                           \
result;                                                                             \
})

#define HMDDynamicExpectedType(object, class)                                       \
({                                                                                  \
id result;                                                                          \
Class expectedClass;                                                                \
Class objectClass;                                                                  \
id thisObject = (object);                                                           \
if((thisObject) != nil &&                                                           \
(expectedClass = objc_getClass(#class)) != nil &&                                   \
(objectClass = object_getClass(thisObject)) != nil) {                               \
do if(objectClass == expectedClass) {                                               \
result = (thisObject); break;                                                       \
} while((objectClass = class_getSuperclass(objectClass)) != nil);                   \
}                                                                                   \
result;                                                                             \
})

#define HMDDynamicIsClass(object, class)                                            \
({                                                                                  \
    class * result;                                                                 \
    Class expectedClass;                                                            \
    Class objectClass;                                                              \
    id thisObject = (object);                                                       \
    if((thisObject) != nil &&                                                       \
    (expectedClass = objc_getClass(#class)) != nil &&                               \
    (objectClass = object_getClass(thisObject)) != nil) {                           \
        do if(objectClass == expectedClass) {                                       \
            result = (thisObject); break;                                           \
        } while((objectClass = class_getSuperclass(objectClass)) != nil);           \
    }                                                                               \
    result;                                                                         \
})

#if ! defined DC_OB && ! defined DC_CL && ! defined DC_ET
#define DC_OB(object, selector, ...) HMDDynamicCallObject(object, selector, ## __VA_ARGS__)
#define DC_CL(class, selector, ...)  HMDDynamicCallClass(class, selector, ## __VA_ARGS__)
#define DC_ET(object, class)         HMDDynamicExpectedType(object, class)
#define DC_IS(object, class)         HMDDynamicIsClass(object, class)
#else
#warning DC_OB DC_CL DC_ET already defined Dynamic Call may not work properly
#endif

#ifndef HMDDynamicCallInternalImplementation
#if !__has_feature(objc_arc)
#error HMDDynamicCall.h must be included in ARC environment
#endif
#endif

#endif /* HMDDynamicCall_h */

/*
 
 << Objective-C 参数类型 >>
 
 【 变长参数的隐式参数类型提升 】
 
 对于 float 类型浮点
 -> 提升为 double
 
 对于任何范围小于 int类型 的整型 [signed unsigned] [ _Bool char short]
 -> 提升为 int
 (注意: 对于16位机器, 由于 short 和 int 都是 16 位, 所以 unsigned short -> unsigned int)
 
 所以该函数中任何需要 float 的地方都可以直接传递 double 类型
 所以该函数中任何需要 char  的地方都可以直接传递 short, int 类型
 但是对于需要 long 的地方, 必须 (long)666
 
 【 ARC 默认间接对象内存管理属性 __autoreleasing 】
 
 在 ARC 模式下, 有四种类型管理模式 __strong __weak __unsafe_unretained __autoreleasing
 
 当声明     - (void)doSomethingWithError:(NSError **)error; 的时候
 ARC 翻译为 - (void)doSomethingWithError:(NSError * __autoreleasing *)error;
 
 假设定义 NSError * aError;
 (&aError) 的类型是 (NSError * __strong *) 是不同于 (NSError * __autoreleasing *)
 
 那么意味着你需要
 NSError * __autoreleasing aAutoreleasingError;
 [aInstance doSomethingWithError:&aAutoreleasingError];
 aError = aAutoreleasingError;
 
 这一步平时是编译器自动处理的内容 [ 但是 HMDDynamic 动态调用无法判断 ARC 内存管理类型 ⚠️ ]
 所以在使用时 必须由你手动管理   [ 传递正确的 ARC 内存管理模型 ]
 
 但这不意味着每次都是无脑转化为 __autoreleasing
 
 - (void)doSomethingWithError:(NSError **)error;    [不显示声明 默认值为 __autoreleasing]
 - (void)doSomethingWithError:(NSError * __autoreleasing *)error;
 - (void)doSomethingWithError:(NSError * __strong *)error;
 - (void)doSomethingWithError:(NSError * __weak *)error;
 - (void)doSomethingWithError:(NSError * __unsafe_unretained *)error;
 
 你需要灵性的使用 根据不同类型自己判断
 
 【 返回保留对象 NS_RETURNS_RETAINED 】
 
 在 Objective-C 语言中的方法名取第一段[OC方法名用:分段]
 若该字符串开头等于 "alloc" "copy" "mutableCopy" "new"
 并且后面之后便是 [ 字符串结尾 / 或者一个大写字母 ] , 在 ARC 环境下默认解释为
 
    [ 返回对象自带 referenceCount + 1 ]
 
 这对于在纯 ARC 编写的代码中不需要注意, 但是在 MRC 代码中只能自己保证正确性了
 
 */
