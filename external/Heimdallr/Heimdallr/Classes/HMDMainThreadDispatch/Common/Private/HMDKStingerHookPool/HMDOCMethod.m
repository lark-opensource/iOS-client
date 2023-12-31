//
//  HMDOCMethod.m
//  Heimdallr
//
//  Created by bytedance on 2022/10/13.
//

#include <stdatomic.h>
#import "HMDMacro.h"
#import "HMDOCMethod.h"
#import "HMDSwizzle.h"

static BOOL parseMethodString(NSString * _Nonnull methodString, Class * _Nonnull class,
                              SEL * _Nonnull selector, BOOL * _Nonnull isInstance);

@implementation HMDOCMethod

@synthesize status = _status;

- (instancetype _Nullable)initWithClass:(Class _Nonnull)aClass
                               selector:(SEL)selector
                            classMethod:(BOOL)classMethod {
    if(self = [super init]) {
        _methodClass = aClass;
        _selector = selector;
        _classMethod = classMethod;
    }
    return self;
}

- (instancetype _Nullable)initWithString:(NSString * _Nonnull)methodString {
    if(methodString == nil) DEBUG_RETURN(nil);
    
    Class aClass; SEL selector; BOOL isInstance;
    if(parseMethodString(methodString, &aClass, &selector, &isInstance)) {
        BOOL validMethod;
        if(isInstance) validMethod = (hmd_classHasInstanceMethod(aClass, selector) != NULL);
        else validMethod = (hmd_classHasClassMethod(aClass, selector) != NULL);
        if(validMethod) {
            return [self initWithClass:aClass selector:selector classMethod:!isInstance];
        } DEBUG_ELSE
    } DEBUG_ELSE
    
    return nil;
}

+ (instancetype _Nullable)methodWithString:(NSString * _Nonnull)methodString {
    return [[HMDOCMethod alloc] initWithString:methodString];
}

- (void)setStatus:(NSUInteger)status {
    __atomic_store_n(&_status, status, __ATOMIC_RELEASE);
}

- (NSUInteger)status {
    return __atomic_load_n(&_status, __ATOMIC_ACQUIRE);
}

#pragma mark - Equal and Hash

- (BOOL)isEqual:(id _Nonnull)object {
    if([object isKindOfClass:HMDOCMethod.class]) {
        __kindof HMDOCMethod *anotherMethod = object;
        return [self isEqualToMethod:anotherMethod];
    }
    return NO;
}

- (BOOL)isEqualToMethod:(HMDOCMethod * _Nonnull)anotherMethod {
    if(anotherMethod.classMethod == self.classMethod &&
       anotherMethod.methodClass == self.methodClass &&
       sel_isEqual(anotherMethod.selector, self.selector)) return YES;
    return NO;
}

- (NSUInteger)hash {
    return (NSUInteger)(__bridge void *)_methodClass;
}

@end

static BOOL parseMethodString(NSString * _Nonnull methodString, Class _Nullable * _Nonnull class,
                              SEL _Nullable * _Nonnull selector, BOOL * _Nonnull isInstance) {
    
    if (methodString.length == 0 || class == NULL || selector == NULL || isInstance == NULL) DEBUG_RETURN(NO);
    
    DEBUG_ASSERT(class != NULL && selector != NULL && isInstance != NULL);
    
    NSString *method = [methodString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([method hasPrefix:@"+"])      isInstance[0] = NO;
    else if([method hasPrefix:@"-"]) isInstance[0] = YES;
    else return NO;
    
    // remove '+' or '-'
    method = [method substringFromIndex:1];
    method = [method stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // remove '[]'
    if (method.length > 2 && [method hasPrefix:@"["] && [method hasSuffix:@"]"])
        method = [method substringWithRange:NSMakeRange(1, method.length - 2)];
    
    NSArray<NSString *> *components = [method componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (!components || components.count != 2) DEBUG_RETURN(NO);
    
    NSString *classString = components[0];
    NSString *selectorString = components[1];
    
    if (classString.length == 0 || selectorString.length == 0)
        DEBUG_RETURN(NO);
    
    class[0] = NSClassFromString(classString);
    selector[0] = NSSelectorFromString(selectorString);
    
    if(class[0] == nil || selector[0] == NULL) DEBUG_RETURN(NO);
    
    return YES;
}

