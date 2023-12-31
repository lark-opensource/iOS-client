//
//  AWE2DStickerTextGenerator.m
//  AAWELaunchMainPlaceholder-iOS8.0
//
//  Created by 赖霄冰 on 2019/4/15.
//

#import "AWE2DStickerTextGenerator.h"
#import <YYText/NSAttributedString+YYText.h>
#import <YYText/YYTextLayout.h>

#define A(x) (x & 0x000000FF)
#define B(x) ((x & 0x0000FF00) >> 8)
#define G(x) ((x & 0x00FF0000) >> 16)
#define R(x) ((x & 0xFF000000) >> 24)

@implementation AWE2DStickerTextGenerator

//        typedef struct {
//            int charSize;
//            int letterSpacing;
//            int lineWidth;
//            float lineHeight;
//            int textAlign;
//            int textIndent;
//            int split;
//
//            int lineCount;
//            char * familyName;
//            unsigned int textColor;
//            unsigned int backColor;
//            bool isPlaceholder;
//        } IESEffectTextLayoutStruct;
// 参数说明：https://bytedance.feishu.cn/space/doc/doccnNm5SSylruJ3GGCZbU#

+ (IESEffectBitmapStruct)generate2DTextBitmapWithText:(NSString *)text textLayout:(IESEffectTextLayoutStruct)layout {
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text ?: @""];
    attributedText.yy_font = [UIFont fontWithName:@(layout.familyName) size:layout.charSize] ?: [UIFont systemFontOfSize:layout.charSize];
    attributedText.yy_color = [UIColor colorWithRed:R(layout.textColor)/255.0 green:G(layout.textColor)/255.0 blue:B(layout.textColor)/255.0 alpha:A(layout.textColor)/255.0];
    attributedText.yy_kern = @(layout.letterSpacing);
    attributedText.yy_alignment = layout.textAlign;
    attributedText.yy_headIndent = layout.textIndent;
    attributedText.yy_lineHeightMultiple = layout.lineHeight;
    
    YYTextTruncationType truncationType;
    NSLineBreakMode lineBreakMode;
    switch (layout.split) {
        case 0:
            truncationType = YYTextTruncationTypeNone;
            lineBreakMode = NSLineBreakByWordWrapping;
            break;
        case 1:
            truncationType = YYTextTruncationTypeNone;
            lineBreakMode = NSLineBreakByWordWrapping;
            break;
        case 2:
            truncationType = YYTextTruncationTypeEnd;
            lineBreakMode = NSLineBreakByTruncatingTail;
            break;
        default:
            truncationType = YYTextTruncationTypeNone;
            lineBreakMode = NSLineBreakByWordWrapping;
            break;
    }

    // lineWidth=0 优先级 > lineCount 优先级，split优先级，
    CGSize rectSize;
    NSInteger lineCount;
    CGFloat drawWidth;
    if (layout.lineWidth == 0) {
        rectSize = [attributedText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, attributedText.yy_font.lineHeight) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        lineCount = 1;
        drawWidth = rectSize.width;
    } else {
        rectSize = CGSizeMake(layout.lineWidth, CGFLOAT_MAX);
        attributedText.yy_lineBreakMode = lineBreakMode;
        YYTextContainer *textContainer = [YYTextContainer containerWithSize:rectSize];
        textContainer.maximumNumberOfRows = layout.split == 0 ? 0 : layout.lineCount;
        textContainer.truncationType = truncationType;
        YYTextLayout *textLayout = [YYTextLayout layoutWithContainer:textContainer text:attributedText];
        rectSize = textLayout.textBoundingSize;
        lineCount = textLayout.rowCount;
        drawWidth = layout.lineWidth;
    }
    
    CGRect textRect = (CGRect){CGPointZero, rectSize};
    CGRect drawRect = CGRectMake(0, 0, drawWidth, CGRectGetHeight(textRect));
    
    if (CGRectIsEmpty(drawRect) || CGRectIsInfinite(drawRect)) {
        return [self p_emptyBitmap];
    }
    UIGraphicsBeginImageContext(drawRect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context == NULL) {
        return [self p_emptyBitmap];
    }
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:R(layout.backColor)/255.0 green:G(layout.backColor)/255.0 blue:B(layout.backColor)/255.0 alpha:A(layout.backColor)/255.0].CGColor);
    CGContextFillRect(context, textRect);
    
    [attributedText drawInRect:textRect];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // get raw pixels
    UInt32 *inputPixels;
    CGImageRef cgImage = [image CGImage];
    NSUInteger inputWidth = CGImageGetWidth(cgImage);
    NSUInteger inputHeight = CGImageGetHeight(cgImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bitsPerComponent = 8;
    NSUInteger inputBytesPerRow = bytesPerPixel * inputWidth;
    
    inputPixels = (UInt32 *)calloc(inputHeight * inputWidth, sizeof(UInt32));
    
    context = CGBitmapContextCreate(inputPixels,
                                    inputWidth,
                                    inputHeight,
                                    bitsPerComponent,
                                    inputBytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    if (context == NULL) {
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(context);
        free(inputPixels);
        return [self p_emptyBitmap];
    }
    
    CGContextDrawImage(context, drawRect, cgImage);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    IESEffectBitmapStruct bitmap;
    bitmap.data = (unsigned char *)inputPixels;
    bitmap.width = (int)inputWidth;
    bitmap.height = (int)inputHeight;
    bitmap.line = (int)lineCount;
    
    return bitmap;
}

+ (IESEffectBitmapStruct)p_emptyBitmap {
    IESEffectBitmapStruct bitmap;
    bitmap.data = NULL;
    bitmap.width = 0;
    bitmap.height = 0;
    bitmap.line = 0;
    return bitmap;
}

@end
