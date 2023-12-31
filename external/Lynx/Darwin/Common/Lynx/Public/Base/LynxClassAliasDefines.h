//  Copyright 2023 The Lynx Authors. All rights reserved.

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

#if TARGET_OS_IPHONE
typedef UIColor COLOR_CLASS;
typedef UITextView TEXTVIEW_CLASS;
typedef UIView VIEW_CLASS;
typedef UIImage IMAGE_CLASS;
#elif TARGET_OS_MAC
typedef NSColor COLOR_CLASS;
typedef NSTextView TEXTVIEW_CLASS;
typedef NSView VIEW_CLASS;
typedef NSImage IMAGE_CLASS;
#endif
