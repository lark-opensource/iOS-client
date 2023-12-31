//
//  BDXRichTextFormater.h
//  BDXElement
//
//  Created by 李柯良 on 2020/7/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXRichTextFormater <NSObject>

- (NSAttributedString *)formateRawText:(NSString *)rawText defaultAttibutes:(NSDictionary<NSAttributedStringKey, id> *) defaultAttriutes;

@end

NS_ASSUME_NONNULL_END
