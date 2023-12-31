//
//  ScaleCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/5.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "ScaleCommand.h"

@interface ScaleCommand ()

@property (nonatomic, assign) CGFloat sx;
@property (nonatomic, assign) CGFloat sy;

@end

@implementation ScaleCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"sc";
}

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context
{
    self.sx = [[data objectForKey:@"sx"] floatValue];
    self.sy =  [[data objectForKey:@"sy"] floatValue];
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    CGContextScaleCTM(context, self.sx, self.sy);
}

- (void)recycle {
    
    _sx = 0;
    _sy = 0;
}

@end
