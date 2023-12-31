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

#import "NSAttributedString+YYText.h"
#import "NSParagraphStyle+YYText.h"
#import "UIPasteboard+YYText.h"
#import "UIView+YYText.h"
#import "YYLabel.h"
#import "YYText.h"
#import "YYTextArchiver.h"
#import "YYTextAsyncLayer.h"
#import "YYTextAttribute.h"
#import "YYTextContainerView.h"
#import "YYTextDebugOption.h"
#import "YYTextEffectWindow.h"
#import "YYTextInput.h"
#import "YYTextKeyboardManager.h"
#import "YYTextLayout.h"
#import "YYTextLine.h"
#import "YYTextMagnifier.h"
#import "YYTextParser.h"
#import "YYTextRubyAnnotation.h"
#import "YYTextRunDelegate.h"
#import "YYTextSelectionView.h"
#import "YYTextTransaction.h"
#import "YYTextUtilities.h"
#import "YYTextView.h"
#import "YYTextWeakProxy.h"

FOUNDATION_EXPORT double YYTextVersionNumber;
FOUNDATION_EXPORT const unsigned char YYTextVersionString[];
