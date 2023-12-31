//
//  StrokeRectCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/6.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "StrokeRectCommand.h"

@interface StrokeRectCommand ()

@property(nonatomic, assign) CGRect rect;

@end

@implementation StrokeRectCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"sr";
}

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context
{
    NSInteger x = [[data objectForKey:@"x"] floatValue];
    NSInteger  y =  [[data objectForKey:@"y"] floatValue];
    NSInteger  width =  [[data objectForKey:@"w"] floatValue];
    NSInteger height =[[data objectForKey:@"h"] floatValue];
    
    self.rect = CGRectMake(x, y, width, height);
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    CGContextSetStrokeColorWithColor(context, drawContext.strokeColor.CGColor);
    CGContextStrokeRect(context, _rect);
}

- (void)recycle {
    _rect = CGRectZero;
}

@end
