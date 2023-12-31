//
//  RotateCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/5.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "RotateCommand.h"

@interface RotateCommand ()

@property (nonatomic, assign) CGFloat angle;

@end

@implementation RotateCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"ro";
}

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context
{
    self.angle = [[data objectForKey:@"degree"] floatValue];
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    CGContextRotateCTM(context, self.angle);
}

- (void)recycle {
    _angle = 0;
}

@end

