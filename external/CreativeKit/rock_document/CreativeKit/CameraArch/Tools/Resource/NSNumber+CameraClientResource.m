//
//  NSNumber+CameraClientResource.m
//  CameraClient
//
//  Created by Liu Deping on 2020/4/8.
//

#import "NSNumber+CameraClientResource.h"
#import "ACCResourceUnion.h"
#import <IESLiveResourcesButler/IESLiveResouceBundle+KeyValue.h>

int ACCIntConfig(NSString *name)
{
    return [NSNumber acc_intValueWithName:name];
}

BOOL ACCBoolConfig(NSString *name)
{
    return [NSNumber acc_boolValueWithName:name];
}

CGFloat ACCFloatConfig(NSString *name)
{
    return [NSNumber acc_floatValueWithName:name];
}

NSNumber *ACCNumberConfig(NSString *name)
{
    return [NSNumber acc_numberWithName:name];
}

@implementation NSNumber (CameraClientResource)

+ (int)acc_intValueWithName:(NSString *)name
{
    NSNumber *value = [self acc_numberWithName:name];
    return [value intValue];
}

+ (CGFloat)acc_floatValueWithName:(NSString *)name
{
    NSNumber *value = [self acc_numberWithName:name];
    return [value floatValue];
}

+ (BOOL)acc_boolValueWithName:(NSString *)name
{
    NSNumber *value = [self acc_numberWithName:name];
    return [value boolValue];
}

+ (NSNumber *)acc_numberWithName:(NSString *)name
{
    NSNumber *value = ACCResourceUnion.cameraResourceBundle.value(name);
    NSAssert(value != nil, @"CameraClient does not find value:%@", name);
    return value;
}

@end
