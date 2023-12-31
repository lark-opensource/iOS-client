//
//  ACCEditPageTextStorage.m
//  CameraClient
//
//  Created by resober on 2020/3/3.
//

#import "ACCEditPageTextStorage.h"
#import <CreationKitInfra/ACCRTLProtocol.h>

@interface ACCEditPageTextStorage()
@property (nonatomic, strong) NSMutableAttributedString *storage;

@end

@implementation ACCEditPageTextStorage


- (instancetype)init{
    self = [super init];
    if (self) {
        _storage = [[NSMutableAttributedString alloc] initWithString:@"" attributes:nil];
        // ALPAttributedStringOperation hook the NSMutableAttributedString, add operation history to NSMutableAttributedString, if we don't disable Operations Collection, large amount of operation will be retained by NSMutableAttributedString
        [ACCRTL() disableOperationsCollectionForAttributedString:_storage];
    }
    return self;
}


#pragma mark - NSTextStorage Primitive Methods

- (NSString *)string {
    return self.storage.string;
}

- (NSDictionary<NSAttributedStringKey,id> *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    return [self.storage attributesAtIndex:location effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(nonnull NSString *)aString {
    [self beginEditing];
    [self.storage replaceCharactersInRange:range withString:aString];
    [self edited:NSTextStorageEditedCharacters range:range changeInLength:aString.length - range.length];
    [self endEditing];
}

- (void)setAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs range:(NSRange)range {
    [self beginEditing];
    [self.storage setAttributes:attrs range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)clearUnderlineStyleFirst {
    // clear all underlines first due to there are many extra underlines that add by `refreshUnderLineStyleForWikipediaAttachment`. If not clear first then will cause overlapping.
    [self beginEditing];
    NSRange range = NSMakeRange(0, self.storage.length);
    [self.storage addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleNone) range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

@end
