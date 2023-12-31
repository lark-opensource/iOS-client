//
//  PathControlCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/10/10.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "PathControlCommand.h"

/*
"bp" -> beginPath
"cp" -> closePath
"mt" -> moveTo
"lt" -> lineTo
"ar" -> arc
"at" -> arcTo
"qc" -> quadraticCurveTo
"bc" -> bezierCurveTo
"rc" -> rect
"st" -> stroke
"fi" -> fill
 */

typedef NS_ENUM(NSInteger, LolaPathAction) {
    LolaPathAction_None = 0,
    LolaPathAction_FILL,
    LolaPathAction_STROKE,
};

@interface PathControlCommand ()

@property (nonatomic, copy) NSString *subType;

@property (nonatomic, assign) LolaPathAction action;

@property(nonatomic, strong) UIBezierPath *path;

@property(nonatomic, strong) NSDictionary *pathData;

@end

@implementation PathControlCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"pas";
}

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context
{
    NSString *subType = [data objectForKey:@"st"];
    self.subType = subType;
    
//    if ([self.subType isEqualToString:@"bp"]) {
//        [self beignPath:context];
//    } else if ([self.subType isEqualToString:@"mt"]) {
//        [self moveTo:data context:context];
//    } else if ([self.subType isEqualToString:@"cp"]) {
//        [self closePath:context];
//    } else if ([self.subType isEqualToString:@"lt"]) {
//        [self lineTo:data context:context];
//    } else if ([self.subType isEqualToString:@"ar"]) {
//        [self arc:data context:context];
//    } else if ([self.subType isEqualToString:@"at"]) {
//        [self arcTo:data context:context];
//    } else if ([self.subType isEqualToString:@"qc"]) {
//        [self quadraticCurveTo:data context:context];
//    } else if ([self.subType isEqualToString:@"bc"]) {
//        [self bezierCurveTo:data context:context];
//    } else if ([self.subType isEqualToString:@"rc"]) {
//        [self rect:data context:context];
//    } else if ([self.subType isEqualToString:@"st"]) {
//        [self stroke:context];
//    } else if ([self.subType isEqualToString:@"fi"]) {
//        [self fill:context];
//    }
    
    self.pathData = data;
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
        if ([self.subType isEqualToString:@"bp"]) {
            [self beignPath:drawContext context:context];
        } else if ([self.subType isEqualToString:@"mt"]) {
            [self moveTo:drawContext context:context];
        } else if ([self.subType isEqualToString:@"cp"]) {
            [self closePath:drawContext context:context];
        } else if ([self.subType isEqualToString:@"lt"]) {
            [self lineTo:drawContext context:context];
        } else if ([self.subType isEqualToString:@"ar"]) {
            [self arc:drawContext context:context];
        } else if ([self.subType isEqualToString:@"at"]) {
            [self arcTo:drawContext context:context];
        } else if ([self.subType isEqualToString:@"qc"]) {
            [self quadraticCurveTo:drawContext context:context];
        } else if ([self.subType isEqualToString:@"bc"]) {
            [self bezierCurveTo:drawContext context:context];
        } else if ([self.subType isEqualToString:@"rc"]) {
            [self rect:drawContext context:context];
        } else if ([self.subType isEqualToString:@"st"]) {
            [self stroke:drawContext context:context];
        } else if ([self.subType isEqualToString:@"fi"]) {
            [self fill:drawContext context:context];
        }

    
//    switch (self.action) {
//        case LolaPathAction_FILL:
//        {
//            self.path.lineWidth = drawContext.lineWidth;
//            [drawContext.fillColor set];
//            [self.path fill];
//        }
//            break;
//        case LolaPathAction_STROKE:
//        {
//            self.path.lineWidth = drawContext.lineWidth;
//            [drawContext.strokeColor set];
//            [self.path stroke];
//        }
//            break;
//        default:
//            break;
//    }
}

- (void)recycle {
    _subType = nil;
    _action = LolaPathAction_None;
    _path = nil;
}

#pragma mark -
- (void)beignPath:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
//    UIBezierPath *path = [UIBezierPath new];
//    [context addNewPath:path];
    
    CGContextBeginPath(context);
}

- (void)closePath:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
//    UIBezierPath *path = [context currentPath];
//    [path closePath];
    
    CGContextClosePath(context);
}

- (void)fill:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
//    self.action = LolaPathAction_FILL;
//    self.path = [context currentPath];
    
    if (CGContextIsPathEmpty(context) && drawContext.lastPath) {
        CGContextAddPath(context, drawContext.lastPath.CGPath);
    } else {
        CGPathRef path = CGContextCopyPath(context);
        drawContext.lastPath = [UIBezierPath bezierPathWithCGPath:path];
        
        CGPathRelease(path);
    }
    
    CGContextFillPath(context);
}

