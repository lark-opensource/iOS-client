//
//  UINavigationController+pushCrash.m
//  LarkApp
//
//  Created by sniperj on 2019/8/20.
//

#import "UINavigationController+pushCrash.h"
#import <objc/runtime.h>
#import "LKHookUtil.h"
#import <LKLoadable/Loadable.h>

@interface WebDefaultUIKitDelegateCleaner : NSObject
@property (nonatomic, strong) NSPointerArray *delegates;
@end

@implementation WebDefaultUIKitDelegateCleaner

- (void)dealloc {
    [self cleanDelegates];
}

-(instancetype)init {
    if (self = [super init]) {
        self.delegates = [NSPointerArray weakObjectsPointerArray];
    }
    return self;
}

- (void)recordWebDelegate:(id)delegate {
    NSUInteger index = [self.delegates.allObjects indexOfObject:delegate];
    if (index == NSNotFound) {
        [self.delegates addPointer:(__bridge void *)(delegate)];
    }
}

- (void)cleanDelegates {
    [self.delegates.allObjects enumerateObjectsUsingBlock:^(id webDelegate, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([webDelegate isKindOfClass: NSClassFromString(@"_WebSafeForwarder")]) {
            Ivar ivar = class_getInstanceVariable([webDelegate class], "defaultTarget");
            object_setIvar(webDelegate, ivar, nil);
            Ivar ivar2 = class_getInstanceVariable([webDelegate class], "target");
            object_setIvar(webDelegate, ivar2, nil);
        }
    }];
}

@end

@interface NSObject (WebSafe_Private)

@property (nonatomic, readonly) WebDefaultUIKitDelegateCleaner *webDelegateCleaner;

@end

@implementation NSObject (WebSafe)

- (WebDefaultUIKitDelegateCleaner *)webDelegateCleaner {
    WebDefaultUIKitDelegateCleaner *cleaner = objc_getAssociatedObject(self, _cmd);
    if (!cleaner) {
        cleaner = [[WebDefaultUIKitDelegateCleaner alloc] init];
        objc_setAssociatedObject(self, _cmd, cleaner, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cleaner;
}

- (id)safe_initWithTarget:(id)arg1 defaultTarget:(id)arg2 {
    if ([NSStringFromClass([arg2 class]) isEqualToString: @"WebDefaultUIKitDelegate"]) {
        [[arg2 webDelegateCleaner] recordWebDelegate: self];
    }
    if ([NSStringFromClass([arg1 class]) isEqualToString:@"NSHTMLWebDelegate"]) {
        [[arg1 webDelegateCleaner] recordWebDelegate: self];
    }
    return [self safe_initWithTarget: arg1 defaultTarget: arg2];
}

@end

@interface UIView (pushCrash)

@end

@implementation UIView (pushCrash)

- (void)cus_addSubview:(UIView *)view positioned:(long long)position relativeTo:(UIView *)toView {
    if (self == view) {
        return;
    }
    [self cus_addSubview:view positioned:position relativeTo:toView];
}

@end

@implementation UINavigationController (pushCrash)

- (void)ac_pushViewController:(id)viewController transition:(int)transition forceImmediate:(_Bool)force {
    BOOL needClear = [self ac_checkTransition];
    if (needClear) {
        [self ac_clearOperation];
    }
    [self ac_pushViewController:viewController transition:transition forceImmediate:force];
}

- (id)ac_popViewControllerWithTransition:(int)transition allowPoppingLast:(_Bool)allowPoppingLast {
    BOOL needClear = [self ac_checkTransition];
    id value = [self ac_popViewControllerWithTransition:transition allowPoppingLast:allowPoppingLast];
    if (needClear) {
        [self ac_clearOperation];
    }
    return value;
}

- (id)ac_popToViewController:(id)viewController transition:(int)transition {
    BOOL needClear = [self ac_checkTransition];
    id value = [self ac_popToViewController:viewController transition:transition];
    if (needClear) {
        [self ac_clearOperation];
    }
    return value;
}

- (BOOL)ac_checkTransition {
    bool lastOperationAnimated = NO;
    //获取last opertaion 是否还在转场动画中
    SEL lastOperationSEL =  NSSelectorFromString(@"wasLastOperationAnimated");
    if ([self respondsToSelector:lastOperationSEL]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        lastOperationAnimated = [self performSelector:lastOperationSEL];
#pragma clang diagnostic pop
    }
    return lastOperationAnimated;
}

- (void)ac_clearOperation {
    //只是clear转场动画, navigation堆栈依旧保持原样
    SEL clearLastOperationSEL = NSSelectorFromString(@"_clearLastOperation");
    if ([self respondsToSelector:clearLastOperationSEL]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:clearLastOperationSEL];
#pragma clang diagnostic pop
    }
}

@end

LoadableRunloopIdleFuncBegin(LarkCrashSanitizer_pushCrash)
SwizzleMethod(NSClassFromString(@"_WebSafeForwarder"),NSSelectorFromString(@"initWithTarget:defaultTarget:"), [NSObject class] ,@selector(safe_initWithTarget:defaultTarget:));
SwizzleMethod([UIView class], NSSelectorFromString(@"_addSubview:positioned:relativeTo:"), [UIView class], @selector(cus_addSubview:positioned:relativeTo:));
SwizzleMethod([UINavigationController class], NSSelectorFromString(@"pushViewController:transition:forceImmediate:"), [UINavigationController class], @selector(ac_pushViewController:transition:forceImmediate:));
SwizzleMethod([UINavigationController class], NSSelectorFromString(@"_popViewControllerWithTransition:allowPoppingLast:"), [UINavigationController class], @selector(ac_popViewControllerWithTransition:allowPoppingLast:));
SwizzleMethod([UINavigationController class], NSSelectorFromString(@"popToViewController:transition:"), [UINavigationController class], @selector(ac_popToViewController:transition:));
LoadableRunloopIdleFuncEnd(LarkCrashSanitizer_pushCrash)
