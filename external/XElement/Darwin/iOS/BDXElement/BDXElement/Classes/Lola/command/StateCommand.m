//
//  StateCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/5.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "StateCommand.h"

@interface StateCommand ()

@property (nonatomic, copy) NSString *state;

@end

@implementation StateCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"sta";
}

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context
{
    self.state = [data objectForKey:@"state"];
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    if ([self.state isEqualToString:@"save"]) {
        CGContextSaveGState(context);
    } else if ( [self.state isEqualToString:@"restore"]) {
        CGContextRestoreGState(context);
    }
}

- (void)recycle {
    _state = nil;
}

@end
