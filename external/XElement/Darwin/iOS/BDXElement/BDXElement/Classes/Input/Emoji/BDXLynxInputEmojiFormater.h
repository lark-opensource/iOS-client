//
//  BDXLynxInputEmojiFormater.h
//  BDXElement
//
//  Created by 张凯杰 on 2021/8/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXLynxInputEmojiFormater <NSObject>

- (NSAttributedString *)formateRawText:(NSString *)rawText defaultAttibutes:(NSDictionary<NSAttributedStringKey, id> *) defaultAttriutes;

@end

NS_ASSUME_NONNULL_END
