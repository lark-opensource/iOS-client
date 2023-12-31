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

#import "BDXExpandLynxInput.h"
#import "BDXExpandLynxTextArea.h"
#import "BDXLynxDialerKeyListener.h"
#import "BDXLynxDigitKeyListener.h"
#import "BDXLynxInput.h"
#import "BDXLynxInputBracketRichTextFormater.h"
#import "BDXLynxInputEmojiFormater.h"
#import "BDXLynxInputShadowNode.h"
#import "BDXLynxInputUtils.h"
#import "BDXLynxKeyListener.h"
#import "BDXLynxNumberKeyListener.h"
#import "BDXLynxTextArea.h"
#import "BDXLynxTextAreaShadowNode.h"
#import "BDXLynxTextKeyListener.h"
#import "BDXLynxTextView.h"
#import "InputType.h"

FOUNDATION_EXPORT double XElementVersionNumber;
FOUNDATION_EXPORT const unsigned char XElementVersionString[];