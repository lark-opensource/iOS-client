//
//  LolaDrawCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/10/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "LolaDrawCommand.h"

@interface LolaDrawCommand ()

@end


@implementation LolaDrawCommand

- (void)dealloc
{
//    NSLog(@"<-------> %s", __func__);
}

- (instancetype)init
{
    if (self = [super init]) {
        NSAssert([self typeStr].length >0, @"require implement typeStr");
    }
    
    return self;
}

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context
{
    
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<type: %@>", @"abs"];
}

- (void)recycle {}

@end
