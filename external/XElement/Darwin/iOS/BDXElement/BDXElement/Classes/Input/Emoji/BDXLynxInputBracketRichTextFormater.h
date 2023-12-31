//
//  BDXLynxInputBracketRichTextFormater.h
//  BDXElement
//
//  Created by 张凯杰 on 2021/8/9.
//

#import <Foundation/Foundation.h>
#import "BDXLynxInputEmojiFormater.h"

UIKIT_EXTERN NSString *const LynxInputTextAttachmentToken;

NS_ASSUME_NONNULL_BEGIN

@interface LynxTextareaAttachment : NSTextAttachment

@property (nullable, nonatomic, strong) NSDictionary *attachmentInfo;

- (NSString *)getAttachmentName;

@end

@class BDXLynxInputBracketRichTextFormater;
@protocol BDXLynxInputBracketRichTextFormaterUIDelegate <NSObject>

@optional
- (NSAttributedString *)BDXLynxInputBracketRichTextFormater:(BDXLynxInputBracketRichTextFormater *)formator replaceAttributeMarkString:(NSAttributedString *)markString;

@end

@interface BDXLynxInputBracketRichTextFormater : NSObject<BDXLynxInputEmojiFormater>

+ (instancetype)sharedFormater;

@property (nonatomic, weak) id<BDXLynxInputBracketRichTextFormaterUIDelegate> UIDelegate;

@end

NS_ASSUME_NONNULL_END
