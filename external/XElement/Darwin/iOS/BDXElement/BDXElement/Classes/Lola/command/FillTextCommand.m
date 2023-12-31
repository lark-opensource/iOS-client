//
//  FillTextCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/4.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "FillTextCommand.h"

@interface FillTextCommand ()

@property(nonatomic, assign) CGPoint origin;
@property(nonatomic, copy) NSString *text;

@end

@implementation FillTextCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"ft";
}

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context
{
    NSInteger x = [[data objectForKey:@"x"] floatValue];
    NSInteger  y =  [[data objectForKey:@"y"] floatValue];
    
    self.origin = CGPointMake(x, y);
    
    self.text = [data objectForKey:@"text"];
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    //todo：font解析
    UIFont *font = drawContext.font ?: [UIFont systemFontOfSize:12.0];
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = drawContext.textAlign;

    NSDictionary *attriDict = @{NSFontAttributeName: font,
                                NSParagraphStyleAttributeName : style,
                                NSForegroundColorAttributeName : drawContext.fillColor ?: [UIColor blackColor]
                                };
    
    CGFloat originY = self.origin.y +[self calculateBaselineOffset:drawContext];
    CGContextSetTextDrawingMode(context, kCGTextFill);
    [self.text drawAtPoint:CGPointMake(self.origin.x, originY) withAttributes:attriDict];    
}

- (void)recycle {
    _origin = CGPointZero;
    _text = nil;
}

#pragma mark -
- (CGFloat)calculateBaselineOffset:(LolaDrawContext *)context
{
    CGFloat offset = 0;
    LolaTextBaseLine baselineType = context.baseLine;
    UIFont *font = [UIFont systemFontOfSize:15];

    switch (baselineType) {
        case LolaTextBaseLine_TOP:
        case LolaTextBaseLine_HANGDING:
            offset = font.leading;
            break;
        case LolaTextBaseLine_BOTTOM:
            offset = -font.lineHeight;
            break;
        case LolaTextBaseLine_MIDDLE:
            offset = font.lineHeight *0.5;
            break;
        default:
            break;
    }
    
    return offset;
}
@end
