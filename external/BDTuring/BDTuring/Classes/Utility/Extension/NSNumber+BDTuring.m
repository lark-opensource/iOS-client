//
//  NSNumber+BDTuring.m
//  BDTuring
//
//  Created by bob on 2020/7/9.
//

#import "NSNumber+BDTuring.h"

@implementation NSNumber (BDTuring)

- (id)turing_safeJsonObject {
    return [self copy];
}

@end
