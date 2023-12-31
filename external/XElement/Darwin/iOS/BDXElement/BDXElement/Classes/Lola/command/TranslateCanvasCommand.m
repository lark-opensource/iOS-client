//
//  TranslateCanvasCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/5.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "TranslateCanvasCommand.h"

@interface TranslateCanvasCommand ()

@property (nonatomic, assign) CGFloat dx;
@property (nonatomic, assign) CGFloat dy;

@end

@implementation TranslateCanvasCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"ts";
}

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context
{
    self.dx = [[data objectForKey:@"dx"] floatValue];
    self.dy =  [[data objectForKey:@"dy"] floatValue];
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    CGContextTranslateCTM(context, self.dx, self.dy);
}

- (void)recycle {
    _dx = 0;
    _dy = 0;
}

#pragma mark -

@end
