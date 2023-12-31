//
//  NSNumber+ACCAdditions.m
//  CreativeKit-Pods-Aweme
//
//  Created by Liu Deping on 2021/2/8.
//

#import "NSNumber+ACCAdditions.h"

@implementation NSNumber (ACCAdditions)

- (BOOL)acc_isNaN
{
    return isnan(self.doubleValue);
}

- (id)acc_safeJsonObject
{
    if (self.acc_isNaN) {
        return @"nan";
    } else {
        return self.copy;
    }
}

@end
