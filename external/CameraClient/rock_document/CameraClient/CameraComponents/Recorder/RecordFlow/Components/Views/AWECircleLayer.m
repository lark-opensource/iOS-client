//
//  AWECircleLayer.m
//  Aweme
//
//  Created by 郝一鹏 on 2017/8/23.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWEWhiteCircleLayer.h"

@implementation AWECircleLayer

+ (instancetype)circleLayerWithUsePinkColor:(BOOL)usePinkColor {
    return [[AWEWhiteCircleLayer alloc] init];
}

- (void)drawInContext:(CGContextRef)context
{
    [super drawInContext:context];
    
    UIGraphicsPushContext(context);
    
    [self drawCircleInContext:context];
    
    UIGraphicsPopContext();
}

- (void)drawCircleInContext:(CGContextRef)c
{

}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"innerFragment"] || [key isEqualToString:@"circleColor"]) {
        return YES;
    }
    return [super needsDisplayForKey:key];
}


@end
