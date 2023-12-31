//
//  NSError+OP.m
//  LarkOPInterface
//
//  Created by yinyuan on 2020/7/13.
//

#import "NSError+OP.h"
#import "OPError.h"

@implementation NSError (OP)

- (OPError * _Nullable)opError {
    if (![self isKindOfClass:OPError.class]) {
        return nil;
    }
    return (OPError *)self;
}

@end
