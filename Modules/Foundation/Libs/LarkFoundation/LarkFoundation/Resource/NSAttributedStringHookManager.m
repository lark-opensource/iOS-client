//
//  NSAttributedStringHookManager.m
//  Pods
//
//  Created by 李勇 on 2019/11/20.
//

#import "NSAttributedStringHookManager.h"
#import <objc/runtime.h>
#import <LKLoadable/Loadable.h>

@implementation NSAttributedStringHookManager

#pragma mark - NSConcreteAttributedString
+ (void)hookAttributedString {
    /* 去除私有 API
    // get NSConcreteAttributedString's init method
    Class attributedClass = NSClassFromString(@"NSConcreteAttributedString");
    Method oldMethod = class_getInstanceMethod(attributedClass, @selector(initWithString:));
    // add method to NSConcreteAttributedString
    const char *type = method_getTypeEncoding(oldMethod);
    IMP imp = class_getMethodImplementation(self, @selector(create:));
    class_addMethod(attributedClass, @selector(create:), imp, type);
    // method exchange
    Method newMethod = class_getInstanceMethod(attributedClass, @selector(create:));
    method_exchangeImplementations(oldMethod, newMethod);
     */
}

- (instancetype)create:(NSString*)string {
    string = [string stringByReplacingOccurrencesOfString:@"?️" withString:@"?"];
    return [self create:string];
}

#pragma mark - NSConcreteMutableAttributedString
+ (void)hookMutableAttributedString {
    /* 去除私有 API
    // exchange initWithString:
    {
        // get NSConcreteMutableAttributedString's init method
        Class attributedClass = NSClassFromString(@"NSConcreteMutableAttributedString");
        Method oldMethod = class_getInstanceMethod(attributedClass, @selector(initWithString:));
        // add method to NSConcreteMutableAttributedString
        const char *type = method_getTypeEncoding(oldMethod);
        IMP imp = class_getMethodImplementation(self, @selector(createMutable:));
        class_addMethod(attributedClass, @selector(createMutable:), imp, type);
        // method exchange
        Method newMethod = class_getInstanceMethod(attributedClass, @selector(createMutable:));
        method_exchangeImplementations(oldMethod, newMethod);
    }
    // exchange initWithString:attributes:
    {
        // get NSConcreteMutableAttributedString's init method
        Class attributedClass = NSClassFromString(@"NSConcreteMutableAttributedString");
        Method oldMethod = class_getInstanceMethod(attributedClass, @selector(initWithString:attributes:));
        // add method to NSConcreteMutableAttributedString
        const char *type = method_getTypeEncoding(oldMethod);
        IMP imp = class_getMethodImplementation(self, @selector(createMutable:attributes:));
        class_addMethod(attributedClass, @selector(createMutable:attributes:), imp, type);
        // method exchange
        Method newMethod = class_getInstanceMethod(attributedClass, @selector(createMutable:attributes:));
        method_exchangeImplementations(oldMethod, newMethod);
    }
     */
}

- (instancetype)createMutable:(NSString*)string {
    string = [string stringByReplacingOccurrencesOfString:@"?️" withString:@"?"];
    return [self createMutable:string];
}

- (instancetype)createMutable:(NSString*)string attributes:(NSDictionary*)attributes {
    string = [string stringByReplacingOccurrencesOfString:@"?️" withString:@"?"];
    return [self createMutable:string attributes:attributes];
}

@end

LoadableMainFuncBegin(hookAttributedString)
// Only problems on iOS11
if (@available(iOS 12.0, *)) { return; }
[NSAttributedStringHookManager hookAttributedString];
[NSAttributedStringHookManager hookMutableAttributedString];
LoadableMainFuncEnd(hookAttributedString)
