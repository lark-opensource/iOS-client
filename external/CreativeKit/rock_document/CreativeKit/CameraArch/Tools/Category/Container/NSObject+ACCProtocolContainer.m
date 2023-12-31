//
//  NSObject+ACCProtocolContainer.m
//  ByteDanceKit
//
//  Created by Howie He on 2021-05-08.
//

#import "NSObject+ACCProtocolContainer.h"

@implementation NSObject (ACCProtocolContainer)

- (nullable id)acc_getProtocol:(Protocol *)protocol
{
    if ([self conformsToProtocol:protocol]) {
        return self;
    }
    NSAssert(@"%@ should conforms to %@", self, NSStringFromProtocol(protocol));
    return nil;
}

@end
