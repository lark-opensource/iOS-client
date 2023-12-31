//
//  BTD_isEmptyFunctions.m
//  ByteDanceKit
//
//  Created by bytedance on 2020/6/22.
//

#import <Foundation/Foundation.h>
#import "BTDMacros.h"

BOOL BTD_isEmptyString(id param){
    if(!param){
        return YES;
    }
    if ([param isKindOfClass:[NSString class]]){
        NSString *str = param;
        return (str.length == 0);
    }
    NSCAssert(NO, @"BTD_isEmptyString: param %@ is not NSString", param);
    return YES;
}

BOOL BTD_isEmptyArray(id param){
    if(!param){
        return YES;
    }
    if ([param isKindOfClass:[NSArray class]]){
        NSArray *array = param;
        return (array.count == 0);
    }
    NSCAssert(NO, @"BTD_isEmptyArray: param %@ is not NSArray", param);
    return YES;
}

BOOL BTD_isEmptyDictionary(id param){
    if(!param){
        return YES;
    }
    if ([param isKindOfClass:[NSDictionary class]]){
        NSDictionary *dict = param;
        return (dict.count == 0);
    }
    NSCAssert(NO, @"BTD_isEmptyDictionary: param %@ is not NSDictionary", param);
    return YES;
}
