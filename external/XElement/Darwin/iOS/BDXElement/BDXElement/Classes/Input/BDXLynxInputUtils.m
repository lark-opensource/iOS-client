//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "BDXLynxInputUtils.h"
#import <Foundation/Foundation.h>
#import <CoreText/CTFramesetter.h>

@implementation BDXLynxInputUtils

+ (CGSize)getAttributedStringSize:(NSAttributedString *)attributedString
                      constraints:(CGSize)constraints {
    NSString *text = [attributedString string];
    NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
    // CoreText treats last newline as end of line instead of newline
    if (attributedString.length > 0 && [[text substringFromIndex:text.length - 1] isEqualToString:@"\n"]) {
        NSInteger nextLineIndex = attributedString.length - 1;
        NSAttributedString *nextLineString = [attributedString attributedSubstringFromRange:NSMakeRange(nextLineIndex, 1)];
        [mutableAttributedString appendAttributedString:nextLineString];
    }
    CGSize sizeThatFits = CGSizeZero;
    if (attributedString.length > 0) {
        CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)mutableAttributedString);
        sizeThatFits = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0,0), NULL, constraints, NULL);
        if (frameSetter) CFRelease(frameSetter);
    }
    
    return sizeThatFits;
}


@end
