//
//  BDXLynxAbstractTextShadowNode.h
//  BDXElement
//
//  Created by li keliang on 2020/6/8.
//

#import <Lynx/LynxShadowNode.h>
#import "BDXLynxInlineElement.h"
#import "BDXLynxRichTextStyle.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxAbstractTextShadowNode : LynxShadowNode<BDXLynxInlineElement>

@property (nonatomic) BDXLynxRichTextStyle *textStyle;
@property (nonatomic, assign) BOOL dirty;

- (void)resetParagraphStyle:(void(^)(NSMutableParagraphStyle *paragraphStyle))block;

@end

NS_ASSUME_NONNULL_END
