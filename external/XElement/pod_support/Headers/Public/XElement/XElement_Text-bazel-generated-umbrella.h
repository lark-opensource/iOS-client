#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "BDXBracketRichTextFormater.h"
#import "BDXLynxAbstractTextShadowNode.h"
#import "BDXLynxInlineElement.h"
#import "BDXLynxInlineEventTarget.h"
#import "BDXLynxInlineImageShadowNode.h"
#import "BDXLynxInlineTextShadowNode.h"
#import "BDXLynxInlineTruncationShadowNode.h"
#import "BDXLynxRichTextStyle.h"
#import "BDXLynxTextShadowNode.h"
#import "BDXLynxTextUI.h"
#import "BDXLynxVarietyTextShadowNode.h"
#import "BDXRichTextFormater.h"

FOUNDATION_EXPORT double XElementVersionNumber;
FOUNDATION_EXPORT const unsigned char XElementVersionString[];