//
//  NSObject+OK.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "NSObject+OK.h"
#import <objc/objc.h>
#import <objc/runtime.h>
@implementation NSObject (OK)

- (id)ok_safeJsonObject {
    return [self description];
}

- (NSString *)ok_safeJsonObjectKey {
    return [self description];
}

- (NSString *)ok_jsonStringEncoded {
    if (![NSJSONSerialization isValidJSONObject:self]) {
        return nil;
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:self
                                                   options:kNilOptions
                                                     error:nil];
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString *)ok_jsonStringEncodedForJS {
    NSString *string = [self ok_jsonStringEncoded];
    string = [string stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    string = [string stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];

    return string;
}

+ (BOOL)ok_swizzleInstanceMethod:(SEL)origSelector with:(SEL)newSelector
{
    Method originalMethod = class_getInstanceMethod(self, origSelector);
    Method swizzledMethod = class_getInstanceMethod(self, newSelector);
    if (!originalMethod || !swizzledMethod) {
        return NO;
    }
    if (class_addMethod(self,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        class_replaceMethod(self,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        class_replaceMethod(self,
                            newSelector,
                            class_replaceMethod(self,
                                                origSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
    return YES;
}

+ (BOOL)ok_swizzleClassMethod:(SEL)origSelector with:(SEL)newSelector
{
    Class cls = [self class];
    Method originalMethod = class_getClassMethod(cls, origSelector);
    Method swizzledMethod = class_getClassMethod(cls, newSelector);
    if (!originalMethod || !swizzledMethod) {
        return NO;
    }
    Class metacls = objc_getMetaClass(NSStringFromClass(cls).UTF8String);
    if (class_addMethod(metacls,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        class_replaceMethod(metacls,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    return YES;
}

@end
