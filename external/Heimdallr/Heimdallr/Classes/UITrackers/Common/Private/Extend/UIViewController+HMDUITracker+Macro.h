//
//  UIViewController+HMDUITracker+Macro.h
//  Pods
//
//  Created by bytedance on 2021/12/2.
//

/* 这部分代码简单，但是为了简洁放到了这里 */

#ifndef UIViewController_HMDUITracker_Macro_h
#define UIViewController_HMDUITracker_Macro_h

#pragma mark - create_super_info 宏的定义和解释

/*      create_super_info 宏
        创建了一个 struct objc_super 取名为 super_info

        struct objc_super super_info = {
            .receiver = thisSelf,
            .super_class = superClass
        }                                                 */

#define create_super_info(thisSelf, superClass) \
struct objc_super super_info = {                \
.receiver = (thisSelf),                         \
.super_class = (superClass) }

#pragma mark - void_msgSendSuper_void 和 void_msgSendSuper_BOOL 宏的含义

/*      就是强制类型转换了 objc_msgSendSuper
 
        void_msgSendSuper_void 意思是 (输入参数为 void 返回参数为 void)       也就是只有 self, SEL 参数
        void_msgSendSuper_BOOL 意思是 (输入参数只有 BOOL 返回参数为 void)     也就是有 self, SEL, BOOL 参数   */

#define void_msgSendSuper_void(super_info, selector) \
((void (*)(struct objc_super *, SEL))objc_msgSendSuper)((super_info), (selector))

#define void_msgSendSuper_BOOL(super_info, selector, BOOLValue) \
((void (*)(struct objc_super *, SEL, BOOL))objc_msgSendSuper)((super_info), (selector), (BOOLValue))

#pragma mark - (XXX)_msgSendSuper 宏定义

/*      目前有 (LoadView/ViewDidLoad/ViewWillAppear/ViewDidAppear)_msgSendSuper  也就是对应着
 
            -[UIViewController loadView]
            -[UIViewController viewDidLoad]
            -[UIViewController viewWillAppear]
            -[UIViewController viewDidAppear]           这几个方法使用的 objc_msgSendSuper */

#define LoadView_msgSendSuper(super_info, selector) \
void_msgSendSuper_void((super_info), (selector))

#define ViewDidLoad_msgSendSuper(super_info, selector) \
void_msgSendSuper_void((super_info), (selector))

#define ViewWillAppear_msgSendSuper(super_info, selector, animated) \
void_msgSendSuper_BOOL((super_info), (selector), (animated))

#define ViewDidAppear_msgSendSuper(super_info, selector, animated) \
void_msgSendSuper_BOOL((super_info), (selector), (animated))

#endif /* UIViewController_HMDUITracker_Macro_h */
