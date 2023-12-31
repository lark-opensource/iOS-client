//
//  NSSet+OK.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "NSSet+OK.h"
#import "NSObject+OK.h"

@implementation NSSet (OK)

- (id)ok_safeJsonObject {
    
    return [self.allObjects ok_safeJsonObject];
}

@end