- (void)stroke:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
//    self.action = LolaPathAction_STROKE;
//    self.path = [context currentPath];
        
    if (CGContextIsPathEmpty(context) && drawContext.lastPath) {
        CGContextAddPath(context, drawContext.lastPath.CGPath);
    } else {
        CGPathRef path = CGContextCopyPath(context);
        drawContext.lastPath = [UIBezierPath bezierPathWithCGPath:path];
        
        CGPathRelease(path);
    }
    
    CGContextSetStrokeColorWithColor(context, drawContext.strokeColor.CGColor);
    CGContextStrokePath(context);
}

- (void)moveTo:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    NSDictionary *data = self.pathData;
    CGFloat x = [[data objectForKey:@"x"] floatValue];
    CGFloat y = [[data objectForKey:@"y"] floatValue];
    
//    UIBezierPath *path = [context currentPath];
//    [path moveToPoint:CGPointMake(x, y)];
    CGContextMoveToPoint(context, x, y);
}

- (void)lineTo:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    NSDictionary *data = self.pathData;

    CGFloat x = [[data objectForKey:@"x"] floatValue];
    CGFloat y = [[data objectForKey:@"y"] floatValue];
//
//    UIBezierPath *path = [context currentPath];
//    [path addLineToPoint:CGPointMake(x, y)];
    
    CGContextAddLineToPoint(context, x, y);
}

- (void)arc:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    NSDictionary *data = self.pathData;

    CGFloat x = [[data objectForKey:@"x"] floatValue];
    CGFloat y = [[data objectForKey:@"y"] floatValue];
    CGFloat radius = [[data objectForKey:@"r"] floatValue];
    CGFloat sAngle = [[data objectForKey:@"sAngle"] floatValue];
    CGFloat eAngle = [[data objectForKey:@"eAngle"] floatValue];
    BOOL clockwise = [[data objectForKey:@"cw"] boolValue];

//    UIBezierPath *path = [context currentPath];
//    [path addArcWithCenter:CGPointMake(x, y) radius:radius startAngle:sAngle endAngle:eAngle clockwise:clockwise];
    
    CGContextAddArc(context, x, y, radius, sAngle, eAngle, clockwise);

}

- (void)arcTo:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    NSDictionary *data = self.pathData;

    CGFloat x1 = [[data objectForKey:@"x1"] floatValue];
    CGFloat y1 = [[data objectForKey:@"y1"] floatValue];
    CGFloat x2 = [[data objectForKey:@"x2"] floatValue];
    CGFloat y2 = [[data objectForKey:@"y2"] floatValue];
    CGFloat radius = [[data objectForKey:@"r"] floatValue];
     
//    UIBezierPath *path = [context currentPath];
    
    CGContextAddArcToPoint(context, x1, y1, x2, y2, radius);

}

- (void)quadraticCurveTo:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    NSDictionary *data = self.pathData;

    CGFloat x = [[data objectForKey:@"x"] floatValue];
    CGFloat y = [[data objectForKey:@"y"] floatValue];
    CGFloat cpx = [[data objectForKey:@"cpx"] floatValue];
    CGFloat cpy = [[data objectForKey:@"cpy"] floatValue];
    
//    UIBezierPath *path = [context currentPath];
//    [path addQuadCurveToPoint:CGPointMake(x, y) controlPoint:CGPointMake(cpx, cpy)];
    
    CGContextAddQuadCurveToPoint(context, cpx, cpy, x, y);

}

- (void)bezierCurveTo:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    NSDictionary *data = self.pathData;

    CGFloat x = [[data objectForKey:@"x"] floatValue];
    CGFloat y = [[data objectForKey:@"y"] floatValue];
    CGFloat cp1x = [[data objectForKey:@"cp1x"] floatValue];
    CGFloat cp1y = [[data objectForKey:@"cp1y"] floatValue];
    CGFloat cp2x = [[data objectForKey:@"cp2x"] floatValue];
    CGFloat cp2y = [[data objectForKey:@"cp2y"] floatValue];
//
//    UIBezierPath *path = [context currentPath];
//    [path addCurveToPoint:CGPointMake(x, y) controlPoint1:CGPointMake(cp1x, cp1y) controlPoint2:CGPointMake(cp2x, cp2y)];
    CGContextAddCurveToPoint(context, cp1x, cp1y, cp2x, cp2y, x, y);
}


- (void)rect:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    NSDictionary *data = self.pathData;

    CGFloat x = [[data objectForKey:@"x"] floatValue];
    CGFloat y =  [[data objectForKey:@"y"] floatValue];
    CGFloat width =  [[data objectForKey:@"w"] floatValue];
    CGFloat height =[[data objectForKey:@"h"] floatValue];

    CGRect rect = {x,y,width,height};
//    UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:rect];
//    UIBezierPath *path = [context currentPath];
//    [path appendPath:rectPath];
    
    CGContextAddRect(context, rect);
}

@end
