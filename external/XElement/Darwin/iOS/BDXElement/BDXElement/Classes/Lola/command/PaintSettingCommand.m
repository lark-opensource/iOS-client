//
//  PaintSettingCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/2.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "PaintSettingCommand.h"
#import <Lynx/LynxColorUtils.h>
#import "LolaFontUtil.h"

@interface PaintSettingCommand ()

@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, strong) UIColor *fillColor;

//private var strokeCap = Paint.Cap.BUTT
@property (nonatomic, assign) CGLineCap lineCap;
//private var lineJoin = Paint.Join.BEVEL
@property (nonatomic, assign) CGLineJoin lineJoin;

//private var textAlign = Paint.Align.LEFT
@property (nonatomic, assign) NSTextAlignment textAlign;

@property (nonatomic, strong) UIFont *font;

@property (nonatomic, assign) LolaTextBaseLine baseLine;

//  private var strokeWidth = DEFAULT_LINE_WIDTH
@property (nonatomic, assign) CGFloat lineWidth;

@property (nonatomic, assign) CGBlendMode blendMode;

//shadow
@property (nonatomic, assign) CGFloat shadowX;
@property (nonatomic, assign) CGFloat shadowY;
@property (nonatomic, assign) CGFloat shadowRadius;
@property (nonatomic, strong) UIColor *shadowColor;

@property (nonatomic, assign) CGFloat miterLimit;
@property (nonatomic, assign) CGFloat globalAlpha;
@property (nonatomic, assign) BOOL antiAlias;

@property (nonatomic, copy) NSString *subType;

//gradient
@property (nonatomic, assign) CGPoint start;
@property (nonatomic, assign) CGPoint end;
@property (nonatomic, strong) NSArray<UIColor *> *colors;
@property (nonatomic, strong) NSArray *locations;
@end

@implementation PaintSettingCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"ps";
}

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context
{
    //todo：所有objectForKey
    NSString *subType = [data objectForKey:@"st"];
    self.subType = subType;
    NSString *value = [data objectForKey:@"v"];
    if (subType.length <= 0) {
        return;
    }

    if ([subType isEqualToString:@"lc"]) {
        [self configLineCap:value];
    } else if ([subType isEqualToString:@"lj"]) {
        [self configLineJoin:value];
    } else if ([subType isEqualToString:@"ta"]) {
        [self configTextAlign:value];
    } else if ([subType isEqualToString:@"ml"]) {
        self.miterLimit = [value floatValue];
    } else if ([subType isEqualToString:@"lw"]) {
        self.lineWidth = [value floatValue];
    } else if ([subType isEqualToString:@"fs"]) {
        self.fillColor = [LynxColorUtils convertNSStringToUIColor:value];
    } else if ([subType isEqualToString:@"ss"]) {
        self.strokeColor = [LynxColorUtils convertNSStringToUIColor:value];
    } else if ([subType isEqualToString:@"ga"]) {
        self.globalAlpha = [value floatValue];
    } else if ([subType isEqualToString:@"sx"]) {
        self.shadowX = [value floatValue];
    } else if ([subType isEqualToString:@"sy"]) {
        self.shadowY = [value floatValue];
    } else if ([subType isEqualToString:@"sr"]) {
        self.shadowRadius = [value floatValue];
    } else if ([subType isEqualToString:@"sc"]) {
        self.shadowColor = [LynxColorUtils convertNSStringToUIColor:value];
    } else if ([subType isEqualToString:@"ft"]) {
        [self configFontStyle:value];
    } else if ([subType isEqualToString:@"bl"]) {
//        self.baseLine =
    } else if ([subType isEqualToString:@"sld"]) {
        [self configLinearGradient:data];
    } else if ([subType isEqualToString:@"srd"]) {
    } else if ([subType isEqualToString:@"gco"]) {
        [self configBlendMode:value];
    } else if ([subType isEqualToString:@"aa"]) {
        self.antiAlias = [value boolValue];
    }
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    NSString *subType = self.subType;

    if ([subType isEqualToString:@"lc"]) {
        drawContext.lineCap = self.lineCap;
        CGContextSetLineCap(context, self.lineCap);
    } else if ([subType isEqualToString:@"lj"]) {
        drawContext.lineJoin = self.lineJoin;
        CGContextSetLineJoin(context, self.lineJoin);
    } else if ([subType isEqualToString:@"ta"]) {
        drawContext.textAlign = self.textAlign;
    } else if ([subType isEqualToString:@"ml"]) {
        drawContext.miterLimit = self.miterLimit;
        CGContextSetMiterLimit(context, self.miterLimit);
    } else if ([subType isEqualToString:@"lw"]) {
        drawContext.lineWidth = _lineWidth;
        CGContextSetLineWidth(context,self.lineWidth);
    } else if ([subType isEqualToString:@"fs"]) {
        drawContext.fillColor = self.fillColor;
        CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
    } else if ([subType isEqualToString:@"ss"]) {
        drawContext.strokeColor = _strokeColor;
        CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);
    } else if ([subType isEqualToString:@"ga"]) {
        drawContext.globalAlpha = _globalAlpha;
        CGContextSetAlpha(context, self.globalAlpha);
    } else if ([subType isEqualToString:@"sx"]) {
        drawContext.shadowX = _shadowX;
        [self setShadow:context drawContext:drawContext];
    } else if ([subType isEqualToString:@"sy"]) {
        drawContext.shadowY = _shadowY;
        [self setShadow:context drawContext:drawContext];
    } else if ([subType isEqualToString:@"sr"]) {
        drawContext.shadowRadius = _shadowRadius;
        [self setShadow:context drawContext:drawContext];
    } else if ([subType isEqualToString:@"sc"]) {
        drawContext.shadowColor = _shadowColor;
        [self setShadow:context drawContext:drawContext];
    } else if ([subType isEqualToString:@"ft"]) {
        drawContext.font = self.font;
    } else if ([subType isEqualToString:@"bl"]) {
        //baseLine
        drawContext.baseLine = self.baseLine;
    } else if ([subType isEqualToString:@"sld"]) {
        //LinearShader
        [self drawGradient:context drawContext:drawContext linear:YES];
    } else if ([subType isEqualToString:@"srd"]) {
        //RadialShader
    } else if ([subType isEqualToString:@"gco"]) {
        drawContext.blendMode = self.blendMode;
        CGContextSetBlendMode(context, self.blendMode);
    } else if ([subType isEqualToString:@"aa"]) {
        //AntiAlias
        drawContext.antiAlias = self.antiAlias;
        CGContextSetShouldAntialias(context,self.antiAlias);
    }
}


