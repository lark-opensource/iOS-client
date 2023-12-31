//
//  NSNumber+OK.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "NSNumber+OK.h"

@implementation NSNumber (OK)

- (id)ok_safeJsonObject {
    /// fallback to zero
    if (!isnormal(self.doubleValue)) {
        return @(0);
    }
    
    return [self copy];
}

- (NSString *)ok_safeJsonObjectKey {
    return self.stringValue;
}

@end
