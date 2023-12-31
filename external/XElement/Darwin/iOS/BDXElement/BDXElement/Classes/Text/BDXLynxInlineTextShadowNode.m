//
//  BDXLynxInlineTextShadowNode.m
//  BDXElement
//
//  Created by li keliang on 2020/6/8.
//

#import "BDXLynxInlineTextShadowNode.h"
#import "BDXLynxInlineEventTarget.h"

#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxHtmlEscape.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxRawTextShadowNode.h>

@interface BDXLynxInlineTextShadowNode()

@end

@implementation BDXLynxInlineTextShadowNode

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_SHADOW_NODE("x-inline-text")
#else
LYNX_REGISTER_SHADOW_NODE("x-inline-text")
#endif

- (BOOL)isVirtual
{
    return YES;
}

- (NSAttributedString *)inlineAttributeString
{

    [self.textStyle.attributeTexts removeAllObjects];

    for (LynxShadowNode * _Nonnull inlineTextChild in self.children) {

        if ([inlineTextChild isKindOfClass:LynxRawTextShadowNode.class]) {
            NSString *inlineTextString =((LynxRawTextShadowNode*) inlineTextChild).text;
            if ([inlineTextString rangeOfString:@"&"].location != NSNotFound) {
              inlineTextString = [inlineTextString stringByUnescapingFromHtml];
            }
            if (!self.textStyle.noTrim) {
              inlineTextString = [inlineTextString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
            if (inlineTextString.length == 0) {
              continue;
            }
            
            NSAttributedString *text = nil;
            if (self.textStyle.richTextFormater) {
                text = [self.textStyle.richTextFormater formateRawText:inlineTextString defaultAttibutes:self.textStyle.defaultAttriutes];
            } else {
                text = [[NSAttributedString alloc] initWithString:inlineTextString attributes:self.textStyle.defaultAttriutes];
            }

            [self.textStyle appendAttributeText:text];
        } else if ([inlineTextChild isKindOfClass:[BDXLynxAbstractTextShadowNode class]]) {
          [self.textStyle appendAttributeText:[((BDXLynxAbstractTextShadowNode*) inlineTextChild) inlineAttributeString]];
        }
    }

    NSMutableAttributedString* str = self.textStyle.ultimateAttributedString;
  
    if (str.length == 0) {
        return nil;
    }

    [str addAttribute:[NSString stringWithFormat:@"%@%@", BDXLynxInlineElementSignKey, @(self.sign)]
                value:[[BDXLynxTextInfo alloc] initWithShadowNode:self]
                range:NSMakeRange(0, str.length)];
    return str;
}

- (BOOL)needsEventSet {
    return YES;
}
@end