#pragma mark - private
- (void)configLineCap:(NSString *)cap
{
    if ([cap isEqualToString:@"butt"]) {
        self.lineCap = kCGLineCapButt;
    } else if ([cap isEqualToString:@"square"]) {
        self.lineCap = kCGLineCapSquare;
    } else if ([cap isEqualToString:@"round"]) {
        self.lineCap = kCGLineCapRound;
    }
}

- (void)configLineJoin:(NSString *)join
{
    if ([join isEqualToString:@"bevel"]) {
        self.lineJoin = kCGLineJoinBevel;
    } else if ([join isEqualToString:@"miter"]) {
        self.lineJoin = kCGLineJoinMiter;
    } else if ([join isEqualToString:@"round"]) {
        self.lineJoin = kCGLineJoinRound;
    }
}

- (void)configTextAlign:(NSString *)align
{
    if ([align isEqualToString:@"center"]) {
        self.textAlign = NSTextAlignmentCenter;
    } else if ([align isEqualToString:@"start"]) {
        self.textAlign = NSTextAlignmentLeft;
    } else if ([align isEqualToString:@"end"]) {
        self.textAlign = NSTextAlignmentRight;
    } else if ([align isEqualToString:@"left"]) {
        self.textAlign = NSTextAlignmentLeft;
    } else if ([align isEqualToString:@"right"]) {
        self.textAlign = NSTextAlignmentRight;
    }
}

