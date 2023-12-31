//
//  FBSwiftGraphElement.m
//  FBRetainCycleDetector
//
//  Created by  郎明朗 on 2021/5/7.
//

#import "FBSwiftGraphElement.h"
#import "FBRetainCycleUtils.h"
#import "FBGetSwiftAllRetainedObjectsHelper.h"
#import <objc/runtime.h>

@implementation FBSwiftGraphElement

+ (BOOL)judegeIfSwiftInstanceWith:(id)object{
    if (object) {
        reportAlog([NSString stringWithFormat:@"%@%@", @"judegeIfSwiftInstanceWith: ", NSStringFromClass(object_getClass(object)) ?:@"nil"]);
        if ([object isProxy] && [object class] == nil) {
            return false;
        }
        return [NSClassFromString(@"FBGetSwiftAllRetainedObjects") isSwiftInstanceWith:object];
    }
    return false;
}


- (NSSet *)allRetainedObjects {
    
    __attribute__((objc_precise_lifetime)) id object = self.object;
    Class aCls = object_getClass(object);
    
    if (!object || !aCls) {
      return nil;
    }
    
    //get associate
    NSMutableArray *results = [[[super allRetainedObjects] allObjects] mutableCopy];
    
    
//    记录找每个class strong property 耗时
//    struct timespec start;
//    clock_gettime(CLOCK_MONOTONIC_RAW, &start);
    
    NSArray<id<PropertyAndNameProtocol>> *ary = [NSClassFromString(@"FBGetSwiftAllRetainedObjects") getAllStrongRetainedReferencesOf:object withConfiguration:self.configuration];
    
//    struct timespec end;
//    clock_gettime(CLOCK_MONOTONIC_RAW, &end);
//    double res = ((int64_t)end.tv_sec * 1000000 + end.tv_nsec / 1000) - ((int64_t)start.tv_sec * 1000000 + start.tv_nsec / 1000);
//    NSLog(@"%@%@%@", NSStringFromClass(aCls),@"查找强引用耗时",@(res));
        
    for (NSInteger i = 0; i < ary.count; i++) {
        id<PropertyAndNameProtocol> temp = [ary objectAtIndex:i];
        if ([temp propertyValue] == [NSNull null]) {
            continue;
        }
        FBObjectiveCGraphElement *element = FBWrapObjectGraphElementWithContext(self, [temp propertyValue], self.configuration, ([temp propertyName]).length > 0 ? @[[temp propertyName]] : nil);
        if (element) {
            [results addObject:element];
        }
    }
    return [NSSet setWithArray:results];
}

@end




