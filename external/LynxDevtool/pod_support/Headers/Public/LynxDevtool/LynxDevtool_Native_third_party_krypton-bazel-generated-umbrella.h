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

#import "third_party/krypton/glue/canvas_manager_interface.h"
#import "third_party/krypton/glue/canvas_runtime.h"
#import "third_party/krypton/glue/canvas_runtime_observer.h"
#import "third_party/krypton/glue/lynx_canvas_runtime.h"

FOUNDATION_EXPORT double LynxDevtoolVersionNumber;
FOUNDATION_EXPORT const unsigned char LynxDevtoolVersionString[];