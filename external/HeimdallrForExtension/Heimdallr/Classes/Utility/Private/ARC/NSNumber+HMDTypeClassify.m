//
//  NSNumber+HMDTypeClassify.m
//  Heimdallr
//
//  Created by sunrunwang on 2019/4/18.
//

#import "NSNumber+HMDTypeClassify.h"

@implementation NSNumber (HMDTypeClassify)

- (BOOL)isIntegerType {
    const char *currentType = [self objCType];
    NSString *encodeString = [NSString stringWithUTF8String:currentType];
    return [@[@"c", @"i", @"s", @"l", @"q", @"C", @"I", @"S", @"L", @"Q", @"B"] containsObject:encodeString];
}

- (BOOL)isBoolType {
    CFTypeID boolID = CFBooleanGetTypeID();
    CFTypeID numID = CFGetTypeID((__bridge CFTypeRef)self);
    return numID == boolID;
}

@end
