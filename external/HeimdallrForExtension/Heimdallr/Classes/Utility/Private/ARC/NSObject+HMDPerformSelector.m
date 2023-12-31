//
//  NSObject+HMDPerformSelector.m
//  Heimdallr
//
//  Created by joy on 2018/7/30.
//

#import "NSObject+HMDPerformSelector.h"
#import <objc/runtime.h>
#import <objc/message.h>

// 为了解决与 Aspects 库同时Hook方法时的问题
static BOOL HMD_isMsgForwardIMP(IMP imp) {
    return imp == _objc_msgForward
#if !defined(__arm64__)
    || imp == (IMP)_objc_msgForward_stret
#endif
    ;
}
@implementation NSObject (HMDPerformSelector)

- (BOOL)hmd_checkHookConflictAndInvokeSelector:(SEL)aSelector withArguments:(nullable NSArray *)arguments
{
    return [self hmd_checkHookConflictAndInvokeSelector:aSelector withArguments:arguments result:NULL];
}

- (BOOL)hmd_checkHookConflictAndInvokeSelector:(SEL)aSelector withArguments:(nullable NSArray *)arguments result:(nullable void *)result
{
    Method aimtMethod = class_getInstanceMethod(self.class, aSelector);
    IMP aimMethodIMP = method_getImplementation(aimtMethod);
    
    if (HMD_isMsgForwardIMP(aimMethodIMP)) {
        //1、创建NSMethodSignature对象
      
        NSString *selectorStr = NSStringFromSelector(aSelector);
        NSString *deleteStr;
        if ([selectorStr hasPrefix:@"hmd_"]) {
            deleteStr = @"hmd_";
            selectorStr = [selectorStr stringByReplacingOccurrencesOfString:deleteStr withString:@""];
        }
        SEL aimtSel = NSSelectorFromString(selectorStr);

        NSMethodSignature *signature = [[self class] instanceMethodSignatureForSelector:aimtSel];
        
        //2、判断传入的方法是否存在
        if (signature==nil) {
            return NO;
        }
        
        //3、创建NSInvocation对象
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:signature];
        
        //4、保存方法所属的对象
        inv.target = self;
        inv.selector = aimtSel;
        
        //5、设置参数
        if (arguments) {
            [arguments enumerateObjectsUsingBlock:^(id  _Nonnull arg, NSUInteger idx, BOOL * _Nonnull stop) {
                //参数是NULL
                if([arg isKindOfClass:[NSNull class]]){
                    arg = nil;
                }
                //参数是SEL类型
                if([arg isKindOfClass:[NSString class]]){
                    if([(NSString *)arg hasPrefix:@"SEL_"]){
                        SEL sel = NSSelectorFromString([(NSString *)arg substringFromIndex:4]);
                        [inv setArgument:&sel atIndex:idx + 2];
                        return;
                    }
                }
                [inv setArgument:&arg atIndex:idx + 2];
            }];
        }

        
        [self forwardInvocation:inv];
        
        // 6、获取返回值
        if (result) {
            [inv getReturnValue:result];
        }
        
        return YES;
    }
    
    return NO;
}

@end
