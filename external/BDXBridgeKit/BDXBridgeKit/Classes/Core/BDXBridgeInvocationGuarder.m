//
//  BDXBridgeInvocationGuarder.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/9.
//

#import "BDXBridgeInvocationGuarder.h"
#import <BDAssert/BDAssert.h>

@interface BDXBridgeInvocationGuarder ()

@property (nonatomic, copy) NSString *message;
@property (nonatomic, assign) NSInteger invocationCount;

@end

@implementation BDXBridgeInvocationGuarder

- (instancetype)initWithMessage:(NSString *)message
{
    self = [super init];
    if (self) {
        _message = [message copy];
    }
    return self;
}

- (void)invoke
{
    ++self.invocationCount;
}

- (void)dealloc
{
    BDAssert(self.invocationCount == 1, self.message ?: @"The guarded handler should be invoked once and only once.");
}

@end
