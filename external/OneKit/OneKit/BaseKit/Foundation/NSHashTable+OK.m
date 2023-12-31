//
//  NSHashTable+OK.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "NSHashTable+OK.h"
#import "NSObject+OK.h"

@implementation NSHashTable (OK)

- (id)ok_safeJsonObject {
    return [self.allObjects ok_safeJsonObject];
}

@end
