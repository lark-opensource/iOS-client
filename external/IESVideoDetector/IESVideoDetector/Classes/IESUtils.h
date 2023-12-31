//
//  IESUtils.h
//  Pods
//
//  Created by geekxing on 2020/6/4.
//

#ifndef IESUtils_h
#define IESUtils_h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_INLINE NSValue *IESStringToValue(const char *type, NSString *str) {
    NSCAssert([str isKindOfClass:NSString.class], @"must be an NSString. got: %@", str) ;
    if (strcmp(type, @encode(CGPoint)) == 0) {
        return [NSValue valueWithCGPoint:CGPointFromString(str)];
    } else if (strcmp(type, @encode(CGSize)) == 0) {
        return [NSValue valueWithCGSize:CGSizeFromString(str)];
    } else if (strcmp(type, @encode(UIEdgeInsets)) == 0) {
        return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsFromString(str)];
    } else if (strcmp(type, @encode(double)) == 0) {
        return @(str.doubleValue);
    } else if (strcmp(type, @encode(float)) == 0) {
        return @(str.floatValue);
    } else if (strcmp(type, @encode(int)) == 0) {
        return @(str.intValue);
    } else if (strcmp(type, @encode(long long)) == 0) {
        return @(str.longLongValue);
    } else if (strcmp(type, @encode(bool)) == 0) {
        return @(str.boolValue);
    }
    NSCAssert(YES, @"not support type: %s", type);
    return nil;
}

NS_INLINE NSString *IESValueToString(NSValue *obj) {
    NSCAssert([obj isKindOfClass:NSValue.class], @"must be an NSValue. got: %@", obj);
    const char *type = obj.objCType;
    if (strcmp(type, @encode(CGPoint)) == 0) {
        return NSStringFromCGPoint([obj CGPointValue]);
    } else if (strcmp(type, @encode(CGSize)) == 0) {
        return NSStringFromCGSize([obj CGSizeValue]);
    } else if (strcmp(type, @encode(UIEdgeInsets)) == 0) {
        return NSStringFromUIEdgeInsets(obj.UIEdgeInsetsValue);
    } else if ([obj isKindOfClass:NSNumber.class]) {
        return [(NSNumber *)obj stringValue];
    }
    return obj.description;
}

#endif /* IESUtils_h */
