//
//  BDXBracketRichTextFormater.m
//  BDXElement
//
//  Created by 李柯良 on 2020/7/6.
//

#import "BDXBracketRichTextFormater.h"

@interface BDXBracketMark : NSObject

@property (nonatomic) NSString *mark;
@property (nonatomic) NSRange  range;

@end

@implementation BDXBracketMark

@end

@implementation BDXBracketRichTextFormater

+ (instancetype)sharedFormater
{
    static BDXBracketRichTextFormater *formator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formator = [BDXBracketRichTextFormater new];
    });
    return formator;
}

- (NSAttributedString *)formateRawText:(NSString *)rawText defaultAttibutes:(NSDictionary<NSAttributedStringKey, id> *) defaultAttriutes
{
    NSMutableAttributedString *attributesString = [[NSMutableAttributedString alloc] initWithString:rawText attributes:defaultAttriutes];
    
    NSString *text = attributesString.string;
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[[^]]+?\\]" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray<NSTextCheckingResult *> *result = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    __block NSMutableArray<BDXBracketMark *> *bracketMarks = [NSMutableArray new];
    
    [result enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BDXBracketMark *mark = [BDXBracketMark new];
        mark.range = obj.range;
        mark.mark = [text substringWithRange:obj.range];
        [bracketMarks addObject:mark];
    }];
    
    __block NSInteger locationOffet = 0;
    [bracketMarks enumerateObjectsUsingBlock:^(BDXBracketMark * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSAttributedString *markString = [[NSAttributedString alloc] initWithString:obj.mark attributes:defaultAttriutes];
        NSAttributedString *replaceMarkString = nil;
        if ([self.UIDelegate respondsToSelector:@selector(BDXBracketRichTextFormater:replaceAttributeMarkString:)]) {
            replaceMarkString = [self.UIDelegate BDXBracketRichTextFormater:self replaceAttributeMarkString:markString];
        }
        
        if (replaceMarkString && ![markString isEqual:replaceMarkString]) {
            markString = replaceMarkString;
            [attributesString replaceCharactersInRange:NSMakeRange(obj.range.location + locationOffet, obj.range.length) withAttributedString:markString];
            locationOffet += (NSInteger)(markString.length - obj.mark.length);
        }
    }];
    
    return attributesString;
}


@end
