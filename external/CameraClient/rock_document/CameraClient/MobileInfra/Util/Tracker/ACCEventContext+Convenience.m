//
//  ACCEventContext+Convenience.m
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import "ACCEventContext+Convenience.h"

@implementation ACCEventContext (Convenience)

+ (instancetype)contextMakeAttributes:(void (^)(ACCAttributeBuilder *))block
{
    ACCEventContext *context = [[ACCEventContext alloc] init];
    return [context makeAttributes:block];
}

+ (instancetype)contextMakeBaseAttributes:(void (^)(ACCAttributeBuilder *))block
{
    return [ACCEventContext contextWithBaseContext:[ACCEventContext contextMakeAttributes:block]];
}

@end
