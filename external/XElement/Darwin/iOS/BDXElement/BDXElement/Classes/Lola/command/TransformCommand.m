//
//  TransformCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/5.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "TransformCommand.h"
@interface TransformCommand ()

@property (nonatomic, assign) CGFloat a;
@property (nonatomic, assign) CGFloat b;
@property (nonatomic, assign) CGFloat c;
@property (nonatomic, assign) CGFloat d;
@property (nonatomic, assign) CGFloat tx;
@property (nonatomic, assign) CGFloat ty;

@end

@implementation TransformCommand

- (NSString *)typeStr
{
    return @"tf";
}

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context
{
    self.a = [[data objectForKey:@"kx"] floatValue];
    self.b =  [[data objectForKey:@"ky"] floatValue];
    self.c = [[data objectForKey:@"sx"] floatValue];
    self.d =  [[data objectForKey:@"sy"] floatValue];
    self.tx = [[data objectForKey:@"dx"] floatValue];
    self.ty =  [[data objectForKey:@"dy"] floatValue];
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    CGAffineTransform tranform = CGAffineTransformMake(self.a, self.b, self.c, self.d, self.tx, self.ty);
    CGContextConcatCTM(context, tranform);
}

- (void)recycle {
    _a = 0;
    _b = 0;
    _c = 0;
    _d = 0;
    _tx = 0;
    _ty = 0;
}

@end
