//
//  BDXBracketRichTextFormater.h
//  BDXElement
//
//  Created by 李柯良 on 2020/7/6.
//

#import <Foundation/Foundation.h>
#import "BDXRichTextFormater.h"

NS_ASSUME_NONNULL_BEGIN

@class BDXBracketRichTextFormater;
@protocol BDXBracketRichTextFormaterUIDelegate <NSObject>

@optional
- (NSAttributedString *)BDXBracketRichTextFormater:(BDXBracketRichTextFormater *)formator replaceAttributeMarkString:(NSAttributedString *)markString;

@end

@interface BDXBracketRichTextFormater : NSObject<BDXRichTextFormater>

+ (instancetype)sharedFormater;

@property (nonatomic, weak) id<BDXBracketRichTextFormaterUIDelegate> UIDelegate;

@end

NS_ASSUME_NONNULL_END
