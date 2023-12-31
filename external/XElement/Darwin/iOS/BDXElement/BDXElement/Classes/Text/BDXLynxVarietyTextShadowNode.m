//
//  BDXLynxVarietyTextShadowNode.m
//  BDXElement
//
//  Created by li keliang on 2020/6/8.
//

#import "BDXLynxVarietyTextShadowNode.h"
#import "BDXLynxInlineTextShadowNode.h"
#import <Lynx/LynxHtmlEscape.h>
#import <Lynx/LynxRawTextShadowNode.h>

@implementation BDXLynxVarietyTextShadowNode

- (void)reloadInlineTexts
{
    self.textStyle.truncationAttributeString = nil;
    [self.textStyle.attributeTexts removeAllObjects];
    [self.children enumerateObjectsUsingBlock:^(LynxShadowNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:LynxRawTextShadowNode.class]) {
            LynxRawTextShadowNode *rawText = (LynxRawTextShadowNode *)obj;
            NSString *rawTextString = rawText.text;
            if ([rawTextString rangeOfString:@"&"].location != NSNotFound) {
              rawTextString = [rawTextString stringByUnescapingFromHtml];
            }
            if (!self.textStyle.noTrim) {
              rawTextString = [rawTextString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
            
            if (rawTextString.length == 0) {
                return;
            }

            if (self.textStyle.richTextFormater) {
                NSAttributedString *text = [self.textStyle.richTextFormater formateRawText:rawTextString defaultAttibutes:self.textStyle.defaultAttriutes];
                [self.textStyle appendAttributeText:text];
            } else {
                NSAttributedString *text = [[NSAttributedString alloc] initWithString:rawTextString attributes:self.textStyle.defaultAttriutes];
                [self.textStyle appendAttributeText:text];
            }
        }
        else if([obj respondsToSelector:@selector(inlineAttributeString)]) {
            if ([obj isKindOfClass:BDXLynxInlineTextShadowNode.class]) {
                BDXLynxInlineTextShadowNode *inlineNode = (BDXLynxInlineTextShadowNode*) obj;
                if (self.textStyle.richTextFormater) {
                    inlineNode.textStyle.richTextFormater = self.textStyle.richTextFormater;
                }
                [inlineNode.textStyle updateTextStyle:self.textStyle];
            }
            if (self.textStyle.richTextFormater && [obj isKindOfClass:BDXLynxInlineTextShadowNode.class]) {
              ((BDXLynxInlineTextShadowNode*) obj).textStyle.richTextFormater = self.textStyle.richTextFormater;
            }
            NSAttributedString *text = ((id<BDXLynxInlineElement>)obj).inlineAttributeString;
            if (!text) {
                return;
            }
            [self.textStyle appendAttributeText:text];
        }
    }];
}

- (NSAttributedString *)inlineAttributeString
{
    __block BOOL dirty = NO;
    [self.children enumerateObjectsUsingBlock:^(LynxShadowNode *obj, NSUInteger idx, BOOL *stop) {
        BDXLynxAbstractTextShadowNode *node = (BDXLynxAbstractTextShadowNode *)obj;
        if ([node isKindOfClass:BDXLynxAbstractTextShadowNode.class]) {
            if (node.dirty) {
                node.dirty = NO;
                dirty = YES;
            }
        }
    }];
    if (self.textStyle.ultimateAttributedString.length == 0 || dirty) {
        [self reloadInlineTexts];
    }
    
    return self.textStyle.ultimateAttributedString;
}


@end
