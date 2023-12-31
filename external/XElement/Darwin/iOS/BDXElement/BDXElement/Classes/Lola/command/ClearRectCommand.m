//
//  ClearRectCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/6.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "ClearRectCommand.h"

@interface ClearRectCommand ()
@property(nonatomic, assign) CGRect rect;


@end

@implementation ClearRectCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"cr";
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
    CGContextClearRect(context, _rect);
}

- (void)recycle {
    _rect = CGRectZero;
}

@end