- (void)configBlendMode:(NSString *)mode
{
    if ([mode isEqualToString:@"source-over"]) {
        self.blendMode = kCGBlendModeNormal;
    } else if ([mode isEqualToString:@"source-atop"]) {
        self.blendMode = kCGBlendModeSourceAtop;
    } else if ([mode isEqualToString:@"source-in"]) {
        self.blendMode = kCGBlendModeSourceIn;
    } else if ([mode isEqualToString:@"source-out"]) {
        self.blendMode = kCGBlendModeSourceOut;
    } else if ([mode isEqualToString:@"destination-over"]) {
        self.blendMode = kCGBlendModeDestinationOver;
    } else if ([mode isEqualToString:@"destination-atop"]) {
        self.blendMode = kCGBlendModeDestinationAtop;
    } else if ([mode isEqualToString:@"destination-in"]) {
        self.blendMode = kCGBlendModeDestinationIn;
    } else if ([mode isEqualToString:@"destination-out"]) {
        self.blendMode = kCGBlendModeDestinationOut;
    } else if ([mode isEqualToString:@"lighter"]) {
        self.blendMode = kCGBlendModePlusLighter;
    } else if ([mode isEqualToString:@"copy"]) {
        self.blendMode = kCGBlendModeCopy;
    } else if ([mode isEqualToString:@"xor"]) {
        self.blendMode = kCGBlendModeXOR;
    } else if ([mode isEqualToString:@"clear"]) {
        self.blendMode = kCGBlendModeClear;
    } else {
        self.blendMode = kCGBlendModeNormal;
    }
}

- (void)configBaseLine:(NSString *)baseLine
{
    if ([baseLine isEqualToString:@"top"]) {
        self.baseLine = LolaTextBaseLine_TOP;
    } else if ([baseLine isEqualToString:@"bottom"]) {
        self.baseLine = LolaTextBaseLine_BOTTOM;
    } else if ([baseLine isEqualToString:@"middle"]) {
        self.baseLine = LolaTextBaseLine_MIDDLE;
    } else if ([baseLine isEqualToString:@"hanging"]) {
        self.baseLine = LolaTextBaseLine_HANGDING;
    } else {
        self.baseLine = LolaTextBaseLine_Normal;
    }
}

- (void)configFontStyle:(NSString *)style
{
   self.font = [LolaFontUtil parseFontWithStyle:style];
}

- (void)configLinearGradient:(NSDictionary *)data
{
    CGFloat x0 = [[data objectForKey:@"x0"] floatValue];
    CGFloat y0 =  [[data objectForKey:@"y0"] floatValue];
    CGFloat x1 =  [[data objectForKey:@"x1"] floatValue];
    CGFloat y1 =[[data objectForKey:@"y1"] floatValue];
    
    self.start = CGPointMake(x0, y0);
    self.end = CGPointMake(x1, y1);
    
    NSMutableArray *array = [NSMutableArray array];
    NSArray *colorStyles = [data objectForKey:@"cs"];
    for (NSString *style in colorStyles) {
        UIColor *color = [LynxColorUtils convertNSStringToUIColor:style];
        [array addObject:(__bridge id)color.CGColor];
    }
    
    self.colors = array;
    self.locations = [data objectForKey:@"ps"];
}

- (void)configRadialGradient:(NSDictionary *)data
{
    CGFloat r0 = [[data objectForKey:@"r0"] floatValue];
    CGFloat r1 =  [[data objectForKey:@"r1"] floatValue];
    
    [self configLinearGradient:data];
}

- (void)setShadow:(CGContextRef)context drawContext:(LolaDrawContext *)drawContext
{
    CGSize offset = {drawContext.shadowX, drawContext.shadowY};
    CGFloat blur = drawContext.shadowRadius;
    UIColor *color = drawContext.shadowColor;
    
    CGContextSetShadowWithColor(context, offset, blur, color.CGColor);
}

- (void)drawGradient:(CGContextRef)context drawContext:(LolaDrawContext *)drawContext linear:(BOOL)isLinear
{
    CGFloat locations[self.locations.count];
    NSInteger i = 0;
    for (NSNumber *location in self.locations) {
        locations[i] = location.floatValue;
        i++;
    }

    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(rgb, (__bridge CFArrayRef)self.colors, locations);
    CGGradientDrawingOptions options = kCGGradientDrawsBeforeStartLocation|kCGGradientDrawsAfterEndLocation;
    
    //todo options
    if (isLinear) {
//        CGContextDrawLinearGradient(context, gradient, _start, _end, options);
    } else {
//        CGContextDrawRadialGradient(context, gradient, _start, _end, CGPointZero, 0, options);
    }

//    free(locations);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(rgb);
}

- (void)recycle {
   _strokeColor = nil;
   _fillColor = nil;
//   _lineCap;
//   _lineJoin;
//_textAlign;
//_textSize;  //?font
//_baseLine;
//_lineWidth;
//_blendMode;
//_shadowX;
//_shadowY;
//_shadowRadius;
//_shadowColor;
//_miterLimit;
//_globalAlpha;
//_antiAlias;
//_subType;
//_start;
//_end;
//_colors;
//_locations;
}

@end
