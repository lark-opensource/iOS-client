//
//  DVETextInputHelper.h
//  NLEEditor
//
//  Created by Lincoln on 2021/12/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVETextInputHelper : NSObject

/// 判断此时输入框是否有高亮内容
+ (BOOL)hasHighLightTextInput:(id<UITextInput>)textInputView;

@end

NS_ASSUME_NONNULL_END
