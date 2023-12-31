//
//  BDXLynxInlineTruncationShadowNode.m
//  BDXElement
//
//  Created by li keliang on 2020/6/8.
//

#import "BDXLynxInlineTruncationShadowNode.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>

// represent '...'
#define ELLIPSIS @OS_STRINGIFY(\u2026)

@implementation BDXLynxInlineTruncationShadowNode

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_SHADOW_NODE("x-inline-truncation")
#else
LYNX_REGISTER_SHADOW_NODE("x-inline-truncation")
#endif

- (BOOL)isVirtual
{
    return YES;
}

- (NSAttributedString *)truncationAttributeString
{
    
    NSMutableAttributedString *trucation = [[super inlineAttributeString] mutableCopy];
    // truncation... use parent attribut since, this part is belong to previouse sub text
    if (!self.parent || ![self.parent isKindOfClass:BDXLynxAbstractTextShadowNode.class]) {
      return nil;
    }
    BDXLynxAbstractTextShadowNode* parent = (BDXLynxAbstractTextShadowNode*)self.parent;
    NSMutableDictionary<NSAttributedStringKey, id> * attribute = [parent.textStyle.defaultAttriutes mutableCopy];
    NSMutableParagraphStyle * paraStyle = [parent.textStyle.paragraphStyle mutableCopy];
    // FIXME(zhixuan): Hack to work around bug of YYText, which truncation does not work \
    // when text-align of the paragraph is not left
    paraStyle.alignment = NSTextAlignmentLeft;
    attribute[NSParagraphStyleAttributeName] = paraStyle;
    
    NSAttributedString *defaultAttibuteString = [[NSAttributedString alloc] initWithString:ELLIPSIS attributes:attribute];

    [trucation insertAttributedString:defaultAttibuteString atIndex:0];
    return trucation;
}

- (NSAttributedString *)inlineAttributeString
{
    return nil;
}

@end
