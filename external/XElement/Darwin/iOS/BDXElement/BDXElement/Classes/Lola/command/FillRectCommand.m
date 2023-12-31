//
//  FillRectCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/10/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "FillRectCommand.h"

@interface FillRectCommand ()
@property(nonatomic, assign) CGRect rect;


@end

@implementation FillRectCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"fr";
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
    //需要存储image吗？
    CGContextFillRect(context, self.rect);
}

- (void)recycle {
    _rect = CGRectZero;
}

@end
