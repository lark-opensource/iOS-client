//
//  NSProxy+ACCProtocolContainer.m
//  CreationKit
//
//  Created by Howie He on 2021-05-08.
//

#import "NSProxy+ACCProtocolContainer.h"

@implementation NSProxy (ACCProtocolContainer)

- (nullable id)acc_getProtocol:(Protocol *)protocol
{
    if ([self conformsToProtocol:protocol]) {
        return self;
    }
    NSAssert(@"%@ should conforms to %@", self, NSStringFromProtocol(protocol));
    return nil;
}

@end
