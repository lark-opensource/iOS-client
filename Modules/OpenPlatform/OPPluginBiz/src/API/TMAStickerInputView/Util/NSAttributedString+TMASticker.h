//
//  TMAAttributedString.h
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/17.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMATextBackedString.h"
#import "TMAAtDataBackedString.h"

@interface TMAAttributedStringMatchingResult: NSObject
@property (nonatomic, assign) NSRange range;
@property (nonatomic, strong) id data;
@end

@interface NSAttributedString (TMAAddition)

- (NSRange)tma_rangeOfAll;

- (nullable NSString *)tma_plainTextForRange:(NSRange)range;

- (NSArray<TMAAttributedStringMatchingResult *> *)tma_findAllStringForAttributeName:(NSString *)attributeName backedStringClass:(Class)backedStringClass inRange:(NSRange)range;

@end

@interface NSMutableAttributedString (TMAAddition)

- (void)tma_setTextBackedString:(nullable TMATextBackedString *)textBackedString range:(NSRange)range;

- (void)tma_setAtDataBackedString:(nullable TMAAtDataBackedString *)atDataBackedString range:(NSRange)range;

- (NSMutableAttributedString *)tma_replaceTextToEmojiForRange:(NSRange)range;

@end
