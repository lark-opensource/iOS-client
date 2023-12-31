//
//  BDXLynxInputBracketRichTextFormater.m
//  BDXElement
//
//  Created by 张凯杰 on 2021/8/9.
//

#import "BDXLynxInputBracketRichTextFormater.h"

NSString *const LynxInputTextAttachmentToken = @"\uFFFC";

@implementation LynxTextareaAttachment

- (NSString *)getAttachmentName {
    NSArray* keys = [_attachmentInfo allKeys];
    if ([keys containsObject:@"imageName"]) {
        return [_attachmentInfo objectForKey:@"imageName"];
    }
    return nil;
}

@end

@interface BDXLynxInputBracketMark : NSObject

@property (nonatomic) NSAttributedString *mark;
@property (nonatomic) NSRange  range;

@end

@implementation BDXLynxInputBracketMark

@end

@implementation BDXLynxInputBracketRichTextFormater

+ (instancetype)sharedFormater
{
    static BDXLynxInputBracketRichTextFormater *formator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formator = [BDXLynxInputBracketRichTextFormater new];
    });
    return formator;
}

- (NSAttributedString *)formateRawText:(NSString *)rawText defaultAttibutes:(NSDictionary<NSAttributedStringKey, id> *)defaultAttriutes
{
    NSMutableAttributedString *attributesString = [rawText mutableCopy];
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\[)([^\\[\\]]+)(])" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray<NSTextCheckingResult *> *result = [regex matchesInString:[attributesString string] options:0 range:NSMakeRange(0, attributesString.length)];
    __block NSMutableArray<BDXLynxInputBracketMark *> *bracketMarks = [NSMutableArray new];
    
    [result enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BDXLynxInputBracketMark *mark = [BDXLynxInputBracketMark new];
        mark.range = obj.range;
        mark.mark = [attributesString attributedSubstringFromRange:obj.range];
        [bracketMarks addObject:mark];
    }];
    
    __block NSInteger locationOffet = 0;
    [bracketMarks enumerateObjectsUsingBlock:^(BDXLynxInputBracketMark * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSAttributedString *markString = [[NSAttributedString alloc] initWithAttributedString:obj.mark];
        NSAttributedString *replaceMarkString = nil;
        if ([self.UIDelegate respondsToSelector:@selector(BDXLynxInputBracketRichTextFormater:replaceAttributeMarkString:)]) {
            replaceMarkString = [self.UIDelegate BDXLynxInputBracketRichTextFormater:self replaceAttributeMarkString:markString];
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
