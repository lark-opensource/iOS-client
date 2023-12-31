//
//  ClipPathCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/6.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "ClipPathCommand.h"

@interface ClipPathCommand ()

@end

@implementation ClipPathCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"cp";
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    CGContextClip(context);
}

@end
