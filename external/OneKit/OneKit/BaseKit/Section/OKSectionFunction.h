//
//  OKSectionFunction.h
//  OneKit
//
//  Created by bob on 2020/10/2.
//

#import <OneKit/OKMacros.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct _OKFunction {
    const char *key;
    const void (*function)(void);
} OKFunction;

#define OKFunctionIdentifier(COUNTER) OKIdentifier(__OneKitFunction, COUNTER)
#define OKFunctionDataIdentifier OKIdentifier(__OneKitFunction_, __COUNTER__)

#define _OK_FUNCTION_EXPORT(key, COUNTER) \
__attribute__((used, no_sanitize_address)) static void OKFunctionIdentifier(COUNTER)(void);\
OKSectionNameData(__OneKitFunction) \
static const OKFunction OKFunctionDataIdentifier = (OKFunction){key, (void *)(&OKFunctionIdentifier(COUNTER))}; \
__attribute__((used, no_sanitize_address)) static void OKFunctionIdentifier(COUNTER)


#define OK_FUNCTION_EXPORT(key) \
_OK_FUNCTION_EXPORT(key, __COUNTER__)

/**
e.g.
1. define function
OK_FUNCTION_EXPORT("a")(void){
    printf("\nFunction:test function a");
}

2.call function
 [[OKSectionFunction sharedInstance] excuteFunctionsForKey:@"a"];
*/

@interface OKSectionFunction : NSObject

+ (instancetype)sharedInstance;

- (void)excuteFunctionsForKey:(NSString *)key;
/// empty method for swift
- (void)excuteSwiftFunctionsForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
