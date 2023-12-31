//
//  TMAAttributedString.m
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/17.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import "NSAttributedString+TMASticker.h"

@implementation TMAAttributedStringMatchingResult
@end

@implementation NSAttributedString (TMAAddition)

- (NSRange)tma_rangeOfAll {
    return NSMakeRange(0, self.length);
}

- (NSString *)tma_plainTextForRange:(NSRange)range {
    if (range.location == NSNotFound || range.length == NSNotFound) {
        return nil;
    }

    NSMutableString *result = [[NSMutableString alloc] init];
    if (range.length == 0) {
        return result;
    }

    NSString *string = self.string;
    [self enumerateAttribute:TMATextBackedStringAttributeName inRange:range options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
        TMATextBackedString *backed = value;
        if (backed && backed.string) {
            [result appendString:backed.string];
        } else {
            [result appendString:[string substringWithRange:range]];
        }
    }];
    return result;
}

- (NSArray<TMAAttributedStringMatchingResult *> *)tma_findAllStringForAttributeName:(NSString *)attributeName backedStringClass:(Class)backedStringClass inRange:(NSRange)range {
    if (range.location == NSNotFound || range.length == NSNotFound) {
        return nil;
    }
    if (range.length == 0) {
        return nil;
    }
    
    NSMutableArray<TMAAttributedStringMatchingResult *> *results = [[NSMutableArray<TMAAttributedStringMatchingResult *> alloc] init];
    [self enumerateAttribute:attributeName inRange:range options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value && [value isKindOfClass:backedStringClass]) {
            TMAAttributedStringMatchingResult *result = [[TMAAttributedStringMatchingResult alloc] init];
            result.range = range;
            result.data = value;
            [results addObject:result];
        }
    }];
    return results;
}

@end

@implementation NSMutableAttributedString (TMAAddition)

- (void)tma_setTextBackedString:(TMATextBackedString *)textBackedString range:(NSRange)range {
    if (textBackedString && ![NSNull isEqual:textBackedString]) {
        [self addAttribute:TMATextBackedStringAttributeName value:textBackedString range:range];
    } else {
        [self removeAttribute:TMATextBackedStringAttributeName range:range];
    }
}

- (void)tma_setAtDataBackedString:(TMAAtDataBackedString *)atDataBackedString range:(NSRange)range {
    if (atDataBackedString && ![NSNull isEqual:atDataBackedString]) {
        [self addAttribute:TMAAtDataBackedStringAttributeName value:atDataBackedString range:range];
    } else {
        [self removeAttribute:TMAAtDataBackedStringAttributeName range:range];
    }
}

- (NSMutableAttributedString *)tma_replaceTextToEmojiForRange:(NSRange)range {
    NSMutableAttributedString *result = self;
    if (range.location == NSNotFound || range.length == NSNotFound) {
        return result;
    }
    if (range.length == 0) {
        return result;
    }
    
    [self enumerateAttribute:TMATextBackedStringAttributeName inRange:range options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
        TMATextBackedString *backed = value;
        if (backed && backed.string) {
            [result replaceCharactersInRange:range withString:backed.string];
        }
    }];
    return result;
}

@end
