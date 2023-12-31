//
//  TSPKPipelineSwizzleUtil.m
//  Musically
//
//  Created by ByteDance on 2022/11/24.
//

#import "TSPKPipelineSwizzleUtil.h"
#import "NSObject+TSAddition.h"

@implementation TSPKPipelineSwizzleUtil

+ (void)swizzleMethodWithPipelineClass:(Class _Nullable)pipelineClass clazz:(Class _Nullable)clazz
{
    NSArray<NSString *> *stubClassMethods = [pipelineClass stubbedClassAPIs];
    for (NSString *method in stubClassMethods) {
        NSString *newMethod = [TSPKPipelineSwizzleUtil getNewMethod:method withDataType:[pipelineClass dataType]];
        [clazz ts_swizzleClassMethod:NSSelectorFromString(method) with:NSSelectorFromString(newMethod)];
    }
    
    NSArray<NSString *> *stubInstanceMethods = [pipelineClass stubbedInstanceAPIs];
    for (NSString *method in stubInstanceMethods) {
        NSString *newMethod = [TSPKPipelineSwizzleUtil getNewMethod:method withDataType:[pipelineClass dataType]];
        [clazz ts_swizzleInstanceMethod:NSSelectorFromString(method) with:NSSelectorFromString(newMethod)];
    }
}

+ (NSString *)getNewMethod:(NSString *)method withDataType:(NSString *)dataType
{
    return [NSString stringWithFormat:@"%@_%@_%@", @"tspk", dataType, method];
}

@end
