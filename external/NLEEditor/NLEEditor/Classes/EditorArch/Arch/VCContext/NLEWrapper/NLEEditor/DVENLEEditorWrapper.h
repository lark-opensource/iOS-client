//
//  DVENLEEditorWrapper.h
//  NLEEditor
//
//  Created by bytedance on 2021/9/16.
//

#import <Foundation/Foundation.h>
#import "DVENLEEditorProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class NLEEditor_OC;

@interface DVENLEEditorWrapper : NSObject <DVENLEEditorProtocol>

- (instancetype)initWithNLEEditor:(NLEEditor_OC *)nleEditor;

@end

NS_ASSUME_NONNULL_END
