//
//  TSPKCallStackRuleInfo.m
//  BDAlogProtocol
//
//  Created by bytedance on 2022/7/21.
//

#import "TSPKCallStackRuleInfo.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "TSPKCallStackMacro.h"
#import <objc/runtime.h>
#import "TSPKBinaryInfo.h"

@implementation TSPKCallStackRuleInfo

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        self.className = [dict btd_stringValueForKey:@"class"];
        self.selName = [dict btd_stringValueForKey:@"sel"];
        self.isMeta = [dict btd_boolValueForKey:@"isClassMethod"];
        self.binaryName = nil;
        self.slide = 0;
        self.start = [self vmOffset]; // calculate start = (NSUInteger)imp
        self.end = 0;
    }
    return self;
}

- (BOOL)isCompleted {
    return !BTD_isEmptyString(self.binaryName) && self.end != 0;
}

- (NSUInteger)vmOffset {
    if (BTD_isEmptyString(self.className) || BTD_isEmptyString(self.selName)) {
        return 0;
    }

    Class c = NSClassFromString(self.className);
    SEL s = NSSelectorFromString(self.selName);
    Method m = NULL;
    if (self.isMeta) {
        m = class_getClassMethod(c, s);
    } else {
        m = class_getInstanceMethod(c, s);
    }
    if (m == NULL) {
        return 0;
    }

    IMP imp = method_getImplementation(m); // calculate by runtime
    return (NSUInteger)imp;
}

- (NSString *)uniqueKey {
    return [NSString stringWithFormat:@"%@%@%@", self.className, self.isMeta?@"::":@":", self.selName];
}

- (NSComparisonResult)compare:(TSPKCallStackRuleInfo *)otherInfo {
    return [@(self.start) compare:@(otherInfo.start)];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"class:%@ selector:%@ start:%@ end:%@ binaryName:%@", self.className, self.selName, @(self.start), @(self.end), self.binaryName];
}

@end

@implementation TPSKCallStackDataTypeInfo

@end
